UNWEAR_MASK equ 247
wear_sub
	pshs d,x,y
	; is it being worn?
	; set beingworn bit
	lda sentence+1
	pshu a
	lda #PROPERTY_BYTE_2
	pshu a
	jsr get_object_attr
	pulu a
	ora #BEINGWORN_MASK
	pshs a
	nop ; now write it back
	lda sentence+1 ; param 1
	pshu a
	lda #PROPERTY_BYTE_2
	pshu a ;param 2
	puls a	;get props byte
	pshu a  ; param 3 (new value)
	jsr set_object_attr	
	; put it in top lvl inventory 
	lda sentence+1
	pshu a
	lda #HOLDER_ID
	pshu a
	lda #PLAYER ; 
	pshu a
	jsr set_object_attr
	;confirm
	ldx #done
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts

;clear wear bit on anything whose 
;holder is not the player	
unwear_all
	pshs d,x,y
	ldx #obj_table
@lp lda ,x
	cmpa #255  ; hit end
	beq @x
	lda HOLDER_ID,x ;skip player's things
	cmpa #PLAYER 
	beq @c
	lda PROPERTY_BYTE_2,x
	anda #UNWEAR_MASK  ; clear worn bit
	sta PROPERTY_BYTE_2,x
@c	leax OBJ_ENTRY_SIZE,x
	bra @lp
@x	puls y,x,d
	rts
	
