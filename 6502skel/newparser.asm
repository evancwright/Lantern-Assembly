 ;6502 parse
 

	
	.module parse
parse
	jsr strtok
	jsr compact_verb
	jsr validate_verb
	lda encodeFail
	cmp #1
	bne _c
	rts
_c	lda #1  ; if only a verb, done
	cmp numWords  
	bne _d
	rts
_d	jsr find_prep_index
	lda prepIndex
	cmp #255
	beq _np ; one noun
	;there are two nouns (score noun1)
	lda #1
	sta startIx
	lda $prepIndex
	sta endIx
	jsr score_words
	;did the scoring work? (if not return)
	lda encodeFail
	cmp #1
	beq _x
	jsr disambigute
	lda maxScoreObj
	sta dobjId
	lda encodeFail
	cmp #1
	beq _x
	;score noun 2
	lda prepIndex
	clc
	adc #1
	sta startIx
	;was the second noun supplied
	lda $numWords
	cmp startIx
	bne _s
	lda #$missingDobj%256
	sta strAddr
	lda #$missingDobj/256
	sta strAddr+1
	jsr printstrcr
	lda #1
	sta encodeFail
	rts
_s	sta endIx
	jsr score_words
	jsr disambigute
	lda maxScoreObj
	sta iobjId
	jmp _x
_np	;only one noun
	jsr clear_scores
	lda #1
	sta startIx
	lda $numWords
	sta endIx
	jsr score_words
	lda encodeFail
	cmp #1
	beq _x
	jsr disambigute
	lda maxScoreObj
	sta dobjId 
_x	rts

	.module validate_verb
validate_verb
	lda #$verbBuffer%256
	sta strDest
	lda #$verbBuffer/256
	sta strDest+1
	lda #verb_table%256
	sta $tableAddr
	lda #verb_table/256  ; set up table to search
	sta $tableAddr+1
	jsr get_entry_id	; result to word1 ; searches table for string stored in strdest
	lda $wrdId
	sta verbId
	cmp #255
	bne _x
	lda #1
	sta encodeFail
	jsr bad_verb
_x	rts

;this is not a function! it must
;pull all the regs pushed by encode_sentence
bad_verb
		lda #1
		sta encodeFail
 		lda #badverb%256	 ;print "I don't know the verb '"
		sta $strAddr
		lda #badverb/256
		sta $strAddr+1		
		jsr printstr
		lda #verbBuffer%256
		sta $strAddr
		lda #verbBuffer/256
		sta $strAddr+1
		jsr printstr ;  'print the verb'
		lda #endquote%256
		sta $strAddr
		lda #endquote/256
		sta $strAddr+1		
		jsr printstrcr
		rts

;prints 'I DON'T RECOGNIZE THE WORD '...'
;the index of the unknown word is in 'y'
bad_word
		tya
		pha
		lda #1
		sta encodeFail
		lda #badword%256	 ;print "I DONT' RECOGNIZE"...
		sta $strAddr
		lda #badword/256
		sta $strAddr+1		
		jsr printstr
		pla
		tay
		jsr set_str_dest
		lda $strDest
		sta $strAddr
		lda $strDest+1
		sta $strAddr+1
		jsr printstr ;   print the unrecognized word
		lda #endquote%256
		sta $strAddr
		lda #endquote/256
		sta $strAddr+1		
		jsr printstrcr
		rts


	
	.module find_prep_index
find_prep_index
	lda #255
	sta prepIndex
	lda #0
_lp	
	pha ; save loop counter
	tay
	lda wordIndexes,y
	tay
	jsr set_str_dest
	jsr is_prep2
	pla ; restore loop counter
	ldy strIndex 
	cpy #255 
	bne _y
	clc
	adc #1
	cmp $numWords
	beq _x
	jmp _lp
_y	sta prepIndex
	lda $strIndex
	sta prepId 
_x	rts
	

;sets strDest to kbdbuf+y
;y contains index
	.module set_str_dest
set_str_dest
	lda #kbdbuf%256
	sta strDest
	lda #kbdbuf/256
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
	.module append_space
append_space
	ldy #0
_lp	lda $verbBuffer,y
	cmp #0
	beq _x
	iny
	jmp _lp
	lda #' '
	sta $verbBuffer,y
_x	rts

	
	.module compact_verb
compact_verb
 	lda $numWords
	cmp #0
	beq _d
	ldy wordIndexes
	jsr set_str_dest  ; put src addr in strDest
	lda strDest
	sta strSrc
	lda strDest+1
	sta strSrc+1
	lda #$verbBuffer%256 ; set destination
	sta $strDest
	lda #$verbBuffer/256
	sta $strDest+1
	jsr strcpy  	;copy word[0] to buffer
	ldy wordIndexes+1
 	jsr is_prep2
	lda strIndex
	cmp #255
	beq _d
	jsr append_space  ; put a ' '
	ldy #1
	lda wordIndexes,y	; get wordIndex,y
	tay
	jsr set_str_dest
	jsr strcat  ; copy prep onto verb 
_d  rts

	
;positions endIx at the character just past the current word	
;at a space or null
	.module seek_end
seek_end
	ldy startIx
_lp	lda kbdbuf,y
	cmp #' '
	beq _x
	cmp #0
	beq _x
	iny
	jmp _lp
_x	sty endIx
	rts

;positions startIx at the first char after a space
	.module seek_start
seek_start
	ldy startIx
