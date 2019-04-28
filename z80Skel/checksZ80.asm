;check rules for z80 shell
;If a check fails, the check function unwinds the stack
;so the caller doesn't need to check the return status

ID equ 0
HOLDER equ 1
OBJ_ATTRS_SIZE equ 17
OBJ_SIZE equ 19

;returns 1 or 0 in register a
;not sure we need this check anympre
*MOD
check_see_dobj
    call get_player_room
	ld b,a
	ld a,(sentence+1)
	ld c,a
	call b_ancestor_of_c
	cp 1
	jp z,$y?;
	ld hl,nosee
	call OUTLINCR
	inc sp
	inc sp
$y?	ret


;if the prep is in,
;the iobj must be an open container
;if the prep is on,
;the obj must be a supporter
;capacity is not checked, but should be!
*MOD
check_put
		push ix
		ld ix,obj_table
		ld de,PROPERTY_BYTE_1
		ld a,(sentence+3)
		ld b,a
		ld c,OBJ_ENTRY_SIZE
		call bmulc
		add ix,bc
		add ix,de  ; ix now has container supporter byte
		ld a,(sentence+2)
		cp 0  ; 0=in
		jp z,$pi?
		cp 6  ; 6=on
		jp z,$po?
		jp $y? ; not in or on - must be ok
$pi?	nop ; is do a container?		
		bit CONTAINER_BIT,(ix)
		jp z,$nc?
		nop ; ? is it closed
		bit OPEN_BIT,(ix)
		jp z,$clsd?
		jp $y?
$po?	nop ; is do a supporter?
		bit SUPPORTER_BIT,(ix)
		jp z,$ns?
		jp $y?
$clsd?  ld hl,closed
		call OUTLINCR
		jp $n?
$nc?	ld hl,notcontainer
		call OUTLINCR	
		jp $n?
$np?    ld hl,impossible
		call OUTLINCR		
		jp $n?		
$ns?	ld hl,notsupporter
		call OUTLINCR
$n?		inc sp ; unwind stack
		inc sp
$y?		pop ix
		ret

;returns 1 or 0 in register a
*MOD
check_see_iobj
    call get_player_room
	ld b,a
	ld a,(sentence+3)
	ld c,a
	call b_ancestor_of_c
	cp 1
	jr z,$y? 
	ld hl,nosee
	call OUTLINCR
	inc sp
	inc sp
$y?	
	ret

*MOD
check_dobj_supplied
	ld a,(sentence+1)
	cp 255
	jp nz,$x?
	ld hl,missingnoun
	call OUTLINCR
	inc sp
	inc sp
$x?	ret

*MOD
check_iobj_supplied
		ld a,(sentence+3)
		cp 255
		jp nz,$x?
		ld hl,missingnoun
		call OUTLINCR
		inc sp
		inc sp
$x?		ret


*MOD
check_dobj_portable
	ld a,(sentence+1)
	ld b,a	
	ld c,PORTABLE
	call get_obj_prop
	cp 1
	jr z,$x?
	ld hl,notportable
	call OUTLINCR
	inc sp
	inc sp
$x?	ret
	
*MOD
check_have_dobj 
	ld b,PLAYER_ID
	ld a,(sentence+1)
	ld c,a
	call b_ancestor_of_c
	cp 1
	jr z,$x?
	ld hl,donthave
	call OUTLINCR
	inc sp
	inc sp
$x?	ret

*MOD
check_dont_have_dobj 
	ld b,PLAYER_ID
	ld a,(sentence+1)
	ld c,a
	call b_ancestor_of_c
	cp 0
	jr z,$x?
	ld hl,alreadyhave
	call OUTLINCR
	inc sp
	inc sp
$x?	ret

*MOD	
check_dobj_opnable
	ld a,(sentence+1)
	ld b,a	
	ld c,OPENABLE
	call get_obj_prop
	cp 1
	jr z,$x?
	ld hl,notopenable
	call OUTLINCR
	inc sp
	inc sp
