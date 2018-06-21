 ;printing

;prints the string whose index is in 'a'
;sets (strAddr) to the start of the string to print
;the function updates it as it goes
;tableAddr needs to have the table name set
	.module printix
printix:
			sta $srchIndex ; save index to print
			pha ; save rergs
			txa
			pha
			tya
			pha
			ldx #0
			ldy #0 ; y is our loop counter
_lp			cpx $srchIndex
			beq _x
			clc
			jsr next_string
			inx ; increment loop counter
			jmp _lp
_x			clc
			lda $tableAddr	; //add 1 to skip len byte
			adc #1
			sta $tableAddr
			lda $tableAddr+1
			adc #0				; add carry byte to hi byte
			sta $tableAddr+1
			;copy table addr into str addr
			lda ($tableAddr+1)
			sta strAddr+1
			lda ($tableAddr)
			sta strAddr
			jsr printstr
			pla
			tay
			pla
			tax
			pla
			rts
			
printixcr
	jsr printix
	jsr printcr
	rts

;prints the word whose index is in 'a'
;tableAddr is preserved			
print_word
	sta $srchIndex
	pha 
	txa
	pha
	tya 
	pha
	ldx $tableAddr+1 ; save old table entry
	ldy $tableAddr
	lda #dictionary/256; 
	sta $tableAddr+1
	lda #dictionary%256
	sta $tableAddr
	lda $srchIndex ; reload 'a'
	jsr printix
	stx $tableAddr+1 
	sty $tableAddr 
	pla
	tay
	pla
	tax
	pla
	rts

print_description
	
	jsr printix
	rts

 	
			
;prints the name of the object supplied in 'a'
;each entry is 4 four bytes
	.module print_obj_name
print_obj_name
		sta $objId
		pha	; save regs
		txa
		pha
		tya
		pha
		lda $tableAddr	;save old tableAddr (lo)
		pha
		lda $tableAddr+1	;save old tableAddr (hi)
		pha
		lda #$obj_word_table/256	; load obj_name_table into 0 page
		sta $tableAddr+1;
		lda #$obj_word_table%256	
		sta $tableAddr;	
		lda objId;
_lp		cmp #0
		beq _out
		jsr inc_tabl_addr
		jsr inc_tabl_addr
		jsr inc_tabl_addr
		jsr inc_tabl_addr
		sec
		sbc #1  ; dec a
		jmp _lp
_out	ldy #1
		lda ($tableAddr),y
		jsr print_word
		ldy #2
		lda ($tableAddr),y
		cmp #255
		beq _x 
		jsr printsp ;print a space
		jsr print_word
		ldy #3
		lda ($tableAddr),y
		cmp #255
		beq _x
		jsr printsp ;print a space
		jsr print_word
_x		jsr printsp ;print a space
		pla 	;restore tableAddr (hi)
		sta $tableAddr+1
		pla		 ;restore tableAddr (lo)
		sta $tableAddr
		pla	;pull regs
		tay
		pla
		tax
		pla
		rts
		 
printstrcr:
		jsr printstr
		jsr printcr
		rts

;prints the string in 'a' from the string 
;table		
print_frm_str_tbl
		sta $objId		
		pha	; save regs
		tax
		pha
		tya
		pha
		lda $tableAddr ; save old addr
		pha
		lda $tableAddr+1
		pha
 		lda #string_table%256
		sta $tableAddr
		lda #string_table/256
		sta $tableAddr+1		
		lda $objId
		jsr printix
		jsr printcr
		pla				;restore table addr
		sta $tableAddr+1
		pla
		sta $tableAddr
		pla	;restore
		tay
		pla
		tax
		pla
		rts
		
;prints description of item in 'a'
;registers are not preserved

print_obj_description
		ldy #DESC_ID
		jsr get_obj_attr  ; puts desc is in 'a'
		pha
		lda #string_table%256
		sta $tableAddr
		lda #string_table/256
		sta $tableAddr+1		
		pla
		jsr printix
		jsr printcr
		rts


		
;direction is in 'a'		
print_nogo_msg
		sec				; take two's complement of number
		lda #255
		sbc  $newRoom
		clc
		adc #1
		pha
		lda #nogo_table%256	; set up table addr
		sta $tableAddr
		lda #nogo_table/256
		sta $tableAddr+1
		pla
		jsr printixcr	; print
		rts

print_a_contains
		pha
		lda #the%256
		sta strAddr
		lda #the/256
		sta strAddr+1
		jsr printstr
		pla ;restore a	
		pha
		jsr print_obj_name
		lda #contains%256
		sta strAddr
		lda #contains/256
		sta strAddr+1
		jsr printstrcr		
		pla
		rts		
		
print_on_a_is
		pha 
		lda #onthe%256
		sta strAddr
		lda #onthe/256
		sta strAddr+1
		jsr printstr
		pla ;restore a	
		pha
		jsr print_obj_name
		lda #is%256
		sta strAddr
		lda #is/256
		sta strAddr+1
		jsr printstrcr		
		pla
		rts

;the object to print is stored in objId
;it's addr should be in tableAddr
	.module print_list_header
print_list_header
		pha
		tya
		pha	
		jsr indent
		lda container
		cmp #1
		beq _c
		ldy #0
		lda ($tableAddr),y
		jsr print_on_a_is
		jmp _x
_c		
		ldy #0 
		lda ($tableAddr),y
		jsr print_a_contains
_x		pla
		tay
		pla
		rts

		
	.module print_adj	
print_adj
	ldy #PROPERTY_BYTE_2
	lda ($tableAddr),y
	and #LIT_MASK
	cmp #0
	beq _bw
	lda #providingLight%256
	sta strAddr	
	lda #providingLight/256
	sta strAddr+1
	jsr printstr
	jmp _x
_bw	lda ($tableAddr),y
	and #BEINGWORN_MASK
	cmp #0
	beq _x
	lda #beingWorn%256
	sta strAddr	
	lda #beingWorn/256
	sta strAddr+1
	jsr printstr
_x	 
	rts

;computes the length of the word at strAddr,y
;and stores in wrdLen
;use to make sure words don't wrap onto the next line
;registers are preserved
	.module get_wrd_len
get_wrd_len
	pha
	txa
	pha
	tya
	pha
	ldx #0
	iny ; space space word starts on
_lp lda ($strAddr),y
	cmp #32 ; space
	beq _x
	cmp #0 ; null
	beq _x
	inx
	iny
	jmp _lp	
_x  stx wrdLen
	pla
	tay
	pla
	tax
	pla
	rts


 		
contains .text "CONTAINS..."	
	.byte 0
onthe .text "ON THE "	
	.byte 0
is .text "IS..."	
	.byte 0
providingLight .text " (PROVIDING LIGHT)"	
	.byte 0
beingWorn .text " (BEING WORN)"	
	.byte 0
scoreText .text "SCORE "
	.byte 0
hundred .text "/100"
	.byte 0
objId .byte 0		
srchIndex .byte  0
wrdLen .byte 0
