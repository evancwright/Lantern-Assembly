;look.asm

*MOD
look_sub
		push bc
		push de
		push hl
		push ix
		ld de,OBJ_ENTRY_SIZE
		nop ; can the player see?
		call player_has_light
		cp 1
		jp z,$y?
		ld hl,pitchdark
		;call OUTLIN
		;call printcr
		call OUTLINCR
		jp $x?
$y?		call get_player_room ; -> a
		ld d,a  ; stash room in d
		call print_obj_name
		call printcr

		;initial description on room?
		ld b,a		; get initial desc for room
		ld c,INITIAL_DESC_ID
		call get_obj_attr ; -> a
		cp 0ffh ; intial description
		jp z,$lk?
		;print it
		ld b,a ; print_table_entry takes string id in b
		ld ix,string_table
		call print_table_entry
		call printcr
		;clear the initial description
		ld b,d ; room		
		ld c,INITIAL_DESC_ID
		ld a,0ffh
		call set_obj_attr	
		ld a,d ; reset room 
		jp $itm?
$lk?	ld b,d
		call print_obj_desc
$itm?	ld h,a
		nop ; now print all visible objects
 		ld ix,obj_table
$lp?	ld a,(ix);get id
		cp 0		; skip offscreen
		jp z,$c?
		cp 1		; skip player
		jp z,$c?
		cp 0ffh
		jp z,$x?
		bit SCENERY_BIT,(ix+PROPERTY_BYTE_1)
		jp nz,$c?
;		nop ; is this object in this room?
		ld a,(ix+HOLDER) ; get holder byte
		cp b
		jp nz,$c?
		ld a,(ix) ; reload obj id byte
		push bc
		ld b,a ; 
		call z,list_object ; look at id 'b'
		pop bc
$c?		add ix,de ; skip object
		jp $lp?
$x?		pop ix
		pop hl
		pop de
		pop bc
		ret

;prints description of obj in 'b'
print_obj_desc
	push af
	push bc
	push ix
	ld c,DESC_ID
	call get_obj_attr ; res to 'a'
	ld b,a
	ld ix,string_table
	call print_table_entry
	call printcr
	pop ix
	pop bc
	pop af
	ret
		
;called by look_sub		
;prints the initial description for object in b
;if it has one. Otherwise it defaults to "THERE IS A ____ HERE"
;the contents of the object are also printed.
;ix contains addr of object in table
*MOD
list_object
	push af
	push bc
	push de
	push ix
	push iy
	push ix ; put obj addr in iy
	pop iy
	ld d,b ; save obj
	ld c,INITIAL_DESC_ID
	call get_obj_attr 
	cp 0ffh		
	jp z,$n?			
	ld b,a
	ld ix,string_table
	call print_table_entry ; uses b and ix
	call printcr
	jp $x? 
$n?	ld hl,thereisa
	push bc
    call OUTLIN
	pop bc
	ld a,b
	call print_obj_name
	ld hl,here
	call OUTLIN
	call printcr
$x?	ld a,d
    call indent_more
	call print_contents_header ;  of object in 'a'
	
	; call print_contents  ; of object in 'a'
$s?	call indent_less
	pop iy
	pop ix
	pop de
	pop bc
	pop af
	ret
	

		
;player has light	
;player has light result in 'a'
*MOD
player_has_light
		push bc
		push de
		push hl
		push ix
		;is the room emitting light?
		call get_player_room 
		ld b,a
		ld d,a
		ld c,EMITTING_LIGHT
		call get_obj_prop
		cp 1
		jp z,$y?
		ld hl,OBJ_ENTRY_SIZE
		ld ix,obj_table ;loop over every object. if its a child of player
$lp?	ld a,(ix) ;and not inside a closed container return true
		ld e,a ;save obj id
		cp 0ffh	;hit end? jump out
		jp z,$n?
		nop ; is it emitting light?
		ld b,a  ; put obj id in 'b'
		ld c,EMITTING_LIGHT
		call get_obj_prop
		cp 0	
		jp z,$skp?	; if it's not 'lit' we don't care about it
		ld c,d ; player room
		ld b,e ; object id
		;call b_visible_to_c ; is it a in same room as player
		call c_sees_b
		cp 1	
		jp z,$y?	; if it's not 'lit' we don't care about it
