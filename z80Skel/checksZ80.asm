;check rules for z80 shell

ID equ 0
HOLDER equ 1
OBJ_ATTRS_SIZE equ 17
OBJ_SIZE equ 19

;returns 1 or 0 in register a
;not sure we need this check anympre
check_see_dobj
;	push af
;	push bc
;	push hl
;   call get_player_room
;	ld b,a
;	ld a,(sentence+1)
;	ld c,a
;	call b_ancestor_of_c
;	cp 1
;	jp z,$y?;
;	ld hl,nosee
;	call OUTLIN
;	call printcr
;	jp $x?
;$y?	pop hl
;	pop bc
;	pop af
	ret


;returns 1 or 0 in register a
check_see_iobj
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

check_iobj_supplied
	ret


*MOD
check_dobj_portable
	ld a,(sentence+1)
	ld b,a	
	ld c,PORTABLE
	call get_obj_prop
	cp 1
	jp z,$x?
	ld hl,notportable
	call OUTLIN
	call printcr
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
	jp z,$x?
	ld hl,donthave
	call OUTLIN
	call printcr
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
	jp z,$x?
	ld hl,alreadyhave
	call OUTLIN
	call printcr
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
	jp z,$x?
	ld hl,notopenable
	call OUTLIN
	call printcr
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
	jp z,$x?
	ld hl,closed
	call OUTLIN
	call printcr
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
	jp z,$x?
	ld hl,itslocked
	call OUTLIN
	call printcr
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
	jp z,$x?
	ld hl,notlocked
	call OUTLIN
	call printcr
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
		jp z,$x?
		ld hl,alreadyopen
		call OUTLIN
		call printcr
		inc sp
		inc sp
$x?		ret

;checks if the do is a child of the io	
*MOD
check_not_self_or_child

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
	jp z,$n?
	nop ; check contains
	call b_ancestor_of_c
	cp 1
	jp z,$n?; 
	ld a,0
	jp $x?
$n? ld hl,impossible
	call OUTLIN
	call printcr
	ld a,0
$x?	pop bc
	ret

*MOD
check_prep_supplied
	ret

*MOD
check_light
	call player_has_light
	cp 1
	jp $x?
	ld hl,pitchdark
	call OUTLIN
	call printcr
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
		jp nz,$x?
		ld hl,notcontainer
		call OUTLIN
		call printcr
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
		jp nz,$x?
		ld hl,notwearable
		call OUTLIN
		call printcr
		inc sp
		inc sp
$x?		ret

missingnoun	DB "IT LOOKS LIKE YOU'RE MISSING A NOUN.",0h
notlocked DB "YOU DON'T SEE THAT.",0h	
nosee DB "YOU DON'T SEE THAT.",0h
notwearable DB "THAT'S NOT WEARABLE.",0h	
	