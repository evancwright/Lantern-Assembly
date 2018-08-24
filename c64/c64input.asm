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
		cmp #$14  ; backspace?
		beq _bs
		cmp #0Dh
		beq _kbout
		sta $kbdbuf,y; ;store key 
		jsr cout1 ; echo it
;		jsr undrscr
		iny
		jmp _kblp
_bs	
		jsr save_cursor
		ldx saveHCur  ; if already in col 1, don't back up any more
		cpx #1
		beq _kblp
		jsr cout1 ; back up on screen
		lda #0
		sta $kbdbuf,y; 
 		dey		
 		sta $kbdbuf,y; 
 		jmp _kblp
_kbout	
		lda #0	; null terminate buffer
		sta $kbdbuf,y;
		jsr printcr	; new line
		jsr printcr	; new line
 
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

;backs the cursor up	
backup
	pha
	tax
	pha
	tay
	pha
	; get current pos
	sec ; carry flag 1 = get 
	ldx #0
	ldy #0
	jsr PLOT
	; set current pos
	clc ; carry flag 0 = set 
	dey ; back up
	jsr PLOT ; save cur pos
	pla
	tay
	pla
	tax
	pla
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