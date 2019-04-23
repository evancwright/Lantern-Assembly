;cpm.asm
BDOS EQU 5
RCONF EQU 1
A_READ EQU 3
C_STAT EQU 11
C_RAWIO EQU 6
WCONF EQU 2  ; "write to console function"
C_READSTR EQU 0Ah
ESC EQU 1Bh
CR EQU 0Dh
LF EQU 0Ah

*MOD
CLS
	push hl
	ld hl,cpmcls
	call OUTLIN
	pop hl
	ret
;assumes string is loaded into hl
*MOD
OUTLIN
	push af
	push bc
	push de
	push hl
$lp? ld a,(hl)
	cp 0
	jp z,$x?
	ld e,a
	ld c,WCONF
	push hl
	call BDOS
	pop hl
	inc hl
	jp $lp?
$x?	pop hl	
	pop de
	pop bc
	pop af
	ret

; hl contains string
*MOD
OUTLINCR
	push af
	push bc
	push de
	push hl
	call OUTLIN
	call PRINTCR
	pop hl
	pop de
	pop bc
	pop af
	ret

CRTBYTE
	push bc
	push de
	ld e,a
	ld c,WCONF
	call BDOS
	pop de
	pop bc
	ret
	
PRINTCR
	push af
	push bc
	push de
	ld e,CR
	ld c,WCONF
	call BDOS
	ld e,LF
	ld c,WCONF
	call BDOS
	pop de
	pop bc
	pop af
	ret

*MOD
get_char
	;loop until char is ready
$lp? 
;	 ld a,(randlo)
;	 inc a
;	 ld (randlo),a
	 
	 ld c,C_RAWIO
	 ld e,0FFh;
	 call BDOS
	 cp 0
	 jp z,$lp?	 
	 ret
	
*MOD	
getlin
	;clear the buffer
	ld a,0
	ld b,40
	ld hl,INBUF
$lp?
	ld (hl),a
	inc hl
	djnz $lp? 
	ld de,inrec
	ld c,C_READSTR
	call BDOS
	call PRINTCR
	call PRINTCR
	ret


;char in e	
*MOD
print_char
	push af
	push bc
	push de
	push hl
	ld c,WCONF
	call BDOS	
	pop hl
	pop de
	pop bc
	pop af
	ret

showcrsr DB ESC,'[?25h',0
hidecrsr DB ESC,'[?25l',0
cpmcls 	DB ESC,'[2J',0
cpmhome DB ESC,'[;H',0
set40col DB ESC, '[=0',0


inrec 	DB 40  ; len of buffer
bytesrd DB 0	
INBUF
inputbuffer ; cpm populates this struct	
chars	DS 40  ; space
	