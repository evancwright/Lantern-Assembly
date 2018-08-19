;sentences6502.asm
;(c) Evan Wright, 2017

;if any sentences are run
;sentenceRun is set to true
	.module process_sentence
process_sentence
		lda #0 ; clear handled flag
		sta handled
		
		jsr run_checks ; do checks
		lda checkFailed
		cmp #1
		beq _x

		lda sentence+1
		sta oldDobj
		lda sentence+3
		sta oldIobj
		jsr run_preactions ; run preactions
		jsr run_actions ;
		jsr run_postactions ;
		
		lda handled
		cmp #1
		beq _x

		;not handled
		lda #confused%256	
		sta strAddr
		lda #confused/256	
		sta strAddr+1
		jsr printstrcr
		
_x		rts
		
run_preactions
		lda #preactions_table%256
		sta $tableAddr
		lda #preactions_table/256
		sta $tableAddr+1
		jsr run_user_sentences
 		rts

;try exact matches
;if nothing run, try wildcard match
;if nothing run, run default
		.module run_actions
run_actions	
		lda #0
		sta sentenceRun
		
		lda #actions_table%256  ;set up table
		sta $tableAddr
		lda #actions_table/256
		sta $tableAddr+1
		jsr run_user_sentences
		
		lda sentenceRun	; matched?
		cmp #1		
		beq _skip
		
		lda #actions_table%256 ; reload table 
		sta $tableAddr
		lda #actions_table/256
		sta $tableAddr+1

		lda #0
		sta sentenceRun
		jsr run_wildcards_sentences
		
		lda sentenceRun	; matched?
		cmp #1
		beq _skip
		jsr run_default_actions
_skip		
		rts		
		
run_postactions
		lda #postactions_table%256
		sta $tableAddr
		lda #postactions_table/256
		sta $tableAddr+1
		jsr run_user_sentences
		rts

;loops through jump table		
	.module run_default_actions
run_default_actions
		lda #0
		sta defaultHandled
		lda #$sentence_table%256
		sta $tableAddr
		lda #$sentence_table/256
		sta $tableAddr+1
		ldy #0
_lp		lda ($tableAddr),y
		cmp #255 
		beq _x
		cmp $sentence		; do the verbs match?
		bne _skp
		jsr inc_tabl_addr
		lda #1
		;missing store defaultHandled?
		sta defaultHandled
		sta handled
		ldx ($tableAddr)  ; set up the indirect jump
		ldy ($tableAddr+1)
		stx $tableAddr
		sty $tableAddr+1
		ldy #0
		lda ($tableAddr),y
		sta jumpVector
		ldy #1
		lda ($tableAddr),y
		sta jumpVector+1
        lda #_nxt/256		; push return address (so we can fake a jump)
		pha
		lda #_nxt%256
		pha
		jmp ($jumpVector)  ; can't don an indirect function call 
_nxt	nop ; padding for byte alignment
		jmp _x
_skp	jsr inc_tabl_addr
		jsr inc_tabl_addr
		jsr inc_tabl_addr
		jmp _lp
_x  	rts


;this subrountines run the pre-sentence processing checks
;if a check failes, the stack is popped twice before rts
;is called so that the check function returns from run_sentence
;as well
	.module run_checks
run_checks
		lda #0
		sta checkFailed
		lda #check_table%256
		sta $tableAddr
		lda #check_table/256
		sta $tableAddr+1
_lp		ldy #0
 		lda ($tableAddr),y
		cmp #255
		beq _x
		cmp $sentence ; verb match?
		bne _c
		ldy #1
		lda ($tableAddr),y
		sta jumpVector       ; simulate a function call
		ldy #2
		lda ($tableAddr),y
		sta jumpVector+1
        lda #_nxt/256		; push return address (so we can fake a jump)
		pha
		lda #_nxt%256
		pha
		jmp ($jumpVector)   
_nxt	nop ; padding for byte alignment
		lda checkFailed
		cmp #1
		beq _x
_c		jsr inc_tabl_addr  ; skip to next entry
		jsr inc_tabl_addr
		jsr inc_tabl_addr
		jmp _lp
_x		rts

;table address is set by caller in tableAddr
	.module run_user_sentences
run_user_sentences
_lp		ldy #0
		lda ($tableAddr),y
		cmp #255
		beq _x
		cmp $sentence 
		bne _c
		iny 
		lda ($tableAddr),y ;word2
		cmp $sentence+1
		bne _c
		iny 
		lda ($tableAddr),y ;word3
		cmp $sentence+2
		bne _c
		iny 
		lda ($tableAddr),y ;word4
		cmp $sentence+3
		bne _c	
_run	lda #1	
		sta handled
		
		ldy #4
		lda ($tableAddr),y	; put jumpAddr in vector
		sta $jumpVector
		iny
		lda ($tableAddr),y
		sta $jumpVector+1
		
		lda #_nxt/256		; put return addr onto stack
		pha
		lda #_nxt%256
		pha
		
		jmp ($jumpVector)	; run the sentence
		
_nxt	nop ; padding - don not remove!
		
		lda #1			; flag that we ran a sentence
		sta sentenceRun

		jmp _x
_c		clc				;add 6 bytes to skip to next entry
		lda $tableAddr
		adc #6
		sta $tableAddr
		lda $tableAddr+1
		adc #0
		sta $tableAddr+1
		jmp _lp
_x		rts

	.module run_wildcards_sentences	
run_wildcards_sentences

_lp		lda sentence+1;load the old io and do
		pha
		lda sentence+3
		pha
		
		ldy #0
		lda ($tableAddr),y ;hit end of table?
		cmp #255
		beq _x
		
		cmp $sentence  ;do verbs match?
		bne _c   

		iny 
		lda ($tableAddr),y ;word1
		cmp #254	; is it a wildcard?
		bne _prp
		lda #254	; replace noun with '*"
		sta sentence+1

_prp	iny
		lda ($tableAddr),y ;word2
		cmp $sentence+2  ;do preps match?
		bne _c   
		
_io		iny 
		lda ($tableAddr),y ;word3
		cmp #254
		bne _dn
		lda #254
		sta sentence+3
		
_dn		;sentence should now match wildcarded string
		;see if it actually does
		ldy #1
		lda ($tableAddr),y 
		cmp $sentence+1
		bne _c	
		
		ldy #3
		lda ($tableAddr),y 
		cmp $sentence+3
		bne _c	
		;sentences match!  run them
_run	lda #1
		sta handled

		ldy #4
		lda ($tableAddr),y	; put jumpAddr in vector
		sta $jumpVector
		iny
		lda ($tableAddr),y
		sta $jumpVector+1
		
		lda #_nxt/256		; put return addr onto stack
		pha
		lda #_nxt%256
		pha
		
		lda oldDobj
		sta sentence+1
		lda oldIobj
		sta sentence+3
		jmp ($jumpVector)	; run the sentence
		
_nxt	nop ; padding - don not remove!
		
		lda #1			; flag that we ran a sentence
		sta sentenceRun
		;restore old sentence
		
		jmp _x
_c		pla 
		sta sentence+3
		pla
		sta sentence+1
		
		clc				;add 6 bytes to skip to next entry
		lda $tableAddr
		adc #6
		sta $tableAddr
		lda $tableAddr+1
		adc #0
		sta $tableAddr+1
		jmp _lp
		
_x		;restore old sentence
		pla 
		sta sentence+3
		pla
		sta sentence+1
		rts

jumpVector .word 0
defaultHandled .byte 0
sentenceRun .byte 0  ;flag used for wildcards
handled .byte 0 ; action taken or not
oldDobj .byte 0
oldIobj .byte 0