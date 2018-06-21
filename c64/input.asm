;6052 input routine

#define SP 32
#define GT 62
#define BS 14
#define CR 20 
#define UNDRSCR 164
#define keyin $FFCF
#define HCUR 201
#define VCUR 211
#define PLOT 65520

	.module  readkb
readkb
		pha ;save a
		txa ;save x
		pha 
		tya ;save y
		pha
		lda #GT	;  '>'
		jsr cout1
		jsr undrscr
		ldy #0
_kblp	jsr keyin
		cmp #0
		beq _kblp   
		cmp #BS  ; backspace?
		beq _bs
		cmp #CR
		beq _kbout
		sta buffer,y; ;store key 
		jsr cout1 ; echo it
		
		jsr undrscr
		iny
		jmp _kblp
_bs		lda #SP	; space
		jsr cout1 
		nop ;back the cursor up
		nop ;		dec $24		; back up
		nop ;		dec $24		; back up
		lda #$E2 ; back up (CHANGE ME)
		jsr cout1 
		dey
		lda #0
		sta buffer,y
		nop ; back up cursor on screen
	;	dec $24 ; back up (CHANGE ME)
		jsr undrscr
		jmp _kblp
_kbout	
		pha ; save cr
		;dec $24	; back up and rub out the cursor
		lda #CR	; new line
		jsr cout1
		pla ; restore cr
		jsr cout1
		lda #$0	; null terminate buffer
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
	lda #UNDRSCR	
	jsr cout1 
	lda $hcur
	sec
	sbc #1 
	sta $hcur
	pla
	rts

jsr backup
	; get current pos
	sec ; carry flag 1 = get 
	ldx #0
	ldy #0
	jsr PLOT
	; set current pos
	clc ; carry flag 0 = get 
	ldx VER
	dey ; back up
	ldy HOR
	lda #0
	jsr PLOT ; save cur pos
	rst
		
char .byte 0
buffer .block 40		