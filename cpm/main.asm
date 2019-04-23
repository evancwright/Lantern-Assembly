;main file for trs-80 shell
 
*INCLUDE objdefsZ80.asm ; equs
 
;QINPUT equ 1bb3h		; ROM ROUTINES
;CRTBYTE equ  0033H
;INBUF equ 41e8h
;CLS equ 01c9h
;OUTLIN equ 28a7h		; src str in HL/

	ORG 100H
START
		ld (stackSav),sp
		call CLS
		ld hl,welcome ; print welcome,author,version
		call OUTLINCR
		ld hl,author
		call OUTLINCR
		ld hl,version
		call OUTLINCR
		call printcr
		call look_sub
$inp?	call getcommand
		jp $inp?
		ret

*MOD		
getcommand
		;call QINPUT
		call getlin
		call parse				; get the words
;		call validate_words		; make sure verb,io,do are in tables
;		call encode				; try to map words to objects
;		call validate_encode	; make sure it worked
		call check_parse_fail
		cp 1
		jr z,$x?
		call run_sentence
		call do_events
$x?		ret

*INCLUDE doeventsZ80.asm		
*INCLUDE cpm.asm	
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
*INCLUDE put.asm
*INCLUDE miscZ80.asm
*INCLUDE wear_sub.asm
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
*INCLUDE save.asm
*INCLUDE math.asm

stacksav DW 0

	END START
;END
