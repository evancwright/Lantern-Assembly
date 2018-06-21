;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; run_actions.asm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; x contains address of table
; with actions.
;
; registers are clobbered
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
run_actions
	stx table ; save table
	pshs d,x,y 
	pshu a
	pshu a  ; push a return code
	jsr try_exact
	pulu a  ; check return code
	cmpa #1
	beq @y
	ldx table ; reload table addr
	lda #0	; push a 0 onto the stack
	pshu a	
   jsr try_wildcards
   pulu a
	cmpa #0
	beq @x 
@y  lda #1
	sta ,u
	sta handled
@x	puls y,x,d
	rts

;called by run actions
;puts a 1 on user stack if run,else 0
;assumes the return val has been pushed
;by the caller
;x is used to crawl through the sentence table
;y points to wildcardized sentence
try_exact
	lda #0 ;assume not run
	sta ,u
@lp	lda ,x
	cmpa #$ff  ; hit end?
	beq @x
	ldb #0
@l2	lda b,x  ;get a byte from table
	ldy #sentence
	leay b,y
	cmpa 0,y ;compare it to sentence
	bne @c   ;if no match, continue
	incb
	cmpb #4  ;done?
	bne @l2  ;loop
	nop ; if got here sentence matches
	jsr [4,x]
	lda #1		;put a 1 on return stack
	sta handled
	sta ,u
	bra @x
@c  leax 6,x	; entries are 6 bytes
	bra @lp
@x	rts

;called by run actions	
;if the sentence has a *, the input
;is also set to a *
;puts a 0 or 1 on user stack
;assumes the space for it 
;has been pushed
;x is used to crawl through the sentence table
;y points to wildcardized sentence
try_wildcards
	lda #0 ; set return code to 0
	sta ,u
@lp	lda ,x
	cmpa #$ff  ; hit end?
	beq @x
	jsr cpy_input 
	nop ;is the d.o. in the sentence a * (254)?
	lda 1,x
	cmpa #254
	bne @c
    sta wildcardized+1	; replace with *
@c  lda 3,x
	cmpa #254
	bne @c2
    sta wildcardized+3 	; replace with *	 
@c2 nop ; input sentence is now wildcardized
	ldb #0
	ldy #wildcardized
@l2	lda b,x  ;get a byte from table
	cmpa b,y ;compare it to sentence
	bne @c3   ;if no match, continue
	incb
	cmpb #4  ;done?
	bne @l2  ;loop
	nop ; if got here sentence matches
	jsr [4,x]
	lda #1		;put a 1 on return stack
	sta handled
	sta ,u
	bra @x
@c3 leax 6,x	; entries are 6 bytes
	bra @lp	
@x	rts

;moves the sentences into 
;a temp area to be 'wildcardized'
cpy_input
	lda sentence
	sta wildcardized
	lda sentence+1
	sta wildcardized+1
	lda sentence+2
	sta wildcardized+2
	lda sentence+3
	sta wildcardized+3
	rts
	
;temp storage for wildcardized sentence
wildcardized .byte 0
		.byte 0
		.byte 0
		.byte 0

table .word 0
handled .byte 0
		