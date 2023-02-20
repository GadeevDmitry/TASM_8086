;======================================================================
; Выводит в видео память число в двоичной форме
;======================================================================
; Entry:    STACK:
;           7 1: color attr
;           4 2: number to print in video segment
;           2 2: start addr to print
;           0 2: return addr
; Expects:  ES -> video segment
;
; Exit:     None
; Destroys: AX, BX, CX, DI
;======================================================================

print_bin   proc
        push bp

        mov bp, sp
        mov di, [bp+4]
        mov ax, [bp+6]
        mov bh, [bp+9]

        add di, 2 * 14h ; сдвинули адрес на позицию последнего символа
        mov cx, 10h     ; кол-во двоичных цифр в регистре

        mov byte ptr es:[di]  , 'b' ;
        mov          es:[di+1], bh  ;
        sub di, 02h                 ; положили букву 'b' - binary

@@Next:
;#if------------------------
        test cx, 03h
        jnz @@End_space
;#true
        mov byte ptr es:[di]  , ' ' ;
        mov          es:[di+1], bh  ;
        sub di, 02h                 ; кладем пробел после каждых четырех цифр
;#endif---------------------
@@End_space:

        mov bl, 01h     ; bl - битовая маска двоичной цифры
        and bl, al      ; bl = младшая цифра AX

        add bl, '0'     ; bl = цифра-символ для вывода на экран
        mov es:[di], bx ; положили цифру в видео память

        sub di, 02h     ; уменьшили адрес
        shr ax, 1       ; избавились от только что обработанной цифры

        loop @@Next

        pop bp
        ret
print_bin   endp

;======================================================================
; Выводит в видео память число в Hex
;======================================================================
; Entry:    STACK:
;           7 1: color attr
;           4 2: number to print in video segment
;           2 2: start addr to print
;           0 2: return addr
; Expects:  ES -> video segment
;
; Exit:     None
; Destroys: AX, BX, CX, DI
;======================================================================

print_hex   proc
        push bp

        mov bp, sp
        mov di, [bp+4]
        mov ax, [bp+6]
        mov bh, [bp+9]

        add di, 2 * 06h ; сдвинули адрес на позицию последнего символа
        mov cx, 04h     ; кол-во hex-цифр в регистре

        mov byte ptr es:[di]  , 'h' ;
        mov          es:[di+1], bh  ;
        sub di, 02h                 ; положили букву 'h' - hex

@@Next:
;#if------------------------
        test cx, 01h
        jnz @@End_space
;#true
        mov byte ptr es:[di]  , ' ' ;
        mov          es:[di+1], bh  ;
        sub di, 02h                 ; кладем пробел после каждых двух цифр
;#endif---------------------
@@End_space:

        mov bl, 0Fh     ; bl - битовая маска hex-цифры
        and bl, al      ; bl = младшая цифра AX

;#if------------------------
        cmp bl, 0Ah
        jb @@Digit
;#true
        add bl, 'A'-0Ah ; bl = буква-символ для вывода на экран
        jmp @@Print
;#false
@@Digit:
        add bl, '0'     ; bl = цифра-символ для вывода на экран
;#endif---------------------
@@Print:

        mov es:[di], bx ; положили hex-цифру в видео память

        sub di, 2h      ; уменьшили адрес
        shr ax, 4h      ; избавились от только что обработанной цифры

        loop @@Next

        pop bp
        ret
print_hex   endp

;======================================================================
; Выводит в видео память число в десятичной форме
;======================================================================
; Entry:    STACK:
;           7 1: color attr
;           4 2: number to print in video segment
;           2 2: start addr to print
;           0 2: return addr
; Expects:  ES -> video segment
;
; Exit:     None
; Destroys: AX, BX, CX, DX, SI, DI
;======================================================================

print_dec   proc
        push bp

        mov bp, sp
        mov di, [bp+4]
        mov ax, [bp+6]
        mov bh, [bp+9]

        add di, 2 * 06h ; сдвинули адрес на позицию последнего символа
        mov cx, 05h     ; максимальное кол-во десятичных цифр в регистре
        mov si, 10d     ; si = 10 - делитель

        mov byte ptr es:[di]  , 'd' ;
        mov          es:[di+1], bh  ;
        sub di, 02h                 ; положили букву 'd' - dec

        mov byte ptr es:[di]  , ' ' ;
        mov          es:[di+1], bh  ;
        sub di, 02h                 ; положили пробел

