;======================================================================
; Возвращает длину строки ES:[DI], не включая символ конца строки
; Длина строки должна быть не более 2^11 символов
;======================================================================
; Entry: ES:DI -  string addr
;           AL -  string's end character
;----------------------------------------------------------------------
; Expects:  df =  0
;----------------------------------------------------------------------
; Exit:     AX -  length of the string without string's end character
; Destroys: AX, CX, DI
;======================================================================

strlen_esdi proc

        mov cx, 801h        ; cx = 2^11 + 1 - максимальная длина строки в байтах + символ конца строки
        repne scasb
        mov ax, 800h
        sub ax, cx

        ret

strlen_esdi endp

;======================================================================
; Возвращает длину строки DS:[SI], не включая символ конца строки
; Длина строки должна быть не более 2^12 символов
;======================================================================
; Entry: DS:SI -  string addr
;           AL -  string's end character
;----------------------------------------------------------------------
; Expects:  df =  0
;----------------------------------------------------------------------
; Exit:     AX -  length of the string without string's end character
; Destroys: AX, BX, CX, ES, DI
;======================================================================

strlen_dssi proc

        mov  bx, ds
        mov  es, bx ; es = ds
        mov  di, si ; di = si

        call strlen_esdi
        ret

strlen_dssi endp

;======================================================================
; Копирует CX символов из DS:[SI] в ES:[DI]
;======================================================================
; Entry: DS:SI -  addr of string to copy from
;        ES:DI -  addr of string to copy in
;           CX -  number of characters to copy
;----------------------------------------------------------------------
; Expects:  df =  0
;----------------------------------------------------------------------
; Exit:     None
; Destroys: CX, SI, DI
;======================================================================

memcpy      proc

        rep movsb
        ret

memcpy     endp

;======================================================================
; Копирует строку DS:[SI] в ES:[DI]
;======================================================================
; Entry: DS:SI -  addr of string to copy from
;        ES:DI -  addr of string to copy in
;           AL -  string's end character
;----------------------------------------------------------------------
; Expects:  df =  0
;----------------------------------------------------------------------
; Exit:     None
; Destroys: BX, CX, SI, DI
;======================================================================

strcpy      proc

        mov  cx, ax

        push cx
        push es
        push di
        call strlen_dssi
        pop di
        pop es
        pop cx

        inc  ax
        xchg ax, cx         ; cx - длина ds:[si] вместе с символом конца строки
                            ; al - string's end character
        rep movsb

strcpy      endp

;======================================================================
; Размещает символ AL в первых CX позициях ES:[DI]
;======================================================================
; Entry: ES:DI -  addr of string to copy in
;           CX -  number of characters to copy
;           AL -  character to copy
;----------------------------------------------------------------------
; Expects:  df =  0
;----------------------------------------------------------------------
; Exit:     None
; Destroys: CX, DI
;======================================================================

memset      proc

        rep stosb
        ret

memset      endp

;======================================================================
; Сравнивает первые CX символов DS:[SI] и ES:[DI]
;=====================================================================
; Entry: ES:DI -  addr of the first  string to compare
;        DS:SI -  addr of the second string to compare
;           CX -  number of characters to check
;----------------------------------------------------------------------
; Expects:  df =  0
;----------------------------------------------------------------------
; Exit:     AH < 0, ds:[si] < es:[di]
;           AH > 0, ds:[si] > es:[di]
;           AH = 0, ds:[si] = es:[di]
; Destroys: AH, CX, SI, DI
;======================================================================

memcmp      proc

    repe cmpsb
    jb   @@Neg_res
    ja   @@Pos_res

@@Neu_res:
        xor ah, ah
        ret

@@Pos_res:
        mov ah, 1
        ret
@@Neg_res:
        mov ah, -1
        ret

memcmp      endp

;======================================================================
; Сравнивает строки DS:[SI] и ES:[DI]
; Длина строки должна быть не более 2^12 символов
;======================================================================
; Entry: ES:DI -  addr of the first  string to compare
;        DS:SI -  addr of the second string to compare
;           AL -  string's end character
;----------------------------------------------------------------------
; Expects:  df =  0
;----------------------------------------------------------------------
; Exit:     AH < 0, ds:[si] < es:[di]
;           AH > 0, ds:[si] > es:[di]
;           AH = 0, ds:[si] = es:[di]
; Destroys: AH, BX, CX, SI, DI
;======================================================================

strcmp          proc

        mov  bx, ax
        call strlen_esdi
        inc  ax
        xchg bx, ax

        repe cmpsb
        ja @@Pos_res
        jb @@Neg_res

@@Neu_res:
        xor ah, ah
        ret
@@Pos_res:
        mov ah, 1
        ret
@@Neg_res:
        mov ah, -1
        ret

strcmp          endp

;======================================================================
; Выводит однострочное сообщение в видео память
;======================================================================
; Entry: ES:DI -  start addr to print the message in
;        DS:SI -  start addr to read  the message from
;           AH -  color attr
;           AL -  string's end character
;----------------------------------------------------------------------
; Expects:  ES -> video segment
;           df =  0
;----------------------------------------------------------------------
; Exit:     SI -> addr after string's end character
; Destroys: AL, CX, SI, DI
;======================================================================

video_oneline_message   proc

        push es
        push di
        push ax

        call strlen_dssi
        mov  cx, ax         ; cx = длина сообщения

        pop ax
        pop di
        pop es

        cmp cx, 0
        je @@Exit           ; if (длина сообщения равна нулю) jmp @@Exit
@@Next:
        lodsb               ; al      = ds:[si]
        stosw               ; es:[di] = ax (ah = attr)
        loop @@Next

@@Exit: inc si              ; skip string's end character
        ret

