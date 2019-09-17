 ;printing

;prints the string whose index is in 'a'
;sets (strAddr) to the start of the string to print
;the function updates it as it goes
;tableAddr needs to have the table name set

printix
			sta srchIndex ; save index to print
			pha ; save rergs
			txa
			pha
			tya
			pha
			ldx #0
			ldy #0 ; y is our loop counter
:lp			cpx srchIndex
			beq :x
			clc
			jsr next_string
			inx ; increment loop counter
			jmp :lp
:x			clc
			lda tableAddr	; //add 1 to skip len byte
			adc #1
			sta tableAddr
			lda tableAddr+1
			adc #0				; add carry byte to hi byte
			sta tableAddr+1
			;copy table addr into str addr
			lda tableAddr+1
			sta strAddr+1
			lda tableAddr
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
	sta srchIndex
	pha 
	txa
	pha
	tya 
	pha
	ldx tableAddr+1 ; save old table entry
	ldy tableAddr
	lda #>dictionary
	sta tableAddr+1
	lda #<dictionary
	sta tableAddr
	lda srchIndex ; reload 'a'
	jsr printix
	stx tableAddr+1 
	sty tableAddr 
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
	
print_obj_name
		sta objId
		pha	; save regs
		txa
		pha
		tya
		pha
		lda tableAddr	;save old tableAddr (lo)
		pha
		lda tableAddr+1	;save old tableAddr (hi)
		pha
		lda #>obj_word_table	; load obj_name_table into 0 page
		sta tableAddr+1	
		lda #<obj_word_table
		sta tableAddr
		lda objId
:lp		cmp #0
		beq :out
		jsr inc_tabl_addr
		jsr inc_tabl_addr
		jsr inc_tabl_addr
		jsr inc_tabl_addr
		sec
		sbc #1  ; dec a
		jmp :lp
:out	ldy #1
		lda (tableAddr),y
		jsr print_word
		ldy #2
		lda (tableAddr),y
		cmp #255
		beq :x 
		jsr printsp ;print a space
		jsr print_word
		ldy #3
		lda (tableAddr),y
		cmp #255
		beq :x
		jsr printsp ;print a space
		jsr print_word
:x		jsr printsp ;print a space
		pla ;restore tableAddr (hi)
		sta tableAddr+1
		pla	 ;restore tableAddr (lo)
		sta tableAddr
		pla	;pull regs
		tay
		pla
		tax
		pla
		rts
		 
printstrcr
		jsr printstr
		jsr printcr
		rts

;prints the string in 'a' from the string 
;table		
print_frm_str_tbl
		sta objId		
		pha	; save regs
		tax
		pha
		tya
		pha
		lda tableAddr ; save old addr
		pha
		lda tableAddr+1
		pha
 		lda #<string_table
		sta tableAddr
		lda #>string_table
		sta tableAddr+1		
		lda objId
		jsr printix
		jsr printcr
		pla				;restore table addr
		sta tableAddr+1
		pla
		sta tableAddr
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
		lda #<string_table
		sta tableAddr
		lda #>string_table
		sta tableAddr+1		
		pla
		jsr printix
		jsr printcr
		rts


		
;direction is in 'a'		
print_nogo_msg
		sec				; take two's complement of number
		lda #255
		sbc newRoom
		clc
		adc #1
		pha
		lda #<nogo_table	; set up table addr
		sta tableAddr
		lda #>nogo_table
		sta tableAddr+1
		pla
		jsr printixcr	; print
		rts

print_a_contains
		pha
		lda #<the
		sta strAddr
		lda #>the
		sta strAddr+1
		jsr printstr
		pla ;restore a	
		pha
		jsr print_obj_name
		lda #<contains
		sta strAddr
		lda #>contains
		sta strAddr+1
		jsr printstrcr		
		pla
		rts		
		
print_on_a_is
		pha 
		lda #<onthe
		sta strAddr
		lda #>onthe
		sta strAddr+1
		jsr printstr
		pla ;restore a	
		pha
		jsr print_obj_name
		lda #<is
		sta strAddr
		lda #>is
		sta strAddr+1
		jsr printstrcr		
		pla
		rts

;the object to print is stored in objId
;it's addr should be in tableAddr

print_list_header
		pha
		tya
		pha	
		jsr indent
		lda container
		cmp #1
		beq :c
		ldy #0
		lda (tableAddr),y
		jsr print_on_a_is
		jmp :x
:c		ldy #0 
		lda (tableAddr),y
		jsr print_a_contains
:x		pla
		tay
		pla
		rts

print_adj
	ldy #PROPERTY_BYTE_2
	lda (tableAddr),y
	and #LIT_MASK
	cmp #0
	beq :bw
	lda #<providingLight
	sta strAddr	
	lda #>providingLight
	sta strAddr+1
	jsr printstr
	jmp :x
:bw	lda (tableAddr),y
	and #BEINGWORN_MASK
	cmp #0
	beq :x
	lda #<beingWorn
	sta strAddr	
	lda #>beingWorn
	sta strAddr+1
	jsr printstr
:x	rts

;computes the length of the word at strAddr,y
;and stores in wrdLen
;use to make sure words don't wrap onto the next line
;registers are preserved
	
get_wrd_len
	pha
	txa
	pha
	tya
	pha
	ldx #0
	iny ; space space word starts on
:lp lda (strAddr),y
	cmp #32 ; space
	beq :x
	cmp #0 ; null
	beq :x
	inx
	iny
	jmp :lp	
:x  stx wrdLen
	pla
	tay
	pla
	tax
	pla
	rts


 		
contains ASC 'contains...'	
	DFB 0
onthe ASC 'On the '	
	DFB 0
is ASC 'is...'
	DFB 0
providingLight ASC ' (providing light)'
	DFB 0
beingWorn ASC ' (being worn)'
	DFB 0
scoreText ASC 'score '
	DFB 0
hundred ASC '/100'
	DFB 0
objId DFB 0		
srchIndex DFB  0
wrdLen DFB 0
