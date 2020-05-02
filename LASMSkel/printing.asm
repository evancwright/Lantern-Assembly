;cpc64 print routines
CR equ 13h
CLEAR EQU 8Ah ; clear control code

*MOD 
GETLIN
	readkb
	ret
	
	
*MOD
OUTLIN
		push af
		push bc
		push de
		push hl
		push ix
		push iy
$lp?	ld a,(hl)
		cp 0
		jp z,$x?
		cp 32 ; space
		jp nz,$c?
		call word_len ;len->b
		;is there room left on line
		ld a,(HCUR)
		ld c,a
		ld a,(SCRWIDTH)
		dec a
		sub c ; a has remaining len
		cp b
		jp nc,$sp?
		call printcr
		inc hl  ; skip following space
		jp $lp?
$sp?	ld a,32 ; reload space	
$c?		inc hl
		push hl
		chout
		ld a,(HCUR)
		inc a	; update the cursor position
		ld (HCUR),a
		pop hl
		jp $lp?	
$x?
		pop iy
		pop ix
		pop hl
		pop de
		pop bc
		pop af
		ret
	
;string to print is in hl	
*MOD
OUTLINCR		
		call OUTLIN
		call printcr
		ret

*MOD
printcr
		push af
		newln
		ld a,0
		ld (HCUR),a
		pop af
		ret	
		
CURXSAV DB 0
CURYSAV DB 0
HCUR DB 0	
SCRWIDTH DB 40
SCRHEIGHT DB 20
hundred DB "/100",0h 		
