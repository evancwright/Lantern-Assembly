;parser test program
*INCLUDE objdefsZ80.asm ; equs
 
;QINPUT equ 1bb3h		; ROM ROUTINES
CRTBYTE equ  0033H
INBUF equ 41e8h
CLS equ 01c9h
;OUTLIN equ 28a7h		; src str in HL/

	ORG 5200H
START
$lp?
	call getlin
	call parse
	jr $lp?	
	ret

*INCLUDE io.asm	
*INCLUDE parser2Z80.asm
*INCLUDE tables.asm
*INCLUDE strings.asm
*INCLUDE articlesZ80.asm
*INCLUDE PrepTableZ80.asm
*INCLUDE StringTableZ80.asm
*INCLUDE ObjectTableZ80.asm
*INCLUDE DictionaryZ80.asm
*INCLUDE VerbTableZ80.asm
*INCLUDE ObjectWordTableZ80.asm
*INCLUDE Look.asm
*INCLUDE RoutinesZ80.asm
*INCLUDE print_rets.asm
*INCLUDE checksZ80.asm
*INCLUDE inventoryZ80.asm
*INCLUDE put.asm
*INCLUDE containersZ80.asm
*INCLUDE math.asm
	END START