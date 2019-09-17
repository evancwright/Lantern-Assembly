;main.asm for c64
;evanwright 2017-19

	put defs6502.s	

SPACE EQU 32
GT EQU 62
BS EQU 14
CR EQU $0D
UNDRSCR EQU 164
INVALID EQU 255

;#define rdkey $FD0C

cout1 EQU $FFD2
scrWdth EQU $24

;zero page vars
strAddr EQU $03 ; 3-4
tableAddr EQU $05 ; bytes 5-6
strSrc 	EQU $FB ; (fb-fc)
strDest	EQU $FD ; (fd-de)


;define cls $FC58

;basic header
;header to turn this into a .D64 file
;this is the starting address 
;in little endian format 
	org 2047  
	;DON'T REMOVE THIS - NEEDED TO LOAD PROGRAM
	DB #1 ; load addr lo
	DB #16 ; load addr hi

	put prgheader.s

;assembly code starts here at address 4109

 	
start
	tsx			 ;save stack
	stx stack

	lda #23
	sta $D018
	
	lda #scrWdth
	sta charsLeft
	
	jsr cls
	jsr show_intro
 	jsr look_sub
:lp
	jsr clr_buffr
    jsr printcr
	jsr print_title_bar
	
	;clear the encode fail flag
	lda #0
	sta encodeFail
		
	jsr readkb
	
	lda #scrWdth
	sta charsLeft
	
 	cmp #CR ; cr
	bne :c
	jsr no_input
	jmp :lp
:c  lda #0
	sta strSrc
	
	jsr parse
	
	lda encodeFail
	cmp #1
	beq :lp
	
	jsr process_sentence		
	jsr player_can_see	
	jsr do_events
	jsr inv_weight	
	jmp :lp

:x 	jsr printcr
	rts

	__INCLUDES__
	
	put c64input.s
	put intro6502.s
	put strings6502.s
	put printing6502.s
	put c64printing.s
	put formatting6502.s
	put look6502.s
	put newparser.s
	put scoring6502.s
	put tables6502.s
	put routines6502.s
	put attributes6502.s
	put checks6502.s
	put sentences6502.s
	put movement6502.s
	put light6502.s
	put inventory6502.s
	put containers6502.s
	put math6502.s
	put itoa6502.s
	put c64save.s
	put doevents6502.s
	put wear_sub.s
	put ObjectWordTable6502.s
	put Dictionary6502.s
	put StringTable6502.s
	put VerbTable6502.s
	put CheckRules6502.s
beginData
	put ObjectTable6502.s	
	put builtinVars6502.s
	put userVars6502.s	
endData
	put NogoTable6502.s
	put PrepTable6502.s
	put articles6502.s
	put sentence_table_6502.s
	put before_table_6502.s
	put instead_table_6502.s
	put after_table_6502.s
	put Welcome6502.s


goodbye ASC 'Bye'
	DB 0
prompt 	ASC '>'
	DB 0
confused ASC 'I don',2D,'t follow you.'
	DB 0

stack DB 0
spcChar DB #$20
temp DB 0
charMask DB #$0  ; used on apple
 