video_oneline_message   endp

;======================================================================
; Выводит многострочное сообщение в видео память
;======================================================================
; Entry: ES:DI -  start addr to print the message in
;        DS:SI -  start addr to read  the message from
;           AH -  color attr
;           AL -  string's end     character
;           DL -  string's newline character
;----------------------------------------------------------------------
; Expects:  ES -> video segment
;           df =  0
;----------------------------------------------------------------------
; Exit:     SI -> addr after string's end character
; Destroys: AL, BX, CX, SI, DI
;======================================================================

video_message   proc

        push ax
        push es
        push di
        call strlen_dssi
        mov cx, ax          ; cx = длина сообщения
        pop di
        pop es
        pop ax

        cmp cx, 0
        je @@Exit           ; if (длина строки равна нулю) jmp @@Exit

        mov bx, di          ; bx = адрес текущей строки в видео памяти
@@Next:
        lodsb               ; al = ds:[si]
        cmp al, dl
        je @@Newline        ; if (al == newline_char) jmp @@Newline

        stosw               ; es:[di] = ax (ah = attr)
        loop @@Next
        jmp  @@Exit

@@Newline:
        add bx, 160d        ; 160d - кол-во байт в видеопамяти для одной строки на экране
        mov di, bx
        loop @@Next

@@Exit: inc si              ; skip string's end character
        ret

video_message   endp

;======================================================================
; Выводит однострочное сообщение по центру заданной строки экрана
;======================================================================
; Entry: DS:SI -  start addr to read the message from
;           AH -  color attr
;           AL -  string's end     character
;           BL -  vertical offset on screen to print the message in
;----------------------------------------------------------------------
; Expects:  screen_height equ <max number of lines on the screen>
;           screen_length equ <max number of characters in the string>
;           ES -> video segment
;           df =  0
;----------------------------------------------------------------------
; Exit:     SI -> addr after string's end character
; Destroys: AL, CX, SI, DI
;======================================================================

video_center_oneline_message    proc

        push ax
        push bx
        push es

        call strlen_dssi
        mov cx, ax          ; cx = длина сообщения

        pop es              ; es -> video segment
        pop bx              ; bl =  вертикальный отступ
        mov ax, 160d
        mul bl
        mov di, ax          ; di = 160d * bl - адрес начала строки на экране в видеопамяти
        
        mov ax, screen_length
        sub ax, cx
        shr ax, 1
        shl ax, 1           ; ax = [(screen_length - message_length) / 2] * 2 - горизонтальный отступ
        add di, ax          ; di = адрес в видео памяти начала вывода
        pop ax              ; ah = attr, al = символ конца строки

        cmp cx, 0
        je @@Exit           ; if (пустое сообщение) jmp @@Exit
@@Next:
        lodsb               ; al = ds:[si]
        stosw               ; es:[di] = ax (ah = attr)
        loop @@Next

@@Exit: inc si              ; skip string's end character
        ret


video_center_oneline_message    endp

;======================================================================
; Выводит многострочное сообщение в видео память по центру экрана
;======================================================================
; Entry: DS:SI -  start addr to read the message from
;           AH -  color attr
;           AL -  string's end     character
;           DL -  string's newline character
;----------------------------------------------------------------------
; Expects:  df =  0
;           ES -> video segment
;----------------------------------------------------------------------
; Exit:     BL -  max length of the string in the message
;           BH -  number of strings in the message
; Destroys: AL, BX, CX, DX, SI, DI
;======================================================================

center_video_message    proc

        mov di, si      ; di = start addr to read the message from (save si)
        mov dh, al      ; dh = string's end character (save al)
        xor bl, bl      ; bl = 0 - максимальная длина строки сообщения
        xor bh, bh      ; bh = 0 - кол-во строк в сообщении
        xor cl, cl      ; cl = 0 - длина текущей строки

@@Next: lodsb           ; al = DS:[SI]
        cmp al, dl
        je  @@Str_end   ; if (символ перевода строки) jmp @@Str_end
        cmp al, dh
        je  @@Str_end   ; if (символ конца сообщения) jmp @@Str_end

        inc cl
        jmp @@Next

@@Str_end:
        inc bh
        cmp cl, bl
        ja  @@Upd_max_len   ; if (длина текущей строки > максимальная длина строки) jmp @@Upd_max_len
        jmp @@Next_cond     ; else                                                  jmp @@Next_cond

@@Upd_max_len:
        mov bl, cl

@@Next_cond:
        xor cl, cl          ; cl = 0 - длина текущей строки
        cmp al, dh
        jne @@Next          ; if (не символ конца сообщения) jmp @@Next
;----------------------------------------------------------------------

        mov cl, screen_height
        sub cl, bh
        shr cl, 1           ; cl = (screen_height - number of string's in message) / 2 - вертикальный отступ

        mov si, di          ; si = start addr to read the message from
        push bx

@@Print_str:
        cmp bh, 1
        jne @@Newline_last_char ; if (кол-во оставшихся строк не равно единице) jmp @@Newline_last_char

@@Null_last_char:
        mov al, dh              ; al = string's end     character (ah = attr)
        jmp @@Call_video_center_oneline_message

@@Newline_last_char:
        mov al, dl              ; al = string's newline character (ah = attr)

@@Call_video_center_oneline_message:
        mov bl, cl              ; bl = вертикальный отступ
        push cx
        call video_center_oneline_message
        pop cx

        inc cl                  ; увеличиваем отступ
        dec bh                  ; уменьшаем кол-во оставшихся строк
        cmp bh, 0
        jne @@Print_str         ; if (кол-во оставшихся строк в сообщении не равно нулю) jmp @@Print_str

        pop bx
        ret
center_video_message    endp