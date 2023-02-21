;======================================================================
; Рисует рамку в видео памяти (frontend)
;----------------------------------------------------------------------
; Формат данных:
; x y h w attr type mssg'0'
;
; x, y - pos of upper left corner
; h, w - internal height and width of the frame
; attr - color attr
; type - frame's style
;    0 - simple frame
;    1 - dollar frame
;    2 - smiles frame
; mssg - message to put into the frame
;  '0' - end-character
;======================================================================
; Entry: DS:SI - addr of array with data
;----------------------------------------------------------------------
; Expects:  df =  0
;           ES -> video segment
;----------------------------------------------------------------------
; Exit:     None
; Destroys: AX, BX, CX, DX, DI
;======================================================================

frame   proc

        call read_mem_dec   ; bl = x
        mov al, 160d        ; 160d - кол-во байт в видеопамяти для одной строки на экране

        xchg al, bl
        mul  bl
        mov  di, ax         ; di = 160d*x

        call read_mem_dec   ; bl = y
        mov bh, 0
        shl bx, 1           ; 2 байта на символ в видеопамяти
        add di, bx          ; di = 160d*x + y (смещение в видеопамяти)

        call read_mem_dec   ; bl = h
        mov bh, bl

        call read_mem_dec   ; bl = l
        mov dh, bl

        call read_mem_dec   ; bl = attr
        xchg bl, dh
        ;-------------------; di = video mem offset, bh = h, bl = l, dh = attr

        push bx             ; save bx
        call read_mem_dec   ; bl = type

        mov al, 9d          ; 9 - количество символов для задания рамки
        mul bl
        pop bx

        lea si, type_0
        add si, ax          ; si = type_i = type_0 + 9*i

        mov ah, dh          ; ah = attr

        call frame_draw
        ret

frame   endp

;------------0-----1-----2-----3-----4-----5-----6-----7-----8
type_0 db 0C9h, 0CDh, 0BBh, 0BAh, 020h, 0BAh, 0C8h, 0CDh, 0BCh
type_1 db 4 DUP(024h),            020h, 4 DUP(024h)
type_2 db 4 DUP(001h),            020h, 4 DUP(001h)

;======================================================================
; Рисует рамку в видео памяти (backend)
;======================================================================
; Entry: ES:DI - addr of upper left corner of the frame                      _________________
;        DS:SI - addr of the array with ASCCI codes of the frame's parts    |0|______1______|2|
;           AH - color attr                                                 | |             | |
;           BH - internal height of the frame                               |3|      4      |5|
;           BL - internal length of the frame                               |_|_____________|_|
;                                                                           |6|______7______|8|
;----------------------------------------------------------------------
;           df =  0
; Expects:  ES -> video segment
;----------------------------------------------------------------------
; Exit:     None
; Destroys: AL, BH, CX, DX, DI
;======================================================================

frame_draw  proc

@@Draw_top:
        mov dl, bl
        inc dl
        inc dl      ; dl - полная длина рамки
        xor dh, dh  ; dx = dl
        shl dl, 1   ; dl - кол-во байтов на строку рамки (2 байта на символ в видеопамяти)

        mov cx, 160d; cx - кол-во байтов в видеопамяти для строки на экране
        sub cx, dx  ; cx - величина для перевода строки и возврата каретки
        push cx

        mov cl, bl
        mov al, [si+0]
        mov dh, [si+1]
        mov dl, [si+2]
        call frame_draw_line

        pop cx
        add di, cx
        push cx

        cmp bh, 0
        je @@Draw_tail

@@Draw_mid:
        mov cl, bl
        mov al, [si+3]
        mov dh, [si+4]
        mov dl, [si+5]
        call frame_draw_line

        pop cx
        add di, cx
        push cx

        dec bh
        jnz @@Draw_mid

@@Draw_tail:
        pop cx

        mov cl, bl
        mov al, [si+6]
        mov dh, [si+7]
        mov dl, [si+8]
        call frame_draw_line

        ret

frame_draw  endp

;======================================================================
; Рисует строку рамки в видео памяти (backend)
;======================================================================
; Entry: ES:DI -  start addr of the line to draw
;           AH -  color attr
;           AL -  character to fill the begin  of the line                   ________________
;           DH -  character to fill the midlle of the line                  |AL|____DH____|DL|
;           DL -  character to fill the end    of the line
;           CL -  internal length of the line (frame)
;----------------------------------------------------------------------
; Expects:  df =  0
            СH =  0
;           ES -> video segment
;----------------------------------------------------------------------
; Exit:     None
; Destroys: AL, CX, DI
;======================================================================

frame_draw_line proc
                        ; AH = color  attr
        stosw           ; AL = begin  char

        mov al, dh
        rep stosw       ; AL = middle char

        mov al, dl
        stosw           ; AL = end    char

        ret

frame_draw_line endp

include lib.asm