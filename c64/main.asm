;main.asm
;evanwright 2017

.include "defs6502.asm"	

#define SPACE 32
#define GT 62
#define BS 14
#define CR $0D
#define UNDRSCR 164
#define INVALID 255
;#define rdkey $FD0C

#define cout1 $FFD2
;#define scrWdth $21

;zero page vars
#define strAddr $03 ; 3-4
#define tableAddr  $05 ; bytes 5-6
#define strSrc 	$FB ; (fb-fc)
#define strDest	$FD ; (fd-de)

#define kbBufLo kbdbuf%256
#define kbBufHi kbdbuf/256

;define cls $FC58

;basic header
;header to turn this into a .D64 file
;this is the starting address 
;in little endian format 
.org 2047  
.byte 01h ; load addr lo
.byte 10h ; load addr hi

.include prgheader.asm

;assembly code starts here at address 4109

 	.module main
start
	tsx			 ;save stack
	stx stack
	
	jsr cls
	jsr show_intro
 	jsr look_sub
_lp
    jsr printcr
	jsr print_title_bar
	
	;clear the encode fail flag
	lda #0
	sta encodeFail
		
	jsr readkb
 	cmp #CR ; cr
	bne _c
	jsr no_input
	jmp _lp
_c  lda #0
	sta strSrc
	
	jsr parse
	
	lda encodeFail
	cmp #1
	beq _lp
	
	jsr process_sentence		
	jsr player_can_see	
	jsr do_events
	jsr inv_weight	
	jmp _lp

_x 	jsr printcr
	rts

.include "c64input.asm"
.include "intro6502.asm"
.include "strings6502.asm"
.include "printing6502.asm"
.include "c64printing.asm"
.include "look6502.asm"
;.include "c64parser.asm"
.include "newparser.asm"
.include "scoring6502.asm"
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
.include "c64save.asm"
.include "doevents6502.asm"
.include "wear_sub.asm"
.include "Events6502.asm"
.include "ObjectWordTable6502.asm"
.include "Dictionary6502.asm"
.include "StringTable6502.asm"
.include "VerbTable6502.asm"
.include "CheckRules6502.asm"
beginData
.include "ObjectTable6502.asm"	
.include "builtinVars6502.asm"
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

temp .byte 0
.end





