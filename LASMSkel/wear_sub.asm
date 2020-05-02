;z80 wear function

*MOD
wear_sub
		ld a,(sentence+1)
		ld b,a
		ld c,WORN
		call get_obj_prop
		cp 1
		jp z,$aw?
		ld a,(sentence+1)
		ld b,a
		ld c,WORN
		ld a,1
		call set_obj_prop
		ld hl,youputon
		call outlin
		ld a,(sentence+1)
		call print_obj_name
		ld hl,periodstr
		call outlincr
		jp $x?
$aw?	ld a,(sentence+1)
		ld hl,alreadyworn		
		call outlincr
$x?		ret

;sets beingworn to false if
;holder is not the player
*MOD
unwear_items
	ld hl,obj_table
	ld de,OBJ_ENTRY_SIZE
$lp? ld a,(hl)
	cp 255
	jp z,$x?
	push hl
	pop ix
	
	ld a,(ix+HOLDER_ID) ;not worn by player
	cp PLAYER_ID
	jp z,$c?
	
	bit WORN_BIT,(ix+PROPERTY_BYTE_2)
	;and WORN_MASK
	;cp 0
	jp z,$c?
	ld b,(hl)
	ld a,WORN
	ld c,a
	ld a,0
	call set_obj_prop
$c? add hl,de	
	jp $lp?
$x?	ret
		
youputon DB "You are now wearing the ",0h
alreadyworn DB "You're already wearing that.",0h	