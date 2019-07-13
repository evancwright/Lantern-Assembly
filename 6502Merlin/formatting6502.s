;print formatting functions
	 
printstr
	ldy #0
:lp	
	lda (strAddr),y
	cmp #0
	beq :x
	jsr printf_word
	;print white space until a new word is hit or the end of the line is hit
	jsr print_wht_spc
	jmp :lp
:x	rts

;prints a word but takes will print a carriage return if necessary
 
printf_word
	jsr get_word_len
	lda wrdLen
	cmp charsLeft
	beq :eq
	bcs :ne
;enough space
	jsr print_str_word
	jmp :x
:ne ; not enough
	jsr printcr
	lda #scrWdth
	sta charsLeft
	jsr print_str_word
	jmp :x
:eq ; exactly enough
	jsr print_str_word
	jsr skip_whitespace
:x	rts

;prints wht space until a word, null, or endline is hit
;if the end of a line is hit, y will be advanced to the next word
 
print_wht_spc
:lp
	lda (strAddr),y
	cmp #0
	beq :x  ; hit a null done
	cmp #' ' 
	bne :x   ; hit a char done
	lda spcChar
	jsr cout1
	dec charsLeft
	lda charsLeft
	cmp #0 
	beq :e  ; no space left on line
	iny
	jmp :lp
:e  jsr skip_whitespace
	jsr printcr
	lda #scrWdth
	sta charsLeft
:x	rts


;skip whitespace
;use when starting on a new line
 
skip_whitespace
:lp
	lda (strAddr),y
	cmp #' '
	bne :x
	cmp #0
	beq :x
	iny 
	jmp :lp
:x	rts

;prints the word referenced by (Strstrc),y
;updates chars left
 
print_str_word
:lp	
	lda (strAddr),y
	cmp #0
	beq :x
	cmp #' '
	beq :x 
	jsr charout1
	dec charsLeft
	iny
	jmp :lp
:x	rts



get_word_len
	txa
	pha
	tya
	pha
	ldx #0
:lp 
	lda (strAddr),y
	cmp #' '
	beq :x
	cmp #0
	beq :x
	inx
	iny
	jmp :lp
:x	
	stx wrdLen
	pla
	tay
	pla
	tax
	rts
 	
ysav DB 0

charsLeft DB 40
