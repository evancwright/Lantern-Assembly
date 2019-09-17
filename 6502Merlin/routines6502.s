;sets the playerRoom variable
;and leaves var in 'a'
get_player_room
	pha
	tya
	pha
	ldy #OBJ_ENTRY_SIZE+HOLDER_ID
	lda obj_table,y
	sta playerRoom
	pla
	tay
	pla
	lda playerRoom
	rts
	
;assumes check_move has passed
enter_sub
	lda sentence+1 ; 1st noun
	ldy #ENTER
	jsr get_obj_attr ; obj=a attr=y  (get room's property)
	tax ; put new room in x and go there
	lda #PLAYER_ID
	ldy #HOLDER_ID
	jsr set_obj_attr
	jsr look_sub
	rts


;sets the variable ancestorFlag		
;to one if the var child is actually
;a child of the var ancestor
 
check_ancestor
		lda #0
		sta ancestorFlag
:lp		lda child
		ldy #HOLDER_ID
		jsr get_obj_attr
		cmp parent
		beq :y
		cmp #0
		beq :n
		sta child
		jmp :lp
:n      lda #0
		jmp :x
:y      lda #1
:x		sta ancestorFlag
		rts

;used by the loop which tries to map objects to the 
;environment
; the parent needs to be set by the caller
; the child to check needs to by stored in the global child by the caller
; point to the check_ancestor
	 
visible_ancestor		
		lda tableAddr ;save table
		pha
		lda tableAddr+1
		pha

		ldy #0		; get current object (child)
		lda (tableAddr),y
		sta child
		
		ldx #0  ; loop counter
		lda #0	;clear search flag
		sta visibleAncestorFlag
:lp		
		lda child
		ldy #HOLDER_ID
		jsr get_obj_attr
		nop  ; 
		tax ;save child's parent
		cmp parent
		beq :y
		cmp #0  ; hit offscreen
		beq :n		
		txa ; restore child's parent
		sta child  ; child's parent is the new child
		
		cmp #PLAYER_ID ; skip over player
		beq :s
		
		nop ; is parent closed?
		
		ldy #0
		jsr get_obj_attr  ; positions table pointer so we can get 
		
		ldy #PROPERTY_BYTE_1		
		lda (tableAddr),y ; table
		and #SUPPORTER_MASK
		cmp #SUPPORTER_MASK		
		beq :s
		
		ldy #PROPERTY_BYTE_1		
		lda (tableAddr),y ; table		
		and #OPEN_MASK
		cmp #OPEN_MASK
		bne :n
:s		
		jmp :lp
:n      lda #0
		jmp :x
:y      lda #1
:x		sta visibleAncestorFlag 
		pla					;restore table
		sta tableAddr+1 
		pla
		sta tableAddr
		rts		
		
;called by the parser
;child is where-ever tableAddr
;is pointing
;parent is set to the player room
in_player_room
		pha
		tay
		pha
		ldy #0  ; load id
		lda (tableAddr),y
		sta child
		jsr get_player_room
		sta parent
		jsr visible_ancestor
		pla
		tay
		pla
		rts
		
in_player_inventory
		lda tableAddr ;save table
		pha
		lda tableAddr+1
		pha

		lda #PLAYER_ID
		sta parent
		lda sentence+1
		sta child
		jsr get_obj_attr  ; position tableAddr at child
		jsr visible_ancestor

		pla					;restore table
		sta tableAddr+1 
		pla
		sta tableAddr

		rts

;restore stack and return		
quit_sub
		ldx stack
		txs
		rts
		
parent DB 0
child  DB 0
ancestorFlag DB 0
visibleAncestorFlag DB 0
cantDoThat ASC "You can't do that."
	DB 0