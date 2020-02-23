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
		
		ld hl,0
		call TXT_SET_CUR
		
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
		call draw_top_bar	 
		call getlin
		call printcr		
 		call parse				; get the words
	
$go?	call validate_words		; make sure verb,io,do are in tables
		call encode				; try to map words to objects
		call validate_encode	; make sure it worked
		call run_sentence
		call printcr
		call do_events
		call draw_top_bar
quit	ret

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
*INCLUDE print_rets.asm
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
	end start
	
