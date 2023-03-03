.model tiny
.code
.186

org 100h
locals @@

Start: jmp Main

;----------------------------------------------------------------------
PUSH_HOT_KEY equ 20h    ;   scan code of pushed hot key
PULL_HOT_KEY equ 0A0h   ;   scan code of pulled hot key
BUFF_SIZE    equ 15d*80d;   size of buffers (in words)
;----------------------------------------------------------------------
old_09h_addr    dd ?
old_08h_addr    dd ?

frame_status    db 0h               ;   frame switched (on: 1)/(off: 0)

buff_image      dw 2*BUFF_SIZE DUP(?)
buff_saved      dw 2*BUFF_SIZE DUP(?)

show_frame_data db "0 0 13 72 03 0 ", 0h
;                   _ - вертикальный отступ
;                     _ - горизонтальный отступ
;                       __ - высота рамки
;                          __ - ширина рамки
;                             __ - color attr
;                                _ - тип рамки
;----------------------------------------------------------------------

;======================================================================
; Кладет значения всех регистров перед прерыванием в стек
;======================================================================
; Entry: ______________________
;       |_flags_|_CS_|_IP_|_AX_|
;       ^         seg:ofs   ^AX перед прерыванием
;       SP перед прерыванием
;----------------------------------------------------------------------
; Exit:                        __________________________________________________________________
;        _____________________|__________________________________________________________________|___
;       |_flags_|_CS_|_IP_|_AX_|_BP_|_IP_|_ES_|_SS_|_DS_|_CS_|_SP_|_BP_|_DI_|_SI_|_DX_|_CX_|_BX_|_AX_|
;       ^          |    |_____________|                   |    |
;       |          |______________________________________|    |
;       |______________________________________________________|
;
;======================================================================

save_all_reg macro
        push bp                 ;   save bp
        mov  bp, sp
        mov  ax, ss:[bp+4]      ;   ax = old_ip
        push ax es ss ds
        mov  ax, ss:[bp+6]      ;   ax = old_cs
        push ax
        mov  ax, bp             ;
        add  ax, 10d            ;   ax = old_sp
        push ax
        mov  ax, ss:[bp]        ;   ax = old_bp
        push ax di si dx cx bx
        mov  ax, ss:[bp+2]      ;   ax = old_ax
        push ax

        endm

;======================================================================
; Восстанавливает значения всех регистров (кроме CS, IP, SP) перед прерыванием из стека
; (Обратный к save_all_reg)
;======================================================================

restore_all_reg macro
        pop ax bx cx dx si di bp
        pop ax                  ;   ax = old_sp
        pop ax                  ;   ax = old_cs
        pop ds ss es
        pop ax                  ;   ax = old_ip
        pop ax                  ;   ax = old_bp (bp already restored)

        endm

;======================================================================
; Копирует содержимое buff_from в buff_to
;======================================================================

copy_buff macro seg_from, ofs_from, seg_to, ofs_to
        mov ax, seg_from
        mov ds, ax              ;   ds -> seg_from
        mov si, ofs_from        ;   si =  ofs_from

        mov ax, seg_to
        mov es, ax              ;   es -> seg_to
        mov di, ofs_to          ;   di =  ofs_to

        mov cx, 2*BUFF_SIZE     ;   cx = size of buffers in bytes
        call memcpy

        endm

;======================================================================
; Обновляет buff_saved значениями из video segment, которые не совпадают со
; значениями соответствующих ячеек в buff_image
;======================================================================
; Destroys: BX, CX, SI, DI, DS, ES
;======================================================================

upd_buff macro
        mov ax, 0B800h
        mov ds, ax          ;   ds -> video segment
        xor si, si          ;   si -> video offset

        mov ax, cs
        mov es, ax          ;   es =  cs
        lea di, buff_image  ;es:di -> buff_image
        lea bx, buff_saved  ;es:bx -> buff_saved

        mov cx, BUFF_SIZE
        call upd_buffer

        endm

;======================================================================
; Рисует рамку с регистрами
;======================================================================

draw_frame_reg macro frm_data_seg, frm_data_ofs, draw_seg, reg_clr_attr, reg_ofs
        ;-----------------------
        mov ax, frm_data_seg
        mov ds, ax              ;   ds -> frame_data_seg
        lea si, frm_data_ofs    ;   si -> frame_data_ofs
        mov ax, draw_seg
        mov es, ax              ;   es -> draw_seg
        cld                     ;   df = 0
        ;-----------------------;   параметры для рамки
        call frame

        ;-----------------------
        mov ah, reg_clr_attr    ;   ah =  color attr
        mov di, reg_ofs         ;   di -  register's offset
        mov bp, sp              ;   bp -> top of stack
        ;-----------------------;   параметры для регистров
        call draw_all_reg

        endm