@@Next: mov dx, 00h
        div si          ; (dx, ax)/si <=> ax/10

        mov bl, dl      ; dx = ax mod 10 => dx < 10 => dx = dl
        add bl, '0'     ;
        mov es:[di], bx ;

        sub di, 2h      ;

        loop @@Next

        pop bp
        ret
print_dec   endp

;======================================================================
; Считывает десятичное число из консоли
;======================================================================
; Entry:    None
; Expects:  Decimal number input
;
; Exit:     DX - entered number
;           AX != 0 in case of error and AX = 0 in case of no error
; Destroys: AX, BX, CX, DX
;======================================================================

input_dec   proc
        push bp
        mov  bp, sp

        mov bx, 00h
        mov dx, 00h
        mov cx, 10d     ; cx = 10 - делитель

@@Next: mov ah, 01h
        int 21h         ; считали символ

;#if------------------------
        cmp al, '0'
        jb @@End_input
        cmp al, '9'
        ja @@End_input  ; проверка считанного символа
;#true
        mov bl, al
        sub bl, '0'     ; спасаем al - текущий символ

        mov ax, dx      ;
        mul cx          ;
        jo @@Overflow   ;
        add ax, bx      ;
        jc @@Overflow   ; пересчитываем текущее число

        mov dx, ax      ; спасаем ax
        jmp @@Next
;#endif---------------------
@@End_input:

;#if------------------------
        cmp al, 0Dh
        je @@Success_exit
;#true
        mov cx, dx

        mov ah, 02h
        mov dl, 0Ah
        int 21h         ; выводим enter в консоль

        mov dx, cx
        jmp @@Success_exit
;#endif---------------------

@@Overflow:
        mov ah, 02h
        mov dl, 0Ah
        int 21h         ; выводим enter в консоль

        mov ah, 09h
        mov dx, offset @@Err_msg
        int 21h         ; выводим сообщение в консоль

        jmp @@Err_exit

@@Err_msg: db 'ERROR: 16-bit register overflow', 0Ah, '$'

@@Err_exit:
        mov ax, 01h

        pop bp
        ret

@@Success_exit:
        mov ax, 00h

        pop bp
        ret
input_dec   endp

;======================================================================
; Рисует рамку в видео памяти
;======================================================================
; Entry:    None
; Expects:  ES -> video segment
;
; Exit:     None
; Destroys: AX, BX, CX, DI
;======================================================================

;----------------------------------------------------------------------
; DEFAULT FRAME PARAMETERS
;----------------------------------------------------------------------

;-------------------0------2------4------6------8-----10-----12-----14-----16- ; _____________________________
frame_part   dw 03C9h, 03BBh, 03BCh, 03C8h, 03BAh, 03CDh, 03BAh, 03CDh, 0020h  ; |_0|__________10__________|2_|
frame_offset dw 00h                                                            ; |  |                      |  |
frame_length db 49h                                                            ; |_8|          16          |12|
frame_height db 0Eh                                                            ; |__|______________________|__|
                                                                               ; |_6|__________14__________|4_|
make_frame  proc

;----------------------------------------------------------------------
; FRAME_FRONTEND
;----------------------------------------------------------------------

push bp
mov  bp, sp
mov  di, 82h    ; адрес начала аргументов командной строки

mov ah, 09h
lea dx, @@Welcome_msg
int 21h
jmp @@Read_fmt

@@Welcome_msg: db "Frame_builder:", 0Ah, "Enter the frame's parameters input format", 0Ah, '$'

@@Read_fmt:
        call getchar
        push ax
        call getchar
        push ax

;----------------------------------------------------------------------
; parts
;----------------------------------------------------------------------

        mov ax, [bp+(-2)]
        cmp ax, 'a'
        je @@CMD_arg_parts
        cmp ax, 'A'
        je @@CMD_arg_parts 

        cmp ax, 'c'
        je @@Console_parts
        cmp ax, 'C'
        je @@Console_parts

        jmp @@Sizes

