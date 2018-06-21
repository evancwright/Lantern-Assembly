#define SCREEN $0400

.org 2047  ; 2048
.byte 01h ; load addr lo
.byte 10h ; load addr hi

;.org 2048
.include prgheader.asm

	.module main
start
;_lp
	lda #12
	sta $C9
	lda #15
	sta $D4
	lda #65
 	sec
	jsr $FFF0 ; plot
	jsr $FFD2 ; CHAROUT
;	jmp _lp
	rts
.end
