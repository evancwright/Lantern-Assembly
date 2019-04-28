;movement.asm
;puts move dir in a

*MOD
move_player
		push bc
		push de
		push ix
		;convert the verb to a direction
		call get_player_room
		ld b,a ; save room
		call get_move_dir
		ld c,a	;direction code
		call get_obj_attr ; dir in 'a'->
		ld d,a  ; save 'door' for later
		cp 128	; ? is it positive or negative
		jp m,$go?
		neg		; flip accumulator (2's complement)
		ld b,a
		ld ix,nogo_table
		call print_table_entry
		call printcr
		jp $x?
$go?	nop ; is 'a' a door?
		ld e,a
		ld b,a
		ld c,DOOR
		call get_obj_prop
		cp 1 
		ld a,e	
		jp nz,$go2?   ; not a door- just go
		nop ; is it closed?
		ld c,OPEN ; b still contains obj id
		call get_obj_prop
		cp 1	 		
		jp nz,$dc?	; not closed
		nop ; load the door's  direction attr into 'a'
		call get_move_dir ; dir in 'a'->
		ld c,a  ; direction
		call get_obj_attr ; dir in 'a'->
		ld b,d   ; door
		call get_obj_attr  ; get dir a leave in 'a'
		jp $go2?
$dc?	ld hl,doorclosed
		call OUTLIN
		call printcr
		jp $x?	
$go2?	ld b,PLAYER_ID		; move player to location
		ld c,HOLDER_ID
		call set_obj_attr	
		call look_sub
$x?		pop ix
		pop de
		pop bc
		ret

*MOD
enter_sub
		push bc
		push hl
		nop ; is the dobj enterable
		ld a,(sentence+1)
		ld b,a
		ld c,ENTER
		call get_obj_attr
		cp 255
		jp nz,$y?
	    ld hl,noenter;
		call OUTLINCR
		jp $x?
$y?	ld b,PLAYER_ID
		ld c,HOLDER_ID
		call set_obj_attr
		call look_sub
$x?		pop hl
		pop bc
		ret
	
;puts move dir (attr) in a 	
*MOD
get_move_dir
		push de
		push ix
		ld ix,direction_map
		ld a,(sentence) ; get verb
		sub n_verb_id
		ld d,0
		ld e,a
		add ix,de
		ld a,(ix)	
		pop ix
		pop de
		ret

;direction table
;maps direction verb id to the attribute numbers
direction_map
	DB 4 ; N
	DB 5 ; SOUTH
	DB 6 ; EAST
	DB 7 ; WEST 
	DB 8 ; NORTHEAST 
	DB 9 ; SOUTHEAST 
	DB 10 ;SOUTHWEST
	DB 11 ;NORTHWEST
	DB 12 ;UP 
	DB 13 ;DOWN 
	DB 14 ;ENTER 
	DB 15 ;OUT 
	DB 0ffh
	
doorclosed DB "The door is closed.",0h	
noenter DB "You can't enter that.",0h