.model tiny
.code

org 100h
locals @@

Start:  mov si, 0B800h
        mov es, si      ; es -> video segment

        mov di, 0h
        mov dx, 0E49h
        mov bh, 03h
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

        mov ax, si
        add ax, bp
        mov di, 160*3+20
        call print_bin

        mov ax, si
        add ax, bp
        mov di, 160*4+20
        call print_hex

        push bp
        push si

        mov ax, si
        add ax, bp
        mov di, 160*5+20
        call print_dec

        pop si
        pop bp
;----------------------------------------------------------------------
;PRINT SUB
;----------------------------------------------------------------------
        mov ax, si
        sub ax, bp
        mov di, 160*3+80
        call print_bin

        mov ax, si
        sub ax, bp
        mov di, 160*4+80
        call print_hex

        push bp
        push si

        mov ax, si
        sub ax, bp
        mov di, 160*5+80
        call print_dec

        pop si
        pop bp
;----------------------------------------------------------------------
        jmp Exit

Welcome_msg: db 'Print two decimal numbers', 0Ah, '$'

Exit:   mov ax, 4c00h
        int 21h         ; exit(0)

include lib.asm

end Start