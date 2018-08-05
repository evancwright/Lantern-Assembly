;scoring6502.asm
;scoring6502.asm


;loops over every object in the obj_word_table
;if the word id stored in WordId maps to it,
;the object is scored
	.module score_objects
score_objects
	ldy #0
	lda #$obj_word_table%256
	sta $tableAddr
	lda #$obj_word_table/256
	sta $tableAddr+1
_lp	
	ldy #0
	lda ($tableAddr),y
	cmp #255
	beq _x
 	sta objToScore
	;does the word apply to the object
	jsr does_wrd_match_obj ; 
	lda wordIdMatch
	cmp #0
	beq _n
	jsr score_object
	jmp _c
_n	ldy objToScore
	lda #INVALID
	sta scores,y
_c	jsr inc_tabl_addr 
	jsr inc_tabl_addr
	jsr inc_tabl_addr
	jsr inc_tabl_addr
	jmp _lp
_x	rts


;scores each object in objectwordtable
;using the word id stored in objToScore
;and puts the score in the score table
;precondition: wordId is set, scores zeroed out (if this is the first pass)
;postcondition: scores are set
		.module score_object
score_object
		ldx objToScore
		lda scores,x
		cmp #INVALID ; don't score objects previously marked as INVALID
		beq _x
		inc scores,x ; give potential matches 1 point  
 		jsr get_player_room 
		sta parent
		ldx objToScore ; reload to be safe
		stx child
		jsr visible_ancestor ; can player see it?
		lda visibleAncestorFlag
		cmp #0
		beq _x
		ldx objToScore ; reload object id
		inc scores,x  ; add one more to the score
_x		rts


;sets all scores to 0
;clear maxScoreObj 
	.module clear_scores
clear_scores
	lda #255
	sta maxScoreObj 
	lda #0
	ldy #0
_lp
	sta scores,y
	iny
	cpy $NumObjects
	bne _lp
	rts



	.module get_max_score
get_max_score
	ldy #0
	sty maxScore
_lp
	lda scores,y
	cmp #INVALID
	beq _s
  	cmp maxScore
	bcc _c  ; jmp on <=
	sta maxScore
	sty maxScoreObj
	jmp _c
_s  lda #0
	sta  scores,y ; set INVALID score to 0
_c	
	iny
	cpy $NumObjects
	bne _lp	
	rts

;counts the number of objects with the max score	
	.module get_max_count
get_max_count
	ldy #0
	sta maxScoreCount
_lp
	lda scores,y
	cmp maxScore
	bne _s  ; jmp on <=
	inc maxScoreCount	
_s	
	iny
	cpy $NumObjects
	bne _lp	
	rts



;sets wordIdMatch to 1 if the word stored else 0
;in WordId matches ObjId
;loop is needed to check for synonyms
	.module does_wrd_match_obj
does_wrd_match_obj
	pha
	tax
	pha
	tay
	pha
 	;save curr table addr
	lda $tableAddr
	pha
	lda $tableAddr+1
	pha
	lda #0 ; loop counter
	;set table to obj_word_table
	lda #obj_word_table%256
	sta $tableAddr
	lda #obj_word_table/256
	sta $tableAddr+1
_lp ldy #0
	lda ($tableAddr),y
	cmp #255
	beq _n
	cmp $objToScore
	bne _s
 	ldy #1
	lda ($tableAddr),y
	cmp $wordId
	beq _y
	ldy #2
	lda ($tableAddr),y
	cmp $wordId
	beq _y
	ldy #3
	lda ($tableAddr),y
	cmp $wordId
	beq _y
	;move to next owt table entry
_s	jsr inc_tabl_addr
	jsr inc_tabl_addr
	jsr inc_tabl_addr
	jsr inc_tabl_addr
	jmp _lp
 	;restore table addr
_y	lda #1
	sta wordIdMatch
	jmp _x
_n  lda #0
_x	sta wordIdMatch
	pla
	sta $tableAddr+1
	pla
	sta $tableAddr
	pla
	tay
	pla
	tax
	pla
	rts

;scores all ojects using the words from startIx to endIx
;sets encodeFail to 1 or 0
	.module score_words
score_words	
	lda startIx
_lp ;is the word in the dictionary
	pha ; save loop counter
	tay
	lda wordIndexes,y
	pha ; save index of word
	tay
	jsr set_str_dest
	lda #dictionary%256
	sta $tableAddr
	lda #dictionary/256
	sta $tableAddr+1
	jsr get_word_index
	pla ; pop index
	tay ; y contain index
	lda $strIndex 
	cmp #255
	beq _f
	sta wordId
	jsr set_str_dest
	;match word to objects
	jsr score_objects
	pla ; restore loop counter
	clc
	adc #1
	cmp endIx
	bne _lp
	jmp _x
_f	
	lda #1
	sta encodeFail
	pla ; pop loop counter
	tay
	lda wordIndexes,y
	tay
	jsr bad_word	
_x	rts

	