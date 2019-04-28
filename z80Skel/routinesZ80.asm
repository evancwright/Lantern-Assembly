;z80 routines

;returns property c of object b in register a
*MOD
get_obj_attr
		push bc
		push de
		push hl
		push ix
		ld h,c	; save attr in h
		ld c,OBJ_ENTRY_SIZE
		call bmulc
		push bc	; bc->de
		pop de
		ld ix,obj_table
		add ix,de	 ; add attr offset to ix
		ld d,0		 ; create the attr offset
		ld e,h	
		add ix,de	 ; add attr offset to ix
		ld a,(ix)    ; finally get the byte
		pop ix
		pop hl
		pop de
		pop bc
		ret

*MOD
;set property c of object b to register a
set_obj_attr
		push bc
		push de
		push hl
		push ix
		ld h,c
		ld c,OBJ_ENTRY_SIZE
		call bmulc
		push bc
		pop de
		ld ix,obj_table
		add ix,de	 ; add table offset to ix
		ld d,0
		ld e,h
		add ix,de	 ; move to byte
		ld (ix),a    ; finally get the byte
		pop ix
		pop hl
		pop de
		pop bc
		ret		
		
;returns property c of object b in register a
;the property should be 0-15 inclusive
*MOD
get_obj_prop
		push bc
		push de
		ld d,PROPERTY_BYTE_1
		ld a,c ; get the correct byte
		ld e,c ; save the prop to get (we need it later) 
		cp 8
		jp z,$s?
		jp c,$s? ; jump on <=
		inc d	; property is in the next byte
$s?		ld c,d  ; move byte to get to c
		call get_obj_attr ; put attr byte 'c' in 'a'
	    ld b,e	; put prop to test in 'b'
		call make_prop_mask ; puts mask from pop 'b' in 'b'
		and b ; test the bit in the mask (and leave result in 'a')
		cp 0		;it it's a zero, leave it
		jp z,$x?
		ld a,1		;conver non zero value to 1
$x?		pop de
		pop bc
		ret


;sets property c of object b to val in register 'a'
;the property should be 0-15 inclusive
*MOD
set_obj_prop
		push bc
		push de
		push hl
		ld (propVal),a
		ld e,c ; save prop #
		ld c,OBJ_ENTRY_SIZE
		call bmulc  ; calc offset 
		ld hl,obj_table
		add hl,bc
		ld bc,PROPERTY_BYTE_1
		add hl,bc ; get offset of prop byte 1
		ld a,e ; check prop #
		cp 8
		jp z,$s?
		jp c,$s? ;jump on minus
		inc hl	; property is in the next byte
$s?		
		ld b,e
		call make_prop_mask ; puts mask from pop 'b' in 'b'
		ld a,(propVal)
		cp 0
		jp z,$clr?
		ld a,(hl) ; get the byte 
		or b ; test the bit in the mask (and leave result in 'a')
		jp $sav?
$clr?   ld a,b
		cpl	; flip mask
		ld b,(hl)
		and b
$sav?	ld (hl),a
$x?		pop hl
		pop de
		pop bc
		ret

clr_obj_prop
		call make_prop_mask ; puts mask from pop 'b' in 'b'
		ld (hl),a
		ret
		
;looks up the mask for the property number in b
;mask is returned in 'b'
;c is not changed
make_prop_mask
	push de
	push hl
	push iy
	ld iy,mask_table 
	ld d,0	
	ld e,b
	add iy,de
	dec iy 
	ld b,(iy)	; load mask from table
	pop iy
	pop hl
	pop de
	ret

;player room in 'a'
get_player_room
		push bc
		ld b,PLAYER_ID	
		ld c,HOLDER_ID
		call get_obj_attr
		ld (player_room),a
		pop bc
		ret

inside_closed_container
		ret
		
;put 1 or 0 in a if b is an ancestor of c		
*MOD
b_ancestor_of_c
		push bc
		push de
		ld d,b ; save parent
		ld b,c ; child object
		ld c,HOLDER_ID
$lp?	call get_obj_attr ; puts holder in a
		cp d	 	; ancestor found
		jp z,$y?
		cp 0		; hit top level - ancestor not found
		jp z,$n?
		ld b,a		; is b's parent (reg a) a descendant of c
		jp $lp?
$n?		ld a,0
		jp $x?
$y?		ld a,1
$x?		pop de
		pop bc
		ret


;multiple b x c and puts result in bc
;registers are preserved
*MOD
bmulc 
		push af
		push de
		push ix
		ld d,0 ; add c to b times
		ld e,c
		ld a,b ; use  b and loop counter
		ld ix,0
$lp?	cp 0
		jp z,$x?
		add ix,de
		dec a
		jp $lp?
$x?		push ix ; ld bc,ix
		pop bc
		pop ix
		pop de
		pop af
		ret
	
;table of mask bytes for looking up
;properties of objects		
mask_table
	DB SCENERY_MASK ;equ 1 
	DB SUPPORTER_MASK ;equ 2
	DB CONTAINER_MASK ;equ 4
	DB TRANSPARENT_MASK ;equ 8
	DB OPENABLE_MASK ;equ 16
	DB OPEN_MASK ;equ 32
	DB LOCKABLE_MASK ;equ 64
	DB LOCKED_MASK ;equ 128
	DB PORTABLE_MASK ;equ 1
	DB USER3_MASK ;equ 2
	DB WEARABLE_MASK ;equ 4
	DB BEING_WORN_MASK ;equ 8
	DB USER1_MASK ;equ 16
	DB LIT_MASK ;equ 32	
	DB DOOR_MASK ;equ 64
	DB USER2_MASK ;equ 128

propVal DB 0	
player_room DB 0
