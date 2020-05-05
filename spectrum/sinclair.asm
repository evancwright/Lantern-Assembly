;sinclair

;BASE equ  3C00H ; address of charset
ATTRS equ 5800H ; 22528 address of attr
ATTRS_PLUS_32 equ 5820H  ; address of attr
ATTRS_PLUS_64 equ 5840H  ; address of attr
REGION1 equ 4000H
REGION1_PLUS_32 equ 4020H
REGION1_PLUS_64 equ 4040H
ROW2 equ 040DCH ; 16384+256  1604
REGION2 equ 04800H  ; 18432
REGION3 equ 05000H ; 20480

ROMCHARS equ 03C00H
S_POS equ 05C88H ; 23688 

;ENTRY :	B=LINE,C=COLUMN 
;PRESERVED : BC,DE 
;EXIT: HL=ADDRESS IN DISPLAY FILE, A=L 

df_loc	ld	a,b 
		and	0f8h 
		add	a,40h 
		ld	h,a 
		ld	a,b 
		and	7 
		rrca 
		rrca 
		rrca 
		add a,c
		ld l,a
		ret
		
;FINDS ATTR FOR A BYTE IN THE DISP FILE
;ENTRY: HL=D.F. ADDRESS 
;PRESERVED: HL,BC 
;EXIT: DE =ATTR. ADDRESS, A=D 
df_att 
		ld	a,h 	
		rrca
		rrca
		rrca
		and 3
		or 58h
		ld	d,a 
		ld	e,l
		ret			
		
;ENTRY: B=LINE, C=COLUMN 
;PRESERVED: BC 
;EXIT: HL=D.F. ADDRESS
; DE=ATTR. ADDRESS
; A=ATTR(B,C) 
;DFCC IS ALTERED stores address to print at in d_file
locate
		ld a,b
		and 18h
		ld h,a
		set 6,h
		rrca
		rrca
		rrca
		or 58h
		ld d,a
		ld a,b
		and 7
		rrca
		rrca
		rrca
		add a,c
		ld l,a
		ld e,a
		ld a,(de)
		ld (DFCC),hl
		ret
		
;clears screen and attrs
;PRESERVED: A ;EXIT: BC-0, DE =5B0ßH, HL=5AFFH
cls1 
		ld hl,04000h
		ld bc,01800h
		ld (hl),l
		ld d,h
		ld e,1
		ldir 
		ld (hl),a
		ld bc,02ffh
		ldir 
		ret		

;A - CHAR		
;prints char in 'a' to 		
*MOD
print1_zx
			push af
			push bc
			push de
			push hl
	
			push af
			call upd_crs
			pop af
			
			ld l,a
			ld h,0
			add hl,hl
			add hl,hl
			add hl,hl
			ld de,(BASE)
			add hl,de
			
			;take D_FILE address
			ld de,(DFCC)
			ld b,8
			
			;print char row by row
$nxtRow?	ld a,(hl)
			ld (de),a
			inc hl
			inc d
			djnz $nxtRow?

			;construct attr address
			ld a,d
			rrca
			rrca
			rrca
			dec a
			and 3
			or 58h
			ld d,a
			ld hl,(ATT)
			;take old attr
			ld a,(de)
			
			;construct new one
			xor l
			and h
			xor l
			
			;replace attr
			ld (de),a
			
			;finally set DFCC to next print pos
			ld hl,DFCC
			inc (hl)
			jp nz,$x?
			inc hl
			ld a,(hl)
			add a,8
			ld (hl),a
			
			;update the cursor pos
$x?		;	call upd_crs
			pop hl
			pop de
			pop bc
			pop af
			ret

;prints str in HL			
;calls print1
*MOD
zx_printstr
		push af
		push bc
		push de
		push hl

		;set the print location based
		;on cursor position
		call repos_cursor

		;set src for char data
		ld hl,3C00h
		ld (BASE),hl
		
		pop hl

		
$lp?	ld a,(hl)
		cp 0
		jp z,$x?
		
		;will the word fit on the line?
		cp 32 ; space?
		jp nz, $go?
		
		call word_len ; word_len -> b
		ld a,(CRSRX)
		add a,b
		cp 31
		jp m,$sp?
		
		;replace the space with a newline
		call zx_newline
		inc hl	; skip space
		jp $lp?
		
		
$sp?	ld a,32 ; reload space

$go?	push hl
		call print1_zx ; 
		pop hl
		inc hl
		jp $lp?
		
$x?		 
		pop de
		pop bc
		pop af
		ret


*MOD
zx_newline
		push hl
		ld a,0			;back to left
		ld (CRSRX),a
		ld a,(CRSRY)	;down (if room)
		cp 23
		jp z,$scl?
		inc a
		ld (CRSRY),a				
		jp $x?
$scl? 	call zx_scroll
$x? 	call repos_cursor
		pop hl
		ret

;scrolls lines up, but leaves the top line
;with the room and the score intact
;notes, screen is in three chunks
;
*MOD
zx_scroll
 		
		call scroll_rgn1

		ld a,8
		ld (SCROLL_LPS),a
		ld de,REGION2
		call scroll_rgn
		
		ld a,8
		ld (SCROLL_LPS),a
		ld de,REGION3
		call scroll_rgn
 
		ld bc,704 ; scroll attrs
		ld hl,ATTRS_PLUS_64
		ld de,ATTRS_PLUS_32
		ldir ; hl->de repeating		
		
		call clr_btm_line

		ret 

