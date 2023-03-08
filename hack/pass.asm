.model tiny
.code

org 100h
locals @@

buff_size   equ 0Ah
enter_ascii equ 13d

Start:	mov ah, 09h
		lea dx,	password_welcm_msg
		int 21h						;	приветствие

		mov di, ds
		mov es, di					;	es = ds
		lea di, password_buff		;	es:di -> password_buff

		mov ah, 01h					;	DOS Fn 01h
		cld
Input_char:
		int 21h						;	al = введенный символ
		cmp al, enter_ascii
		je  Input_end				;	if (al == enter_ascii) jmp Password_cmp

		stosb						;	es:[di] = al, di++
		jmp Input_char

Input_end:
		stosb						;	es:[di] = enter_ascii, di++
		lea di, password_buff		;	es:di  -> password_buff
		lea si, password_correct	;	ds:si  -> password_correct

Password_cmp:
		lodsb						;	al = очередной символ password_correct
		scasb						;	   (es:[di] == al) ? zf = 0 : zf != 0
		jne Wrong_password			;	if (es:[di] != al) jmp Wrong_password

		cmp al, enter_ascii
		je  Right_password			;	if (al == enter_ascii) jmp Right_password
		jmp Password_cmp			;	else				   jmp Password_cmp

Right_password:
		mov ah, 09h
		lea dx, password_right_msg
		int 21h						;	right password message

		jmp Exit

Wrong_password:
		mov ah, 09h
		lea dx, password_wrong_msg
		int 21h						;	wrong password message

		jmp Exit

Exit:	mov ax, 4C00h
		int 21h

;----------------------------------------------------------------------
password_buff 	 	db buff_size DUP(?)
password_correct 	db "aboba", enter_ascii

password_welcm_msg	db "Enter your password!", 				   0Ah, '$'
password_right_msg  db "Correct password! Access is allowed!", 0Ah, '$'
password_wrong_msg	db "Wrong password! Access denied!", 	   0Ah, '$'
;----------------------------------------------------------------------

end Start