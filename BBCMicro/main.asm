;main.asm
;evanwright 2017
INVALID EQU 255
BUFFER_SIZE EQU 80

	put defs6502

;scrWdth EQU $21
scrWdth EQU $28
hcur EQU $24
vcur EQU $25

;zero page vars

strSrc EQU	$70 ; some zero page addr
strDest	EQU $72 ; some zero page addr
tableAddr EQU $74
strAddr EQU $76
PAGE_19 EQU $1900
PAGE_20 EQU $2000
PAGE_107 EQU $6B00
OSFILESAV EQU #0 
;kbdbuf EQU $3D0

	org PAGE_20
	
	
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
	lda #0
	sta encodeFail	
	jsr getline
	nop
	lda buffer
	cmp #0 ; cr
	bne :c
	jsr no_input
	jmp :lp
:c 	;jsr toascii not needed on BBC
	lda #0
	sta strSrc
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


	put intro6502
	put strings6502
	put printing6502
	put look6502
;	put bbcparser
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
	put bbcsave
	put doevents6502
	put wear_sub
	put ObjectWordTable6502
	put Dictionary6502
	put StringTable6502
	put VerbTable6502
	put CheckRules6502
	put formatting6502
	put bbcio
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
msg	ASC	"HELLO"
	DB 0
goodbye ASC "BYE"
	DB 0
prompt 	ASC ">"
	DB 0
confused ASC "I DON'T FOLLOW YOU."
	DB 0
;quit DB "QUIT",0h
stack DB 0
spcChar DB #$20 ; space

