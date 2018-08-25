;main.asm
;evanwright 2017

.include "defs6502.asm"	

#define INVALID 255
#define strAddr $CE
#define fmtByte $32
#define altChar1 $C00E
#define altChar2 $C00F
#define RDALTCHAR $C01E
#define getlin $FD67 
#define rdkey $FD0C


#define keyin  $FD0C
#define getlin $FD6A 
#define cout1 $FDF0
#define scrWdth $24  ; 39
#define hcur $24
#define vcur $25
#define kbdbuf $200
;zero page vars
#define strAddr $CE
#define fmtByte $32
#define tableAddr FE
#define strSrc 	$EB ; some zero page addr
#define strDest	$FA ; some zero page addr

 
#define kbBufLo $0
#define kbBufHi $02

#define cls $FC58
.org $800   ; was $800 (moved it to make room for I/O buffer)
	.module main
start
	tsx			 ;save stack
	stx stack
	lda #32
	sta charsLeft
	jsr cls
	jsr show_intro
 	jsr look_sub
_lp
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

.include "input.asm"
.include "intro6502.asm"
.include "strings6502.asm"
.include "printing6502.asm"
.include "a2printing.asm"
.include "look6502.asm"
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
.include "a2save.asm"
.include "doevents6502.asm"
.include "wear_sub.asm"
.include "Events6502.asm"
.include "ObjectWordTable6502.asm"
.include "Dictionary6502.asm"
.include "StringTable6502.asm"
.include "VerbTable6502.asm"
.include "CheckRules6502.asm"
.include "a2fileio.asm"
.include "formatting6502.asm"
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
;NumWords .db 
stack .byte 0
spcChar .byte $A0
.end
