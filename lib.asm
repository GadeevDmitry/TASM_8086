.model tiny
.code

org 100h
locals @@

Start:  mov di, 0B800h  ;
        mov es, di      ; es -> video segment

        ;-------------------------------------------------
        mov ax, 9F3Dh   ; ax = число для вывода на экран
        mov bh, 17h     ; bh = color attr
        mov di, 20d     ; di = начальный адрес для вывода
        ;-------------------------------------------------
        call print_hex

        mov ax, 4c00h   ;
        int 21h         ; exit(0)

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

        add di, 2 * 0Fh ; сдвинули адрес на позицию последней цифры
        mov cx, 10h     ; кол-во двоичных цифр в регистре

@@Next: mov bl, 01h     ; bl - битовая маска двоичной цифры
        and bl, al      ; bl = младшая цифра AX

        add bl, '0'     ; bl = цифра-символ для вывода на экран
        mov es:[di], bx ; положили цифру в видео память

        sub di, 2h      ; уменьшили адрес
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

        add di, 2 * 03h ; сдвинули адрес на позицию последней цифры
        mov cx, 04h     ; кол-во hex-цифр в регистре

@@Next: mov bl, 0Fh     ; bl - битовая маска hex-цифры
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

end Start