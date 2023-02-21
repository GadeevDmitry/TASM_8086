.model tiny
.code

org 100h
locals @@

Start:  mov bx, 0b800h
        mov es, bx

        mov si, 80h
        xor bh, bh
        mov bl, [si]            ;
        lea si, [si+bx+1]       ;
        mov byte ptr [si], 0    ; push 0 after command line arguments

        mov si, 82h
        call frame

Exit:   mov ax, 4c00h
        int 21h

include frame.asm

end Start