*MOD
;de =start addr of bank
;scrolls a region of the screen, up one 
;line of chars
scroll_rgn

		ld (SCROLLTEMP),de
				
		ld a,(SCROLLTEMP) ;don't copy 1st 
		cp 40h			  ;bank down - 1st
		jp z,$cpy?	;starts at 4000h
		  
		;copy eight lines (for 1st row) into
		;the last lines in the previous bank
		;the byte difference will be
		; 2k -(7x32) = 1824 bytes

		ld hl,(SCROLLTEMP)
		ld a,8 ; rows to copy
		
		ld de,1824
		and a ; clr carry
		sbc hl,de
		push hl ; hl->de
		pop de 
		
		ld hl,(SCROLLTEMP) ; src
$lp?	ld bc,32 ; bytes per row
		ldir ; hl->de
		
		;add 224 to de and hl
		;to get to the next line 
		;of pixels to copy
		push hl  ; save hl
		
		ld bc,224
		push de	; de->hl
		pop hl
		add hl,bc  	
		push hl ; hl->de
		pop de
		
		pop hl ; restore hl
		
		add hl,bc
		
		;loop
		dec a
		cp 0
		jp nz,$lp?
				
		;copy 7 rows of 32 chars
$cpy? 	ld a,(SCROLL_LPS)
$lp2?  	
		ld hl,(SCROLLTEMP)
		ld de,(SCROLLTEMP)
		ld bc,32
	    add hl,bc ; copy from 3rd row
		
		push hl ; hl is set up, save it
		
		ld hl,(SCROLLTEMP)
		ld bc,0
		add hl,bc ; ...to 2nd row
		
		push hl ; hl->de
		pop de
		
		pop hl ; restore hl
		
		ld bc,224 ; times to loop
		ldir ; hl->de
		
		;advance scroll temp to next 
		;block of bytes
		ld hl,(SCROLLTEMP)
		ld bc,256
		add hl,bc
		ld (SCROLLTEMP),hl
		
		;loop
		dec a
		cp 0
		jp nz,$lp2?
		
		ret
		
;moves the cursor position 	 
;this should be called by print1

*MOD
upd_crs
	ld a,(CRSRX)
	inc a
	ld (CRSRX),a
	cp 32d
	jp nz,$x?
	
	ld a,(NOSCROLL)
	cp 1
	jp z,$x?
	call zx_newline
	 
$x? ret		
			

;reset the 'print at' position		
repos_cursor
	ld bc,(CRSRY) ; grabs x,y
	ld a,b
	ld b,c
	ld c,a
	call locate		
	ret

*MOD	
clr_btm_line

		ld a,1
		ld (NOSCROLL),a
		
		ld a,0
		ld (CRSRX),a ; col 0
		ld a,23  ; line 23
		ld (CRSRY),a
		call repos_cursor
		
		ld a,32  ; 32 spaces
		
$lp?	push af
		ld a,32  ; ascii space
		call print1_zx
		pop af
		dec a
		cp 0
		jp nz,$lp?
		
		ld a,0
		ld (CRSRX),a
		ld a,23
		ld (CRSRY),a
		call repos_cursor

		ld a,0
		ld (NOSCROLL),a
		
		ret

;This is the 'delete' key function
*MOD		
back_up
	;are we all the way left?
	ld a,(CRSRX)
	cp 1
	jp z,$x?
	
	;back up
	ld a,(CRSRX)
	dec a
	ld (CRSRX),a
	call repos_cursor

	;back up buffer index
	ld a,(BUFIX)
	dec a
	ld (BUFIX),a
	
	;overwrite character
	ld d,0
	ld a,(BufIx)
	ld e,a
	ld hl,InBuf
	add hl,de
	ld a,0
	ld (hl),a
	
	
		
	;print a space
	ld a,32 
	call print1_zx
	
	;back up again
	ld a,(CRSRX)
	dec a
	ld (CRSRX),a
	call repos_cursor
	
$x?	ret
*MOD
scroll_rgn1

		ld a,8

		ld de,REGION1_PLUS_32
		ld hl,REGION1_PLUS_64
$lp?	
		ld bc,192
		ldir ; hl->de repeating
		
		;add 64 to hl and de
		ld bc,64
		add hl,bc
		push hl ; save it
		
		;add 64 to de 
		push de
		pop hl
		add hl,bc
		ex de,hl
		
		pop hl  ; restore it
		
		dec a
		cp 0
		jp nz,$lp?
		ret
		

*MOD

		
ATT DB 38h ; 
MASK DB 0 ; Attribute mask for printing	
DFCC DW 4000 ; DF Address of cell x,y (set by locate sub)
BASE DW 3C00h
CRSRY DB 0
hcur  ; hcur and crsrx are same
CRSRX DB 0
SCROLLTEMP DW 0
NOSCROLL DB 0
SCROLL_LPS DB 7 ; how many rows to move
curstr DB ">"
	DB 0
