;checks6502.asm
;(c) Evan Wright, 2017


;this is just a legacy thing.  visibility is now
;checked by the in the sentence handling
	.module check_see_dobj
check_see_dobj
	lda $tableAddr
	pha
	lda $tableAddr+1
	pha
	jsr get_player_room
	sta parent
	lda $sentence+1
	sta child
	ldy #0
	jsr get_obj_attr
	jsr visible_ancestor
	lda visibleAncestorFlag
	cmp #0
	bne _x
	jsr dont_see
	lda #1
	sta checkFailed
_x	pla	
	sta $tableAddr+1
	pla 
	sta $tableAddr
	rts

;this is just a legacy thing.  visibility is now
;checked by the in the sentence handling
	.module check_see_iobj
check_see_iobj
	lda $tableAddr
	pha
	lda $tableAddr+1
	pha
	jsr get_player_room
	sta parent
	lda $sentence+3
	sta child
	ldy #0
	jsr get_obj_attr
	jsr visible_ancestor
	lda visibleAncestorFlag
	cmp #0
	bne _x
	jsr dont_see
	lda #1
	sta checkFailed
_x	pla	
	sta $tableAddr+1
	pla 
	sta $tableAddr
	rts
	

	.module check_dobj_supplied
check_dobj_supplied
		lda dobjId	
		cmp #255
		bne _x
		lda #missingDobj%256
		sta $strAddr
		lda #missingDobj/256
		sta $strAddr+1
		jsr printstrcr
		lda #1
		sta checkFailed
_x		rts

	.module check_iobj_supplied
check_iobj_supplied
		lda iobjId
		cmp #255
		bne _x
		lda #missingDobj%256
		sta $strAddr
		lda #missingDobj/256
		sta $strAddr+1
		jsr printstrcr		
		lda #1
		sta checkFailed
_x		rts

	.module check_dobj_portable
check_dobj_portable

;save table
		lda $tableAddr
		pha
		lda $tableAddr+1
		pha

		lda $sentence+1
		ldx #PORTABLE
		jsr get_obj_prop
		cmp #0
		bne _x
		jsr thats_not_something
_x		pla
		sta $tableAddr+1
		pla
		sta $tableAddr
		rts

check_dobj_unlocked
		rts

;produces an error message if the
;do is a child of the io
.module check_dobj_wearable
check_dobj_wearable
		lda $sentence+1
		ldx #WEARABLE
		jsr get_obj_prop
		cmp #0
		bne _x
		jsr not_wearable
_x		rts
		
.module check_iobj_container	
check_iobj_container	
		lda sentence+3
		ldy #PROPERTY_BYTE_1
		jsr get_obj_attr
		and #SUPPORTER + CONTAINER
		cmp #0
		bne _x
		lda #nosurface%256
		sta strAddr
		lda #nosurface/256
		sta strAddr+1
		jsr printstrcr
		lda #1
		sta checkFailed
_x		rts

	.module check_have_dobj
check_have_dobj 
		;save table
		lda $tableAddr
		pha
		lda $tableAddr+1
		pha

		lda #PLAYER_ID
		sta parent
		lda $sentence+1
		sta child
		jsr get_obj_attr ; set table addr
		jsr visible_ancestor
		lda visibleAncestorFlag
		cmp #0
		bne _x
		lda #1
		sta checkFailed
		lda #dontHave%256
		sta $strAddr
		lda #dontHave/256
		sta $strAddr+1
		jsr printstrcr
_x		pla	
		sta $tableAddr+1
		pla 
		sta $tableAddr
		rts

check_dont_have_dobj 
		lda #0
		sta checkFailed
		rts ;
		nop ; //this was crashing
		lda #PLAYER_ID
		sta parent
		lda $sentence+1
		sta child
		jsr get_obj_attr ; position table
		jsr visible_ancestor
		lda visibleAncestorFlag
		cmp #1
		bne _x
		lda #1
		sta checkFailed
		lda #alreadyHave%256
		sta $strAddr
		lda #alreadyHave/256
		sta $strAddr+1
		jsr printstrcr
		rts
		
	.module check_dobj_opnable
check_dobj_opnable
		lda $tableAddr	;save table
		pha
		lda $tableAddr+1
		pha
		lda $sentence+1
		ldx #OPENABLE
		jsr get_obj_prop
		cmp #0
		bne _x
		jsr thats_not_something
		jmp _x
_x		pla		
		sta $tableAddr+1	;restore table
		pla
		sta $tableAddr
		rts


	.module check_dobj_lockable
check_dobj_lockable
		lda $sentence+1
		ldx #LOCKABLE
		jsr get_obj_prop
		cmp #1
		beq _x
		jsr thats_not_something
_x		rts


;called by 'close'
	.module check_dobj_open
check_dobj_open		
		lda $sentence+1
		ldx #OPEN
		jsr get_obj_prop
		cmp #1
		beq _x
		jsr dobj_already_closed
_x		rts
		
 

	.module check_dobj_locked
check_dobj_locked
		lda $sentence+1
		ldx #LOCKED
		jsr get_obj_prop
		cmp #0
		bne _x
		jsr dobj_already_locked
