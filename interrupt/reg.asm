.model tiny
.code
.186

org 100h
locals @@

Start:  xor bx, bx                      ;   bx = 0
        mov es, bx                      ;   es = 0
        mov bx, 4d*9d                   ;   es:[bx] -> ячейка с адресом INT 09h

        mov ax, es:[bx]
        mov word ptr old_09h_addr,   ax ;   save int_09h offset
        mov ax, es:[bx+2]
        mov word ptr old_09h_addr+2, ax ;   save int_09h segment

        cli
        mov es:[bx],   offset New_09h   ;   set new offset
        mov ax, cs
        mov es:[bx+2], ax               ;   set new segment
        sti

        mov ax, 3100h
        mov dx, offset Program_end
        shr dx, 4                       ;   dx = program_size / 16 (paragraph = 16 byte)
        inc dx                          ;   округление вверх
        int 21h                         ;   TSR

;======================================================================
; Перехват INT 09h
;----------------------------------------------------------------------
; Выводит рамку и состояния регистров в видеопамять при нажатии D
; Передает управление старому обработчику иначе
;======================================================================

New_09h proc
        push ax
        in   al, 60h            ;   al = scan_code нажатой клавиши

        cmp  al, 0A0h
        je   @@Exit             ;   if (al == scan_code(pull D)) jmp @@Exit
        cmp  al, 20h
        jne  @@Old_handler      ;   if (al != scan_code(push D)) jmp @@Old_handler
        jmp  @@Frame_key        ;   else                         jmp @@Frame_key

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
        test cs:is_frame_on, 0FFh
        jnz  @@Hide_frame       ;   if (is_frame_on != 0) jmp @@Hide_frame
                                ;   else                      @@Show_frame
@@Show_frame:
        push bp                 ;   save bp
        mov  bp, sp
        mov  ax, ss:[bp+4]      ;   ax = old_ip
        push ax es ss ds
        mov  ax, ss:[bp+6]      ;   ax = old_cs
        push ax
        mov  ax, bp             ;
        add  ax, 4              ;   ax = old_sp
        push ax
        mov  ax, ss:[bp]        ;   ax = old_bp
        push ax di si dx cx bx
        mov  ax, ss:[bp+2]      ;   ax = old_ax
        push ax

        ;-----------------------
        mov ax, cs
        mov ds, ax              ;   ds = cs
        lea si, show_frame_data ;   ds:si -> switch on frame data
        mov ax, 0B800h
        mov es, ax              ;   es -> video segment
        cld                     ;   df = 0
        ;-----------------------;   параметры для рамки
        mov  is_frame_on, 1
        call frame              ;   нарисовали рамку

        ;-----------------------
        mov ah, 07h             ;   ah = color attr
        mov di, 65d*2d + 160d   ;   es:di - start addr to print the registers
        mov bp, sp              ;   bp -> top of stack
        ;-----------------------;   параметры для регистров
        call draw_all_reg

        pop ax bx cx dx si di bp
        pop ax                  ;   ax = old_sp
        pop ax                  ;   ax = old_cs
        pop ds ss es
        pop ax                  ;   ax = old_ip
        pop ax                  ;   ax = old_bp
        jmp @@Exit

@@Hide_frame:
        push bx cx dx si di es ds
        ;-----------------------
        mov ax, cs
        mov ds, ax              ;   ds = cs
        lea si, hide_frame_data ;   ds:[si] -> switch off frame data
        mov ax, 0B800h
        mov es, ax              ;   es -> video segment
        cld                     ;   df = 0
        ;-----------------------;   параметры для рамки
        mov  is_frame_on, 0
        call frame              ;   стерли рамку

        pop ds es di si dx cx bx
        jmp @@Exit


New_09h endp

;----------------------------------------------------------------------
old_09h_addr    dd ?
is_frame_on     db 0h
show_frame_data db "0 0 13 72 03 0 ", 0h
hide_frame_data db "0 0 13 72 00 0 ", 0h
;                   _ - вертикальный отступ
;                     _ - горизонтальный отступ
;                       __ - высота рамки
;                          __ - ширина рамки
;                             __ - color attr
;                                _ - тип рамки

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
;                                                 ^
;                                                 BP
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

include ../lib/frame.asm

Program_end:
end Start

mov ax, 1234h
        mov cx, 13d

Next:   push ax
        loop Next

        mov ah, 07h
        mov bp, sp
        mov di, 0B800h
        mov es, di
        mov di, 63d*2d

        call draw_all_reg
        mov cx, 13d

Prev:   pop ax
        loop Prev

        mov ax, 4C00h
        int 21h