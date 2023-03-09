.model tiny
.code

org 100h
locals @@

;------------------------
buff_size   equ 20d
enter_ascii equ 13d
;------------------------

Start:	mov ah, 09h					;	Dos Fn 09h "display text"
		lea dx,	password_welcm_msg
		int 21h						;	приветствие

		mov di, ds
		mov es, di					;	es = ds
		lea di, password_buff		;	es:di -> password_buff

		xor cx, cx					;	cx = 0 - кол-во введенных символов
		mov ah, 01h					;	DOS Fn 01h "kybd input"
		cld
Input_char:
		int 21h						;	al = введенный символ
		cmp al, enter_ascii
		je  Input_end				;	if (al == enter_ascii) jmp Input_end

		stosb						;	es:[di] = al, di++
		inc cx						;	кол-во введенных символов += 1
		jmp Input_char

Input_end: jmp Start_cmp

;----------------------------------------------------------------------
password_buff 	 	db buff_size DUP(?)			;	20d bytes
password_correct 	db "F$@sdq!-_8,9k7s~?f.u"	;	20d bytes

password_welcm_msg  db "Hi bro, you have to enter the password! Just formality, you understand, I think",	0Ah, '$'	;	81d bytes
password_wrong_msg	db "Oh, no, bro! You forgot the password?",												0Ah, '$'	;	39d bytes
password_right_msg	db "That's all! And you were afraid)", 													0Ah, '$'	;	34d bytes
;----------------------------------------------------------------------

Start_cmp:
		lea di, password_buff		;	es:di  -> password_buff
		lea si, password_correct	;	ds:si  -> password_correct

		cmp cx, buff_size
		jb  Wrong_password			;	if (cx < buff_size) jmp Wrong_password

Password_cmp:
		lodsb						;	al = очередной символ password_correct
		scasb						;	   (es:[di] == al) ? zf = 0 : zf != 0
		jne Wrong_password			;	if (es:[di] != al) jmp Wrong_password

		loop Password_cmp

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

end Start