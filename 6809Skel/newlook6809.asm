;new look 6809.asm
new_look
	pshs d,x,y
	jsr get_player_room ; leave on stack
	ldy #obj_table ; move to obj 2
	leay OBJ_ENTRY_SIZE,y
	leay OBJ_ENTRY_SIZE,y
@lp lda ,y ; get object id
	cmpa #255 
	beq @x ; hit end of table
	lda HOLDER_ID,y
	cmpa ,u  ; in player room?
	bne @c  ; continue
	lda PROPERTY_BYTE_2,y
	tsta SCENERY_MASK
	beq @c  ; skip scenery
	jsr print_print_or_desc
	lda PROPERTY_BYTE_2,y
	tsta SUPPORTER_MASK
	bne @ns ; not supporter
	jsr print_supporter_contents
	bra @c
@ns lda PROPERTY_BYTE_2,y
	tsta OPEN_CONTAINER
	bne @c ; not open container
	jsr print_supporter_contents
@c 
	leay OBJ_ENTRY_SIZE,y  ;  next object
	bra @lp
@x	leau 1,u  ; pop player room
	puls y,x,d
	rts

;y points to object entry
print_name_or_desc
	lda INITIAL_DESC,y
	cmpa #255
	bne @nm
	lda INITIAL_DESC,y
	jsr print_table_entry
	jsr PRINTCR
	bra @x
@nm
	ldx #thereis a 
	jsr print_table_entry
	lda NAME,y
	jsr print_table_entry
	ldx #here 
	jsr print_table_entry
@x	rts
	
print_container_contents
	rts
	
print_supporter_contents
	rts