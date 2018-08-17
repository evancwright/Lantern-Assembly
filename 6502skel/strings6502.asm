;6502 string routines


;strSrc and strDest must be set
	.module strcat
strcat	
		lda #0
		ldy #0
		sta srcIx
_mv		lda (strDest),y
		cmp #0
		beq _cp
		iny
		jmp _mv
_cp
		sty dstIx
_lp		
		ldy srcIx
		lda (strSrc),y
		iny
		sty srcIx
		ldy dstIx
		sta (strDest),y
		iny
		sty dstIx
		cmp #0
		beq _x
		iny
		jmp _lp
_x		rts

;copies tableAddr into str src
;then adds 1 to it.  This is used
;to skip the length byte in the table
;no registers affected

tab_addr_to_str_src
		pha
		lda $tableAddr
		sta strSrc
		lda $tableAddr+1
		sta strSrc+1
		clc
		lda strSrc
		adc #1
		sta strSrc
		lda strSrc+1
		adc #0 		; add any carry
		sta strSrc+1
		pla
		rts

 
		
;the 0 page variable
;strSrc and strDest must be set
;x is  preserved
;the normal compare is 6 chars
;if you want to compare more chars
;set cmpLen to a bigger number
;result is in 'a'
	.module streq6
streq6	
 		ldy #0
_lp		lda (strSrc),y
		jsr to_upper
		sta $temp
		lda (strDest),y
		jsr to_upper
		cmp $temp
		bne _n
		cmp #0 ; if equal and null, string are equal
		beq _y
		iny 
		cpy cmpLen	 ; just match first 6 letters
		beq _y 
		jmp _lp
_y		lda #1
		jmp _x
_n		lda #0
_x		rts


;copies strsrc to strdest
;if a null or space is encountered,
;the copy stops
;these zero-page must be set by the caller
;iy contains the offset of the word
	.module strcpy
strcpy
		pha
		ldy #0
_lp		lda (strSrc),y
		sta (strDest),y
		cmp #0
		beq _x
		iny
		jmp _lp
_x		pla
		rts

;converts char in A to upper
	.module to_upper
to_upper 
    cmp #225 ; lowercase 'a'
	bcc _x
	sec
	sbc #160 ; to upper 
_x	rts
		
srcIx .byte 0
dstIx .byte 0
streqRes .byte 0
cmpLen .byte 6  ; how many bytes to compare comparing strings