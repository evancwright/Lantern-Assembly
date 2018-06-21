
;checks
MAX_BACKDROP_ROOMS equ 6 ; (5 actually)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;loop over table
;if verb matches, run the check
;if the check returns 0, pop the stack (unwind it one level)
;then rts to complete bail from 
;sentence processing
;returns 1 or 0 on user stack
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_see_dobj
	pshs d,x,y
	lda #1	; push return val
	pshu a
	nop #is it a backdrop?
	lda sentence+1	
	ldb #OBJ_ENTRY_SIZE
	mul
	tfr d,x
	leax obj_table,x
	leax PROPERTY_BYTE_2,x
	lda ,x
	anda #BACKDROP_MASK
	cmpa #BACKDROP_MASK
	bne @n
	nop ; it was a backdrop - is it visible in the rooms?
	jsr is_visible_backdrop
	pulu a
	cmpa #1
	beq @x
@n	nop #do normal check
	jsr get_player_room ; leave it on stack
	lda sentence+1	
	pshu a
	jsr is_visible_child_of  ; leave result on stack
	pulu a
	cmpa #0
	lbne @x
	ldx #nosee 
	jsr PRINT
	jsr PRINTCR
	lda #0		; change return code to 0
	sta ,u
@x	puls y,x,d
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;puts ret var, dobj, player room on stack
;then pops off top two params
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_visible_backdrop
	pshs d,x,y
	lda #0	; push return var
	pshu a 
	lda sentence+1
	pshu a
	jsr get_player_room 	; get and leave on stack
	ldx #backdrop_table
@lp	lda ,x ; load obj id
	cmpa #$ff ; hit end?
	beq @x
	cmpa 1,u ; is this the object?
	bne @c 
	ldb #1  ; found object in table...check for room matches
@il	cmpb #MAX_BACKDROP_ROOMS ; six entries for an object 
	beq #@c
	lda b,x  ; get a room it's visible in
	cmpa ,u	 ; is it one of the rooms?
	bne @n	 ; no - continue
	lda #1    ; put 1 in return var and return
	sta	2,u	  		 
	bra @x
@n	incb 	; continue inner loop
	bra @il
@c	leax 6,x ; skip over entry
	bra @lp
@x	leau 2,u  ; pop param + local off stack (leaving return on top)
	puls y,x,d
	rts
	
;return a 1 or 0 on user stack
check_dobj_supplied
		pshs d,x,y
		lda #1		;put a 1 on stack
		pshu a
		lda sentence+1	; dobj
		cmpa #NO_OBJECT
		bne @x
		ldx #nodobj	; print "YOU NEED TO SAY ..."
		jsr PRINT
		ldx #word1
		jsr PRINT
		ldx #period		; print remainder
		jsr PRINT
		jsr PRINTCR
		lda #0		; return a 0
		sta ,u
@x		puls y,x,d
		rts
nodobj 	.strz "YOU NEED TO SAY WHAT YOU WANT TO "	

;return a 1 or 0 on user stack
check_prep_supplied
		pshs d,x,y
		lda #1		;put a 1 on stack
		pshu a
		lda sentence+2	; prep
		cmpa #NO_OBJECT
		bne @x
		ldx #nodobj	; print "TRY FORMAT ...."
		jsr PRINT
		jsr PRINTCR
		lda #0		; return a 0
		sta ,u
@x		puls y,x,d
		rts

		
noprep 	.strz "TRY THE FORMAT: VERB NOUN PREPOSITION NOUN"


check_iobj_supplied
		pshs d,x,y
		lda #1		;put a 1 on stack
		pshu a
		lda sentence+3	; iobj
		cmpa #NO_OBJECT
		bne @x
		ldx #nodobj	; print "YOU NEED TO SAY ..."
		jsr PRINT
		ldx #word1 ;verb
		jsr PRINT
		ldx #the
		jsr PRINT
		ldx #word2 ; "d.o."
		jsr PRINT
		ldx #space
		jsr PRINT
		ldx #word3  ; prep
		jsr PRINT
		ldx #period		
		jsr PRINT
		jsr PRINTCR
		lda #0		; return a 0
		sta ,u