$x?	ret

*MOD	
check_dobj_open
	ld a,(sentence+1)
	ld b,a	
	ld c,OPEN
	call get_obj_prop
	cp 1
	jr z,$x?
	ld hl,closed
	call OUTLINCR
	inc sp
	inc sp
$x?	ret


*MOD
check_dobj_unlocked
	ld a,(sentence+1)
	ld b,a	
	ld c,LOCKED
	call get_obj_prop
	cp 0
	jr z,$x?
	ld hl,itslocked
	call OUTLINCR
	inc sp
	inc sp
$x?	ret

*MOD
check_dobj_locked
	ld a,(sentence+1)
	ld b,a	
	ld c,LOCKED
	call get_obj_prop
	cp 1
	jr z,$x?
	ld hl,notlocked
	call OUTLINCR
	inc sp
	inc sp
$x?	ret

*MOD
check_dobj_closed
		ld a,(sentence+1)
		ld b,a	
		ld c,OPEN
		call get_obj_prop
		cp 0
		jr z,$x?
		ld hl,alreadyopen
		call OUTLINCR
		inc sp
		inc sp
$x?		ret

;checks if the do is a child of the io	
*MOD
check_not_self_or_child
	call check_nested_containership
	cp 1
	jr z,$x?
	ld hl,badput
	call OUTLINCR
	inc sp;
	inc sp;
$x?	ret

;checks if the do is a child of the io	
;returns 1 or 0 in 'a'
;1 means the containership is invalid
*MOD
check_nested_containership
	push bc
	nop ; check self
	ld a,(sentence+1)
	ld b,a
	ld a,(sentence+3)
	cp b
	jr z,$n?
	nop ; check contains
	call b_ancestor_of_c
	cp 1
	jr z,$n?; 
	ld a,1
	jr $x?
$n? ld a,0
$x?	pop bc
	ret

*MOD
check_prep_supplied
	ld a,(sentence+1)
	cp INVALID
	jr nz,$x?
	ld hl,missingprep
	call OUTLINCR 
	inc sp
	inc sp
$x?	ret

*MOD
check_light
	call player_has_light
	cp 1
	jr $x?
	ld hl,pitchdark
	call OUTLINCR
	inc sp
	inc sp
$x?	ret
	

*MOD
check_iobj_container
		ld a,(sentence+3)
		ld b,a	
		ld c,PROPERTY_BYTE_1
		call get_obj_attr
		and CONTAINER_MASK + SUPPORTER_MASK
		jr nz,$x?
		ld hl,notcontainer
		call OUTLINCR
		inc sp
		inc sp
$x?		ret

*MOD
check_dobj_wearable
		ld a,(sentence+1)
		ld b,a	
		ld c,PROPERTY_BYTE_2
		call get_obj_attr
		and WEARABLE_MASK
		cp 0
		jr nz,$x?
		ld hl,notwearable
		call OUTLINCR
		inc sp
		inc sp
$x?		ret

;see if the weight of the dobj + inv weight is greater than player's capacity
*MOD
check_weight
		ld a,(DobjId)
		call get_inv_weight ; result -> a
		ld d,a  ; save in d
		ld a,PLAYER_ID
		call get_inv_weight ; result -> a 
		add a,d
		cp MAX_INV_WEIGHT
		jr z,$x?
		jr c,$x?
		ld hl,tooheavystr
		call OUTLINCR
		inc sp
		inc sp
$x?		ret


missingnoun	DB "Missing noun.",0h
missingprep	DB "Missing preposition.",0h
notlocked DB "It's not locked.",0h	
nosee DB "You don't see that.",0h
notwearable DB "That's not wearable.",0h	
badput DB "That would violate the laws of physics.",0h	
impossible DB "That's impossible.",0h	
closed DB "It's closed.",0h	
notcontainer DB "You can't put things in that.",0h
notsupporter DB "You find no suitable surface.",0h
tooheavystr DB "Your load is too heavy.",0h