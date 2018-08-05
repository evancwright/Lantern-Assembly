;main.asm
;evanwright 2017

.include "defs6502.asm"	


#define scrWdth $21
#define hcur $24
#define vcur $25

;zero page vars

#define strSrc 	$70 ; some zero page addr
#define strDest	$72 ; some zero page addr
#define tableAddr $74
#define strAddr $76
#define PAGE_19 $1900
#define PAGE_20 $2000
#define PAGE_107 $6B00
#define OSFILESAV #0 

.org $PAGE_20
	.module main
start
	tsx			 ;save stack
	stx stack
	l	
	jsr cls
	jsr show_intro
 	jsr look_sub
_lp
 	jsr clr_buffr
	jsr clr_words
    jsr printcr
	jsr print_title_bar
	jsr getline
	nop
	lda buffer
	cmp #0 ; cr
	bne _c
	jsr no_input
	jmp _lp
_c 	jsr toascii
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

	jsr remove_articles
	jsr get_verb
	jsr get_nouns ; 
	
	jsr encode_sentence
	lda #1
	cmp encodeFailed
	beq _lp
	
	jsr map_nouns
	
	jsr check_mapping ; make sure objects were visible
	lda #1
	cmp encodeFailed
	beq _lp
	
	jsr process_sentence	
	
;	jsr do_events
	jsr player_can_see	
	jsr do_events
	jsr inv_weight
 		
	jmp _lp

_x 	jsr printcr
	rts


.include "intro6502.asm"
.include "strings6502.asm"
.include "printing6502.asm"
.include "look6502.asm"
.include "bbcparser.asm"
.include "tables6502.asm"
.include "routines6502.asm"
.include "attributes6502.asm"
.include "checks6502.asm"
.include "sentences6502.asm"
.include "movement6502.asm"
.include "light6502.asm"
.include "inventory6502.asm"
.include "containers6502.asm"
.include "math6502.asm"
.include "bbcsave.asm"
.include "doevents6502.asm"
.include "wear_sub.asm"
.include "Events6502.asm"
.include "ObjectWordTable6502.asm"
.include "Dictionary6502.asm"
.include "StringTable6502.asm"
.include "VerbTable6502.asm"
.include "CheckRules6502.asm"
.include "bbcio.asm"
beginData
.include "ObjectTable6502.asm"	
.include "builtInVars6502.asm"
.include "userVars6502.asm"	
endData
.include "NogoTable6502.asm"
.include "PrepTable6502.asm"
.include "articles6502.asm"
.include "sentence_table_6502.asm"
.include "before_table_6502.asm"
.include "instead_table_6502.asm"
.include "after_table_6502.asm"
.include "Welcome6502.asm"

temp	.byte 0
msg	.text	"HELLO"
	.byte 0
goodbye .text "BYE"
	.byte 0
prompt 	.text ">"
	.byte 0
confused .text "I DON'T FOLLOW YOU."
	.byte 0
;quit .byte "QUIT",0h
stack .byte 0
.end
