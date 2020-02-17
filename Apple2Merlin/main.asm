;main.asm
;evanwright 2017

	put defs6502

INVALID EQU 255

fmtByte EQU $32
altChar1 EQU $C00E
altChar2 EQU $C00F
RDALTCHAR EQU $C01E
rdkey EQU $FD0C
keyin EQU $FD0C
cout1 EQU $FDF0
scrWdth EQU $24  ; 39
hcur EQU $24
vcur EQU $25
kbdbuf EQU $200
;zero page vars
strAddr EQU $CE
tableAddr EQU $FE
strSrc 	EQU $EB ; some zero page addr
strDest	EQU $FA ; some zero page addr

 
kbBufLo EQU $0
kbBufHi EQU $02

cls EQU $FC58

	ORG $800   ; was $800 (moved it to make room for I/O buffer)
	 
start
	tsx			 ;save stack
	stx stack
	lda #scrWdth
	sta charsLeft
	jsr cls
	jsr show_intro
 	jsr look_sub
:lp
	jsr clr_buffr
    jsr printcr
	jsr print_title_bar
	;clear the fail flag
	lda #0
	sta encodeFail	
	jsr readkb
	lda #scrWdth
	sta charsLeft
	lda $200
	cmp #$8D ; cr
	bne :c
	jsr no_input
	jmp :lp
:c 	jsr toascii
	lda #0
	sta strSrc
;	lda #kbBufHi ; did the user type quit
;	sta strSrc+1
;	lda #quit%256
;	sta strDest
;	lda #quit/256	
;	sta strDest+1
;	jsr streq6
;	cmp #1
;	beq _x
 	jsr parse
	lda encodeFail
	cmp #1
	beq :lp	
	jsr process_sentence		
	jsr player_can_see	
	jsr do_events
	jsr inv_weight
	inc moves
	jmp :lp
:x 	jsr printcr
	rts

	put input
	put intro6502
	put strings6502
	put printing6502
	put a2printing
	put look6502
	put newparser
	put scoring6502
	put tables6502
	put routines6502
	put attributes6502
	put checks6502
	put sentences6502
	put movement6502
	put light6502
	put inventory6502
	put containers6502
	put math6502
	put itoa6502
	put a2save
	put doevents6502
	put wear_sub
	put ObjectWordTable6502
	put Dictionary6502
	put StringTable6502
	put VerbTable6502
	put CheckRules6502
	put a2fileio
	put formatting6502
beginData
	put ObjectTable6502
	put builtInVars6502
	put userVars6502
endData
	put NogoTable6502
	put PrepTable6502
	put articles6502
	put sentence_table_6502
	put before_table_6502
	put instead_table_6502
	put after_table_6502
	put Welcome6502
	
__INCLUDES__	
	
temp	DB 0
msg	ASC	"Hello"
	DB 0
goodbye ASC "Bye"
	DB 0
prompt 	ASC ">"
	DB 0
confused ASC "I don't follow you."
	DB 0
;quit DFB "QUIT",0h
;NumWords .db 
stack DB 0
spcChar DB $A0
charMask DB $80

