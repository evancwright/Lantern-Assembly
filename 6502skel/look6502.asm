;look6502.asm
;Evan Wright, 2017

	.module look_sub
look_sub
	pha
	txa
	pha
	tay
	pha
	jsr player_can_see
	lda playerCanSee
	cmp #0
	beq _nl
	jsr get_player_room
	pha
	jsr print_obj_name
	jsr printcr
	pla
	jsr print_obj_description
	jsr list_objects
	jmp _x
_nl lda #noLight%256
	sta strAddr
	lda #noLight/256
	sta strAddr+1
	jsr printstrcr
_x	pla
	tay
	pla
	tax
	pla
	rts

.module look_in_sub
look_in_sub
	lda $sentence+1
	ldx #CONTAINER
	jsr get_obj_prop ; sets table addr
	cmp #1
	beq _lk
	lda #noPeek%256
	sta $strAddr
	lda #noPeek/256
	sta $strAddr+1	
	jsr printstrcr
	jmp _x
_lk	
	lda $sentence+1
	ldx #OPEN
	jsr get_obj_prop ; sets table addr
	cmp #0
	beq _cl 
	;does it have anything?
	lda $sentence+1
	jsr has_visible_child
	lda visibleChild
	cmp #0
	bne _sh
	lda #itsEmpty%256
	sta $strAddr
	lda #itsEmpty/256
	sta $strAddr+1	
	jsr printstrcr
	jmp _x
_sh	jsr print_list_header
	lda $sentence+1
	sta parentId
	inc indentLvl
	jsr list_items
	dec indentLvl
	jmp _x
_cl
	lda #itsClosed%256
	sta $strAddr
	lda #itsClosed/256
	sta $strAddr+1	
	jsr printstrcr
_x	rts
	
;prints objects in the player's room
;either inital desc or "there is a ____ here"
;after that it recurses uses the list_items sub
	.module list_objects
list_objects
		jsr get_player_room	 ; make sure player room is set
		lda #obj_table%256
		sta $tableAddr
		lda #obj_table/256
		sta $tableAddr+1		
_lp		ldy #0	; need to index with 0
		lda ($tableAddr),y
		cmp #0	; skip 'offscreen'
		beq _c
		cmp #1	; skip player
		beq _c
		cmp #255
		beq _x
		ldy #HOLDER_ID
		lda ($tableAddr),y
		cmp playerRoom
		bne _c
		ldy #PROPERTY_BYTE_1
		lda ($tableAddr),y
		ldy #SCENERY
		and $maskTable,y  ; is it visible?
		cmp #1
		beq _c
		ldy #INITIAL_DESC_ID
		lda ($tableAddr),y
		cmp #255
		beq _s
		jsr print_frm_str_tbl ; print initial desc
		jmp _l
_s		ldy #0	; reload id
		lda ($tableAddr),y
		jsr list_object
_l		nop ; list contents
		ldy #0	 ; reload parent
		lda ($tableAddr),y
		jsr has_visible_child
		lda visibleChild
		cmp #0
		beq _c  ; no objects? continue
		lda ($tableAddr),y ;reload id
		
		sta parentId
		jsr supporter_or_open_container
		jsr print_list_header
		inc indentLvl
		jsr list_items ; recurse
		dec indentLvl
_c		jsr next_entry
		jmp _lp
_x
		rts

;describes the object in $sentence+1
;if the object has contents
;those are listed
look_at_sub
		lda $sentence+1
		jsr print_obj_description
		jsr printcr
		nop ; does it have contents
		nop ; if yes, list them
		rts

list_object
		pha
		lda #thereisa%256
		sta $strAddr
		lda #thereisa/256
		sta $strAddr+1	
		jsr printstr
		pla
		jsr print_obj_name
		lda #here%256
		sta $strAddr
		lda #here/256
		sta $strAddr+1	
		jsr printstrcr
		rts
		
playerRoom .byte 0	
ambientLight .byte 1 ;	
thereisa .byte "THERE IS A ",0h
here .byte "HERE.",0h
noLight .text "IT IS PITCH DARK."
.byte 0
noPeek .text "YOU CAN'T SEE INSIDE THAT."
.byte 0
itsClosed .text "IT'S CLOSED."
.byte 0
itsEmpty .text "IT'S EMPTY."
.byte 0