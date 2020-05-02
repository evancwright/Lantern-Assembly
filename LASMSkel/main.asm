;main.asm
;(c) Evan Wright, 2017-2020
*INCLUDE objdefsZ80.asm

;main program goes here
main

		ld sp,STACK
		
		ld a,0  ; screen width
		ld hl,SCRWIDTH
		setp
		
		ld a,1  ; screen height
		ld hl,SCRHEIGHT
		setp
		
		cls
				
		ld hl,welcome ; print welcome,author,version
		call OUTLINCR
 
		ld hl,author
		call OUTLINCR
 
		ld hl,version
		call OUTLINCR
 
		call printcr
		call look_sub
		
$inp?	 
		push ix
		push iy
		
;		call draw_top_bar
		sline
		call getcommand
 
		pop iy
		pop ix
 
		jp $inp?
	
		ret

getcommand
		;call QINPUT
		ld hl,INBUF
		getline
		ld a,0
		ld (HCUR),a
 		call parse				; get the words
$go?	call check_parse_fail
		cp 1
		jr z,$x?
		call run_sentence
		call do_events
$x?		sline
		ret

SAVESTART
*INCLUDE ObjectTableZ80.asm
*INCLUDE BuiltInVarsZ80.asm
*INCLUDE UserVarsZ80.asm
SAVEEND

*INCLUDE parser2Z80.asm
*INCLUDE doeventsZ80.asm		
*INCLUDE printing.asm
*INCLUDE look.asm
*INCLUDE tables.asm
*INCLUDE strings.asm
*INCLUDE checksZ80.asm
*INCLUDE sentencesZ80.asm
*INCLUDE movementZ80.asm
*INCLUDE containersZ80.asm
*INCLUDE routinesZ80.asm
*INCLUDE inventoryZ80.asm
*INCLUDE open_close.asm
*INCLUDE wear_sub.asm
*INCLUDE put.asm
*INCLUDE quitZ80.asm
*INCLUDE EventsZ80.asm
*INCLUDE articlesZ80.asm
*INCLUDE PrepTableZ80.asm
*INCLUDE StringTableZ80.asm
*INCLUDE DictionaryZ80.asm
*INCLUDE VerbTableZ80.asm
*INCLUDE ObjectWordTableZ80.asm
*INCLUDE NogoTableZ80.asm
*INCLUDE sentence_tableZ80.asm
*INCLUDE before_table_Z80.asm
*INCLUDE instead_table_Z80.asm
*INCLUDE after_table_Z80.asm
*INCLUDE CheckRulesZ80.asm
*INCLUDE WelcomeZ80.asm
*INCLUDE math.asm
*INCLUDE save.asm
INBUF ds 40
STACKBOTTOM
	ds 256 
STACK
	dw 0	; stack padding
stacksav DW 0
	
	
