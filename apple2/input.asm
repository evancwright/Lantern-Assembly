;6052 input routine
#define buffer 200

	.module  readkb
readkb
		pha ;save a
		txa ;save x
		pha 
		tya ;save y
		pha
		lda #$3e	;  '>'
		ora #80h	; turn on don't flash bit 
		jsr cout1
		jsr undrscr
		ldy #0
_kblp	
		inc lastRand ; reseed rand from kb
		lda $c000 	; kb strobe
		bpl _kblp   
		
		sta $c010; ;clear strobe 
		cmp #88h  ; backspace?
		beq _bs
		cmp #8Dh
		beq _kbout
		pha
		jsr cout1 
		pla
		cmp #225  ; 'a' 
		bcc _s  ; <
		sbc #160 ; convert it to upper
_s		sta $200,y; ;store key 
		jsr undrscr
		iny
		jmp _kblp
_bs		lda $hcur	;not at start of line?
		cmp #1
		beq _kblp
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
		jmp _kblp
_kbout	
		pha ; save cr
		;dec $24	; back up and rub out the cursor
		lda #$A0
		jsr cout1
		pla ; restore cr
		jsr cout1
		lda #$0
		sta buffer,y;

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
		lda $hcur
		sec
		sbc #1 
		sta $hcur
		pla
		rts
		
char .byte 0		