;put.asm
;this needs to be redone! (put in vs. put on)
;before this runs the following checks have passed
;iobject supplied
;iobject container
;not self or child
*MOD
put_sub
		push bc
		push de
		push hl
		push ix
		ld a,(sentence+1)
		ld b,a
		ld c,HOLDER
		ld a,(sentence+3)
		call set_obj_attr
		ld hl,done
		call OUTLIN  ; move this to an default 'after' sentence
		call printcr
		pop ix
		pop hl
		pop de
		pop bc
		ret

