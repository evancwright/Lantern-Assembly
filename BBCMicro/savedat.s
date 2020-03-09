;bbcmicro save function

#define SAVEFILE 0
#define OSFILE FFDD
start	
main
	.db A9,0 ; lda #SAVEFILE
	.db ;ldx  ctrlblock%256
	ldy  ctrlblock/256
	jsr $OSFILE
	rts
ctrlblock
	.dw progname
	.dw 0x00,0x20  ; load addr
	.dw 0x00
	.dw 0x00,0x20  ; exec addr
	.dw 0x00
	.dw 0x00,0x20  ; file addr in memory
	.dw 0x00
	.dw ENDADDR   ; lo-byte first
	.dw 0x00	
progname
	.strz "ADVGAME",0x0d
	end start

ctrlblock
	.dw progname
	.dw 0x00,0x20  ; load addr
	.dw 0x00
	.dw 0x00,0x20  ; exec addr
	.dw 0x00
	.dw 0x00,0x20  ; file addr in memory
	.dw 0x00
	.dw ENDADDR   ; lo-byte first
	.dw 0x00