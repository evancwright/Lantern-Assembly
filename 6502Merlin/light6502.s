;light6502.asm
;(c) Evan C. Wright, 2017

;see if the player's room is lit
;loop through every object
;if it is emitting light
;is it a visible child of the player's room
	 
player_can_see
		;save table addr
		lda tableAddr
		pha
		lda tableAddr+1
		pha
		
		lda #0
		sta playerCanSee
		jsr get_player_room
		ldx #LIT
		jsr get_obj_prop
		cmp #1
		beq :y
		
		;go to start of obj_table
		lda #<obj_table
		sta tableAddr
		lda #>obj_table
		sta tableAddr+1
		
:lp		ldy #0
		lda (tableAddr),y
		cmp #255		
		beq :n
		
		ldy #PROPERTY_BYTE_2
		lda (tableAddr),y
		and #LIT_MASK
		cmp #0
		beq :c
		
		jsr get_player_room
		sta parent
		
		jsr visible_ancestor
		lda visibleAncestorFlag
		cmp #1
		beq :y
		
:c		jsr next_entry	
		jmp :lp
:y		lda #1
		sta playerCanSee
		lda #0
		sta turnsWithoutLight
		jmp :x		
:n		inc turnsWithoutLight
:x		pla
		sta tableAddr+1
		pla
		sta tableAddr
		rts
		
playerCanSee DB 1
;turnsWithoutLight DB 0		
