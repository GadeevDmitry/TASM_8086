.model tiny
.code

org 100h
locals @@

;======================================================================
; Выводит текст, обернутый в рамку
;----------------------------------------------------------------------
; Данные передаются через аргументы командной строки в формате:
; frame_type <пробел> <frame_data>
;======================================================================
; Если frame_type равно 0, то выберется режим auto_frame, который
; выводит текст по центру экрана и оборачивает его рамкой.
;----------------------------------------------------------------------
; Формат <frame_data>:
; attr type mssg'0'
;
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
; Если frame_type равно 1, то выберется режим frame, который рисует
; рамку заданных размеров и выводит текст сначала первой строки рамки
;----------------------------------------------------------------------
; Формат <frame_data>:
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
;----------------------------------------------------------------------

Start:  mov bx, 0b800h
        mov es, bx              ; es -> video segment

        mov si, 80h
        xor bh, bh
        mov bl, [si]            ; bx = длина (в байтах) аргументов командной строки

        lea si, [si+bx+1]
        mov byte ptr [si], 0    ; push 0 after command line arguments

        mov si, 82h             ; first command line argument

        call read_mem_dec
        cmp bl, 0
        je call_auto_frame

call_frame:
        call frame
        jmp  Exit

call_auto_frame:
        call auto_frame

Exit:   mov ax, 4c00h
        int 21h

include frame.asm

end Start
