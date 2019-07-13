;apple2 printing routines

printcr
	pha
	lda #$8D ; non-flashing cr
	jsr cout1
	lda #scrWdth
	sta charsLeft
	pla
	rts
		

;printsp
printsp
	pha
	lda #$A0  ; non-flashing cr
	jsr cout1
	pla
	rts
		
;prints the room name and score across the top
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
:lp 
		sta $400,y
	 	iny 
		cpy #40 ; screen width
		beq :out
		jmp :lp
:out	lda #0
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
		lda #<hundred
		sta strAddr
		lda #>hundred
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
:lp		lda divResult
		ldy #10
		jsr div ; a mod y
		lda divResult
		cmp #0 ; done?
		beq :x
		lda remainder
		clc
		adc #$B0 ; to ascii and turn on don't flash bit
		jsr cout1	
		jsr backup_2
		jmp :lp
:x		;print last char
		lda remainder
		clc
		adc #$B0	; to ascii and turn off flash
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
	ora #$80
	jsr cout1
	rts
	
		
;;;;;;;;;;;;;;APPLE 2 CODE!!!;;;;;;;;;;
;converts apple text to ascii
;addr to convert is in strSrc
;registers are preserved
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
toascii
		pha
		tay
		pha
		ldy #0
:lp		lda $200,y
		jsr fix_digits
		cmp #$8D
		bne :y
		lda #0
		sta $200,y
		jmp :x
:y		cmp #0
		beq :x
		cmp #$AD  ; -
		bne :s
		lda #'-'
		jmp :h
:s		cmp #$A0 ; space?
		bne :g
		lda #$20 ; 'ASCII Space'
		jmp :h
:g		cmp #$C1 ; 'A'
		bcc :c  ; < a
		cmp #$DB  ; 'Z'+1
		bcs :c ; > 'Z'
		and #$3F
		clc
		adc #64
:h		sta $200,y
:c		iny 
		jmp :lp 
:x		pla
		tay
		pla
		rts
	