
;assumes check_dobj_opnable has been called.
*MOD
open_sub
	push af
	push bc
	push de
	push ix
	ld a,(sentence+1)
	ld b,a ; obj byte
	ld c,OPEN ; property byte
	ld a,1
	call set_obj_prop
 	ld hl,done
	call OUTLINCR
	call reveal_items
	pop ix
	pop de
	pop bc
	pop af
	ret


; machine generate Z80 routine from XML file
*MOD
close_sub
	push af
	push bc
	push de
	push ix
	ld a,(sentence+1)
	ld b,a
	ld c, 19
	call bmulc
	ld ix,obj_table
	add ix,bc ; jump to object
	ld bc,PROPERTY_BYTE_1 ; get prop byte
	add ix,bc ; jump to the object's byte we need
 	bit OPENABLE_BIT,(ix) ; test openable prop bit
	jp z,$a?
	bit OPEN_BIT,(ix) ; test open prop bit
	jp z,$b?
	res OPEN_BIT,(ix)
	;ld a,OPEN_BIT
	;cpl 
	;and (ix) ; and (ix) into acc
	;ld (ix),a
	ld hl,done
	call OUTLINCR	
	jp $d? ; skip else 
$d?	nop ; end else
	jp $e? ; skip else 
$b?	nop ; close ($dobj.open == 0)
	nop ; {  println("IT'S ALREADY CLOSED.")
	ld hl,alreadyclosed
	call OUTLINCR
$e?	nop ; end else
	jp $f? ; skip else 
$a?	nop ; close ($dobj.openable==1)
	nop ; println("THAT'S NOT CLOSEABLE.")
	ld hl,notcloseable
	call OUTLINCR
$f?	nop ; end else
	pop ix
	pop de
	pop bc
	pop af
	ret

*MOD
lock_sub
		push af
		push bc
		push de
		push ix
		ld a,(sentence+1)
		ld b,a
		ld c, 19
		call bmulc
		ld ix,obj_table
		add ix,bc ; jump to object	
		ld bc,PROPERTY_BYTE_2 ; get prop byte
		add ix,bc ; jump to the object's byte we need
		bit LOCKABLE_BIT,(ix) ; test openable prop bit
		jp z,$nl?
		bit LOCKED_BIT,(ix) ; test open prop bit
		jp z,$al?
		set LOCKED_BIT,(ix)
		ld hl,done
		call OUTLINCR
$nl?	ld hl,notlockable
		call OUTLINCR
		jp $x?	
$al?	ld hl,alreadylocked
		call OUTLINCR
$x?		pop ix
		pop de
		pop bc
		pop af
		ret	

*MOD	
reveal_items
	ld a,(sentence+1) 
	call has_contents ; result to a->
	cp 0
	jp z,$x?	
	ld hl,openingThe
	call OUTLIN	
	ld a,(sentence+1) 
	call print_obj_name
	ld hl,reveals
	call OUTLINCR
	ld a,(sentence+1) 
	call print_contents
$x?	ret
		
*MOD		
unlock_sub
	nop ; TBD
	ret

notlockable DB "That's not lockable.",0h	
alreadylocked DB "It's already locked.",0h
openingThe DB "Opening the ", 0h
reveals DB "reveals:", 0h
;alreadyopen DB "IT'S ALREADY OPEN.",0h
