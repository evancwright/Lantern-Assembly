;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;print-returns
;these are NOT subroutines.  calling subroutines should
;long branch to these addresses.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_ret_no_have
	ldx #nohave
	jsr PRINT		 ;close the sentence
	jsr PRINTCR		;newline
	puls y,x,d
	rts


print_ret_bad_noun
	pshs x
	ldx #bad_noun
	jsr PRINT		;print 1st part
	puls x			;load word
	jsr PRINT		;print the word
	ldx #close_quote
	jsr PRINT		 ;close the sentence
	jsr PRINTCR		;newline
	puls y,x,d
	rts

print_ret_bad_verb
	ldx #badverb
	jsr PRINT
	ldx #word1
	jsr PRINT
	ldx #close_quote
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts
	
print_ret_not_portable
	ldx #notportable
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts
 		
	
print_ret_no_see
	ldx #badobj
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts	
 
print_ret_already_open
	ldx #alreadyopen
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts	

print_ret_not_closeable
	ldx #notcloseable
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts	
	
print_ret_already_closed
	ldx #alreadyclosed
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts	

print_ret_not_supporter
	ldx #notsupporter
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts	
	
print_ret_not_container
	ldx #notcontainer
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts	


print_ret_dont_understand
	ldx #dontunderstand
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts	

print_ret_bad_put_command
	ldx #dontunderstand
	jsr PRINT
	jsr PRINTCR
	ldx #badputcommand
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts	

print_ret_bad_open
	ldx #dontunderstand
	jsr PRINT
	jsr PRINTCR
	ldx #badopen
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts

print_ret_not_openable
	ldx #notopenable
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts

print_ret_pardon
	ldx #pardon
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts

	
print_ret_io_closed
	ldx #the
	jsr PRINT
	lda sentence+3
	pshu a
	jsr print_obj_name
	ldx #isclosed
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts

	
	
print_ret_bad_examine
	ldx #badexamine
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts

print_ret_no_light
	ldx #itispitchdark
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts

print_ret_locked
	ldx #the
	jsr PRINT
	lda sentence+1
	pshu a
	jsr print_obj_name
	ldx #islocked
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts

;this actually is a subroutine
;it checks the object in the direction
;the player is trying to move
;the move direction is on the user stack
print_object_closed
	pshs d,x,y
	ldx #the
	jsr PRINT
	nop ; get current room
	jsr get_player_room
	pulu a
	ldb #OBJ_ENTRY_SIZE
	mul
	tfr d,x	
	leax obj_table,x
	jsr get_move_direction ; convert verb to get move direction
	pulu b
	lda b,x ; now has room player is moving into (the door)
	ldb #OBJ_ENTRY_SIZE
	mul
	tfr d,x
	leax obj_table,x
	nop ; get that object's name attribute
	lda OBJ_ID,x
	pshu a
	jsr print_obj_name
	ldx #isclosed
	jsr PRINT 
	jsr PRINTCR
	puls y,x,d
	rts
	
	
badverb .strz "I DON'T KNOW THE VERB, '"
badexamine .strz "TRY: EXAMINE (SOMETHING)."
badopen .strz "TRY: OPEN (SOMETHING)."
period .strz "."
bad_noun .strz "I DON'T KNOW THE WORD, '"
close_quote .strz "'."
badobj .strz "YOU DON'T SEE THAT."	
nohave .strz "YOU DON'T HAVE THAT."	
noeat .strz  "THAT IS NOT SOMETHING YOU CAN EAT."
notportable .strz 	"YOU CAN'T TAKE THAT."
notcontainer .strz 	"YOU CAN'T PUT THINGS IN THAT."
notsupporter .strz 	"YOU FIND NO SUITABLE SURFACE."
dontunderstand .strz "I DON'T UNDERSTAND."
badputcommand .strz "TRY PUT (SOMETHING) IN (SOMETHING ELSE)."
notcloseable .strz "THAT IS NOT CLOSEABLE."
notopenable .strz "THAT IS NOT OPENABLE."
alreadyclosed .strz "IT'S ALREADY CLOSED."
alreadyopen .strz "IT'S ALREADY OPEN."
islocked .strz " IS LOCKED."
putconfused .strz "PUT " 
the .strz "THE "
isclosed .strz " IS CLOSED."
itispitchdark .strz "IT IS PITCH DARK."
pardon .strz "PARDON?"
