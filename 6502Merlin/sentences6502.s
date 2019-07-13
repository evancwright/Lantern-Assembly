;sentences6502.asm
;(c) Evan Wright, 2017

;if any sentences are run
;sentenceRun is set to true
	 
process_sentence
		lda #0 ; clear handled flag
		sta handled
		
		jsr run_checks ; do checks
		lda checkFailed
		cmp #1
		beq :x

		lda sentence+1
		sta oldDobj
		lda sentence+3
		sta oldIobj
		jsr run_preactions ; run preactions
		jsr run_actions ;
		jsr run_postactions ;
		lda handled
		cmp #1
		beq :x
		;not handled
		lda #<confused
		sta strAddr
		lda #>confused
		sta strAddr+1
		jsr printstrcr
:x		rts
		
run_preactions
		lda #<preactions_table
		sta tableAddr
		lda #>preactions_table
		sta tableAddr+1
		jsr run_user_sentences
 		rts

;try exact matches
;if nothing run, try wildcard match
;if nothing run, run default
		 
run_actions	
		lda #0
		sta sentenceRun
		
		lda #<actions_table  ;set up table
		sta tableAddr
		lda #>actions_table
		sta tableAddr+1
		jsr run_user_sentences
		
		lda sentenceRun	; matched?
		cmp #1		
		beq :skip
		
		lda #<actions_table ; reload table 
		sta tableAddr
		lda #>actions_table
		sta tableAddr+1
		;		
		lda #0
		sta sentenceRun
		jsr run_wildcards_sentences
		;
		lda sentenceRun	; matched?
		cmp #1
		beq :skip
		jsr run_default_actions
:skip	rts		
		
run_postactions
		lda #<postactions_table
		sta tableAddr
		lda #>postactions_table
		sta tableAddr+1
		jsr run_user_sentences
		rts

;loops through jump table		
	 
run_default_actions
		lda #0
		sta defaultHandled
		lda #<sentence_table
		sta tableAddr
		lda #>sentence_table
		sta tableAddr+1
		ldy #0
:lp		lda (tableAddr),y
		cmp #255 
		bne :c
		jmp :x
:c		cmp sentence		; do the verbs match?`
		bne :skp
		jsr inc_tabl_addr
		lda #1
		;missing store defaultHandled?
		sta defaultHandled
		sta handled
		ldx tableAddr  ; set up the indirect jump
		ldy tableAddr+1
		stx tableAddr
		sty tableAddr+1
		ldy #0
		lda (tableAddr),y
		sta jumpVector
		ldy #1
		lda (tableAddr),y
		sta jumpVector+1
        lda #>:nxt		; push return address (so we can fake a jump)
		pha
		lda #<:nxt
		pha
		jmp (jumpVector)  ; can't don an indirect function call 
:nxt	nop ; padding for byte alignment
		jmp :x
:skp	jsr inc_tabl_addr
		jsr inc_tabl_addr
		jsr inc_tabl_addr
		jmp :lp
:x
		rts


;this subrountines run the pre-sentence processing checks
;if a check failes, the stack is popped twice before rts
;is called so that the check function returns from run_sentence
;as well
 
run_checks
		lda #0
		sta checkFailed
		lda #<check_table
		sta tableAddr
		lda #>check_table
		sta tableAddr+1
:lp		ldy #0
 		lda (tableAddr),y
		cmp #255
		beq :x
		cmp sentence ; verb match?
		bne :c
		ldy #1
		lda (tableAddr),y
		sta jumpVector       ; simulate a function call
		ldy #2
		lda (tableAddr),y
		sta jumpVector+1
        lda #>:nxt		; push return address (so we can fake a jump)
		pha
		lda #<:nxt
		pha
		jmp (jumpVector)   
:nxt	nop ; padding for byte alignment
		lda checkFailed
		cmp #1
		beq :x
:c		jsr inc_tabl_addr  ; skip to next entry
		jsr inc_tabl_addr
		jsr inc_tabl_addr
		jmp :lp
:x		rts

;table address is set by caller in tableAddr
 
run_user_sentences
:lp		ldy #0
		lda (tableAddr),y
		cmp #255
		beq :x
		cmp sentence 
		bne :c
		iny 
		lda (tableAddr),y ;word2
		cmp sentence+1
		bne :c
		iny 
		lda (tableAddr),y ;word3
		cmp sentence+2
		bne :c
		iny 
		lda (tableAddr),y ;word4
		cmp sentence+3
		bne :c	
:run	lda #1	
		sta handled
		
		ldy #4
		lda (tableAddr),y	; put jumpAddr in vector
		sta jumpVector
		iny
		lda (tableAddr),y
		sta jumpVector+1
		
		lda #>:nxt2		; put return addr onto stack
		pha
		lda #<:nxt2
		pha
		
		jmp (jumpVector)	; run the sentence
		
:nxt2	nop ; padding - don not remove!
		lda #1			; flag that we ran a sentence
		sta sentenceRun
		jmp :x
:c		clc				;add 6 bytes to skip to next entry
		lda tableAddr
		adc #6
		sta tableAddr
		lda tableAddr+1
		adc #0
		sta tableAddr+1
		jmp :lp
:x		rts

 
run_wildcards_sentences

:lp		lda sentence+1	;load the old io and do
		pha
		lda sentence+3
		pha
		
		ldy #0
		lda (tableAddr),y ;hit end of table?
		cmp #255
		beq :x
		
		cmp sentence  ;do verbs match?
		bne :c   

		iny 
		lda (tableAddr),y ;word1
		cmp #254	; is it a wildcard?
		bne :prp
		lda #254	; replace noun with '*"
		sta sentence+1

:prp	iny
		lda (tableAddr),y ;word2
		cmp sentence+2  ;do preps match?
		bne :c   
		
:io		iny 
		lda (tableAddr),y ;word3
		cmp #254
		bne :dn
		lda #254
		sta sentence+3
		
:dn		;sentence should now match wildcarded string
		;see if it actually does
		ldy #1
		lda (tableAddr),y 
		cmp sentence+1
		bne :c	
		
		ldy #3
		lda (tableAddr),y 
		cmp sentence+3
		bne :c	
		;sentences match!  run them
:run	lda #1
		sta handled
		ldy #4
		lda (tableAddr),y	; put jumpAddr in vector
		sta jumpVector
		iny
		lda (tableAddr),y
		sta jumpVector+1
		
		lda #>:nxt3		; put return addr onto stack
		pha
		lda #<:nxt3
		pha
		
		lda oldDobj
		sta sentence+1
		lda oldIobj
		sta sentence+3
		jmp (jumpVector)	; run the sentence
		
:nxt3	nop ; padding - do not remove!
		;
		lda #1			; flag that we ran a sentence
		sta sentenceRun
		;restore old sentence
		;
		jmp :x
:c		pla 
		sta sentence+3
		pla
		sta sentence+1
		;
		clc				;add 6 bytes to skip to next entry
		lda tableAddr
		adc #6
		sta tableAddr
		lda tableAddr+1
		adc #0
		sta tableAddr+1
		jmp :lp		
:x		;restore old sentence
		pla 
		sta sentence+3
		pla
		sta sentence+1
		rts

jumpVector DW 0
defaultHandled DB 0
sentenceRun DB 0  ;flag used for wildcards
handled DB 0 ; action taken or not
oldDobj DB 0
oldIobj DB 0