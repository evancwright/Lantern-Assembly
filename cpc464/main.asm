;main.asm
;main routine for ZX Spectrum
;(c) Evan Wright, 2017
*INCLUDE cpc464defs.asm
*INCLUDE objdefsZ80.asm

; BASIC STARTS AT 5CCB for Spectrum
	org 4000h ;
start

;main program goes here
main
		ld (stackSav),sp

		;set screen as output channel
		call CLS  
		
		ld hl,0 	; this needs to move to vm
		call TXT_SET_CUR  ; this needs to move to vm
		
		call printcr
		
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
		
		call draw_top_bar
		call getcommand
 
		pop iy
		pop ix
 
		jp $inp?
	
	ret

getcommand
		;call QINPUT
		call getlin
 		call parse				; get the words
$go?	call check_parse_fail
		cp 1
		jr z,$x?
		call run_sentence
		call do_events
$x?		call draw_top_bar
		ret


*INCLUDE doeventsZ80.asm		
*INCLUDE cpc464printing.asm
*INCLUDE cpc464input.asm
;*INCLUDE parser.asm
*INCLUDE parser2Z80.asm
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
*INCLUDE ObjectTableZ80.asm
*INCLUDE BuiltInVarsZ80.asm
*INCLUDE UserVarsZ80.asm
*INCLUDE ObjectWordTableZ80.asm
*INCLUDE NogoTableZ80.asm
*INCLUDE before_table_Z80.asm
*INCLUDE instead_table_Z80.asm
*INCLUDE after_table_Z80.asm
*INCLUDE CheckRulesZ80.asm
*INCLUDE sentence_tableZ80.asm
*INCLUDE WelcomeZ80.asm
*INCLUDE math.asm
*INCLUDE save.asm

stacksav DW 0
	
	nop 	; force CPC to load last byte
;	end start  - this was for Z80 ASM
	
