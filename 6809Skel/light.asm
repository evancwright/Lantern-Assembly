 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;routines having to do with light
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
 
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;returns 1 or 0 on the user stack
 ;if there is light in the player's
 ;room or the something in that room has
 ;a child that is emitting light and is in
 ;a supporter or (an open or transparent container)
 ;
 ;player's room is on user stack
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ambient_light
	pshs d,x,y
	lda #0
	sta playerCanSee
	pulu a	;get object from stack
	ldb #OBJ_ENTRY_SIZE
	mul
	tfr d,x	; save offset
	tfr d,y	; save offset
	leax obj_table,x
	lda PROPERTY_BYTE_2,x
	anda #LIT_MASK
	cmpa #LIT_MASK	
	bne @s ; not emitting light, check children
@y	lda #1 ; emitting light, push 1 and return
	pshu a
	sta playerCanSee
	bra @x
@s	nop 	; see if any children are emitting light
	ldb OBJ_ID,x	;reload id of parent
	ldx #obj_table	
@lp lda OBJ_ID,x    ;get obj id
	cmpa #$ff	;hit end of table?
	beq @n
	cmpb OBJ_ID,x	;is it this object?
	beq @c
	cmpb HOLDER_ID,x ;is it a child of this object?
	bne @c
	lda PROPERTY_BYTE_2,x	;is the object a light source
	anda #LIT_MASK
	cmpa #LIT_MASK
	beq @y
	lda OBJ_ID,x		;if we're the player check children
	cmpa #PLAYER
	beq @p
	lda PROPERTY_BYTE_1,x	;is the object a closed container
	anda #OPEN_CONTAINER_MASK	;
	cmpa #CONTAINER_MASK	;		
	bne @c
	lda OBJ_ID,x     ;reload obj id
@p	pshu a			 ;put child id on stack 
	jsr ambient_light ;is it emitting light
	pulu a
	cmpa #1
	beq @y				
@c  leax OBJ_ENTRY_SIZE,x ; go to next entry
	bra @lp	
@n  lda #0
	pshu a	
@x	puls y,x,d
	rts
	
playerCanSee .db 0
