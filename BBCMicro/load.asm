;bbcmicro save function

SAVEFILE EQU 0
OSFILE EQU FFDD

start	
main
	lda #SAVEFILE
	ldx  ctrlblock%256
	ldy  ctrlblock/256
	jsr $OSFILE
	rts
progname
	ASC "ADVGAME",0x0d
	end start

ctrlblock
	DW progname
	DB 0x00,0x20  ; load addr
	DB 0x00
	DB 0x00,0x20  ; exec addr
	DB 0x00
	DB 0x00,0x20  ; file addr in memory
	DB 0x00
	DW ENDADDR   ; lo-byte first
	DW 0x00