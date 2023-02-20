.model tiny
.code

org 100h
locals @@

Start:  lea si, l_si
        lea di, l_di
        mov al, '$'
        call strcpy

        lea si, l_si
        lea di, l_di
        mov al, '$'
        call strlen_dssi

        lea si, l_si
        lea di, l_di

        mov al, '$'
        call strlen_esdi

        lea si, l_si
        lea di, l_di
        mov al, '$'
        call strcmp

        lea si, l_si
        lea di, l_di
        mov cx, 5d
        call memcmp


        lea si, l_si
        lea di, l_di
        mov cx, 0Ah
        call memmove

        lea si, l_si
        lea di, l_di
        mov al, '^'
        mov cx, 0Ah
        call memset

        jmp Exit
        l_si db "I am Dmitry Gadeev", '$'
        l_di db "I am programming all night", '$'
;----------------------------------------------------------------------
        mov bp, 0B800h
        mov es, bp

        call make_frame

;----------------------------------------------------------------------
;INPUT
;----------------------------------------------------------------------
        mov ah, 09h
        mov dx, offset Welcome_msg
        int 21h                     ; приветствие

        call input_dec
        cmp ax, 0h
        jne Exit
        mov si, dx                  ; первое число в si

        call input_dec
        cmp ax, 0h
        jne Exit
        mov bp, dx                  ; второе число в bp
;----------------------------------------------------------------------
        mov bh, 07h     ; color attr

;----------------------------------------------------------------------
;PRINT SUM
;----------------------------------------------------------------------

        push bx             ; color attr
        lea  ax, [si+bp]
        push ax             ; number to print in video segment = si+bp
        mov  ax, 160*3 + 20
        push ax             ; start addr to print
        call print_bin

        add sp, 2           ; remove start addr to print

        mov  ax, 160*4 + 20
        push ax
        call print_hex

        add sp, 2
        pop cx              ; cx = si+bp: number to print in video segment
        pop bx              ; bx = color attr

        push si
        push bx
        push cx
        mov  ax, 160*5 + 20
        push ax
        call print_dec

        add sp, 4
        pop bx
        pop si

;----------------------------------------------------------------------
;PRINT SUB
;----------------------------------------------------------------------

        push bx
        mov  ax, si
        sub  ax, bp
        push ax
        mov  ax, 160*3 + 80
        push ax
        call print_bin

        add sp, 2

        mov  ax, 160*4 + 80
        push ax
        call print_hex

        add sp, 2

        mov  ax, 160*5 + 80
        push ax
        call print_dec

        add sp, 6
;----------------------------------------------------------------------
        jmp Exit

Welcome_msg: db 'Print two decimal numbers', 0Ah, '$'

Exit:   mov ax, 4c00h
        int 21h         ; exit(0)

include lib.asm

end Start