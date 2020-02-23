;cpc64 print routines
CR equ 13h
CLEAR EQU 8Ah ; clear control code


printcr	
	push af
	push bc
	push de
	push hl
	push ix
	push iy
	ld	a,0Ah 	;line feed
	call CHAROUT
	ld	a,0Dh 	;carriage return
	call CHAROUT	
;	call 47962
	pop iy
	pop ix
	pop hl
	pop de
	pop bc
	pop af
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
		cp 32 ; space;
		jp nz,$c?
		call word_len ;len->b
		;is there room left on line
		ld a,(HCUR)
		ld c,a
		ld a,39
		sub c ; a has remaining len
		cp b
		jp p,$sp?
		call printcr
		inc hl
		jp $lp?
$sp?	ld a,32 ; reload space	
$c?		inc hl
		push hl
		call CHAROUT
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
		
;draws the bar at the top with the room and the score
*MOD
draw_top_bar
		push af
		push de
		push hl
		
		;save crsr x and y
		call TXT_GET_CUR
		push hl ;save cursor
		
		;go to top left
		ld h,1
		ld l,1
		call TXT_SET_CUR
		call TXT_CUR_DISABLE
		call TXT_INVERSE
		
		;draw 3 squars
		ld a,3
$lp?	push af
		ld a,32 ; BLACK SQUARE
		call CHAROUT
		pop af
		dec a
		cp 0
		jp nz,$lp?

		;draw room name

		call get_player_room
		call print_obj_name
		
		;draw 40 inverse spaces
		
		;draw spaces to col 30
$lp2?	ld a,32 ; BLACK SQUARE
		call CHAROUT
		ld a,(HCUR)
		cp 30
		jp nz,$lp2?
				
		;draw score		
		ld hl,hundred
		call OUTLIN
		
		call print_score ; print actual number
		
		;draw remaining blanks
		ld a,35
		call TXT_SET_COL
$lp3?	ld a,32 ; BLACK SQUARE
		call CHAROUT
		ld a,(HCUR)
		cp 40
		jp nz,$lp3?
 
		;restore cursor
		pop hl
		call TXT_SET_CUR

		call TXT_INVERSE		
		call TXT_CUR_ENABLE
		pop hl
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
		ld a,30
		call TXT_SET_COL
		
		ld a,(SCORE)
		ld d,a

$lp?	ld a,d
		ld b,10
		call modulus ; a mod b
		ld c,a ;save char
		
		ld a,d
		ld b,10
		call div ; a div b
		ld d,a ; save temp score		

		cp 0
		jp z,$x?
		
		ld a,c
		add a,48 ; to ascii
		call CHAROUT
		call backup_2

		jp $lp?
	
$x?	
		ld a,c
		add a,48 ; to ascii
		call CHAROUT
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
	push hl
	call TXT_GET_CUR
	ld a,h
	sub a,2
	call TXT_SET_COL
	pop hl
 	pop de
	pop bc
	pop af
	ret

CURXSAV DB 0
CURYSAV DB 0
	
hundred DB "/100",0h 		
