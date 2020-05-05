;cpc464Input
BS equ 7Fh
;read a line of text into the input buffer
*MOD
getlin
		call TXT_CUR_ENABLE
		call TXT_PLACE_CUR
		ld hl,inbuf
$lp?  	call WAIT_CHAR
		jp nc,$lp?	;no char ready
		call atoupper
		ld (hl),a
		cp 0Dh ; CR
		jp z,$out?
		cp BS ; BS
		jp z,$bs?
		push hl
		call CHAROUT
		pop hl
		inc hl
		call TXT_PLACE_CUR
		jp $lp? ;get next char
$bs?	;are we at the start?
		ld a,(HCUR)
		cp 0
		jp z,$lp?
		ld a,0		;clear buffer
		dec hl
		ld (hl),a	
		ld a,32d  ;output a space
		call CHAROUT 
		ld a,08h		;backup twice
		call CHAROUT
		ld a,08h		;backup twice
		call CHAROUT
		ld a,32d  ;output a space
		call CHAROUT 
		ld a,08h
		call CHAROUT
		call TXT_PLACE_CUR
		jp $lp? ;get next char
$out? 	call TXT_HIDE_CUR
		call printcr
		ld a,0
		ld (hl),a
		;call TXT_UNDRAW_CUR
		call TXT_HIDE_CUR
		ld a,32
		call CHAROUT
		call TXT_CUR_DISABLE
		
		;call TXT_UNDRAW_CUR
		ret
		
;puts cursor back on bottom line		
*MOD
fix_cursor
	ld a,(VCUR)
	cp 25
	jp m,$x?
	ld h,25
	ld l,1
	call TXT_SET_CUR
$x?	ret

	
inbuf DS 256
