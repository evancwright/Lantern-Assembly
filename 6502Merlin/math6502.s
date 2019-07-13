;math6502.asm
;(c) Evan C. Wright, 2017

 
next_rand
	pha
	tax
	pha
	tay
	pha
	lda lastRand ; get tap 1
	bne :s
	inc lastRand
	sta lastRand
:s	and rmask1  
	sta rtap1
	lda lastRand ; get tap 2
	and rmask2
	sta rtap2
	lsr	rtap2	;line up bit in pos 0
	lsr rtap2	;line up bit in pos 0
	lda rtap1
	eor rtap2 
	sta rtemp  ; new bit
	lsr lastRand ; shift seed right
	asl rtemp	;put the bit on the left
	asl rtemp
	asl rtemp
	asl rtemp
	asl rtemp
	asl rtemp
	asl rtemp
	lda lastRand
	ora rtemp ; or new bit onto it
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
 
div	
	pha 
	lda #0
	sta divResult
	sty divisor
	pla
:lp	cmp divisor
	bcc     :x
	sec
	sbc divisor
	inc divResult
	jmp :lp
:x	sta remainder
	rts

 
divisor DB 0
remainder DB 0
divResult DB 0
lastRand DB	255	
seed DB 255
rmask1 DB 1
rmask2 DB 4
rtap1 DB 0
rtap2 DB 0
rtemp DB 0
rval DB 0