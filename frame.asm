;======================================================================
; Преобразует данные для рисования рамки в видео памяти (frontend)
;----------------------------------------------------------------------
; Формат данных:
; x y h l attr type mssg'0'
;
; x, y - координаты верхнего левого угла рамки
; h, l - internal height and length of the frame
; attr - color attr
; type - frame's style
;    0 - simple
;    1 - dollar
;    2 - smiles
;    3 - user's:
;       в этом случае после 'type' должны идти:
;       <space> <9 символов-элементов рамки в порядке, указанном ниже> <space>
;        _________________
;       |0|______1______|2|
;       | |             | |
;       |3|      4      |5|
;       |_|_____________|_|
;       |6|______7______|8|
;
; mssg - message to put into the frame (use '~' as a newline character)
;  '0' - end-character
;======================================================================
; Entry: DS:SI - addr of array with data
;----------------------------------------------------------------------
; Expects:  df =  0
;           ES -> video segment
;----------------------------------------------------------------------
; Exit:     None
; Destroys: AX, BX, CX, DX, SI, DI
;======================================================================

frame   proc

        xor bh, bh
        mov cl, 160d        ; 160d - кол-во байт в видеопамяти для одной строки на экране

        call read_mem_dec   ; bx = bl = x
        mov al, cl          ; al = 160d
        mul bl
        mov di, ax          ; di = 160d*x

        call read_mem_dec   ; bx = bl = y
        shl bx, 1           ; 2 байта на символ в видеопамяти
        add di, bx          ; di = 160d*x + 2*y (смещение в видеопамяти)

        call read_mem_dec
        mov bh, bl          ; bh = h

        call read_mem_dec
        mov cl, bl          ; cl = l (temp save)

        call read_mem_dec
        mov dh, bl          ; dh = attr

        call read_mem_dec   ; bl = type
        mov al, 9d          ; 9  - количество символов для задания рамки
        mul bl              ; ax = 9*type

        mov dl, cl          ; dl = l
        ;-----------------------------------
        ; ES:[DI] - смещение в видео памяти верхнего левого угла рамки
        ; DS:[SI] - текущий адрес входных данных
        ; AX      - адрес массива с элементами рамки относительно type_0
        ; BL      - type
        ; BH      - height
        ; DH      - attr
        ; DL      - length
        ;-----------------------------------

        cmp bl, 3
        jne @@Def_arg       ; if (type != user's) jmp @@Def_arg

@@User_arg:
        push di

        lea di, type_0
        add di, ax
        mov ax, ds          ;
        mov es, ax          ; es = ds
                            ; es:[di] - адрес массива с элементами рамки

        mov cx, 9
        rep movsb           ; скопировали элементы рамки из ds:[si] в es:[di]
        inc si              ; пропуск пробела

        mov cx, 0B800h
        mov es, cx          ; es -> video segment

        ;-----------------------------------
        ; SP     -> смещение в видео памяти
        ; DS:[SI] - текущий адрес входных данных
        ; DS:[DI] - адрес массива с элементами рамки
        ;-----------------------------------

        pop cx
        push si
        mov si, di
        sub si, 9d          ; после заполнения массива с элементами рамки, di съехало на 9
        mov di, cx

        ;-----------------------------------
        ; SP     -> текущий адрес входных данных
        ; DS:[SI] - адрес массива с элементами рамки
        ; ES:[DI] - смещение в видео памяти
        ;-----------------------------------
        jmp @@Call_draw

@@Def_arg:
        push si
        lea  si, type_0
        add  si, ax

        ;-----------------------------------
        ; SP     -> текущий адрес входных данных
        ; DS:[SI] - адрес массива с элементами рамки
        ; ES:[DI] - смещение в видео памяти
        ;-----------------------------------

@@Call_draw:
        mov ah, dh  ; ah = color attr
        mov bl, dl  ; bl = length
        push di
        call frame_draw

@@Call_msg:
        pop di
        add di, 162d        ; перенос смещения внутрь рамки
        pop si
        xor al, al          ; al = 0 - символ конца строки
        mov dl, newline_char; dl - символ в качестве первода строки
        call video_message

        ret

frame   endp

;------------0-----1-----2-----3-----4-----5-----6-----7-----8
type_0 db 0C9h, 0CDh, 0BBh, 0BAh, 020h, 0BAh, 0C8h, 0CDh, 0BCh  ; simple
type_1 db 4 DUP(024h),            020h, 4 DUP(024h)             ; dollar
type_2 db 4 DUP(001h),            020h, 4 DUP(001h)             ; smiles
type_3 db 9 DUP(?)                                              ; user's

newline_char db '~'

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
include str.asm