;======================================================================
; Перехват INT 09h
;----------------------------------------------------------------------
; Выводит рамку и состояния регистров в видеопамять при нажатии D
; Передает управление старому обработчику иначе
;======================================================================

New_09h proc
        cld
        push ax
        in   al, 60h            ;   al = scan_code нажатой клавиши

        cmp  al, PULL_HOT_KEY
        je   @@Exit             ;   if (al == PULL_HOT_KEY) jmp @@Exit
        cmp  al, PUSH_HOT_KEY
        jne  @@Old_handler      ;   if (al != PUSH_HOT_KEY) jmp @@Old_handler
        jmp  @@Frame_key        ;   else                    jmp @@Frame_key

@@Old_handler:
        pop ax
        jmp dword ptr cs:old_09h_addr

@@Exit:
        in   al,  61h           ;   al = 61h
        mov  ah,  al            ;   ah = al (save al)
        or   al,  80h           ;
        out  61h, al            ;
        xchg al,  ah            ;
        out  61h, al            ;   мигнули старшим битом 61h

        mov al, 20h
        out 20h, al             ;   сигнал контроллеру прерываний

        pop ax
        iret

@@Frame_key:
        test cs:frame_status, 0FFh
        jnz  @@Hide_frame       ;   if (cs:frame_status != 0) jmp @@Hide_frame
                                ;   else                          @@Show_frame
@@Show_frame:
        save_all_reg

        copy_buff 0B800h 0 cs <offset buff_saved>    ;   video --cp--> buff_saved
        ;-------seg_from
        ;---------ofs_from
        ;--------------seg_to
        ;-------------------------ofs_to

        mov  cs:frame_status, 1
        draw_frame_reg cs show_frame_data 0B800h 07h 65d*2d+160d    ;   draw frame and registers in video segment
        ;----frm_data_seg
        ;--------------------frm_data_ofs
        ;-------------------------------draw_seg
        ;-----------------------------------clr_attr
        ;------------------------------------------------reg_ofs

        copy_buff 0B800h 0 cs <offset buff_image> ;   video --cp--> buff_image

        restore_all_reg
        jmp @@Exit

@@Hide_frame:
        push bx cx si di ds es

        upd_buff
        copy_buff cs <offset buff_saved> 0B800h 0
        mov cs:frame_status, 0

        pop es ds di si cx bx
        jmp @@Exit

New_09h endp

;======================================================================
; Перехват INT 08h
;----------------------------------------------------------------------
; Обновляет значения регистров (если включен режим показа регистров),
; передает управление старому обработчику
;======================================================================

New_08h proc

        test cs:frame_status, 0FFh
        jz   @@Old_handler          ;   if (cs:frame_status == 0) jmp @@Old_handler
                                    ;   else                          @@Upd_reg
@@Upd_reg:
        push ax
        save_all_reg

        upd_buff
        draw_frame_reg cs show_frame_data 0B800h 07h 65d*2d+160d    ;   draw frame and registers in video segment
        ;----frm_data_seg
        ;---------------------frm_data_ofs
        ;-------------------------------draw_seg
        ;----------------------------------clr_attr
        ;------------------------------------- ----------reg_ofs

        copy_buff 0B800h 0 cs <offset buff_image> ;   video --cp--> buff_image

        restore_all_reg
        pop ax

@@Old_handler:
        jmp dword ptr cs:old_08h_addr

New_08h endp

;======================================================================
; Выводит в видеопамять (или другой сегмент) состояния всех регистров,
; каждый на отдельной строке
; Порядок вывода:
; AX BX CX DX SI DI BP SP CS DS SS ES IP
;======================================================================
; Entry: ES:DI -  start addr to print
;           AH -  color attr
;           BP -> top of stack
; Stack:    IP ES SS DS CS SP BP DI SI DX CX BX AX  - values to print
;           12 11 10  9  8  7  6  5  4  3  2  1  0
;                                                ^BP
;----------------------------------------------------------------------
; Expects:  ES -> frame segment
;           df = 0
;----------------------------------------------------------------------
; Exit:     None
; Destroys: AL, BX, CX, SI, DI, BP
;======================================================================

