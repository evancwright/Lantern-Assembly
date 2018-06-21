
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;routines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
look_sub
	pshs d,x,y
	;check for light
	jsr get_player_room
	jsr ambient_light
	pulu a
	cmpa #0
	lbeq print_ret_no_light
	;print room name
	;load the 'holder' of object 1 player
	jsr get_player_room
	pulu a 
	nop	; now get the holder's description attr
	pshu a	; push holder id
	lda #DESC_ID 	; holder attr #
	pshu a	;
	jsr get_object_attr
	pulu a  ; get description id#2	
	nop		; now print that id
	ldx #description_table
	pshu a 
	jsr print_table_entry	; print the description for the room
	jsr PRINTCR
	;jsr list_room_items	
	jsr get_player_room		; get and leave player room on stack
	jsr start_look_sub
	puls x,y,d
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;holder is on the user stack
;used by look_sub
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
start_look_sub
	pshs d,x,y
	lda #0
	ldx #obj_table
@lp lda OBJ_ID,x  
	cmpa #$ff	; hit end of table
	beq @x
	cmpa #PLAYER
	beq @c
	lda PROPERTY_BYTE_1,x  ;check for a skip scenery items
	anda #SCENERY_MASK
	cmpa #SCENERY_MASK
	beq @c
	lda HOLDER_ID,x
	cmpa ,u		; is the player's room the holder of this object
	bne @c
	nop ; now print the object (then handle nesting)
	nop ; does is have an initial description?
	lda INITIAL_DESC_ID,x
	cmpa #255
	beq @n	; no initial description
	pshu a  ; push description param
	pshs x
	ldx #description_table ; put table in x
	jsr print_table_entry
	jsr PRINTCR
	puls x
	bra @f
@n	nop ; no  - print "THERE IS A [OBJECT] HERE."
	pshs x
	ldx #thereis
	jsr PRINT
	puls x
	lda OBJ_ID,x
	pshu a
	jsr print_obj_name
	pshs x
	ldx #here
	jsr PRINT
	jsr PRINTCR
	puls x
	nop ; now check for contains/supporters
@f	jsr print_nested_contents
@c	leax OBJ_ENTRY_SIZE,x	; loop to next object
	bra @lp
@x	pulu a  ; pop stack
	puls y,x,d
	rts	
	
thereis .strz "THERE IS A "
here 	.strz " HERE."		
