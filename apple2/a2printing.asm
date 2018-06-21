;apple2 printing routines

printcr:
	pha
	lda #$8D ; non-flashing cr
	jsr $cout1
	pla
	rts
		

;printsp
printsp
	pha
	lda #$A0  ; non-flashing cr
	jsr $cout1
	pla
	rts
		
;prints the room name and score across the top
	.module print_title_bar
print_title_bar
		lda hcur
		pha
		lda vcur
		pha
		ldy #2	
		sty vcur
		ldy #0	
		sty hcur
		lda #32		
_lp 
		sta $400,y
	 	iny 
		cpy scrWdth ; screen width
		beq _out
		jmp _lp
_out	lda #0
		sta vcur
		jsr $fc22 ; recompute cur offset
		lda #3
		sta hcur		
		jsr get_player_room
		jsr print_obj_name
		pla
		sta vcur
		pla
		sta hcur
		jsr $fc22 ; reset cursor pos
		
		jsr print_score
		rts
	
	.module print_score
print_score
		
		;save old cursor position
		lda hcur
		pha
		lda vcur
		pha
		
		;move cursor to bar		
		lda #0
		sta vcur
		lda #30
		sta hcur
		jsr $fc22 ; recompute cur offset

		;print the string  /100
		lda #hundred%256
		sta strAddr
		lda #hundred/256
		sta strAddr+1
		jsr printstr
		
		;move cursor to bar		
		lda #0
		sta vcur
		lda #29
		sta hcur
		jsr $fc22 ; recompute cur offset

		;now print right to left
		lda score
		sta divResult

_lp		lda divResult
		ldy #10
		jsr div ; a mod y
		lda divResult
		cmp #0 ; done?
		beq _x
	
		lda remainder
		clc
		adc #48 ; to ascii
		ora #80h	; turn on don't flash bit
		jsr cout1	
		jsr backup_2

		jmp _lp
_x	
		;print last char
		lda remainder
		clc
		adc #48 ; to ascii
		ora #80h	; turn on don't flash bit
		jsr cout1
		jsr backup_2

		;restore old cursor
		pla
		sta vcur
		pla 
		sta hcur
		jsr $fc22
		rts


;backup_2
;the sub is used by print score		
backup_2
	lda hcur
	sec
	sbc #2
	sta hcur
	jsr $fc22 ; recompute cur offset
	rts	
	
;printstr
;prints the string whose addr is stored in strAddr
	.module printstr
printstr
			pha
			tya
			pha
			ldy #0
_lp1		lda ($strAddr),y
			cmp #0
			beq _x
			cmp #32 ; space;
			bne _s
			jsr get_wrd_len  ; get and store length of next word
			tax
			sec
			lda $21 ; line len
			sbc hcur
			cmp wrdLen
			bcs _s1	; room left
			lda #$8D		; output a cr instead
			jmp _c
_s1			txa			; restore char and output		
_s			ora #80h	; turn on don't flash bit
_c			jsr $cout1
			iny
			jmp _lp1
_x			pla
			tay
			pla	
			rts

