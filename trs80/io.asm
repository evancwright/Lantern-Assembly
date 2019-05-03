BUFSIZE EQU 48
KEYIN EQU 40H
SCR_WIDTH EQU 63
*MOD
getlin
		push bc
		push de
		push hl
;		call clrbuf
		ld hl,INBUF
		ld b,BUFSIZE
		call KEYIN ; returns len in 'b'
		ld c,b
		ld b,0
		add hl,bc
		ld (hl),0  ; delete cr
		pop hl
		pop de
		pop bc
		call printcr
		ret


;hl = str
OUTLIN
		push af
		push bc
		push de
		push hl
$lp?	ld a,(hl)
		cp 0
		jr z,$x?
		call wrdlen ;len->b
		;is there room left on line
		ld a,(hcur)
		ld c,a
		ld a,SCR_WIDTH
		sub c ; a = SCR_WIDTH - hcur a has remaining len
		cp b  ; chars left >= wrd_len ?
		jr nc,$c?
		call printcr
		call skipspaces			
		jr $lp?
$c?		call printwrd  ; b is still valid
		jp $lp?	
$x?		pop hl
		pop de
		pop bc
		pop af
		ret
		
*MOD
OUTLINCR
		push af
		push bc
		push de
		push hl
		push ix
		push iy
$lp?	ld a,(hl)
		cp 0
		jp z,$x?
		inc hl
		call CRTBYTE
		jp $lp?	
$x?		call printcr
		pop iy
		pop ix
		pop hl
		pop de
		pop bc
		pop af
		ret

		
		
*MOD
clrbuf
		LD A,255
		LD (HL),A
		LD HL,INBUF
$lp?	ld (hl),b
		inc hl
		dec a
		cp 0
		jp nz,$lp?
		LDIR	
		ret


;prints a space (registers are preserved)
printcr
	push af
	push bc
	push de
	push iy
	ld a,0dh ; carriage return
	call CRTBYTE
	ld a,0
	ld (hcur),a
	pop iy
	pop de
	pop bc
	pop af
	ret

hcur dw 0
spacestr DB " ",0	