@@CMD_arg_parts:
        mov bx, 00h
@@CMD_arg_parts_next:
        mov ax, [di]
        xchg ah, al
        mov frame_part[bx], ax
        add di, 2
        add bx, 2
        cmp bx, 18
        jne @@CMD_arg_parts_next

        jmp @@Sizes

@@Console_parts:
        mov di, 00h
        mov ah, 09h
        lea dx, @@Console_parts_welcome_msg
        int 21h

        jmp @@Console_parts_next

@@Console_parts_welcome_msg: db "Enter parts of the frames in format: <ASCCI (1 byte)><ATTR (1 byte)>", 0Ah, '$'
@@Console_parts_next:
        @@Console_parts_param_enter:
                call geth_word
                cmp cl, 0
                jne @@Console_parts_param_enter

        mov frame_part[di], ax
        add di, 2
        cmp di, 12h
        jne @@Console_parts_next

        jmp @@Sizes

;----------------------------------------------------------------------
; sizes
;----------------------------------------------------------------------

@@Sizes:
        mov ax, [bp+(-4)]
        cmp ax, 'a'
        je @@CMD_arg_sizes
        cmp ax, 'A'
        je @@CMD_arg_sizes

        cmp ax, 'c'
        je @@Console_sizes
        cmp ax, 'C'
        je @@Console_sizes

        jmp @@Draw

@@CMD_arg_sizes:
        mov ax, [di]
        mov frame_offset, ax
        add di, 2

        mov al, [di]
        mov frame_length, al
        inc di

        mov al, [di]
        mov frame_height, al
        inc di

        jmp @@Draw

@@Console_sizes:
        mov ah, 09h
        lea dx, @@Console_size_welcome_msg
        int 21h

        jmp @@Console_offset_enter

@@Console_size_welcome_msg: db "Enter offset(2 bytes), length(1 byte) and height(1 byte)", 0Ah, '$'

        @@Console_offset_enter:
                call geth_word
                cmp cl, 0
                jne @@Console_offset_enter
        xchg ah, al
        mov frame_offset, ax

        @@Console_length_enter:
                call geth_byte
                cmp cl, 0
                jne @@Console_length_enter
        mov frame_length, al

        @@Console_height_enter:
                call geth_byte
                cmp cl, 0
                jne @@Console_height_enter
        mov frame_height, al

        jmp @@Draw

;----------------------------------------------------------------------
; FRAME_BACKEND
;----------------------------------------------------------------------

@@Backend_ret_pocket: pop bp
                      ret

@@Draw:
        add sp, 4

        cmp frame_height, 0
        je @@Backend_ret_pocket
        cld

        mov cl, frame_length
        cmp cl, 0
        je @@Backend_ret_pocket

        mov di, frame_offset
        mov ax, frame_part[0]
        stosw
        dec cl

        cmp cl, 1
        jbe @@Draw_root_end

        mov ax, frame_part[10]
@@Draw_root:
        stosw
        dec cl
        cmp cl, 1
        ja @@Draw_root
@@Draw_root_end:

        cmp cl, 0
        je @@Draw_middle
        mov ax, frame_part[2]
        stosw

@@Draw_middle:
        dec frame_height
        cmp frame_height, 1
        jbe @@Draw_tail

@@Draw_middle_cycle:
        mov cl, frame_length
        mov ch, 00h
        add cx, cx              ; cx = frame_length * 2
        sub di, cx
        add di, 160d            ; длина строки экрана в байтах

        mov cl, frame_length
        mov ax, frame_part[8]
        stosw
        dec cl

        cmp cl, 1
        jbe @@Draw_middle_inside_end

        mov ax, frame_part[16]
        @@Draw_middle_inside:
                stosw
                dec cl
                cmp cl, 1
                ja @@Draw_middle_inside
        @@Draw_middle_inside_end:

        cmp cl, 0
        je @@Draw_middle_cycle_cond
        mov ax, frame_part[12]
        stosw

