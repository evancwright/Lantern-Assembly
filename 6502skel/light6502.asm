;light6502.asm
;(c) Evan C. Wright, 2017

;see if the player's room is lit
;loop through every object
;if it is emitting light
;is it a visible child of the player's room
	.module player_can_see
player_can_see
		;save table addr
		lda $tableAddr
		pha
		lda $tableAddr+1
		pha
		
		lda #0
		sta playerCanSee
		jsr get_player_room
		ldx #LIT
		jsr get_obj_prop
		cmp #1
		beq _y
		
		;go to start of obj_table
		lda #obj_table%256
		sta $tableAddr
		lda #obj_table/256
		sta $tableAddr+1
		
_lp		ldy #0
		lda ($tableAddr),y
		cmp #255		
		beq _n
		
		ldy #PROPERTY_BYTE_2
		lda ($tableAddr),y
		and #LIT_MASK
		cmp #0
		beq _c
		
		jsr get_player_room
		sta parent
		
		jsr visible_ancestor
		lda visibleAncestorFlag
		cmp #1
		beq _y
		
_c		jsr next_entry	
		jmp _lp
_y		lda #1
		sta playerCanSee
		lda #0
		sta turnsWithoutLight
		jmp _x		
_n		inc turnsWithoutLight
_x		pla
		sta $tableAddr+1
		pla
		sta $tableAddr
		rts
		
playerCanSee .byte 1
;turnsWithoutLight .byte 0		
