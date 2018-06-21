;printing.asm
;print routines for ZX spectrum
;(c) Evan Wright, 2017

SCREEN equ 16384 ; 4000 hex
SCRSIZE equ 702 ; 32*22 line
SCRCOLOR equ 23693

;output a char
CRTBYTE
		call print1_zx
		ret
 
*MOD 
;prints string in HL 
OUTLIN
		push af
		call zx_printstr
		pop af
		ret

;prints a space (registers are preserved)
printcr
	push af
	push bc
	push de
	push iy
	;ld a,0dh ; carriage return
	;call CRTBYTE
	call zx_newline
	call repos_cursor
	pop iy
	pop de
	pop bc
	pop af
	ret	

;*MOD
;CLS
;		call 3503
;		
;		;move cursor to top
;$x?		ld a,0
;		ld	(xcoord),a
;		ld  (ycoord),a
;		ret

;draws the bar at the top with the room and the score
*MOD
draw_top_bar
		push af
		push de
		
		;save crsr x and y
		ld de,(CRSRY)
		push de

		ld bc,0
		ld(CRSRY),bc
		call repos_cursor
		
		;draw 32 inverse spaces
		
		ld a,31
$lp?	push af
		ld a,0 ; BLACK SQUARE
		call print1_zx
		pop af
		dec a
		cp 0
		jp nz,$lp?
		
		;draw room name
		ld b,2
		ld c,0
		ld (CRSRY),bc
		call repos_cursor
		call get_player_room
		call print_obj_name
		
		;draw score
		ld b,26
		ld c,0
		ld (CRSRY),bc
		call repos_cursor
		ld hl,hundred
		call zx_printstr
		
		call print_score ; print actual number
		
		;restore cursor
		pop de
		ld (CRSRY),de
		call repos_cursor
		
		pop de
		pop af
		
		ret
		
;prints the number to the top bar
*MOD
print_score
		push af
		push bc
		push de
		
		;
		ld b,25
		ld c,0
		ld (CRSRY),bc
		call repos_cursor
		
		ld a,(SCORE)
		ld d,a

$lp?	ld a,d
		ld b,10
		call mod ; a mod b
		ld c,a ;save char
		
		ld a,d
		ld b,10
		call div ; a div b
		ld d,a ; save temp score		

		cp 0
		jp z,$x?
		
		ld a,c
		add a,48 ; to ascii
		call print1_zx	
		call backup_2

		jp $lp?
	
$x?	
		ld a,c
		add a,48 ; to ascii
		call print1_zx	
		call backup_2

		pop de
		pop bc
		pop af
		ret

;backs the cursor up 2
;use to print the score
backup_2
	push af
	push bc
	push de
	and a ; clr flag
	ld a,(CRSRX)
	sbc a,2
	ld (CRSRX),a
	call repos_cursor
	pop de
	pop bc
	pop af
	ret
	
hundred DB "/100",0h 	 
;cursorPos DW SCREEN		
;xcoord defb 0
;ycoord defb 15
 