;======================================================================
; Выводит в видео память число в двоичной форме
;======================================================================
; Entry:    AX - number to print in video segment
;           BH - color attr
;           DI - start addr to print
; Expects:  ES -> video segment
;
; Exit:     None
; Destroys: AX, BL, CX, DI
;======================================================================

print_bin   proc

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

            ret
print_bin   endp

;======================================================================
; Выводит в видео память число в Hex
;======================================================================
; Entry:    AX - number to print in video segment
;           BH - color attr
;           DI - start addr to print
; Expects:  ES -> video segment
;
; Exit:     None
; Destroys: AX, BL, CX, DI
;======================================================================

print_hex   proc

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

            ret
print_hex   endp

;======================================================================
; Выводит в видео память число в десятичной форме
;======================================================================
; Entry:    AX - number to print in video segment
;           BH - color attr
;           DI - start addr to print
; Expects:  ES -> video segment
;
; Exit:     None
; Destroys: AX, BL, CX, DX, SI, DI
;======================================================================

print_dec   proc

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
        ret

@@Success_exit:
        mov ax, 00h
        ret

            ret
input_dec   endp

;======================================================================
; Рисует рамку в видео памяти
;======================================================================
; Entry:    DI - addr of upper left corner of the frame
;           DH - height of the frame
;           DL - length of the frame
;           BH - color attr
; Expects:  ES -> video segment
;
; Exit:     None
; Destroys: AX, BL, CX, DL
;======================================================================

make_frame  proc

lu_corner = 0C9h
ld_corner = 0C8h
ru_corner = 0BBh
rd_corner = 0BCh
l_ver     = 0CCh
r_ver     = 0B9h
u_hor     = 0CBh
d_hor     = 0CAh


shl dl, 1

        mov bl, lu_corner
        mov es:[di], bx

        mov bl, ld_corner
        mov al, 160d
        mul dh
        add di, ax
        mov es:[di], bx

        mov bl, rd_corner
        mov cx, 0h          ;
        mov cl, dl          ;
        add di, cx          ; add di, dl
        mov es:[di], bx

        mov bl, ru_corner
        sub di, ax
        mov es:[di], bx

        sub di, cx          ; di = изначальное di

        mov bl, u_hor
        mov al, 02h
        add di, 02h
        cmp al, dl
        jb @@U_hor
        je @@End_u_hor
        sub di, 02h
        jmp @@End_u_hor

@@U_hor:
        mov es:[di], bx

        add al, 02h
        add di, 02h
        cmp al, dl
        jb @@U_hor
@@End_u_hor:

        mov bl, r_ver
        mov al, 01h
        add di, 160d
        cmp al, dh
        jb @@R_ver
        je @@End_r_ver
        sub di, 160d
        jmp @@End_r_ver

@@R_ver:
        mov es:[di], bx

        inc al
        add di, 160d
        cmp al, dh
        jb @@R_ver
@@End_r_ver:

        mov bl, d_hor
        mov al, 02h
        sub di, 02h
        cmp al, dl
        jb @@D_hor
        je @@End_d_hor
        add di, 02h
        jmp @@End_d_hor

@@D_hor:
        mov es:[di], bx

        add al, 02h
        sub di, 02h
        cmp al, dl
        jb @@D_hor
@@End_d_hor:

        mov bl, l_ver
        mov al, 01h
        sub di, 160d
        cmp al, dh
        jb @@L_ver
        je @@End_l_ver
        add di, 160d
        jmp @@End_l_ver

@@L_ver:
        mov es:[di], bx

        inc al
        sub di, 160d
        cmp al, dh
        jb @@L_ver
@@End_l_ver:

            ret
make_frame  endp