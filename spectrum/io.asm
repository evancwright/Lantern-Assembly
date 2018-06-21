BUFSIZE EQU 48
DELETE EQU 12 
PROMPT EQU 62
CURMODE EQU 23761 ; K,

*MOD
getlin
		;clear buffer
		call clrbuf
		
		;output the prompt
		ld hl,curstr
		call zx_printstr
		;ld a,PROMPT
		;rst 16
		
		;loop until enter key is pressed
$lp2?	call readkb
		
		;convert to ASCII
		call zx_to_ascii
		
		cp 0Ch ; delete?
		jp nz,$s?
		call back_up
		jp $lp2?
		
$s?		cp 13	; newline 
		jp z,$out?

		;echo the char
	
		push af
		call print1_zx
		pop af
		
 
		;store the char in the input buffer
		push af
		ld hl,INBUF  ;add buffIx to start of buffer
		ld d,0
		ld a,(bufIx)
		ld e,a
		add hl,de
		pop af
		
		ld (hl),a ; now store the char
		
		;increment the buffer index
		ld a,(bufIx) 
		inc a
		ld (bufIx),a
				
		jp $lp2?
		
$out?	;ld a,13 ; echo a newline
		;rst 16
		call zx_newline
$x?		ret


;prints the string in (hl) followed
;by a newline		
*MOD
OUTLINCR
		push af
		push bc
		push de
		push hl
		push ix
		push iy
		call OUTLIN ; print (hl)
		call zx_newline  ; move cursor
		;ld	a,13  ; new line char
 		;ei
		;rst 16  ; print char
		;di
		;call newline
		pop iy
		pop ix
		pop hl
		pop de
		pop bc
		pop af
		ret

		
		
*MOD
clrbuf

		
		;set index to 0
		ld a,0
		ld (bufIx),a
		
		;clear buffer
 
		ld b,0
		ld hl,INBUF
		
$lp?	ld (hl),b
		inc hl
		dec a
		cp 0
		jp nz,$lp?
		 	
		ret

		
;converts the character in 'a' to 
;an uppercase ascii char.		
*MOD
zx_to_ascii
		cp 97  ; bail if < lowercase a
		jp c,$x?	
		cp 122 ; if greater than lowercase z, detokenize?
		jp nc,$sc?
		sub 32		;make it uppercase	
		jp $x?

$sc?		
		sub 165 ; convert to ascii
$x?		
		ret


	  DB 0  ; padding - do not remove
bufIx DB 0
INBUF DS 256		
;INBUF DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

	