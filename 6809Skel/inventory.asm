;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;inventory.asm
;routines having to do with the inventory
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;drop sub
;moves an object to the player's room
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drop_sub
	pshs d,x,y
	lda sentence+1
	ldb #OBJ_ENTRY_SIZE
	mul
	tfr d,x
	leax obj_table,x
	leax HOLDER_ID,x
	jsr get_player_room
	pulu a
	sta ,x
	ldx #dropped
	jsr PRINT
	jsr PRINTCR
	bra @x
@x	puls y,x,d
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;param on top is object to consider
;param under top is parent to check for
;0 or non zero is return on the stack
;
;loop over each 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
is_visible_child_of
	pshs d,x,y
	pulu a	;get child (the object)
@lp ldb #OBJ_ENTRY_SIZE
	mul	
	tfr d,x
	leax obj_table,x 
	lda HOLDER_ID,x
	cmpa ,u		;is the parent a match
	beq @y
	cmpa #0		;offscreen
	beq @x
	bra @lp
@y  lda #1  	;if not found, a will be 0
@x	sta ,u		;if a is 0, the answer was no
	puls y,d,x
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;count visible contents
;counts the number of non-scenery
;objects in the object on the user 
;stack
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
count_visible_items
	pshs d,x,y
	lda #0
	pshu a	;push return value
	ldx #obj_table
@lp lda ,x
	cmpa #$ff
	beq @x
	cmpa #1	; don't count the player
	beq @c
	ldb HOLDER_ID,x
	cmpb 1,u	;is the holder the parameter?
	bne @c
	lda PROPERTY_BYTE_1,x		;get the byte with the scenery bit
	anda #SCENERY_MASK
	cmpa #0
	bne @c
	inc 0,u			;found an object
	bra @x			;we only need to find 1
@c  leax OBJ_ENTRY_SIZE,x	 ; skip to next object
	bra @lp
@x	lda ,u	;copy return val
	sta 1,u ;one byte into stack 
	pulu a ;pop local var
	puls y,x,d
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;returns true if paramter 1
;is an adjacent door to the param 2 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
is_adjacent_door
	pshs d,x,y
	jsr get_player_room
	pulu a
	pshu a
	ldb #OBJ_ENTRY_SIZE
	mul
	tfr d,x
	leax obj_table,x
	leax NORTH,x ; skip to direction bytes
	lda #0	;l
@lp ldb a,x
	cmpb sentence+1  ;  is the param, any of the adjacent rooms?
	bne @s
	nop 	;  it's adjacent, is it a door
	nop 	; not doing door check right now
	lda #1  ; return a 1	
	sta ,u
	bra @x
@s	inca	 
	cmpa #10 ; 10 directions
	bne @lp
	lda #0	 ; if got here, not adjacent
	sta ,u	;return a 0
@x	puls y,x,d
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;inventory
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
inventory_sub
	pshs d,x,y
	lda #PLAYER 
	pshu a
	jsr count_visible_items
	pulu a
	cmpa #0
	bne @si 	;show items
	ldx #noitems
	jsr PRINT
	jsr PRINTCR
	bra @x
@si	nop	 	;list items`
	ldx #carrying
	jsr PRINT
	jsr PRINTCR
	lda #PLAYER
	pshu a
	jsr print_obj_contents
@x	puls y,x,d
	rts



carrying .strz "YOU ARE CARRYING..."
noitems .strz "YOU ARE EMPTY HANDED."
nosee .strz "YOU DON'T SEE THAT."
dropped .strz "DROPPED."

