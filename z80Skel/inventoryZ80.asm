;inventory_sub
*MOD
inventory_sub
		push af
		ld a,PLAYER_ID
		call has_contents
		cp 1
		jp nz,$n?
		ld hl,carrying
	    call OUTLIN
		call printcr
		nop; recurse through child items
		ld a,PLAYER_ID
		call print_contents
		jp $x?		
$n?		ld hl,noitems
	    call OUTLIN
		call printcr
$x?		pop af
		ret

;prints name of a and it's contents of obj in 'a'
*MOD
print_contents
		push bc
		push de
		push hl
		push ix
		ld b,a	; save parent
		ld de,OBJ_ENTRY_SIZE
		ld ix,obj_table
$lp?	ld a,(ix)
		cp 0ffh
		jp z,$x?
		ld a,(ix+HOLDER_ID)
		cp b
		jp nz,$c?
		bit SCENERY_BIT,(ix+PROPERTY_BYTE_1)  ; test scenery bit
		jp nz,$c?
		ld a,(ix)
		call indent
		call printa
		call print_obj_name
		ld a,(ix) ; reload obj id
		call append_adj  ; tack on providing light, being worn,...
		call printcr
		nop ; need to test container/supporter
		bit CONTAINER_BIT,(ix+PROPERTY_BYTE_1)
		call nz,print_container_contents
		bit SUPPORTER_BIT,(ix+PROPERTY_BYTE_1)
		call nz,print_supporter_contents
$c?		add ix,de
		jp $lp?
$x?		ld b,a	; found flag->a
		pop ix
		pop hl
		pop de
		pop bc		
		ret
		
;if 'a' has any visible items
;1 is returned in 'a' otherwise 0
*MOD
has_contents
		push bc
		push de
		push hl
		push ix
		ld h,a  ; holder to 'h'
		ld b,0	; found flag
		ld de,OBJ_ENTRY_SIZE
		ld ix,obj_table
		
$lp?	ld a,(ix)  ; hit end of table?
		cp 0ffh
		jp z,$x?
		
		ld a,(ix+HOLDER_ID) ; holder matches?
		cp h
		jp nz,$c?
		
		bit SCENERY_BIT,(ix+PROPERTY_BYTE_1)  ; test scenery bit
		jp nz,$c?  ; if bit is not zero, continue
		
		ld b,1	; set found flag
		jp $x?
$c?		add ix,de
		jp $lp?
$x?		ld a,b	; found flag->a
		pop ix
		pop hl
		pop de
		pop bc
		ret
*MOD		
get_sub
		push af
		push bc
		push de
		push hl
		push ix
		push iy
;		ld a,(sentence+1) ; get dobj
;		ld b,a
;		ld c,PORTABLE
;		call get_obj_prop
;		cp 1
;		jp z,$y?
;		ld hl,notportable
;		call OUTLIN
;		call printcr
;		jp $x? 
;$y?		nop ; is it a child of the player already?
;		ld a,(sentence+1)
;		ld c,a
;		ld b,PLAYER_ID
;		call b_ancestor_of_c
;		cp 0
;		jp z,$y1?
;		ld hl,alreadyhave
;		call OUTLIN
;		call printcr
;		jp $x?
$y1?	nop; move to player
		ld a,(sentence+1)  ; get dobj
		ld b,a
		ld c,HOLDER_ID
		ld a,PLAYER_ID
		call set_obj_attr
		nop ; clear initial description
		ld c,INITIAL_DESC_ID
		ld a,255
		call set_obj_attr		
		ld hl,taken
		call OUTLIN
		call printcr
$x?		pop iy
		pop ix
		pop hl
		pop de
		pop bc
		pop af
		ret
		
*MOD
drop_sub
		push af
		push bc
;		nop ; does player have it
;		ld a,(sentence+1)
;		ld c,a
;		ld b,PLAYER_ID
;		call b_ancestor_of_c
;		cp 1
;		jp z,$y?
;		ld hl,donthave
;		call OUTLIN
;		call printcr
;		jp $x?
$y?		ld a,(sentence+1)
		ld b,a
		ld c,HOLDER_ID
		call get_player_room
		call set_obj_attr
		ld a,(sentence+1)
		ld b,a
		ld c,WORN
		ld a,0
		call set_obj_prop
		ld hl,dropped
		call OUTLIN
		call printcr
$x?		pop bc
		pop af
		ret

*MOD		
;print contents of container in 'a'
print_container_contents
		push bc
		push hl
		ld b,a
		call has_contents
		cp 1
		ld a,b
		jp nz,$x?
		ld hl,initis
		call OUTLIN
		call printcr
		call indent_more
		call print_contents
		call indent_less
$x?		pop hl
		pop bc
		ret

*MOD		
;print contents of container in 'a'
print_supporter_contents
		push bc
		push hl
		ld b,a
		call has_contents
		cp 1
		ld a,b
		jp nz,$x?
		ld hl,onitis
		call OUTLIN
		call printcr
		call indent_more
		call print_contents
		call indent_less
$x?		pop hl
		pop bc
		ret

*MOD	
indent
		push af
		push bc
		push de
		ld a,(indentAmt)
		ld b,a
		cp 0
		jp z,$x?
		ld a,32 ; space
$lp?	call CRTBYTE
		djnz $lp?
$x?		pop de
		pop bc
		pop af
		ret

indent_more
		push af
		ld a,(indentAmt)
		inc a
		inc a
		inc a
 		ld (indentAmt),a
		pop af
		ret
		
indent_less
		push af
		ld a,(indentAmt)
		dec a
		dec a
		dec a
		ld (indentAmt),a
		pop af
		ret


printa
		push bc
		push hl
		ld hl,leadinga
		call OUTLIN
		pop hl
		pop bc
		ret

;prints adjectives for object in 'a'
*MOD
append_adj
		push bc
		push ix
		ld b,a
		ld c,OBJ_ENTRY_SIZE
		call bmulc
		ld ix,obj_table
		add ix,bc
		bit LIT_BIT,(ix+PROPERTY_BYTE_2)
		jp z,$lit?
		ld hl,providingLight
		call OUTLIN
		jp $x?
$lit?	bit WORN_BIT,(ix+PROPERTY_BYTE_2)
		jp z,$x?
		ld hl,beingWorn
		call OUTLIN		
$x?		pop ix
		pop bc
		ret

providingLight DB "(PROVIDING LIGHT)",0h
beingWorn DB "(BEING WORN)",0h
		
indentAmt DB 0		
leadinga DB "A ",0h
taken DB "TAKEN.",0h		
dropped DB "DROPPED.",0h
noitems DB "YOU ARE EMPTY HANDED.",0h
carrying DB "YOU ARE CARRYING:",0h
onitis DB "ON IT IS...",0h;
initis DB "IN IT IS...",0h;
notportable DB "YOU CAN'T PICK THAT UP.",0h
alreadyhave DB "YOU ALREADY HAVE THAT.",0h
