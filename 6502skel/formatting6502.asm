;print formatting functions
	.module printstr
printstr
	ldy #0
_lp	
	lda ($strAddr),y
	cmp #0
	beq _x
	jsr printf_word
	;print white space until a new word is hit or the end of the line is hit
	jsr print_wht_spc
	jmp _lp
_x	rts

;prints a word but takes will print a carriage return if necessary
	.module printf_word
printf_word
	jsr get_word_len
	lda wrdLen
	cmp charsLeft
	beq _eq
	bcs _ne
;enough space
	jsr print_str_word
	jmp _x
_ne ; not enough
	jsr printcr;
	lda #scrWdth
	sta charsLeft
	jsr print_str_word
	jmp _x
_eq ; exactly enough
	jsr print_str_word
	jsr skip_whitespace
_x	rts

;prints wht space until a word, null, or endline is hit
;if the end of a line is hit, y will be advanced to the next word
	.module print_wht_spc
print_wht_spc
_lp
	lda ($strAddr),y
	cmp #0
	beq _x  ; hit a null done
	cmp #' ' 
	bne _x   ; hit a char done
	lda (spcChar)
	jsr cout1
	dec charsLeft
	lda charsLeft
	cmp #0 
	beq _e  ; no space left on line
	iny
	jmp _lp
_e  jsr skip_whitespace
	jsr printcr
	lda #scrWdth
	sta charsLeft
_x	rts


;skip whitespace
;use when starting on a new line
	.module skip_whitespace
skip_whitespace
_lp
	lda ($strAddr),y
	cmp #' '
	bne _x
	cmp #0
	beq _x
	iny 
	jmp _lp
_x
	rts

;prints the word referenced by (Strstrc),y
;updates chars left
	.module print_str_word
print_str_word
_lp	
	lda (strAddr),y
	cmp #0
	beq _x
	cmp #' '
	beq _x 
	jsr charout1
	dec charsLeft
	iny
	jmp _lp
_x	rts


.module get_word_len
get_word_len
	txa
	pha
	tya
	pha
	ldx #0
_lp 
	lda ($strAddr),y
	cmp #' '
	beq _x
	cmp #0
	beq _x
	inx
	iny
	jmp _lp
_x	
	stx wrdLen
	pla
	tay
	pla
	tax
	rts
 	
ysav .byte 0

charsLeft .byte 40