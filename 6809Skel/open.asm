;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;open and closing subroutines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_sub
	pshs d,x,y
	lda sentence+1
	ldb #OBJ_ENTRY_SIZE    
	mul
	tfr d,x
	leax obj_table,x
	lda PROPERTY_BYTE_1,x  ; openable?
	anda #OPENABLE_MASK
	cmpa #OPENABLE_MASK
	lbne print_ret_not_openable
	lda PROPERTY_BYTE_1,x  ; already open?
	anda #OPEN_MASK
	cmpa #OPEN_MASK
	lbeq print_ret_already_open
	lda PROPERTY_BYTE_1,x  ; locked?
	anda #LOCKED_MASK
	cmpa #LOCKED_MASK
	lbeq print_ret_locked
	lda PROPERTY_BYTE_1,x
	ora #OPEN_MASK
	sta PROPERTY_BYTE_1,x
	ldx #done
	jsr PRINT
	jsr PRINTCR
	jsr reveal_contents
	puls y,x,d
	rts
	
close_sub
	pshs d,x,y
	lda sentence+1
	ldb #OBJ_ENTRY_SIZE
	mul
	tfr d,x
	leax obj_table,x
	nop	; is it openable?
	lda PROPERTY_BYTE_1,x
	anda #OPENABLE_MASK	
	cmpa #OPENABLE_MASK
	lbne print_ret_not_closeable
	nop ; is it already closed?
	lda PROPERTY_BYTE_1,x
	anda #OPEN_MASK	
	cmpa #0	; 0 means its closed
	lbeq print_ret_already_closed	;	
	nop ; close it
	lda #OPEN_MASK
	eora PROPERTY_BYTE_1,x
	sta PROPERTY_BYTE_1,x
	ldx #done
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts

;if an object has contents, they are 
;listed
reveal_contents
	pshs d,x,y
	lda sentence+1
	pshu a
	jsr count_visible_items
	pulu a
	cmpa #0
	bne @si 	;show items
	bra @x
@si	nop	 	;list items`
	ldx #reveal1
	jsr PRINT
	lda sentence+1
	pshu a
	jsr print_obj_name
	ldx #reveal2
	jsr PRINT
	jsr PRINTCR
	lda sentence+1
	pshu a
	jsr print_obj_contents
@x	puls y,x,d
	rts
	
	
get_player_room
	pshs d,x,y
	lda #PLAYER
	ldb #OBJ_ENTRY_SIZE
	mul
	tfr d,x
	leax obj_table,x
	lda HOLDER_ID,x
	pshu a
	puls y,x,d
	rts	
	
reveal1 .strz "OPENING THE "	
reveal2 .strz " REVEALS:"	