_lp
	lda kbdbuf,y
	cmp #' '
	bne _x
	iny
	jmp _lp
_x
	sty startIx
	rts

;builds the table of word pointers based on the 
;keyboard buffer.  Articles are filtered out.
	.module strtok
strtok
	lda #0
    sta wordIndexes  ; wordIndexes[0] = 0; //the start
	lda #0
	sta numWords
	ldy #0
	sty startIx
	sty endIx
	jsr seek_start ; position at 1st word
_lp	
	jsr seek_end
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
	lda strIndex;
	cmp #255
	bne _s
	lda startIx    ; store start index in table
	ldy numWords
	sta wordIndexes,y
	inc numWords
_s	
	lda endIx   ; start = end
	sta startIx  
 	inc startIx  ; move past null
	jsr seek_start ; move to next word
	;[startIx] is a null,done
	pla  ; get ' ' or null
	cmp #0
	beq _x
	jmp _lp
_x	;save final word
	lda #0
	ldy endIx
	sta kbdbuf,y
	rts

 	
	
;tests if the word at kbdbuf[y] is an article	
;y contains the index into the keyboard buffer
;preserves a and y
	.module is_article2
is_article2
	pha
	tya
	pha
	jsr set_str_dest ; puts kbdbuf[y] into strdest
	lda #article_table/256  ; set up table to search
	sta $tableAddr+1
	lda #article_table%256
	sta $tableAddr
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
	.module is_prep2
is_prep2
		jsr set_str_dest
  		lda #prep_table%256
		sta $tableAddr
		lda #prep_table/256  ; set up table to search
		sta $tableAddr+1
		jsr get_word_index
  		rts		

;converts apple text to ascii
;addr to convert is in strSrc
;registers are preserved
	.module toascii
toascii
		pha
		tay
		pha
		ldy #0
_lp		lda $200,y
		jsr fix_digits
		cmp #$8D
		bne _s
		lda #0
		sta $200,y
		jmp _x
_s		cmp #0
		beq _x
		cmp #$A0 ; space?
		bne _g
		lda #$20
		jmp _h
_g		cmp #$C1  'A'
		bcc _c  ; < a
		cmp #$DB  ; 'Z'+1
		bcs _c ; > 'Z'
		and #$3F
		clc
		adc #64
_h		sta $200,y
_c		iny 
		jmp _lp 
_x		pla
		tay
		pla
		rts

;checks if a noun mapped to more than 1 object
;set encodeFail to 1 on fail	
	.module disambigute
disambigute
	jsr get_max_score
	jsr get_max_count
	lda maxScoreCount
	cmp #1
	beq _x
	lda #1
	sta encodeFail
	lda #ambig%256
	sta strAddr
	lda #ambig/256
	sta strAddr+1
	jsr printstrcr
_x	rts
		
;clr_buffr
;sets page to all 0s
;registers are not preserved
	.module clr_buffr
clr_buffr
		ldy #0
		lda #0
_lp		sta kbdbuf,y
		iny
		cpy #255
		beq _x
		jmp _lp
_x		ldy #0
		lda #0
_lp2	sta verbBuffer,y
		iny
		cpy #20
		beq _y
		jmp _lp2
_y		
		lda #255
		sta sentence
		sta sentence+1
		sta sentence+2
		sta sentence+3
		rts
		
 
;fixes digits in apple 2 char set
		;char in a
		.module fix_digits
fix_digits
	   cmp #176
	   beq _f
	   cmp #177
	   beq _f
	   cmp #178
	   beq _f
	   cmp #179
	   beq _f
	   cmp #180
	   beq _f	
	   cmp #181
	   beq _f	   
	   cmp #182
	   beq _f	   
	   cmp #183
	   beq _f	   
	   cmp #184
	   beq _f	   
	   cmp #185
	   beq _f	   
	   jmp _x
_f	   sec
	   sbc #128
	   sta kbdbuf,y
_x	   rts

;sets encodeFail to 1 and prints the error message
dont_see
		lda #1
		sta encodeFail
		lda #dontsee%256	 ;print "YOU DON'T SEE THAT."
		sta $strAddr
		lda #dontsee/256
		sta $strAddr+1		
		jsr printstrcr
		rts

no_input
		lda #$pardon%256
		sta strAddr
		lda #$pardon/256
		sta strAddr+1
		jsr printstrcr
		rts 
		
ambig	.db "I DON'T KNOW WHICH ONE YOU MEAN.", 0	 	
;kbdbuf	.text "PUT THE SWORD IN THE BOX",0	
	.db 0


pardon  .db "PARDON?",0h
badword  .db "I DON'T KNOW THE WORD '", 0h
badverb .db "I DON'T KNOW THE VERB '", 0h
dontsee .db "YOU DON'T SEE THAT."
	.db 0
endquote .db "'"
	.db 0


scores .fill 128,0  ; WASTEFUL! FIX LATER
numWords		.db 0
maxScoreCount	.db 0
maxScore 		.db 0
maxScoreObj 	.db 0
wordId		 	.db 0	
wordIdMatch 	.db 0	
objToScore		.db 0	
startIx			.db 0	
endIx			.db 0	
prepIndex		.db 0
encodeFail		.db 0
wordIndexes .fill 12,0
verbBuffer .fill 20,0
sentence 
verbId	.db 255
dobjId	.db 255
prepId	.db 255
iobjId	.db 255

	.end