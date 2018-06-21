;returns the object id for the object whose
;'word' is supplied in b
;the value replaces the parameter
;only visible objects will be considered
;c is clobbered
*MOD
get_obj_id
		push af
		push de
		push ix
		ld d,b ; word id to 'd'
		call get_player_room
		ld b,a ; save it in b
		ld ix,obj_word_table
$lp?	ld a,(ix)	; hit end of table?
		cp 255
		jp z,$nf?
		;do the words match?
		ld a,(ix+1)	;  get word entry
		cp d		;  equal to supplied word?
		jp z, $cv?
		ld a,(ix+2)		; get lp counter
		cp d		;  equal to supplied word?
		jp z, $cv?
		ld a,(ix+3)	;get object's word entry
		cp d		;  equal to supplied word?
		jp z, $cv?
		jp $c?	; words don't match
		;possible match...
		;is it a visible backdrop?
		call is_vis_bckdrp
		cp 1
		jp z,$y
		;is it a visible ancestor of player's room
		ld c,(ix); the current object
		call b_ancestor_of_c  ; reslt->a. Note this should really check visibility
		cp 1
		jp z,$_y?    ; can't see it - go to next obj

$c?		inc ix		; not found. increment ix to next entry
		inc ix		
		inc ix		
		inc ix		
		jp $lp?	; go to next object
$_y?	ld b,(ix)	; they match! back up put the id in b
		jp $_x?
$nf?	ld b,255 	; not found code
$_x?	pop ix
		pop de
		pop af
		ret

