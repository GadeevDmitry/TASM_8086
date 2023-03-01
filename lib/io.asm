;======================================================================
; Выводит в видео память слово в двоичной форме
; Формат вывода:
; ____ ____ ____ ____ b
;======================================================================
; Entry:    BH -  color attr
;           AX -  number to print in video segment
;        ES:DI -  start addr to print
;----------------------------------------------------------------------
; Expects:  ES -> video segment
;----------------------------------------------------------------------
; Exit:     None
; Destroys: AX, BL, CX, DI
;======================================================================

print_bin   proc

        add di, 2 * 20d ; di = адрес буквы 'b' в видео памяти (вывод задом наперед)
        mov cx, 16d     ; cx = кол-во двоичных цифр в регистре

        mov byte ptr es:[di]  , 'b' ;
        mov          es:[di+1], bh  ;
        sub di, 02                  ; положили букву 'b' - binary

@@Next:
        test cx, 03h                ; равно нулю, если 4|cx
        jnz @@End_space             ; кладем пробел после каждых четырех цифр

        mov byte ptr es:[di]  , ' ' ;
        mov          es:[di+1], bh  ;
        sub di, 02h                 ; положили пробел
@@End_space:

        mov bl, 01b
        and bl, al      ; bl = младшая цифра AX

        add bl, '0'
        mov es:[di], bx

        sub di, 02h
        shr ax, 1

        loop @@Next
        ret

print_bin   endp

;======================================================================
; Выводит в видео память слово в Hex-форме
; Формат вывода:
; __ __ h
;======================================================================
; Entry:    BH -  color attr
;           AX -  number to print in video segment
;        ES:DI -  start addr to print
;----------------------------------------------------------------------
; Expects:  ES -> video segment
;----------------------------------------------------------------------
; Exit:     None
; Destroys: AX, BL, CX, DI
;======================================================================

print_hex   proc

        add di, 2 * 06d ; di = адрес буквы 'h' в видео памяти (вывод задом наперед)
        mov cx, 04d     ; кол-во hex-цифр в регистре

        mov byte ptr es:[di]  , 'h' ;
        mov          es:[di+1], bh  ;
        sub di, 02h                 ; положили букву 'h' - hex

@@Next:
        test cx, 01h                ; равно нулю, если 2|cx
        jnz @@End_space             ; кладем пробел после каждых двух цифр

        mov byte ptr es:[di]  , ' ' ;
        mov          es:[di+1], bh  ;
        sub di, 02h                 ; положили пробел
@@End_space:

        mov bl, 0Fh
        and bl, al      ; bl = младшая hex-цифра AX

        cmp bl, 0Ah
        jb @@Digit      ; 0 <= bl <= 9

        add bl, 'A'-0Ah ; 'A' <= bl <= 'F'
        jmp @@Print

@@Digit:
        add bl, '0'
@@Print:

        mov es:[di], bx

        sub di, 2h
        shr ax, 4h

        loop @@Next
        ret

print_hex   endp

;======================================================================
; Выводит в видео память число в десятичной форме
; Формат вывода:
; _____ d
;======================================================================
; Entry:    BH -  color attr
;           AX -  number to print in video segment
;        ES:DI -  start addr to print
;----------------------------------------------------------------------
; Expects:  ES -> video segment
;----------------------------------------------------------------------
; Exit:     None
; Destroys: AX, BL, CX, DX, SI, DI
;======================================================================

print_dec   proc

        add di, 2 * 06h ; di = адрес буквы 'd' в видео памяти (вывод задом наперед)
        mov cx, 05d     ; максимальное кол-во десятичных цифр в регистре
        mov si, 10d     ; si = 10 - делитель

        mov byte ptr es:[di]  , 'd' ;
        mov          es:[di+1], bh  ;
        sub di, 02h                 ; положили букву 'd' - dec

        mov byte ptr es:[di]  , ' ' ;
        mov          es:[di+1], bh  ;
        sub di, 02h                 ; положили пробел

@@Next: mov dx, 00h     ; (dx, ax)/si <=> ax/10
        div si          ; dx = ax % 10; ax = ax // 10
                        ; dx = ax % 10 => dx < 10 => dx = dl

        mov bl, dl      ; bl = младшая десятичная цифра AX
        add bl, '0'
        mov es:[di], bx

        sub di, 2h

        loop @@Next
        ret

print_dec   endp

;======================================================================
; Считывает десятичное число из строки по модулю 256
;======================================================================
; Entry: DS:SI -  start addr to read
;----------------------------------------------------------------------
; Expects:  df =  0
;----------------------------------------------------------------------
; Exit:     BL - read number mod 256
;           SI - addr of the second character after end of the number
; Destroys: AX, BL, DL, SI
;======================================================================

read_mem_dec    proc

        xor bl, bl  ; bl = current number
        mov dl, 10d

@@Next: lodsb
        sub al, '0'
        jb @@Exit   ; if (al < '0') return
        cmp al, 9
        ja  @@Exit  ; if (al > '9') return

        xchg al, bl ; al = current number, bl = last_digit

        mul dl      ; ax = 10al
        add al, bl  ; al+= bl
        mov bl, al  ; bl = current number
        jmp @@Next

@@Exit:
        ret

read_mem_dec    endp

;======================================================================
; Считывает HEX-число из строки по модулю 256
; Число должно содержать символы 0-9, A-F
;======================================================================
; Entry: DS:SI -  start addr to read
;----------------------------------------------------------------------
; Expects:  df =  0
;----------------------------------------------------------------------
; Exit:     BL - read number mod 256
;           SI - addr of the second character after end of the number
; Destroys: AL, BL, SI
;======================================================================

read_mem_hex    proc

        xor bl, bl  ; bl = current_number

@@Next: lodsb       ; al = ds:[si]
        cmp al, '0'
        jb  @@Exit  ; if (al < '0') return
        cmp al, '9'
        jbe @@Digit ; if (al <= '9') jmp @@Digit
        cmp al, 'A'
        jb  @@Exit  ; if (al < 'A') return
        cmp al, 'F'
        jbe @@Letter; if (al <= 'F') jmp @@Letter

@@Digit:
        sub al, '0'
        jmp @@Culc

@@Letter:
        sub al, 'A'
        add al, 0Ah

@@Culc: shl bl, 4
        add bl, al  ; bl = 16*bl + al
        jmp @@Next

@@Exit: ret

read_mem_hex    endp