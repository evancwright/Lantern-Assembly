;c64 printing
SCREEN EQU 400
SCREEN_WIDTH EQU #40
CLR EQU 147
CCOL EQU D4
CROW EQU C9 

printsp
	pha
	lda #SPACE  ; non-flashing cr
	jsr cout1
	pla
	rts

printcr
	pha
	lda #CR ; non-flashing cr
	jsr cout1
	lda SCREEN_WIDTH
	sta charsLeft
	pla
	rts
	
;prints the room name and score across the top
 
print_title_bar
		jsr save_cursor
		ldx #0
		ldy #0
		clc
		jsr PLOT
:lp 	;draw line of spaces
		sta SCREEN,y
	 	iny 
		cpy SCREEN_WIDTH ; SCREEN_WIDTH; screen width
		beq :out
		jmp :lp
:out	clc 
		ldx #0
		ldy #3
		jsr PLOT
 		jsr get_player_room
		jsr print_obj_name
		jsr print_score
		rts
	
 
print_score
		
		;move cursor to end of bar		
		sec
		ldx #0
		ldy #30
		clc
		jsr PLOT

		;print the string  /100
		lda #<hundred
		sta strAddr
		lda #>hundred
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

:lp		lda divResult
		ldy #10
		jsr div ; a mod y
		lda divResult
		cmp #0 ; done?
		beq :x
	
		lda remainder
		clc
		adc #48 ; to ascii
		jsr cout1	
		jsr backup_2

		jmp :lp
:x	
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
	
saveHCur DB 0
saveVCur DB 0

hcur DB 0
vcur DB 0