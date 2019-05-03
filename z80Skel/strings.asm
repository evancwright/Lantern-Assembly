;z80 parser

 
;returns len of str in hl in bc
*MOD
strlen
		push af
		push hl
		ld bc,0
$lp?  	ld a,(hl)
		inc bc  ; inc char to copy
		inc hl  ; inc index
		cp 0d  ; hit null?
		jp z,$x?
		jp $lp?
$x?		pop hl
		pop af
		ret
 
;returns len of str in hl in b
;up to a space or null
*MOD
wrdlen
		push af
		push hl
		ld a,0
		ld b,a
$lp?  	ld a,(hl)
		cp 0
		jr z,$x?
		cp 20h
		jr z,$x?
		inc b  ; inc char to copy
		inc hl  ; inc index
 		jr $lp?
$x?		cp a,20h  ; space?
		jr nz,$c?
		inc b   ; add one more to print the space  
$c?		pop hl
		pop af
		ret
 		

;prints the number of chars in b from hl;
;hl is updated		
*MOD
printwrd
		push bc
$lp?	ld a,(hl)
		inc hl
		call CRTBYTE
		ld a,(hcur) ; hcur++
		inc a
		ld (hcur),a
		djnz $lp?
		pop bc
		ret
		
;skipspace
;advances hl until a non-space is hit
*MOD
skipspaces
$lp?	push af
		ld a,(hl)
		cp 20h  ; space
		jp nz,$x?
		inc hl
		djnz $lp?
$x?		pop af
		ret
		

 
;moves the string from hl to de
*MOD
strcpy
	push af
	push bc
	call strlen ; puts len in bc
	ldir		; copy bc chars from hl to de
	pop bc
	pop af
	ret
	
;copies string in ix
;to iy
strcpyi
	push af
	push ix
	push iy
lp? ld a,(ix)
	ld (iy),a
	cp 0		; null?
	jp z,$_x?
	inc ix
	inc iy
	jp z,$_x?
	jp lp?
$_x?	pop iy
	pop ix
	pop af
	ret	

;Performs a case-insensitive compare
;of string in ix and iy 
;returns 1 or 0 in a
*MOD
streq
	push bc
	push ix
	push iy
$lp? ld a,(ix)	; get a byte
	call atoupper
	ld b,a
	inc ix
	ld a,(iy) ; compare it
	call atoupper
	inc iy
	cp b
 	jp nz,$n?
	cp 0; they were equal. hit end$
	jp z,$y?
	jp $lp? ; repeat	
$y?  ld a,1
    jp $x?	
$n?	ld a,0
$x?	pop iy
	pop ix
	pop bc
	ret 

	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;
;Converts a to upper case
;;;;;;;;;;;;;;;;;;;;;;;;;;
*MOD
atoupper
	cp 97
	jp m,$x?
	cp 122
	jp p,$x?
	sub 32
$x?	ret

;returns the length of the word indexed 
;by hl in register b
;other registers are preserved.
;assumes (hl) points to a space
*MOD
word_len
	push af
	push hl
	
	inc hl	
	ld b,1
$lp?
	ld a,(hl)
	
    cp 0  ; null
	jp z,$x?

    cp 32  ; space
	jp z,$x?	 

	inc b
	inc hl
	jp $lp?

$x?	pop hl
	pop af
	ret
