;z80 table searching routines


;prints an entry in the table
;b contains the number of the string to print
;ix contains table address
*MOD
print_table_entry
	push af
	push bc
	push de
	push hl
	push ix
	ld a,0d ; lp counter 
_lp	cp b	; compare accumulator to a
	jp nz,_sk ; skip this entry
	inc ix  ; skip length byte
	push ix ; move string addr to hl
	pop hl
	call OUTLIN
	jp _x
_sk	inc a		; increment loop counter
	ld	e,(ix+0) ; load length byte
	ld d,0
	add ix,de  ; add it to ix (skip string)
	inc ix 	   ; add 1 to skip length byte
	inc ix 	   ; add 1 to skip null terminator
	jp _lp
_x	pop ix
	pop hl
	pop de
	pop bc
	pop af
	ret

;prints the name of the object whose
;id is supplied in register 'a'
*MOD
print_obj_name
		push af
		push bc
		push de
		push ix
		ld ix,obj_word_table
		ld de,4		; step amount through table
_lp$	cp 0		; done?
		jp z,_out$
		add ix,de
		dec a		; dec loop counter		
		jp _lp$
_out$	inc ix 		; skip past the id byte to the words
		ld b,0
_l2$	ld a,b
		cp 3		; hit 3 word max?
		jp z,_x?
		ld a,(ix)	; get word id
		cp 255d		; done (empty entry)?
		jp z,_x?	
		push bc		;save loop counter
		ld b,a		; put word id in b
		push ix		; save ix
		ld ix,dictionary	
		call print_table_entry
		call print_space
		pop ix		; restore ix (our table index)
		inc ix		; move to next word id
		pop bc		; restore loop counter
		inc b
		jp _l2$	
_x?		pop ix
		pop de
		pop bc
		pop af
		ret
	
;prints a space (registers are preserved)
print_space
	push bc
	push de
	push iy
	ld a,20h	; ascii space
	call CRTBYTE
	pop iy
	pop de
	pop bc
	ret


;get table index
;returns the table index in the word in b (or ff if not found)
;ix contains the address of the word to find
;iy contains the address of the table to search
;c is clobbered
*MOD
get_table_index
		push de
		ld b,0
$_lp?	ld a,(iy)
		cp 255 ; hit end
		jp z,$_nf?
		inc	iy ; skip len byte
		call streq ; test equality - result in a
		cp 1    ; done - b contains index
		jp z,$_x?	;jump if found
		inc b		;update loop counter (index)
		dec iy		;back up an get length byte
		ld d,0
		ld e,(iy)
		add iy,de	; skip to next string
		inc iy		; skip length byte
		inc iy		; skip null
		jp $_lp?	;repeat
		jp $_x?
$_nf?   ld b,255		
$_x?	pop de
		ret

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
		jp z,$cv?
		ld a,(ix+2)		; get lp counter
		cp d		;  equal to supplied word?
		jp z, $cv?
		ld a,(ix+3)	;get object's word entry
		cp d		;  equal to supplied word?
		jp z, $cv?
		jp $c?	; words don't match
		;possible match...
		;is it a visible backdrop?
$cv?	ld a,(ix)
		call is_vis_bckdrp
		cp 1
		jp z,$y?
		;is it a visible ancestor of player's room
		ld a,(player_room)
		ld c,a
		ld b,(ix); the current object
		;call b_ancestor_of_c  ; reslt->a. Note this should really check visibility
		call c_sees_b
		cp 1
		jp z,$y?    ; can't see it - go to next obj

$c?		inc ix		; not found. increment ix to next entry
		inc ix		
		inc ix		
		inc ix		
		jp $lp?	; go to next object
$y?		ld a,(ix)	; they match! back up put the id in b
		ld b,a
		jp $_x?
$nf?	ld b,255 	; not found code
$_x?	pop ix
		pop de
		pop af
		ret

		

;get_verb_id
;the verb is assumed to be in word1
;returns the id # of the verb in a
*MOD
get_verbs_id
		push bc
		push de
		push hl
		push ix
		push iy
 		ld iy,word1
		ld ix,verb_table
$lp?	ld a,(ix)       ;save the id byte
		ld b,a
		cp 0ffh	
		jp z, $x?		; hit end of table
		ld d,0			; set up de with len
		inc ix
		ld e,(ix)		; get length byte
		inc ix			;ix now at text
		call streq
		cp 1   
		jp z,$x?
		push ix		;move ix to hl
		pop hl
		add hl,de	; skip text (add length)
		inc hl		; skip null
		push hl		;transfer back to 2
		pop ix 	; ix is always 2 bytes past hl
		jp $lp?
$x?		ld a,b
		pop iy
		pop ix
		pop hl
		pop de
		pop bc
		ret
		