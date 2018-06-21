PRINT 
	pshs d,u,x,y
;	leax -1,x
;	jsr SYSPRINT
	jsr printstrf
	puls y,x,u,d
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;prints the words in the obj_word_table for
;and object
;the id of the object in on the user stack
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_obj_name
	pshs d,x,y
	nop ; param on stack is passed to subroutine
	jsr find_obj_word_entry ;put x at start of words 
	lda ,x+
	tfr x,y
	ldx #dictionary
	pshu a ; index to print
	jsr print_table_entry
	lda ,y+
	cmpa #$ff ;last word?
	beq @x
	ldx #space 
	jsr PRINT 
	ldx #dictionary
	pshu a
	jsr print_table_entry ; print second word
	lda ,y+
	cmpa #$ff
	beq @x
	ldx #space
	jsr PRINT
	ldx #dictionary
	pshu a
	jsr print_table_entry	
@x	puls y,x,d
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;user stack contains id of obj to print
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
find_obj_word_entry
	pshs d,y
	pulu a	;get obj id
	ldx #obj_word_table
@lp	ldb ,x  ;get id
	cmpb #$ff	;end of table?
	beq @x
	cmpa ,x  ;get id
	beq @x	;found entry
	leax 4,x ; OBJ_WORD_ENTRY SIZE
	bra @lp
@x	leax 1,x ; skip id byte
	puls y,d
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;prints out non scenery items in the 
;param pushed on u
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_obj_contents
	pshs d,x,y
	nop ; now list all the objects
	inc indent_level	;
	ldx #obj_table
@lp lda ,x
	cmpa #$ff	; end of table?
	lbeq @x
	cmpa #PLAYER ; skip over player
	lbeq @c
	lda HOLDER_ID,x ;get holder byte
	cmpa ,u			;compare to parameter
	lbne @c			; skip it
	lda PROPERTY_BYTE_1,x		;get the byte with the scenery bit
	anda #SCENERY_MASK
	cmpa #SCENERY_MASK
	beq @c	; this items is 'invisible' - don't show it
	lda OBJ_ID,x	; reload and push object id
	nop		; does the object have an initial description?
	ldb #OBJ_ENTRY_SIZE
	mul
    pshs x
	tfr d,x
	leax obj_table,x
	ldb INITIAL_DESC_ID,x
	puls x
	cmpb #$ff
	beq @p
	pshs x
	ldx #description_table
	pshu b
	jsr indent
	jsr print_table_entry  ; print initial description
	jsr PRINTCR
	puls x
	bra @r 
@p	jsr indent
	pshs x
	ldx #leadinga
	jsr PRINT
	puls x
	lda OBJ_ID,x
	pshu a
	jsr print_obj_name	; just print the object's name	
	;is it providing light?
	pshs d,x,y
	ldb #LIT ; object is param on top
	pshu b
	lda OBJ_ID,x ; object is param on top
	pshu a
	jsr get_object_prop
	cmpa #0
	beq @j
	ldx #providinglight
	jsr PRINT
@j	puls y,x,d
	;is it being worn?
	pshs d,x,y
	ldb #WORN ; object is param on top
	pshu b
	lda OBJ_ID,x ; object is param on top
	pshu a
	jsr get_object_prop
	cmpa #0
	beq @n
	ldx #beingworn
	jsr PRINT
@n	puls y,x,d
	jsr PRINTCR
	nop ;	if that is an open container or transprent
	nop ;	print its name
@r	jsr print_nested_contents
@c  leax OBJ_ENTRY_SIZE,x	 ; skip to next object
	lbra @lp	
@x	pulu a ; pop parameter
	dec indent_level
	puls y,x,d
	rts	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;handles 'look'
;no params
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
list_room_items
	pshs d,x,y
	jsr get_player_room
	pulu a ;get result
	tfr a,b ; save copy of room
	pshu a	;pass room # to sub
	jsr count_visible_items
	pulu a
	cmpa #0
	beq	@x	; quit if no visible objects
;	ldx #visible_items
;	jsr PRINT
;	jsr PRINTCR
	pshu b	;push room #
	jsr indent
	jsr print_obj_contents
@x	puls y,x,d
	rts

;print_table_entry
;
;prints the text for a word in a table 
; x contains address of table
; u contains index to print
;[length (minus null)][null terminated text]
;
;this function cleans up the stack
;this routine is called by print_object_name
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_table_entry
	pshs d,x,y
	pulu b	   ;get index to print
@lp	cmpb #0		;done looping?
	beq @d
	tfr d,y		;save a,b
	tfr x,d
	addb ,x		;get length byte
	adca #0			;add any carry to hi byte 
	tfr d,x
	leax 2,x	;skip null and length byte
	tfr y,d		;restore a,b
	decb
	bra @lp
@d  leax 1,x	;skip length byte
	jsr PRINT   ; x should now be 1 byte behind str 
	puls y,x,d
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;this subroutine prints the nested contents
;of an object if it has any.
;x contains address of object to examine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
print_nested_contents
	pshs d,x,y
	nop ; check if it has contents
;	inc indent_level
	lda OBJ_ID,x
	pshu a
	jsr count_visible_items
	pulu a
	cmpa #0
	beq @d
	lda PROPERTY_BYTE_1,x
	anda #OPEN_CONTAINER_MASK
	cmpa #OPEN_CONTAINER_MASK
	bne @s
	jsr indent
	pshs x
	ldx #itcontains
	jsr PRINT
	jsr PRINTCR
	puls x
	lda OBJ_ID,x
	pshu a
	jsr print_obj_contents
@s	lda PROPERTY_BYTE_1,x ; is it a supporter
	anda #SUPPORTER_MASK
	cmpa #SUPPORTER_MASK	
	bne @d
	jsr PRINTCR
	pshs x
	jsr indent
	ldx #onitis
	jsr PRINT
	jsr PRINTCR
	puls x
	lda OBJ_ID,x
	pshu a
	jsr print_obj_contents
@d	puls y,x,d
;	dec indent_level
	rts

indent
	pshs d,x,y
	lda indent_level
@lp	cmpa #0
	beq @x
    ldx #space
	jsr PRINT
	deca
	bra @lp
@x	puls y,x,d
	rts
	
indent_level .db 0
	
space .strz " "
leadinga .strz "A "
beingworn .strz "(BEING WORN)"
providinglight .strz "(PROVIDING LIGHT)"