_x		rts
			
		.module check_dobj_closed
check_dobj_closed
		lda $tableAddr
		pha
		lda $tableAddr+1
		pha		
		lda $sentence+1
		ldx #OPEN
		jsr get_obj_prop
		cmp #0
		beq _x
		jsr dobj_already_open
_x		pla
		sta $tableAddr+1
		pla
		sta $tableAddr
		rts


 
check_dobj_enterable
		rts

check_prep_supplied
		rts

check_light
		rts		

	.module check_not_self_or_child
check_not_self_or_child
		lda $tableAddr
		pha 
		lda $tableAddr+1
		pha 
		lda sentence+3
		sta child
		lda sentence+1
		sta parent
		cmp child
		beq _fail  ; make sure they're not the same
		jsr check_ancestor
		lda #1
		cmp ancestorFlag
		beq _fail
		jmp _x
_fail	jsr not_possible	
_x		pla
		sta $tableAddr+1
		pla
		sta $tableAddr
		rts

		
missing_dobj
		rts
		

;prints the verb and sets the fail flag
thats_not_something
		lda #1
		sta checkFailed
		
		lda #thatsNotSomething%256
		sta $strAddr
		lda #thatsNotSomething/256
		sta $strAddr+1
		jsr printstr  ; print that's not ...
		
		lda #verbBuffer%256
		sta $strAddr
		lda #verbBuffer/256
		sta $strAddr+1
		jsr printstr
 
		lda #period%256
		sta $strAddr
		lda #period/256
		sta $strAddr+1		
		jsr printstrcr	; print period	
		
		rts

dobj_already_locked
		lda #1
		sta checkFailed

 		lda #alreadyLocked%256
		sta $strAddr
		lda #alreadyLocked/256
		sta $strAddr+1		
		jsr printstrcr
		rts		
		
dobj_already_unlocked
		lda #1
		sta checkFailed

		lda #the%256
		sta $strAddr
		lda #the/256
		sta $strAddr+1
		jsr printstr  ; print that's not ...
		
		lda $sentence+1
		jsr print_obj_name
		
		lda #alreadyUnlocked%256
		sta $strAddr
		lda #alreadyUnlocked/256
		sta $strAddr+1		
		jsr printstrcr
		rts

;print message, sets flag				
not_possible
		lda #1
		sta checkFailed
 		
		lda #impossible%256
		sta $strAddr
		lda #impossible/256
		sta $strAddr+1
		jsr printstrcr  ; print that's physically possible
		rts

;print message, sets flag		
;not_possible
;		lda #1
;		sta checkFailed
 ;		
	;	lda #impossible%256
	;	sta $strAddr
	;	lda #impossible/256
	;	sta $strAddr+1
	;	jsr printstrcr  ; print msg
	;	rts

;print message, sets flag		
not_wearable
		lda #1
		sta checkFailed
 		
		lda #notwearable%256
		sta $strAddr
		lda #notwearable/256
		sta $strAddr+1
		jsr printstrcr  ; print msg
		rts
		
dobj_already_open
		lda #1
		sta checkFailed
		
		lda #the%256
		sta $strAddr
		lda #the/256
		sta $strAddr+1
		jsr printstr  ; print that's not ...
		
		lda $sentence+1
		jsr print_obj_name
		
		lda #alreadyOpen%256
		sta $strAddr
		lda #alreadyOpen/256
		sta $strAddr+1

		jsr printstrcr  ; print that's not ...
		
		rts

dobj_already_closed
		lda #1
		sta checkFailed
		
		lda #the%256
		sta $strAddr
		lda #the/256
		sta $strAddr+1
		jsr printstr  ; print that's not ...
		
		lda $sentence+1
		jsr print_obj_name
		
		lda #alreadyClosed%256
		sta $strAddr
		lda #alreadyOpen/256
		sta $strAddr+1		
		jsr printstrcr
		
		rts		

;need to implement this!!! 
check_weight
		lda #0
		sta checkFailed
		rts
	
;need to implement this!!! 	
check_put
		lda #0
		sta checkFailed
		rts
		
		
		
checkFailed .byte 0		
missingDobj .text "MISSING NOUN."
.byte 0		
thatsNotSomething .text "THAT'S NOT SOMETHING YOU CAN "
.byte 0		
notContainer .text "THAT'S NOT SOMETHING YOU CAN "
.byte 0
alreadyLocked	.text "IS ALREADY LOCKED."
.byte 0
alreadyUnlocked	.text "IS ALREADY UNLOCKED."
.byte 0
alreadyOpen	.text "IS ALREADY OPEN."
.byte 0
dontHave	.text "YOU DON'T HAVE THAT."
.byte 0
alreadyHave	.text "YOU ALREADY HAVE IT."
.byte 0
alreadyClosed	.text "IS ALREADY CLOSED."
.byte 0
isntLockable	.text "ISN'T LOCKABLE."
.byte 0
impossible	.text "THAT'S NOT PHYSICALLY POSSIBLE."
.byte 0
notwearable	.text "THAT'S NOT WEARABLE."
.byte 0
period .text "."
.byte 0		
nosurface .text "YOU FIND NO SUITABLE SURFACE."
.byte 0		
