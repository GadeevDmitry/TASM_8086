.model tiny
.code

org 100h
locals @@

Start:  mov di, 0B800h  ;
        mov es, di      ; es -> video segment

        ;-------------------------------------------------
        mov ax, 125d    ; ax = число для вывода на экран
        mov bh, 17h     ; bh = color attr
        mov di, 20d     ; di = начальный адрес для вывода
        ;-------------------------------------------------
        call print_dec

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

        add di, 2 * 10h ; сдвинули адрес на позицию последнего символа
        mov cx, 10h     ; кол-во двоичных цифр в регистре

        mov byte ptr es:[di]  , 'b' ;
        mov          es:[di+1], bh  ;
        sub di, 02h                 ; положили букву 'b' - binary

@@Next: mov bl, 01h     ; bl - битовая маска двоичной цифры
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

        add di, 2 * 04h ; сдвинули адрес на позицию последнего символа
        mov cx, 04h     ; кол-во hex-цифр в регистре

        mov byte ptr es:[di]  , 'h' ;
        mov          es:[di+1], bh  ;
        sub di, 02h                 ; положили букву 'h' - hex

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
; Выводит в видео память число в десятичной форме
;======================================================================
; Entry:    AX - number to print in video segment
;           BH - color attr
;           DI - start addr to print
; Expects:  ES -> video segment
;
; Exit:     None
; Destroys: AX, BL, CX, DI
;======================================================================

print_dec   proc

        add di, 2 * 05h ; сдвинули адрес на позицию последнего символа
        mov cx, 05h     ; максимальное кол-во десятичных цифр в регистре

        mov byte ptr es:[di]  , 'd' ;
        mov          es:[di+1], bh  ;
        sub di, 02h                 ; положили букву 'd' - dec

@@Next: mov bl, 10d     ; bl = 10d - делитель
        div bl          ; ax/bl

        mov bl, ah      ;
        add bl, '0'     ; bl - цифра-символ для вывода на экран
        mov es:[di], bx ; положили цифру в видео память

        sub di, 2h      ; уменьшили адрес
        xor ah, ah      ; теперь ah = 0, al = ax // 10

        loop @@Next

            ret
print_dec   endp

end Start