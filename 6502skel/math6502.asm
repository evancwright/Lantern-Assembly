;math6502.asm
;(c) Evan C. Wright, 2017


next_rand
	pha
	tax
	pha
	tay
	pha
	lda lastRand ; get tap 1
	and $rtap1  
	sta $rtemp
	lda lastRand ; get tap 2
	and $rtap2
	lsr	;light up bits
	lsr
	eor $rtap2 
	sta $rtemp  ; new bit
	lda lastRand ; shift seed right
	lsr
	sta lastRand ; and store it
	lda $rtemp  ;get the new bit
	asl ;put the bit on the left
	asl
	asl
	asl
	asl
	asl
	asl
	ora $rtemp ; or it
	sta $temp
	sta rval
	dec rval
	pla
	tay
	pla
	tax
	pla
	rts
 
;mod a by y	
.module	div
div	
	pha 
	lda #0
	sta divResult
	sty divisor
	pla
_lp	cmp divisor
	bmi _x
	sec
	sbc divisor
	inc divResult
	jmp _lp
_x	sta remainder
	rts

 
divisor .byte 0
remainder .byte 0
divResult .byte 0
lastRand .byte	0	
seed .byte 255
rmask1 .byte 1
rmask2 .byte 3
rtap1 .byte 0
rtap2 .byte 0
rtemp .byte 0
rval .byte 0