@x		puls y,x,d
		rts
		
noiobj 	.strz "YOU NEED TO SAY WHAT YOU WANT TO "	

;used by 'get'
;makes sure the player doesn't have an object
check_dont_have_dobj
	pshs d,x,y
	lda #0
	pshu a ; push return code
	lda sentence+1
	pshu a
	lda #PLAYER
	pshu a
	jsr is_child_of ; leave code on stack
	lda #1
	cmpa ,u
	bne @r   ; ne = don't have
	ldx #alreadyhave ; 
	jsr PRINT
	jsr PRINTCR
	lda #0		; return  0
	sta ,u 	
	bra @x
@r	lda #1
    sta ,u
@x	puls y,x,d
	rts
alreadyhave 	.strz "YOU ALREADY HAVE IT."	

;check player has obj.  used by drop
check_have_dobj	
	pshs d,x,y
	lda #0
	pshu a ; push return code
	lda sentence+1	; push dobj
	pshu a
	lda #PLAYER ; push parent
	pshu a
 	jsr is_child_of ; leave code on stack for caller
	lda #1
	cmpa ,u
	lbne print_ret_no_have   ; and leave the 0 on stack
@x	puls y,x,d
	rts
	
;top of stack is player (holder)
;under that is object (child)
;under that is space for return var
is_child_of
	pshs d,x,y
	lda #1	 ; set return val to 1
	sta 2,u
@lp	nop ; is the parent of this object equal to under the stack
	lda 1,u  
	ldb #OBJ_ENTRY_SIZE
	mul
	tfr d,x
	leax obj_table,x
	leax HOLDER_ID,x
	lda ,x ; get parent
	cmpa ,u  ; if holder's parent  equal to parent yes, return (leaving 1 on stack)
	beq @x
	cmpa #0 ; did we hit the top?
	bne @s	; return 0
	lda #0	
	sta 2,u	; put 0 under the params
	bra @x
@s	sta 1,u ; put the child's parent on the stack
	bra @lp 
@x	pulu b ; pop params, leaving return val on stack
	pulu b ;
	puls y,x,d
	rts

