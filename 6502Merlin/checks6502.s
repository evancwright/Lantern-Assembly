;checks6502.asm
;(c) Evan Wright, 2017


;this is just a legacy thing.  visibility is now
;checked by the in the sentence handling
check_see_dobj
	lda tableAddr
	pha
	lda tableAddr+1
	pha
	jsr get_player_room
	sta parent
	lda sentence+1
	sta child
	ldy #0
	jsr get_obj_attr
	jsr visible_ancestor
	lda visibleAncestorFlag
	cmp #0
	bne :x
	jsr dont_see
	lda #1
	sta checkFailed
:x	pla	
	sta tableAddr+1
	pla 
	sta tableAddr
	rts

 
check_dobj_supplied
		lda dobjId	
		cmp #255
		bne :x
		lda #<missingDobj
		sta strAddr
		lda #>missingDobj
		sta strAddr+1
		jsr printstrcr
		lda #1
		sta checkFailed
:x		rts

 
check_iobj_supplied
		lda iobjId
		cmp #255
		bne :x
		lda #<missingDobj
		sta strAddr
		lda #>missingDobj
		sta strAddr+1
		jsr printstrcr		
		lda #1
		sta checkFailed
:x		rts

 
check_dobj_portable
;save table
		lda tableAddr
		pha
		lda tableAddr+1
		pha
		lda sentence+1
		ldx #PORTABLE
		jsr get_obj_prop
		cmp #0
		bne :x
		jsr thats_not_something
:x		pla
		sta tableAddr+1
		pla
		sta tableAddr
		rts

check_dobj_unlocked
		rts

;produces an error message if the
;do is a child of the io

check_dobj_wearable
		lda sentence+1
		ldx #WEARABLE
		jsr get_obj_prop
		cmp #0
		bne :x
		jsr not_wearable
:x		rts
		
	
check_iobj_container	
		lda sentence+3
		ldy #PROPERTY_BYTE_1
		jsr get_obj_attr
		and #SUPPORTER + CONTAINER
		cmp #0
		bne :x
		lda #<nosurface
		sta strAddr
		lda #>nosurface
		sta strAddr+1
		jsr printstrcr
		lda #1
		sta checkFailed
:x		rts

check_have_dobj 
		;save table
		lda tableAddr
		pha
		lda tableAddr+1
		pha
		lda #PLAYER_ID
		sta parent
		lda sentence+1
		sta child
		jsr get_obj_attr ; set table addr
		jsr visible_ancestor
		lda visibleAncestorFlag
		cmp #0
		bne :x
		lda #1
		sta checkFailed
		lda #<dontHave
		sta strAddr
		lda #>dontHave
		sta strAddr+1
		jsr printstrcr
:x		pla	
		sta tableAddr+1
		pla 
		sta tableAddr
		rts

check_dont_have_dobj 
		lda #0
		sta checkFailed
		rts ;
		nop ; //this was crashing
		lda #PLAYER_ID
		sta parent
		lda sentence+1
		sta child
		jsr get_obj_attr ; position table
		jsr visible_ancestor
		lda visibleAncestorFlag
		cmp #1
		bne :x
		lda #1
		sta checkFailed
		lda #<alreadyHave
		sta strAddr
		lda #>alreadyHave
		sta strAddr+1
		jsr printstrcr
:x		rts

check_dobj_opnable
		lda tableAddr	;save table
		pha
		lda tableAddr+1
		pha
		lda sentence+1
		ldx #OPENABLE
		jsr get_obj_prop
		cmp #0
		bne :x
		jsr thats_not_something
		jmp :x
:x		pla		
		sta tableAddr+1	;restore table
		pla
		sta tableAddr
		rts

check_dobj_lockable
		lda tableAddr	;save table
		pha
		lda tableAddr+1
		pha
		lda sentence+1
		ldx #LOCKABLE
		jsr get_obj_prop
		cmp #1
		beq :x
		jsr thats_not_something
:x		pla		
		sta tableAddr+1	;restore table
		pla
		sta tableAddr
		rts


;called by 'close'
check_dobj_open		
		lda sentence+1
		ldx #OPEN
		jsr get_obj_prop
		cmp #1
		beq :x
		jsr dobj_already_closed
:x		rts
		
 

	
check_dobj_locked
		lda sentence+1
		ldx #LOCKED
		jsr get_obj_prop
		cmp #0
		bne :x
		jsr dobj_already_locked
:x		rts
			
 
check_dobj_closed
		lda tableAddr
		pha
		lda tableAddr+1
		pha		
		lda sentence+1
		ldx #OPEN
		jsr get_obj_prop
		cmp #0
		beq :x
		jsr dobj_already_open
:x		pla
		sta tableAddr+1
		pla
		sta tableAddr
		rts


 
check_dobj_enterable
		rts

check_prep_supplied
		rts

check_light
		rts		

		
check_move
		;save table
		lda tableAddr	;save old tableAddr (lo)
		pha
		lda tableAddr+1	;save old tableAddr (hi)
		pha
		;
		lda #1
		sta checkFailed
		jsr verb_to_direction ; puts dir in y
		;if the verb is enter then the new room is what the player is trying to enter
		lda verbId
		cmp #enter_verb_id
		bne :s
		lda dobjId
		jmp :d
