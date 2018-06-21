;title_bar.asm

SCOREPOS equ 1051

draw_bar
	pshs d,x,y
	lda #0
	ldb #32 ; blank
	ldx #1024
@lp stb a,x
	inca
	cmpa #32 ; end of line
	beq @d	;break
	bra @lp ; loop
@d  nop
	jsr print_room_name
	jsr print_score
	puls y,x,d
	rts
	
print_room_name
	pshs d,x,y
	ldy 136 ; COCO cursor
	pshs y	; save cursor pos
	ldy cursrow
	pshs y
	ldx #1024
	stx 136 ; top left
	ldx #0
	stx cursrow
	jsr get_player_room ;get obj and leave it on stack
	jsr print_obj_name
	jsr invert_room
	puls y
	sty cursrow
	puls y		; restore cursor pos
	sty 136
	puls y,x,d
	rts

invert_room
	pshs d,x,y
	ldx #1024
	lda #0
@lp cmpa #24
	beq @x
	ldb a,x
	cmpb #32 ; don't invert blank
	beq @s
	subb #64 ;invert char
	stb a,x ;store it back to mem
@s  inca	
 	bra @lp
@x	puls y,x,d
	rts

;write "/100"
;then print the score next to it	
print_score
	pshs d,x,y
	lda #47  ; inverse "/"
	sta 1024+28
	lda #49   ; inverse "1"
	sta 1024+29
	lda #48  ; inverse "0"
	sta 1024+30
	sta 1024+31
	nop ; now print the score (right justified)
	lda score
	pshu a ; save it
	ldb #10
	ldx #SCOREPOS
	jsr mod8	; get rightmost digit
	adda #48 	; convert digit to inverse char 
    sta ,x		; always draw 1 char
	leax -1,x
	pulu a
	ldb #10		;divide score by 10 (shift it right)
	jsr div8
@lp	cmpa #0		; score > 0
	beq @x
	pshu a 		;save score
	ldb #10
	jsr mod8	; get rightmost digit
	adda #48 	; convert digit to inverse char 
    sta ,x	; draw char
	leax -1,x
	pulu a		; restore score
	ldb #10		;divide score by 10 (shift it right)
	jsr div8
	bra @lp
@x	puls y,x,d
	rts

	
