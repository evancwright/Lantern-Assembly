 ;6502 parser
 

parse
	jsr strtok
	jsr compact_verb
	jsr validate_verb
	lda encodeFail
	cmp #1
	bne :c
	rts
:c	lda #1  ; if only a verb, done
	cmp numWords  
	bne :d
	rts
:d	jsr find_prep_index
	lda prepIndex
	cmp #255
	beq :np ; one noun
	;there are two nouns (score noun1)
	lda #1
	sta startIx
	lda prepIndex
	sta endIx
	jsr score_words
	;did the scoring work? (if not return)
	lda encodeFail
	cmp #1
	beq :x
	jsr disambigute
	lda maxScoreObj
	sta dobjId
	lda encodeFail
	cmp #1
	beq :x
	;score noun 2
	lda prepIndex
	clc
	adc #1
	sta startIx
	;was the second noun supplied
	lda numWords
	cmp startIx
	bne :s
	lda #<missingDobj
	sta strAddr
	lda #>missingDobj
	sta strAddr+1
	jsr printstrcr
	lda #1
	sta encodeFail
	rts
:s	sta endIx
	jsr score_words
	jsr disambigute
	lda maxScoreObj
	sta iobjId
	jmp :x
:np	;only one noun
	jsr clear_scores
	lda #1
	sta startIx
	lda numWords
	sta endIx
	jsr score_words
	lda encodeFail
	cmp #1
	beq :x
	jsr disambigute
	lda maxScoreObj
	sta dobjId 
:x	rts

 
validate_verb
	lda #<verbBuffer
	sta strDest
	lda #>verbBuffer
	sta strDest+1
	lda #<verb_table
	sta tableAddr
	lda #>verb_table  ; set up table to search
	sta tableAddr+1
	jsr get_entry_id	; result to word1 ; searches table for string stored in strdest
	lda wrdId
	sta verbId
	cmp #255
	bne :x
	lda #1
	sta encodeFail
	jsr bad_verb
:x	rts

;this is not a function! it must
;pull all the regs pushed by encode_sentence
bad_verb
		lda #1
		sta encodeFail
 		lda #<badverb	 ;print "I don't know the verb '"
		sta strAddr
		lda #>badverb
		sta strAddr+1		
		jsr printstr
		lda #<verbBuffer
		sta strAddr
		lda #>verbBuffer
		sta strAddr+1
		jsr printstr ;  'print the verb'
		lda #<endquote
		sta strAddr
		lda #>endquote
		sta strAddr+1		
		jsr printstrcr
		rts

;prints 'I DON'T RECOGNIZE THE WORD '...'
;the index of the unknown word is in 'y'
bad_word
		tya
		pha
		lda #1
		sta encodeFail
		lda #<badword	 ;print "I DONT' RECOGNIZE"...
		sta strAddr
		lda #>badword
		sta strAddr+1		
		jsr printstr
		pla
		tay
		jsr set_str_dest
		lda strDest
		sta strAddr
		lda strDest+1
		sta strAddr+1
		jsr printstr ;   print the unrecognized word
		lda #<endquote
		sta strAddr
		lda #>endquote
		sta strAddr+1		
		jsr printstr
		jsr printcr
		rts

find_prep_index
	lda #255
	sta prepIndex
	lda #0
:lp	pha ; save loop counter
	tay
	lda wordIndexes,y
	tay
	jsr set_str_dest
	jsr is_prep2
	pla ; restore loop counter
	ldy strIndex 
	cpy #255 
	bne :y
	clc
	adc #1
	cmp numWords
	beq :x
	jmp :lp
:y	sta prepIndex
	lda strIndex
	sta prepId 
:x	rts
	

;sets strDest to kbdbuf+y
;y contains index
	 
set_str_dest
	lda #<kbdbuf
	sta strDest
	lda #>kbdbuf
	sta strDest+1
	clc
	tya
	adc strDest
	sta strDest
	lda #0
	adc strDest+1
	sta strDest+1
	rts

;sticks a space on the end of the string buffer
append_space
	ldy #0
:lp	lda verbBuffer,y
	cmp #0
	beq :x
	iny
	jmp :lp
:x	lda #' '
	sta verbBuffer,y
	rts

compact_verb
 	lda numWords
	cmp #0
	beq :d
	ldy wordIndexes
	jsr set_str_dest  ; put src addr in strDest
	lda strDest
	sta strSrc
	lda strDest+1
	sta strSrc+1
	lda #<verbBuffer ; set destination
	sta strDest
	lda #>verbBuffer
	sta strDest+1
	jsr strcpy  	;copy word[0] to buffer
	lda numWords ; are we done?
	cmp #1
	beq :d	
	ldy wordIndexes+1
 	jsr is_prep2
	lda strIndex
	cmp #255
	beq :d
	jsr append_space  ; put a ' '
	ldy #1
	lda wordIndexes,y	; get wordIndex,y
	tay
	jsr set_str_dest
	lda strDest
	sta strSrc
	lda strDest+1
	sta strSrc+1
	lda #<verbBuffer ; set destination
	sta strDest
	lda #>verbBuffer
	sta strDest+1
	jsr strcat  ; copy prep onto verb 
	;shift all the pointer (indexes) down
	ldy #2
:s	cpy numWords
	beq :o
	lda wordIndexes,y
	dey 
	sta wordIndexes,y
	iny
	iny
	jmp :s
