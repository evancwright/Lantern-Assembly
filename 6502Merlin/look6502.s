;look6502.asm
;Evan Wright, 2017

look_sub
	pha
	txa
	pha
	tay
	pha
	jsr player_can_see
	lda playerCanSee
	cmp #0
	beq :nl
	jsr get_player_room
	pha
	jsr print_obj_name
	jsr printcr
	pla
	jsr print_obj_description
	jsr list_objects
	jmp :x
:nl lda #<noLight
	sta strAddr
	lda #>noLight
	sta strAddr+1
	jsr printstrcr
:x	pla
	tay
	pla
	tax
	pla
	rts

 
look_in_sub
	lda sentence+1
	ldx #CONTAINER
	jsr get_obj_prop ; sets table addr
	cmp #1
	beq :lk
	lda #<noPeek
	sta strAddr
	lda #>noPeek
	sta strAddr+1	
	jsr printstrcr
	jmp :x
:lk	
	lda sentence+1
	ldx #OPEN
	jsr get_obj_prop ; sets table addr
	cmp #0
	beq :cl 
	;does it have anything?
	lda sentence+1
	jsr has_visible_child
	lda visibleChild
	cmp #0
	bne :sh
	lda #<itsEmpty
	sta strAddr
	lda #>itsEmpty
	sta strAddr+1	
	jsr printstrcr
	jmp :x
:sh	jsr print_list_header
	lda sentence+1
	sta parentId
	inc indentLvl
	jsr list_items
	dec indentLvl
	jmp :x
:cl
	lda #<itsClosed
	sta strAddr
	lda #>itsClosed
	sta strAddr+1	
	jsr printstrcr
:x	rts
	
;prints objects in the player's room
;either inital desc or "there is a ____ here"
;after that it recurses uses the list_items sub
	 
list_objects
		jsr get_player_room	 ; make sure player room is set
		lda #<obj_table
		sta tableAddr
		lda #>obj_table
		sta tableAddr+1		
:lp		ldy #0	; need to index with 0
		lda (tableAddr),y
		sta parentId
		cmp #0	; skip 'offscreen'
		beq :c
		cmp #1	; skip player
		beq :c
		cmp #255
		beq :x
		ldy #HOLDER_ID
		lda (tableAddr),y
		cmp playerRoom
		bne :c
		ldy #PROPERTY_BYTE_1
		lda (tableAddr),y
		ldy #SCENERY
		and maskTable,y  ; is it visible?
		cmp #1
		beq :c
		ldy #INITIAL_DESC_ID
		lda (tableAddr),y
		cmp #255
		beq :s
		jsr print_frm_str_tbl ; print initial desc
		jmp :l
:s		lda parentId ; reload
		jsr list_object ; there is a __ here
:l		nop ; list contents
 		lda parentId
		jsr has_visible_child
		lda visibleChild
		cmp #0
		beq :c  ; no objects? continue
 		lda parentId
		jsr supporter_or_open_container
		lda showContents
		cmp #0
		beq :c
		jsr print_list_header
		inc indentLvl
		lda parentId
		jsr list_items ; recurse
		dec indentLvl
:c		jsr next_entry
		jmp :lp
:x		rts

;describes the object in $sentence+1
;if the object has contents
;those are listed
look_at_sub
		lda sentence+1
		jsr print_obj_description
		jsr printcr
		nop ; does it have contents
		nop ; if yes, list them
		rts

list_object
		pha
		lda #<thereisa
		sta strAddr
		lda #>thereisa
		sta strAddr+1	
		jsr printstr
		pla
		jsr print_obj_name
		lda #<here
		sta strAddr
		lda #>here
		sta strAddr+1	
		jsr printstrcr
		rts
		
playerRoom DB 0	
ambientLight DB 1 ;	

thereisa ASC "There is a "
	DB 0
here ASC "here."
	DB 0
noLight ASC "It is pitch dark."
	DB 0
noPeek ASC "You can't see inside that."
	DB 0
itsClosed ASC "It's closed."
	DB 0
itsEmpty ASC "It's empty."
	DB 0