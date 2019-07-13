;scoring6502.asm
;scoring6502.asm


;loops over every object in the obj_word_table
;if the word id stored in WordId maps to it,
;the object is scored
	 
score_objects
	ldy #0
	lda #<obj_word_table
	sta tableAddr
	lda #>obj_word_table
	sta tableAddr+1
	lda #0
	pha ; push loop counter
:lp	
	pla ; restore loop counter
	cmp NumObjects
	beq :x
	clc
	adc #1
	pha ; save loop counter
	ldy #0
	lda (tableAddr),y
 	sta objToScore
	;does the word apply to the object
	jsr does_wrd_match_obj ; 
	lda wordIdMatch
	cmp #0
	beq :n
	jsr score_object
	jmp :c
:n	ldy objToScore
	lda #INVALID
	sta scores,y
:c	jsr inc_tabl_addr 
	jsr inc_tabl_addr
	jsr inc_tabl_addr
	jsr inc_tabl_addr
	jmp :lp
:x	rts


;scores each object in objectwordtable
;using the word id stored in objToScore
;and puts the score in the score table
;precondition: wordId is set, scores zeroed out (if this is the first pass)
;postcondition: scores are set
		 
score_object
		ldx objToScore
		lda scores,x
		cmp #INVALID ; don't score objects previously marked as INVALID
		beq :x
		inc scores,x ; give potential matches 1 point  
 		jsr get_player_room 
		sta parent
		ldx objToScore ; reload to be safe
		stx child
		jsr visible_ancestor ; can player see it?
		lda visibleAncestorFlag
		cmp #0
		beq :x
		ldx objToScore ; reload object id
		inc scores,x  ; add one more to the score for visible things
:x		rts


;sets all scores to 0
;clear maxScoreObj 
	 
clear_scores
	lda #255
	sta maxScoreObj 
	lda #0
	ldy #0
:lp
	sta scores,y
	iny
	cpy NumObjects
	bne :lp
	rts

 
get_max_score
	ldy #0
	sty maxScore
:lp	lda scores,y
	cmp #INVALID
	beq :s
  	cmp maxScore
	bcc :c  ; jmp on <=
	sta maxScore
	sty maxScoreObj
	jmp :c
:s  lda #0
	sta  scores,y ; set INVALID score to 0
:c  iny
	cpy NumObjects
	bne :lp	
	rts

;counts the number of objects with the max score	
 
get_max_count
	ldy #0
	sty maxScoreCount
:lp lda scores,y
	cmp maxScore
	bne :s  ; jmp on <=
	inc maxScoreCount	
:s	iny
	cpy NumObjects
	bne :lp	
	rts
 

;sets wordIdMatch to 1 if the word stored else 0
;in WordId matches ObjId
;loop is needed to check for synonyms
 
does_wrd_match_obj
	pha
	tax
	pha
	tay
	pha
 	;save curr table addr
	lda tableAddr
	pha
	lda tableAddr+1
	pha
	lda #0 ; loop counter
	;set table to obj_word_table
	lda #<obj_word_table
	sta tableAddr
	lda #>obj_word_table
	sta tableAddr+1
:lp ldy #0
	lda (tableAddr),y
	cmp #255
	beq :n
	cmp objToScore
	bne :s
 	ldy #1
	lda (tableAddr),y
	cmp wordId
	beq :y
	ldy #2
	lda (tableAddr),y
	cmp wordId
	beq :y
	ldy #3
	lda (tableAddr),y
	cmp wordId
	beq :y
	;move to next owt table entry
:s	jsr inc_tabl_addr
	jsr inc_tabl_addr
	jsr inc_tabl_addr
	jsr inc_tabl_addr
	jmp :lp
 	;restore table addr
:y	lda #1
	sta wordIdMatch
	jmp :x
:n  lda #0
:x	sta wordIdMatch
	pla
	sta tableAddr+1
	pla
	sta tableAddr
	pla
	tay
	pla
	tax
	pla
	rts

;scores all ojects using the words from startIx to endIx
;sets encodeFail to 1 or 0
	 
score_words	
	lda startIx
:lp ;is the word in the dictionary
	pha ; save loop counter
	tay
	lda wordIndexes,y
	pha ; save index of word
	tay
	jsr set_str_dest
	lda #<dictionary
	sta tableAddr
	lda #>dictionary
	sta tableAddr+1
	jsr get_word_index
	pla ; pop index
	tay ; y contain index
	lda strIndex 
	cmp #255
	beq :f
	sta wordId
	jsr set_str_dest
	;match word to objects
	jsr score_objects
	pla ; restore loop counter
	clc
	adc #1
	cmp endIx
	bne :lp
	jmp :x
:f	
	lda #1
	sta encodeFail
	pla ; pop loop counter
	tay
	lda wordIndexes,y
	tay
	jsr bad_word	
:x	rts

	