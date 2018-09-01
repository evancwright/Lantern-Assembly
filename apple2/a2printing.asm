;apple2 printing routines

printcr:
	pha
	lda #$8D ; non-flashing cr
	jsr $cout1
	lda #scrWdth
	sta charsLeft
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
		cpy #40 ; screen width
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
 
charout1
	ora #80h
	jsr cout1
	rts