$skp?	ld bc,OBJ_ENTRY_SIZE
		add ix,bc ; skip to next object
		jp $lp?	;repeat
$y?		ld a,1
		jp $x?
$n?		ld a,0		
$x?		pop ix
		pop hl
		pop de
		pop bc
		ret

;doesn't look like this was finished?
*MOD
count_visible_objects
		push af
		push ix
		ld a,0
$lp?	cp 0ffh
		jp z,$x?
		jp $lp?
$x?		pop ix
		pop af
		ret

look_at_sub
		push af
		push bc
		push ix
		ld a,(sentence+1)
		ld b,a
		ld c,DESC_ID
		call get_obj_attr
		ld b,a
		ld ix,string_table
		call print_table_entry
		call printcr
		pop ix
		pop bc
		pop af
		ret

		
;is b is an ancestor of c
;and c can 'see' b
;1 or 0 is returned in 'a'
*MOD
b_visible_to_c
c_sees_b
		push bc
		push de
		push ix
		push iy
$lp?	ld a,b
		cp c  ;if two objects are equal, we suceeded.
		jp z,$y? 
		cp 0
		jp z,$n?  ; hit top of table
		;get child's obj entry
		push bc ; save c 'parent'
		ld c,OBJ_ENTRY_SIZE
		call bmulc
		ld ix,obj_table
		add ix,bc
		;get b's parent's obj entry
		ld b,(ix+HOLDER_ID)
		ld c,OBJ_ENTRY_SIZE
		call bmulc
		ld ix,obj_table
		add ix,bc  
		pop bc ; restore c (parent)
		;is parent_a_closed_container?
		bit CONTAINER_BIT,(IX+PROPERTY_BYTE_1) ; supporter?
		jp z,$c?
		bit OPEN_BIT,(IX+PROPERTY_BYTE_1) ; must be a container
		jp z,$n?  ; closed, return 0
$c?		ld b,(ix+OBJ_ID)   ; parent is new child
		jp $lp?
$n?		ld a,0	 ;parent is closed container 	
		jp $x?
$y?		ld a,1
$x?		pop iy
		pop ix
		pop de
		pop bc
		ret		
;iy contains addr of objects
*MOD
print_contents_header
	push af
	push bc
	push de
	push hl
	ld d,a  ; save obj
	
	ld a,0  		;clr vis objs flag
	ld (visobjs),a  
	
	;ld (hl),a
	ld a,d ; restore obj
	call has_contents
	cp 0
	jp z,$x?
	bit CONTAINER_BIT,(iy+PROPERTY_BYTE_1)
	jp z,$s? ; if not check if supporter
	bit OPEN_BIT,(iy+PROPERTY_BYTE_1)
	jp z,$x?
	ld hl,initis
	call OUTLIN
	call printcr
	ld a,d
	call print_contents
	jp $x?
$s?	bit SUPPORTER_BIT,(iy+PROPERTY_BYTE_1)
	jp z,$x?
	ld hl,onitis
	;call OUTLIN
	;call printcr	
	call OUTLINCR
	ld a,d
	call print_contents
	jp $x?
$n? ld a,1
	ld hl,visobjs
	ld (hl),a
$x? pop hl
	pop de
	pop bc
	pop af
	ret


*MOD
look_in_sub
		ld a,(sentence+1)
		ld b,a
		ld c,CONTAINER
		call get_obj_prop
		cp 0
		jp z,$notc?
		ld a,(sentence+1)
		ld b,a
		ld c,OPEN
		call get_obj_prop
		cp 1
		jp nz,$clsd?
		ld a,(sentence+1)
		call has_contents
		cp 0
		jp z,$ncnt?
		ld a,(sentence+1)
		call print_container_contents
		call print_contents
		jp $x?
$ncnt?	ld hl,nothing
		call outlincr
		jp $x?	
$clsd?  ld hl,closed
		call outlincr
		jp $x?
$notc? 	ld hl,cantlook		
		call outlincr
$x?	
		ret

the DB "The ",0h
cantlook DB "You can't see inside that.",0h
nothing DB "You find nothing.",0h		
visobjs DB 0		
thereisa DB  "There is a ",0h
here DB "here.",0h		
	