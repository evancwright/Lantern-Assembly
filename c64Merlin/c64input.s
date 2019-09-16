;6052 input routine


GETIN EQU FFE4
;#define HCUR 201
;#define VCUR 211
PLOT EQU 65520

 
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
:kblp	jsr getchar
		cmp #0
		beq :kblp
		cmp #BS  ; backspace?
		beq :bs
		cmp #$14  ; backspace?
		beq :bs
		cmp #$0D
		beq :kbout
		sta kbdbuf,y	; ;store key 
		jsr cout1 ; echo it
;		jsr undrscr
		iny
		jmp :kblp
:bs	
		jsr save_cursor
		ldx saveHCur  ; if already in col 1, don't back up any more
		cpx #1
		beq :kblp
		jsr cout1 ; back up on screen
		lda #0
		sta kbdbuf,y	; 
 		dey		
 		sta kbdbuf,y	; 
 		jmp :kblp
:kbout	
		lda #0	; null terminate buffer
		sta kbdbuf,y	;
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
	
	;jsr GETIN
	jsr $FFE4 ; GETIN
;	jsr $FFCF
	sta ctemp
	
	pla
	tay
	pla
	tax
	pla
	
	lda ctemp
	rts
	
charout
	sta ctemp
 	pha
	txa
	pha
	tya
	pha
	
	lda ctemp
	jsr cout1
	
	pla
	tay
	pla
	tax
	pla	

	rts

ask
	jsr clr_buffr
    jsr readkb	
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
	
ctemp DB 0	
char DB 0
kbdbuf DS 256		