:o	dec numWords
:d  rts

	
;positions endIx at the character just past the current word	
;at a space or null
seek_end
	ldy startIx
:lp	lda kbdbuf,y
	cmp #' '
	beq :x
	cmp #0
	beq :x
	iny
	jmp :lp
:x	sty endIx
	rts

;positions startIx at the first char after a space
seek_start
	ldy startIx
:lp	lda kbdbuf,y
	cmp #' '
	bne :x
	iny
	jmp :lp
:x	sty startIx
	rts

;builds the table of word pointers based on the 
;keyboard buffer.  Articles are filtered out.
strtok
	lda #0
    sta wordIndexes  ; wordIndexes[0] = 0; //the start
	lda #0
	sta numWords
	ldy #0
	sty startIx
	sty endIx
	jsr seek_start ; position at 1st word
:lp	jsr seek_end
	ldy endIx   
	lda kbdbuf,y
	pha  ; save last char
	lda #0		;null terminate word
	sta kbdbuf,y  
	;was the word an article?
	;if so, ignore it
	ldy startIx
	jsr is_article2 ;  is it 'noise'?
	ldy endIx
	lda strIndex
	cmp #255
	bne :s
	lda startIx    ; store start index in table
	ldy numWords
	sta wordIndexes,y
	inc numWords
:s	lda endIx   ; start = end
	sta startIx  
 	inc startIx  ; move past null
	jsr seek_start ; move to next word
	;[startIx] is a null,done
	pla  ; get ' ' or null
	cmp #0
	beq :x
	jmp :lp
:x	;save final word
	lda #0
	ldy endIx
	sta kbdbuf,y
	rts

 	
	
;tests if the word at kbdbuf[y] is an article	
;y contains the index into the keyboard buffer
;preserves a and y

is_article2
	pha
	tya
	pha
	jsr set_str_dest ; puts kbdbuf[y] into strdest
	lda #>article_table  ; set up table to search
	sta tableAddr+1
	lda #<article_table
	sta tableAddr
	jsr get_word_index ; searches table for string stored in strdest
	pla
	tay
	pla
	rts
	
;sets strIndex to the index of the
;word in keybd,1 is in the prep table or
;255 if not found
;assumes word is null terminated
;article
 
is_prep2
		jsr set_str_dest
  		lda #<prep_table
		sta tableAddr
		lda #>prep_table  ; set up table to search
		sta tableAddr+1
		jsr get_word_index
  		rts		
		

;checks if a noun mapped to more than 1 object
;set encodeFail to 1 on fail	
 
disambigute
	jsr get_max_score
	jsr get_max_count
	lda maxScoreCount
	cmp #1
	beq :x
	lda #1
	sta encodeFail
	lda #<ambig
	sta strAddr
	lda #>ambig
	sta strAddr+1
	jsr printstrcr
:x	rts
		
;clr_buffr
;sets page to all 0s
;registers are not preserved
 
clr_buffr
		ldy #0
		lda #0
:lp		sta kbdbuf,y
		iny
		cpy #255
		beq :x
		jmp :lp
:x		ldy #0
		lda #0
:lp2	sta verbBuffer,y
		iny
		cpy #20
		beq :y
		jmp :lp2
:y		lda #255
		sta sentence
		sta sentence+1
		sta sentence+2
		sta sentence+3
		rts
		
 
;fixes digits in apple 2 char set
;char in a

fix_digits
	   cmp #176
	   beq :f
	   cmp #177
	   beq :f
	   cmp #178
	   beq :f
	   cmp #179
	   beq :f
	   cmp #180
	   beq :f	
	   cmp #181
	   beq :f	   
	   cmp #182
	   beq :f	   
	   cmp #183
	   beq :f	   
	   cmp #184
	   beq :f	   
	   cmp #185
	   beq :f	   
	   jmp :x
:f	   sec
	   sbc #128
	   sta kbdbuf,y
:x	   rts

;sets encodeFail to 1 and prints the error message
dont_see
		lda #1
		sta encodeFail
		lda #<dontsee	 ;print "YOU DON'T SEE THAT."
		sta strAddr
		lda #>dontsee
		sta strAddr+1		
		jsr printstrcr
		rts

no_input
		lda #<pardon
		sta strAddr
		lda #>pardon
		sta strAddr+1
		jsr printstrcr
		rts 
		
ambig	ASC 'I don',27,'t know which one you mean.'
	DB 0	 	
	

pardon  ASC 'Pardon?'
	DB 0
badword  ASC 'I don',27,'t know the word '
	DB 27
	DB 0
badverb ASC 'I don',27,'t know the verb ',27
	DB 0
dontsee ASC 'You don',27,'t see that here.'
	DB 0
endquote 
	ASC 27
	DB 27
	ASC '. '
	DB	0
	 


scores DS 128,0  ; WASTEFUL! FIX LATER
numWords		DB 0
maxScoreCount	DB 0
maxScore 		DB 0
maxScoreObj 	DB 0
wordId		 	DB 0	
wordIdMatch 	DB 0	
objToScore		DB 0	
startIx			DB 0	
endIx			DB 0	
prepIndex		DB 0
encodeFail		DB 0
wordIndexes DS 12,0
verbBuffer DS 20,0
sentence 
verbId	DB 255
dobjId	DB 255
prepId	DB 255
iobjId	DB 255
