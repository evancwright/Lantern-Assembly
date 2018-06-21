;sets the playerRoom variable
;and leaves var in 'a'
get_player_room
	pha
	tya
	pha
	ldy #OBJ_ENTRY_SIZE+HOLDER_ID
	lda $obj_table,y
	sta playerRoom
	pla
	tay
	pla
	lda playerRoom
	rts
	
	.module enter_sub
enter_sub

		nop ; is the object enterable?
		lda $sentence+1
		ldy #ENTER
		jsr get_obj_attr
		
		cmp #255
		beq _n
		
		tax ; put new room in x and go there
	    lda #PLAYER_ID
		ldy #HOLDER_ID
		jsr set_obj_attr
		jsr look_sub
		jmp _x
		
_n		lda #cantDoThat%256
		sta strAddr
		lda #cantDoThat/256
		sta strAddr+1
		jsr printstrcr
_x		rts

;set the variable ancestorFlag
;sets the variable ancestorFlag		
;to one if the var child is actually
;a child of the var ancestor
	.module check_ancestor
check_ancestor
		lda #0
		sta ancestorFlag
_lp		lda child
		ldy #HOLDER_ID
		jsr get_obj_attr
		cmp parent
		beq _y
		cmp #0
		beq _n
		sta child
		jmp _lp
_n      lda #0
		jmp _x
_y      lda #1
_x		sta ancestorFlag
		rts

;used by the loop which tries to map objects to the 
;environment
; the parent needs to be set by the caller
; table addr needs to be set by the caller to 
; point to the check_ancestor
	.module visible_ancestor
visible_ancestor
		
		lda $tableAddr ;save table
		pha
		lda $tableAddr+1
		pha
 
		ldy #0		; get current object (child)
		lda ($tableAddr),y
		sta child
		
		ldx #0  ; loop counter
		lda #0	;clear search flag
		sta visibleAncestorFlag
_lp		
		lda child
		ldy #HOLDER_ID
		jsr get_obj_attr
		nop  ; is the parent closed ?
		tax ;save parent
		cmp parent
		beq _y
		cmp #0
		beq _n		
		sta child
		txa ; restore parent
		
		cmp #PLAYER_ID ; skip over player
		beq _s
		
		nop ; is parent closed?
		
		ldy #0
		jsr get_obj_attr  ; position table pointer
		
		ldy #PROPERTY_BYTE_1		
		lda ($tableAddr),y ; table
		and #SUPPORTER_MASK
		cmp #SUPPORTER_MASK		
		beq _s
		
		ldy #PROPERTY_BYTE_1		
		lda ($tableAddr),y ; table		
		and #OPEN_MASK
		cmp #OPEN_MASK
		bne _n
_s		
		jmp _lp
_n      lda #0
		jmp _x
_y      lda #1
_x		sta visibleAncestorFlag 
		pla					;restore table
		sta $tableAddr+1 
		pla
		sta $tableAddr
		rts		
		
;called by the parser
;child is where-ever tableAddr
;is pointing
;parent is set to the player room
in_player_room
 
		jsr get_player_room
		sta parent
 
		jsr visible_ancestor

		rts
		
in_player_inventory
		lda $tableAddr ;save table
		pha
		lda $tableAddr+1
		pha

		lda #PLAYER_ID
		sta parent
		lda $sentence+1
		sta child
		jsr get_obj_attr  ; position tableAddr at child
		jsr visible_ancestor

		pla					;restore table
		sta $tableAddr+1 
		pla
		sta $tableAddr

		rts

;restore stack and return		
quit_sub
		ldx stack
		txs
		rts
		
parent .byte 0
child  .byte 0
ancestorFlag .byte 0
visibleAncestorFlag .byte 0
cantDoThat .text "YOU CAN'T DO THAT."
.byte 0	