draw_all_reg    proc

        lea si, reg_name    ;   ds:si - адрес имен регистров
        mov cx, 13d         ;   cx    - кол-во регистров

@@Next: mov  bx, ss:[bp]    ;   bx = очередной регистр
        push cx di
        call draw_one_reg
        pop  di cx

        add di, 160d        ;   перевод строки
        add bp, 2           ;   ss:[bp] -> следующий регистр
        loop @@Next

        ret

draw_all_reg    endp

;----------------------------------------------------------------------
reg_name db "AX", "BX", "CX", "DX", "SI", "DI", "BP", "SP", "CS", "DS", "SS", "ES", "IP"

;======================================================================
; Выводит в видеопамять (или другой сегмент) состояние регистра
; Формат вывода:
; XX 1234
; XX   - имя регистра
; 1234 - значение в Hex формате
;======================================================================
; Entry: DS:SI -  name of register (2 bytes)
;        ES:DI -  start addr to print
;           AH -  color attr
;           BX -  register's value
;----------------------------------------------------------------------
; Expects:  ES -> frame segment
;           df =  0
;----------------------------------------------------------------------
; Exit:  DS:SI -> character after register's name
; Destroys: AL, BX, CX, SI, DI
;======================================================================

draw_one_reg    proc

        lodsb               ;   al = первая буква в имени регистра
        stosw
        lodsb               ;   al = вторая буква в имени регистра
        stosw
        mov al, ' '         ;   al = пробел (3ий символ)
        stosw

        add di, 6           ;   es:di - адрес последней цифры (вывод цифр от младших разрядов к старшим)
        mov cx, 4           ;   cx = кол-во 16-ричных цифр в регистре
@@Next:
        mov al, 0Fh         ;   al - маска младших 4-х разрядов
        and al, bl          ;   al = младшая цифра BX

        cmp al, 0Ah
        jae @@Letter        ;   if (al >= 0Ah) jmp @@Letter
                            ;   else               @@Digit

@@Digit:
        add al, '0'         ;   al: digit -> digit_char
        mov es:[di], ax
        jmp @@Cycle_cond

@@Letter:
        add al, ('A' - 0Ah) ;   al: digit -> letter_char
        mov es:[di], ax

@@Cycle_cond:
        shr bx, 4
        sub di, 2
        loop @@Next

        ret

draw_one_reg    endp

;======================================================================
; Обновляет buffer_3 значениями из buffer_1, которые не совпадают со
; значениями соответствующих ячеек в buffer_2
;======================================================================
; Entry: DS:SI - start addr of buffer_1
;        ES:DI - strat addr of buffer_2
;        ES:BX - start addr of buffer_3
;           CX - size of buffers (in words)
;----------------------------------------------------------------------
; Expects:  CX > 0
;----------------------------------------------------------------------
; Exit:     None
; Destroys: AX, BX, CX, SI, DI
;======================================================================

upd_buffer  proc

@@Next: lodsw
        cmp ax, es:[di]
        jne @@Upd_value     ;   if (ds:[si] != es:[di]) jmp @@Upd_value
        jmp @@Next_cond     ;   else                    jmp @@Next_cond

@@Upd_value:
        mov es:[bx], ax

@@Next_cond:
        inc di
        inc di
        inc bx
        inc bx
        loop @@Next

        ret

upd_buffer  endp

include ../lib/frame.asm

Program_end:

;======================================================================

Main:   xor bx, bx                      ;   bx = 0
        mov es, bx                      ;   es = 0
        mov bx, 4d*8d                   ;   es:bx -> ячейка с адресом INT 08h

        mov ax, es:[bx]
        mov word ptr old_08h_addr,   ax ;   save int_08h offset
        mov ax, es:[bx+2]
        mov word ptr old_08h_addr+2, ax ;   save int_08h segment
        mov ax, es:[bx+4]
        mov word ptr old_09h_addr,   ax ;   save int_09h offset
        mov ax, es:[bx+6]
        mov word ptr old_09h_addr+2, ax ;   save int_09h segment

        cli
        mov es:[bx],   offset New_08h   ;   set New_08h offset
        mov es:[bx+4], offset New_09h   ;   set New_09h offset
        mov ax, cs
        mov es:[bx+2], ax               ;   set New_08h segment
        mov es:[bx+6], ax               ;   set New_09h segment
        sti

        mov ax, 3100h
        mov dx, offset Program_end
        shr dx, 4                       ;   dx = program_size / 16 (paragraph = 16 byte)
        inc dx                          ;   округление вверх
        int 21h                         ;   TSR

end Start
