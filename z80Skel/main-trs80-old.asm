;main file for trs-80 shell
 
*INCLUDE objdefsZ80.asm ; equs
 
;QINPUT equ 1bb3h		; ROM ROUTINES
CRTBYTE equ  0033H
INBUF equ 41e8h
CLS equ 01c9h
;OUTLIN equ 28a7h		; src str in HL/

	ORG 5200H
START
		call CLS
		ld hl,welcome ; print welcome,author,version
		call OUTLIN
		call printcr
		ld hl,author
		call OUTLIN
		call printcr
		ld hl,version
		call OUTLIN
		call printcr
		call printcr
		call look_sub
$inp?	call getcommand
		jp $inp?
		ret
		
getcommand
		;call QINPUT
		call getlin
		call parse				; get the words
		ld a,(sentence)
		cp 0
		jp z,$inp?
		call validate_words		; make sure verb,io,do are in tables
		call encode				; try to map words to objects
		call validate_encode	; make sure it worked
		call run_sentence
		call do_events
		ret
		
*MOD
do_events
*INCLUDE event_jumps_Z80.asm
	call player_has_light
	cp 1
	jp z,$y?
	ld a,(turns_without_light)
	inc a
	ld (turns_without_light),a
	jp $x?
$y?	ld a,0
	ld (turns_without_light),a
$x?	ret
	
*INCLUDE io.asm	
*INCLUDE parser.asm
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
*INCLUDE print_rets.asm
*INCLUDE EventsZ80.asm
*INCLUDE articlesZ80.asm
*INCLUDE PrepTableZ80.asm
*INCLUDE StringTableZ80.asm
*INCLUDE DictionaryZ80.asm
*INCLUDE VerbTableZ80.asm
*INCLUDE ObjectTableZ80.asm
*INCLUDE ObjectWordTableZ80.asm
*INCLUDE NogoTableZ80.asm
*INCLUDE BackDropTableZ80.asm
*INCLUDE before_table_Z80.asm
*INCLUDE instead_table_Z80.asm
*INCLUDE after_table_Z80.asm
*INCLUDE CheckRulesZ80.asm
*INCLUDE sentence_tableZ80.asm
*INCLUDE WelcomeZ80.asm
*INCLUDE UserVarsZ80.asm
score DB 0
gameOver DB 0
moves DB 0
turns_without_light DB 0
health DB 100
	END START
;END