;======================================================================
; Возвращает длину строки ES:[DI]
; Длина строки должна быть не более 2^11 символов
;======================================================================
; Entry:    DI -  string addr
;           AL -  string's end character
;----------------------------------------------------------------------
; Expects:  ES -> string's segment
;           df =  0
;----------------------------------------------------------------------
; Return:   AX -  length of the string
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
; Возвращает длину строки DS:[SI]
; Длина строки должна быть не более 2^12 символов
;======================================================================
; Entry:    SI -  string addr
;           AL -  string's end character
;----------------------------------------------------------------------
; Expects:  DS -> string's segment
;           df =  0
;----------------------------------------------------------------------
; Return:   AX -  length of the string
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
; Entry:    SI -  addr of string to copy from
;           DI -  addr of string to copy in
;           CX -  number of characters to copy
;----------------------------------------------------------------------
; Expects:  DS -> segment of string to copy from
;           ES -> segment of string to copy in
;           df =  0
;----------------------------------------------------------------------
; Return:   None
; Destroys: CX, SI, DI
;======================================================================

memcpy      proc

        rep movsb
        ret

memcpy     endp

;======================================================================
; Копирует строку DS:[SI] в ES:[DI]
;======================================================================
; Entry:    SI -  addr of string to copy from
;           DI -  addr of string to copy in
;           AL -  string's end character
;----------------------------------------------------------------------
; Expects:  DS -> segment of string to copy from
;           ES -> segment of string to copy in
;           df =  0
;----------------------------------------------------------------------
; Return:   None
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
; Entry:    DI -  addr of string to copy in
;           CX -  number of characters to copy
;           AL -  character to copy
;----------------------------------------------------------------------
; Expects:  ES -> segment of string to copy in
;           df =  0
;----------------------------------------------------------------------
; Return:   None
; Destroys: CX, DI
;======================================================================

memset      proc

        rep stosb
        ret

memset      endp

;======================================================================
; Сравнивает первые CX символов DS:[SI] и ES:[DI]
;=====================================================================
; Entry:    DI -  addr of the first  string to compare
;           SI -  addr of the second string to compare
;           CX -  number of characters to check
;----------------------------------------------------------------------
; Expects:  ES -> segment of the first  string
;           DS -> segment of the second string
;           df =  0
;----------------------------------------------------------------------
; Return:   AH < 0, ds:[si] < es:[di]
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
; Entry:    DI -  addr of the first  string to compare
;           SI -  addr of the second string to compare
;           AL -  string's end character
;----------------------------------------------------------------------
; Expects:  ES -> segment of the first  string
;           DS -> segment of the second string
;           df =  0
;----------------------------------------------------------------------
; Return:   AH < 0, ds:[si] < es:[di]
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
