;c64 printing
#define SCREEN 400
#define SCREEN_WIDTH 40
#define CLR 147
#define CCOL D4
#define CROW C9 

printsp
		pha
		lda #SPACE  ; non-flashing cr
		jsr $cout1
		pla
		rts

printcr:
	pha
	lda #$CR ; non-flashing cr
	jsr $cout1
	lda  #scrWdth
	sta charsLeft
	pla
	rts
	
;prints the room name and score across the top
	.module print_title_bar
print_title_bar
		jsr save_cursor
		ldx #0
		ldy #0
		clc
		jsr PLOT
_lp 	;draw line of spaces
		sta $SCREEN,y
	 	iny 
		cpy #SCREEN_WIDTH; screen width
		beq _out
		jmp _lp
_out	clc 
		ldx #0
		ldy #3
		jsr PLOT
 		jsr get_player_room
		jsr print_obj_name
		
		jsr print_score
		rts
	
	.module print_score
print_score
		
		;move cursor to end of bar		
		sec
		ldx #0
		ldy #30
		clc
		jsr PLOT

		;print the string  /100
		lda #hundred%256
		sta strAddr
		lda #hundred/256
		sta strAddr+1
		jsr printstr
		
		;move cursor to bar		
		ldx #0
		ldy #29
		clc
		jsr PLOT
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
		jsr cout1	
		jsr backup_2

		jmp _lp
_x	
		;print last char
		lda remainder
		clc
		adc #48 ; to ascii;		ora #80h	; turn on don't flash bit
		jsr cout1
		jsr backup_2

		;restore old cursor
		jsr restore_cursor
		rts

 		
;the sub is used by print score		
backup_2
	jsr backup
	jsr backup
	rts			

	.module save_cursor
	
save_cursor
	pha
	txa
	pha
	tya
	pha
	sec
	jsr PLOT
	stx saveVCur
	sty saveHCur
	pla 
	tay
	pla
	tax
	pla
	rts
		
	.module restore_cursor
restore_cursor
	ldy saveHCur
	ldx saveVCur
	clc
	jsr PLOT
	rts
	
cls
	lda #CLR
	jsr cout1
	;go to 0,0
	clc
	ldx #0
	ldy #0
	jsr PLOT
	rts

charout1
	jsr cout1
	rts
	
saveHCur .byte 0
saveVCur .byte 0

hcur .byte 0
vcur .byte 0