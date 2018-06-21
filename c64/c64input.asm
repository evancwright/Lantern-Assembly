;6052 input routine


#define GETIN FFE4
;#define HCUR 201
;#define VCUR 211
#define PLOT 65520

	.module  readkb
readkb
		pha ;save a
		txa ;save x
		pha 
		tya ;save y
		pha
		lda #GT	;  '>'
		jsr charout
		
;		jsr undrscr
		ldy #0
_kblp	jsr getchar
		cmp #0
		beq _kblp
		cmp #BS  ; backspace?
		beq _bs
		cmp #0Dh
		beq _kbout
		sta $kbdbuf,y; ;store key 
		jsr cout1 ; echo it
;		jsr undrscr
		iny
		jmp _kblp
_bs		lda #SPACE	; space
		jsr cout1 
		nop ;back the cursor up
		nop ;		dec $24		; back up
		nop ;		dec $24		; back up
		jsr backup
		jsr backup
		dey
		lda #0
		sta $kbdbuf,y
		nop ; back up cursor on screen
	;	dec $24 ; back up (CHANGE ME)
	;	jsr undrscr
		jmp _kblp
_kbout	
		;dec $24	; back up and rub out the cursor
		jsr printcr	; new line
		jsr printcr	; new line
		
		lda #0	; null terminate buffer
		sta $kbdbuf,y;

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
	lda #UNDRSCR	
	jsr cout1 
 	pla
	rts

backup
	; get current pos
	sec ; carry flag 1 = get 
	ldx #0
	ldy #0
	jsr PLOT
	; set current pos
	clc ; carry flag 0 = set 
	dey ; back up
	jsr PLOT ; save cur pos
	rts


getchar
	pha
	txa
	pha
	tya
	pha
	
	jsr $GETIN
;	jsr $FFCF
	sta $ctemp
	
	pla
	tay
	pla
	tax
	pla
	
	lda $ctemp
	rts
	
charout
	sta $ctemp
 	pha
	txa
	pha
	tya
	pha
	
	lda $ctemp
	jsr $cout1
	
	pla
	tay
	pla
	tax
	pla	

	rts
	
ctemp .byte 0	
char .byte 0
kbdbuf .block 256		