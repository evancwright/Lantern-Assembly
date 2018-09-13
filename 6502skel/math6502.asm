;math6502.asm
;(c) Evan C. Wright, 2017

.module next_rand
next_rand
	pha
	tax
	pha
	tay
	pha
	lda lastRand ; get tap 1
	bne _s
	inc lastRand
	sta lastRand
_s	and $rmask1  
	sta $rtap1
	lda lastRand ; get tap 2
	and $rmask2
	sta $rtap2
	lsr	rtap2	;line up bit in pos 0
	lsr $rtap2	;line up bit in pos 0
	lda $rtap1
	eor $rtap2 
	sta $rtemp  ; new bit
	lsr lastRand ; shift seed right
	asl $rtemp;put the bit on the left
	asl $rtemp
	asl $rtemp
	asl $rtemp
	asl $rtemp
	asl $rtemp
	asl $rtemp
	lda lastRand
	ora $rtemp ; or new bit onto it
	sta lastRand
	sta rval
	dec rval  
	pla
	tay
	pla
	tax
	pla
	rts
 
;divides a by y	and stores the result and the remainder
.module	div
div	
	pha 
	lda #0
	sta divResult
	sty divisor
	pla
_lp	cmp divisor
	bcc     _x
	sec
	sbc divisor
	inc divResult
	jmp _lp
_x	sta remainder
	rts

 
divisor .byte 0
remainder .byte 0
divResult .byte 0
lastRand .byte	255	
seed .byte 255
rmask1 .byte 1
rmask2 .byte 4
rtap1 .byte 0
rtap2 .byte 0
rtemp .byte 0
rval .byte 0