;check_self_or_child	
; put box in table (make sure box isn't a child of table)
; used for making sure you can't put an object in iteself or a child 
; return is #0 for true (don't proceed)
; return is #1 for no (ok to proceed)
check_not_self_or_child
	pshs d,x,y
	lda #1	; set return code to 1
	pshu a
	lda sentence+1  ; 
	cmpa sentence+3 
	beq @n	; objects are the same
	lda #0  ; push space for return var (could just subtract 1, too)
	pshu a 
	lda sentence+3 ; child
	pshu a
	lda sentence+1 ; holder 
	pshu a	
	jsr is_child_of  ; params are already on stack
	pulu a
	cmpa #0  ; no means ok to proceed
	beq	@x
@n	lda #0
	sta ,u
	ldx #impossible
	jsr PRINT
	jsr PRINTCR
@x 	puls y,x,d
	rts

;check_dobj_portable
;	pshs d,x,y
;	nop	; can the player see it
;	nop	; is the object portable
;	lda sentence+1
;	ldb #OBJ_ENTRY_SIZE
;	mul
;	tfr d,x
;	leax obj_table,x 
;	lda PROPERTY_BYTE_2,x
;	anda #PORTABLE_MASK
;	cmpa #PORTABLE_MASK
;	beq @y
;	lda #0
;	ldx #impossible
;	jsr PRINT
;	jsr PRINTCR
;	bra @x
;@;y  lda #1
;@x; 	sta ,u
;	puls y,x,d
	rts

check_dobj_portable
	pshs d,x,y
	lda sentence+1
	pshu a
	lda #PROPERTY_BYTE_2
	pshu a
	jsr get_object_attr
	pulu a 	
	anda #PORTABLE_MASK
	cmpa #0
	bne @y
	ldx #notportable
	jsr PRINT
	jsr PRINTCR	
	lda #0
	bra @x
@y	lda #1
@x	pshu a
	puls y,x,d
	rts

check_dobj_opnable
	pshs d,x,y
	lda sentence+1
	pshu a
	lda #PROPERTY_BYTE_1
	pshu a
	jsr get_object_attr
	pulu a 	
	anda #OPENABLE_MASK
	cmpa #0
	bne @y
	ldx #notopenable
	jsr PRINT
	jsr PRINTCR	
	lda #0
	bra @x
@y	lda #1
@x	pshu a
	puls y,x,d
	rts
	
check_dobj_closed
	pshs d,x,y
	lda sentence+1
	pshu a
	lda #PROPERTY_BYTE_1
	pshu a
	jsr get_object_attr
	pulu a 	
	anda #OPEN_MASK
	cmpa #0
	beq @y
	ldx #alreadyopen
	jsr PRINT
	jsr PRINTCR	
	lda #0
	bra @x
@y	lda #1
@x	pshu a
	puls y,x,d
	rts

check_dobj_open
	pshs d,x,y
	lda sentence+1
	pshu a
	lda #PROPERTY_BYTE_1
	pshu a
	jsr get_object_attr
	pulu a 	
	anda #OPEN_MASK
	cmpa #0
	bne @y
	ldx #the
	jsr PRINT
	ldx #word2 ; "d.o."
	jsr PRINT
	ldx #isclosed
	jsr PRINT
	jsr PRINTCR	
	lda #0
	bra @x
@y	lda #1
@x	pshu a
	puls y,x,d
	rts

check_dobj_locked
	pshs d,x,y
	lda sentence+1
	pshu a
	lda #PROPERTY_BYTE_2
	pshu a
	jsr get_object_attr
	pulu a 	
	anda #LOCKED_MASK
	cmpa #LOCKED_MASK
	beq @y
	ldx #notlocked
	jsr PRINT
	jsr PRINTCR	
	lda #0
	bra @x
@y	lda #1
@x	pshu a
	puls y,x,d
	rts

check_dobj_unlocked
	pshs d,x,y
	lda sentence+1
	pshu a
	lda #PROPERTY_BYTE_2
	pshu a
	jsr get_object_attr
	pulu a 	
	anda #LOCKED_MASK
	cmpa #0
	beq @y
	ldx #the
	jsr PRINT
	ldx #sentence+1
	ldx #word1
	jsr PRINT
	ldx #islocked
	jsr PRINT
	jsr PRINTCR	
	lda #0
	bra @x
@y	lda #1
@x	pshu a
	puls y,x,d
	rts

check_dobj_wearable
	pshs d,x,y
	lda sentence+1
	pshu a
	lda #PROPERTY_BYTE_2
	pshu a
	jsr get_object_attr
	pulu a 	
	anda #WEARABLE_MASK
	cmpa #WEARABLE_MASK
	beq @y
 	ldx #notWearable
	jsr PRINT
	jsr PRINTCR	
	lda #0
	bra @x
@y	lda #1
@x	pshu a
    puls y,x,d
	rts

check_light
	pshs d,x,y
	lda playerCanSee
	cmpa #1
 	beq @x
 	ldx #tooDark
	jsr PRINT
	jsr PRINTCR	
	lda #0
@x	pshu a
    puls y,x,d
	rts	
	
notlocked  .strz "IT'S NOT LOCKED."	
impossible .strz "THAT'S PHYSICALLY IMPOSSIBLE."
alreadyWorn .strz "YOU'RE ALREADY WEARING THAT."
notWearable .strz "YOU CAN'T WEAR THAT."
tooDark .strz "IT'S TOO DARK TO SEE."
	