@@Draw_middle_cycle_cond:
        dec frame_height
        cmp frame_height, 1
        ja @@Draw_middle_cycle

@@Draw_tail:
        cmp frame_height, 0
        je @@End

        mov cl, frame_length
        mov ch, 00h
        add cx, cx              ; cx = frame_length * 2
        sub di, cx
        add di, 160d

        mov cl, frame_length
        mov ax, frame_part[6]
        stosw
        dec cl

        cmp cl, 1
        jbe @@Draw_tail_cycle_end

        mov ax, frame_part[14]
@@Draw_tail_cycle:
        stosw
        dec cl
        cmp cl, 1
        ja @@Draw_tail_cycle
@@Draw_tail_cycle_end:

        cmp cl, 0
        je @@End
        mov ax, frame_part[4]
        stosw

@@End:
            pop bp
            ret
make_frame  endp

;======================================================================
; Возвращает введенный символ
;======================================================================
; Entry:    None
; Expects:  None
;
; Return:   AL - entered character
; Destroys: AX, BX, DX
;======================================================================

input_buff_size equ 80h
input_buff       db input_buff_size, ?, input_buff_size DUP(0Dh)
input_buff_pos   db 2

;----------------------------------------------------------------------

getchar     proc

@@Next:
        mov bl, input_buff_pos
        mov bh, 00h
        cmp input_buff[bx], 0Dh
        je  @@fill_input_buff

        mov al, input_buff[bx]
        inc     input_buff_pos
        mov ah, 00h
        ret

@@fill_input_buff:
        mov ax, 0C0Ah
        lea dx, input_buff
        int 21h
        mov input_buff_pos, 2

        mov ah, 02h
        mov dl, 0Ah
        int 21h

        jmp @@Next

        ret
getchar     endp

;======================================================================
; Возвращает однобайтовое число, введенное в Hex формате
;======================================================================
; Entry:    None
; Expects:  None
;
; Return:   AL - entered number
;           CL != 0 in case of error
; Destroys: AX, BX, CX, DX
;======================================================================

geth_byte   proc

        call getchar
        cmp al, '0'
        jb  @@Not_fst_digit
        cmp al, '9'
        ja  @@Not_fst_digit

        sub al, '0'
        jmp @@Second_digit

@@Not_fst_digit:
        cmp al, 'A'
        jb  @@Error_fst
        cmp al, 'F'
        ja  @@Error_fst

        sub al, 'A'
        add al, 10

@@Second_digit:

        mov cl, 04
        shl al, cl
        mov ch, al
        xor al, al

        call getchar
        cmp al, '0'
        jb  @@Not_sec_digit
        cmp al, '9'
        ja  @@Not_sec_digit

        sub al, '0'
        add al, ch

        xor cl, cl  ; no-error flag
        ret

@@Not_sec_digit:
        cmp al, 'A'
        jb @@Error_sec
        cmp al, 'F'
        ja @@Error_sec

        sub al, 'A'
        add al, 10
        add al, ch

        xor cl, cl  ; no-error flag
        ret

@@Error_fst:
        call getchar
@@Error_sec:
        mov ah, 09h
        mov dx, offset @@Err_msg
        int 21h

        mov cl, 1   ; error flag
        ret

@@Err_msg: db "Undefined hexadecimal byte number", 0Ah, '$'

        ret
geth_byte   endp

;======================================================================
; Возвращает двухбайтовое число, введенное в Hex формате
;======================================================================
; Entry:    None
; Expects:  None
;
; Return:   AX - entered number
;           CL != 0 in case of error
; Destroys: AX, BX, CX, DX
;======================================================================

geth_word   proc
        push bp

        call geth_byte
        cmp cl, 0
        jne @@Error

        push ax         ; ______
        call geth_byte  ;       |
        mov bp, sp      ;       |
        mov ah, [bp]    ;       |
        add sp, 2       ; ah = _|
        cmp cl, 0
        jne @@Error

        xchg ah, al ; пользователь вводит не в "перевернутом" формате

        xor cl, cl  ; error-no flag
        pop bp
        ret

@@Error:
        mov cl, 1   ; error flag
        pop bp
        ret

geth_word   endp