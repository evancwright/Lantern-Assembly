;formatted printing routines
;formatted printing routines

POLLKB	EQU $A000 ; VECTOR TO KBSCAN
CRSADDR EQU 0x0088 ; 2 byte addr of cursor
;addr of string is in X
printstrf
	lda #0  ; set line counter to 0
	sta linecntr
@lp
	lda ,x
	cmpa #0 ; don't print str 0?
	beq @out
	;compute remaining space
	lda scrwidth
	suba curscol
	sta charsleft
	jsr wordlen ; len -> A
	cmpa charsleft
	bcc @nl ; word len < charsleft
	jsr printchars ; len still in A
	bra @lp ; back to top
@nl ;print a newline
	inc linecntr
	pshs d ; save len
	jsr PRINTCR
 	lda linecntr
	cmpa printheight ; printed a whole screen?
	bne @p
	;reached last line
	;jsr moreprmpt ; prompt and cls
	lda #0
	sta linecntr ; reset line counter to m
@p	;now actually print the word
	puls d ; restore len
	jsr printchars ; len still in A
	bra @lp ; back to top
@out	
	jsr poscursor
	rts

poscursor
	pshs d,x
	lda cursrow
	ldb scrwidth
	mul
	addb curscol
	adca #0
	tfr d,x
	leax $400,x
	stx CRSADDR
	puls x,d
	rts
	
;prints a "more" prompt, then clears the screen
moreprmpt
	pshs d,x,y
	;move to bottom left
	lda #0
	sta curscol
	lda scrheight
	deca
	sta	 cursrow 
	ldx #more
	jsr printstr
@kb	jsr [POLLKB]  ; PUTS KEYCODE INTO A - 0 = NO KEY 	
	beq @kb	
	jsr scroll
	puls y,x,d 
	rts	

;string in x
;prints until null, no formatting
;called by printstrf
printstr
@lp
	lda ,x+
	cmpa #0
	beq @x
	jsr charout
	bra @lp
@x	rts
	
;X contains start of word
;returns word length in A
;counts the word plus trailing white space
;X is not changed
wordlen
	pshs x
	lda #0
@lp 
	ldb ,x+
	cmpb #' '
    beq @in
	cmpb #0 ; null?
    beq @out
	inca 
	bra @lp
	;now count trailing spaces
@in	
	inca
@lp1 
	ldb ,x+
	cmpb #' '
    bne @out ; hit next word
	inca
	bra @lp1
@out	
	puls x
	rts


;prints word 
;A contains len
;X points to data and is updated
printchars
	tfr a,b
	cmpa #0
	beq @x
@lp	lda ,x+
	jsr charout
	decb
	bne @lp
@x	rts
	
;A contains char to print
;Cursor col is incremented
;lowercase is converted to uppercase
;chars 32-64 have to have 64 added to make
;them non-inverse
;if lowercase is not enabled
charout	
	pshs d ; save char
	pshs d ; save char
	lda cursrow
	ldb scrwidth
	mul
	addb curscol
	adca #0
	tfr d,y
	puls d ; restore char
	ldb lcase
	cmpb #1	
	beq @pr
 	cmpa #31  ; < #31 
	bcs @pr
	cmpa #64  
	bcc @pr   ; > 64?
; 	cmpa #96
;	bcs @p
;	cmpa #128
;	bcc @p
;	suba #32 ; convert it to uppercase
;	bra @p
@ad adda #64	
@pr	;cmpa #32
    ;bne @q
	;lda #96
@q	sta 1024,y 
	lda curscol
	inca
	sta curscol
	jsr	poscursor

	puls d
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CLS
;CLEARS SCREEN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cls
	pshs d,x,y  ; save registers
 	lda #96 ; blank space 	
	ldy #0 ; loop counter
	ldx #1024 ; start of VRAM (400h)
@a 	sta ,x+
	leay 1,y	; inc loop counter
	cmpy scrsize  ; bottom of screen?
	bne @a
	;reset cursor
	lda #0
	sta curscol
	lda #1
	sta cursrow
	jsr poscursor
	puls y,x,d  ; restore registers
	rts

;print a cr
;scrolls if needed
PRINTCR
	pshs d,x,y
	lda #0 ; reset column to 0
	sta curscol
	;if we're on the last line,
	;scroll, otherwise inc curscol
	lda cursrow
	cmpa lastline ; last line?
	bne @inc ; no, drop down
	jsr scroll ; yes, scroll
	bra @s
@inc
	inca 
@s	sta cursrow
	bne @x
	;reached last line
@x	jsr poscursor
	puls y,x,d  ; restore registers
	rts
	
;scrolls the screen one line
;no registers are affected
scroll
	pshs d,x,y
	lda #0
	ldb scrwidth
	tfr d,x ; dest row
	leax 1024,x   
	lslb ; b *= 2
	tfr d,y ; src
	leay 1024,y 
	pshs y ; now compute # of chars to copy
	lda scrheight ; there are h-2rows to copy
	ldb scrwidth
	mul
	tfr d,y ; y is last char addr
	leay 1024,y ; turn it into and addr
	sty lastchar ; store result
	puls y
@lp 
	cmpy lastchar
	beq @dn
	lda ,y+ 
	sta ,x+
	bra @lp	
@dn	;now zero out the last line
;x contains addr to copy into
	ldb #96 ; space
	lda #0
@l2	stb ,x+
	inca 
	cmpa scrwidth
	beq @x
	bra @l2
@x	;set cursor column back to 0
	lda #0
	sta curscol
	lda scrheight ; last line
	deca 
	sta cursrow
	puls y,x,d
	rts 
	
	
scrsize .word 512	
cursrow .byte 1
curscol .byte 0
charsleft .byte 32
printheight .byte 22
linecntr  .byte 0
more .strz "-MORE-"
