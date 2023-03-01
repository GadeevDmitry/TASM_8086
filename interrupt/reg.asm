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
; Выводит рамку в видео память при нажатии D
; Передает управление старому обработчику иначе
;======================================================================

New_09h proc
        push ax
        in   al, 60h            ;   al = scan_code нажатой клавиши
        cmp  al, 20h
        jne  @@Old_handler      ;   if (al != scan_code(D)) jmp @@Old_handler
                                ;   else                        @@Frame_key
@@Frame_key:
        push bx cx dx si di es ds
        ;-----------------------
        mov ax, cs
        mov ds, ax              ;   ds = cs
        mov ax, 0B800h
        mov es, ax              ;   es -> video segment
        cld                     ;   df = 0
        ;-----------------------;   параметры для рамки

        test is_frame_on, 7Fh
        jnz  @@Hide_frame       ;   if (is_frame_on != 0) jmp @@Hide_frame
                                ;   else                      @@Show_frame
@@Show_frame:
        mov  is_frame_on, 1
        lea  si, show_frame_data;   ds:[si] -> switch on frame data
        call frame              ;   нарисовали рамку

        pop  ds es di si dx cx bx
        jmp  @@Exit

@@Hide_frame:
        mov  is_frame_on, 0
        lea  si, hide_frame_data;   ds:[si] -> switch off frame data
        call frame              ;   стерли рамку

        pop ds es di si dx cx bx
        jmp @@Exit

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

include ../lib/frame.asm

Program_end:
end Start