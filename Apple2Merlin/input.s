;6052 input routine
buffer EQU 200

	
readkb
		pha ;save a
		txa ;save x
		pha 
		tya ;save y
		pha
		lda #$3e	;  '>'
		ora #$80	; turn on don't flash bit 
		jsr cout1
		jsr undrscr
		ldy #0
:kblp	
		inc lastRand ; reseed rand from kb
		lda $c000 	; kb strobe
		bpl :kblp   
		
		sta $c010 ;clear strobe 
		cmp #$88  ; backspace?
		beq :bs
		cmp #$8D
		beq :kbout
		pha
		jsr cout1 
		pla
		cmp #225  ; 'a' 
		bcc :s  ; <
		sbc #160 ; convert it to upper
:s		sta $200,y	; ;store key 
		jsr undrscr
		iny
		jmp :kblp
:bs		lda hcur	;not at start of line?
		cmp #1
		beq :kblp
		lda #$A0	; space
		jsr cout1 
		dec $24		; back up
		dec $24		; back up
		lda #$E2
		jsr cout1 
		dey
		lda #0
		sta $200,y
		nop ; back up cursor on screen
		dec $24 ; back up
		jsr undrscr
		jmp :kblp
:kbout	
		pha ; save cr
		;dec $24	; back up and rub out the cursor
		lda #$A0
		jsr cout1
		pla ; restore cr
		jsr cout1
		lda #$0
		sta buffer,y

		pla	;restore registers
		tay ;restore y
		pla
		tax ;restore x 
		pla ;restore a
		rts

;prints an '_' where the cursor is
;then backs up the cursor.		
undrscr
		pha
		lda #$5f	;  '_'
	;	ora #80h	; turn on don't flash bit 
		jsr cout1 
		lda hcur
		sec
		sbc #1 
		sta hcur
		pla
		rts
		
	;writing ask
ask
	jsr clr_buffr
	jsr readkb
	jsr toascii
	lda #<kbdbuf ; setup string source
	sta strDest
	lda #>kbdbuf
	sta strDest+1
	lda #<string_table ; 
	sta tableAddr
	lda #>string_table
	sta tableAddr+1
	jsr get_word_index
	lda strIndex
 	sta answer
	rts
char DFB 0		