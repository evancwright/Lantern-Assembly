;put.asm

*MOD
put_sub
		push bc
		push de
		push hl
		push ix
		ld a,(sentence+3)
		cp 0ffh  ; io supplied
		jp z,$bp?
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
		jp $bp?
$pi?	nop ; is do a container?		
		bit CONTAINER_BIT,(ix)
		jp z,$nc?
		nop ; ? is it closed
		bit OPEN_BIT,(ix)
		jp z,$clsd?
		jp $mv?
$po?	nop ; is do a supporter?
		bit SUPPORTER_BIT,(ix)
		jp z,$ns?
		jp $mv?
		nop ; check nested containership
		call check_nested_containership
		cp 1  ; 1 = invalid (message was printed)
		jp z,$x?
$mv?    ld a,(sentence+1)
		ld b,a
		ld c,HOLDER
		ld a,(sentence+3)
		call set_obj_attr
		ld hl,done
		call OUTLIN
		call printcr
		jp  $x?
$clsd?  ld hl,closed
		call OUTLIN
		call printcr
		jp $x?
$bp?	ld hl,badput
		call OUTLIN
		call printcr
		jp $x?
$nc?	ld hl,notcontainer
		call OUTLIN
		call printcr		
		jp $x?
$np?    ld hl,impossible
		call OUTLIN
		call printcr		
		jp $x?;		
$ns?	ld hl,notsupporter
		call OUTLIN
		call printcr		
$x?		pop ix
		pop hl
		pop de
		pop bc
		ret

closed DB "IT IS CLOSED.",0h	
badput DB "TRY: PUT SOMETHING IN/ON SOMETHING ELSE.",0h	
notcontainer DB "YOU CAN'T PUT THINGS IN THAT.",0h
notsupporter DB "YOU FIND NO SUITABLE SURFACE.",0h
impossible DB "THAT'S NOT PHYSICALLY POSSIBLE.",0h