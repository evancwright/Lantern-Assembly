;main.asm
;evanwright 2017

put defs6502.asm"	

scrWdth EQU $21
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

.org $PAGE_20
	
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
	jsr clr_words
    jsr printcr
	jsr print_title_bar
	jsr getline
	nop
	lda buffer
	cmp #0 ; cr
	bne :c
	jsr no_input
	jmp :lp
:c 	jsr toascii
	lda #0
	sta strSrc
	
	jsr remove_articles
	jsr get_verb
	jsr get_nouns ; 
	
	jsr encode_sentence
	lda #1
	cmp encodeFailed
	beq :lp
	
	jsr map_nouns
	
	jsr check_mapping ; make sure objects were visible
	lda #1
	cmp encodeFailed
	beq :lp
	
	jsr process_sentence	
	
	jsr player_can_see	
	jsr do_events
	jsr inv_weight
 		
	jmp :lp

:x 	jsr printcr
	rts


put intro6502.asm
put strings6502.asm
put printing6502.asm
put look6502.asm
put bbcparser.asm
put tables6502.asm
put routines6502.asm
put attributes6502.asm
put checks6502.asm
put sentences6502.asm
put movement6502.asm
put light6502.asm
put inventory6502.asm
put containers6502.asm
put math6502.asm
put bbcsave.asm
put doevents6502.asm
put wear_sub.asm
put Events6502.asm
put ObjectWordTable6502.asm
put Dictionary6502.asm
put StringTable6502.asm
put VerbTable6502.asm
put CheckRules6502.asm
put bbcio.asm
beginData
put ObjectTable6502.asm	
put builtInVars6502.asm
put userVars6502.asm
endData
put NogoTable6502.asm
put PrepTable6502.asm
put articles6502.asm
put sentence_table_6502.asm
put before_table_6502.asm
put instead_table_6502.asm
put after_table_6502.asm
put Welcome6502.asm

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