:s		jsr get_player_room 
:d		jsr get_obj_attr ; obj=a attr=y  (get room's property)
		sta newRoom
		cmp #127 
		bcs :ng
		ldx #DOOR
		jsr get_obj_prop   ; door?
		cmp #0
		beq :go
		lda newRoom	; it's a door get the direction the door leads
		ldy direction
		jsr get_obj_attr
		sta doorDirection
		lda newRoom	; now see if the door is open/closed_door
		ldx #OPEN
		jsr get_obj_prop
		cmp #1
	    bne :cd	
		lda doorDirection
		sta newRoom		; fall through to go
:go		lda #0
		sta checkFailed 
		jmp :x
:ng		jsr print_nogo_msg
	    jmp :x		
:cd		jsr closed_door
:x		;restore table
		pla
		sta tableAddr+1		
		pla
		sta tableAddr		
		rts
 
check_not_self_or_child
		lda tableAddr
		pha 
		lda tableAddr+1
		pha 
		lda sentence+3
		sta child
		lda sentence+1
		sta parent
		cmp child
		beq :fail  ; make sure they're not the same
		jsr check_ancestor
		lda #1
		cmp ancestorFlag
		beq :fail
		jmp :x
:fail	jsr not_possible	
:x		pla
		sta tableAddr+1
		pla
		sta tableAddr
		rts

		
missing_dobj
		rts
		

;prints the verb and sets the fail flag
thats_not_something
		lda #1
		sta checkFailed
		
		lda #<thatsNotSomething
		sta strAddr
		lda #>thatsNotSomething
		sta strAddr+1
		jsr printstr  ; print that's not ...
		
		lda #<verbBuffer
		sta strAddr
		lda #>verbBuffer
		sta strAddr+1
		jsr printstr
 
		lda #<period
		sta strAddr
		lda #>period
		sta strAddr+1		
		jsr printstrcr	; print period	
		
		rts

dobj_already_locked
		lda #1
		sta checkFailed

 		lda #<alreadyLocked
		sta strAddr
		lda #>alreadyLocked
		sta strAddr+1		
		jsr printstrcr
		rts		
		
dobj_already_unlocked
		lda #1
		sta checkFailed

		lda #<the
		sta strAddr
		lda #>the
		sta strAddr+1
		jsr printstr  ; print that's not ...
		
		lda sentence+1
		jsr print_obj_name
		
		lda #<alreadyUnlocked
		sta strAddr
		lda #>alreadyUnlocked
		sta strAddr+1		
		jsr printstrcr
		rts

;print message, sets flag				
not_possible
		lda #1
		sta checkFailed
 		
		lda #<impossible
		sta strAddr
		lda #>impossible
		sta strAddr+1
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
 		
		lda #<notwearable
		sta strAddr
		lda #>notwearable
		sta strAddr+1
		jsr printstrcr  ; print msg
		rts
		
dobj_already_open
		lda #1
		sta checkFailed
		
		lda #<the
		sta strAddr
		lda #>the
		sta strAddr+1
		jsr printstr  ; print that's not ...
		
		lda sentence+1
		jsr print_obj_name
		
		lda #<alreadyOpen
		sta strAddr
		lda #>alreadyOpen
		sta strAddr+1

		jsr printstrcr  ; print that's not ...
		
		rts

dobj_already_closed
		lda #1
		sta checkFailed
		
		lda #<the
		sta strAddr
		lda #>the
		sta strAddr+1
		jsr printstr  ; print that's not ...
		
		lda sentence+1
		jsr print_obj_name
		
		lda #<alreadyClosed
		sta strAddr
		lda #>alreadyOpen
		sta strAddr+1		
		jsr printstrcr	
		rts		

;this is just a legacy thing.  visibility is now
;checked by the in the sentence handling
	
check_see_iobj
	lda tableAddr
	pha
	lda tableAddr+1
	pha
	jsr get_player_room
	sta parent
	lda sentence+3
	sta child
	ldy #0
	jsr get_obj_attr ; set table to child
	jsr visible_ancestor
	lda visibleAncestorFlag
	cmp #0
	bne :x
	jsr dont_see
	lda #1
	sta checkFailed
:x	pla	
	sta tableAddr+1
	pla 
	sta tableAddr
	rts

		
;need to implement this!!! 	
check_put
		lda #0
		sta checkFailed
		rts
	
;need to implement this!!! 
check_weight
		lda #0
		sta checkFailed
		rts
	
		
		
		
checkFailed DFB 0		
missingDobj ASC 'Missing noun.'
	DB	0	
thatsNotSomething ASC 'That',27,' not something you can '
	DB	0	
notContainer ASC 'That',27,'s not a container.'
	DB 0
alreadyLocked	ASC 'is already locked.'
	DB 0
alreadyUnlocked	ASC 'is already unlocked.'
	DB 0
alreadyOpen	ASC 'is already open.'
	DB 0
dontHave	ASC 'You don',27,'t have that.'
	DB 0
alreadyHave	ASC 'You already have it.'
	DB 0
alreadyClosed	ASC 'is already closed.'
	DB 0
isntLockable	ASC 'isn',27,'t lockable.'
	DB 0
impossible	ASC 'That',27,'s not possible.'
	DB 0
notwearable	ASC 'That',27,'s not wearable.'
	DB 0
period ASC "."
	DB 0
nosurface ASC 'You find no suitable surface.'
	DB 0		
