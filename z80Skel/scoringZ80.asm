;zeroes out all the scores
*MOD
clear_scores
	ret

;scores all the words from startIx to endIx
*MOD
score_words
	ld	a,(startIx)
	ld (tempIndex)a,
$lp?  ;;is the word in the dictionary
 	ld ix,wordPtrs ; get the i-th word pointer
	ld d,0
	ld a,(tempIndex)
	ld e,a
 	add ix,de ; ix now has address of word
	ld iy,dictionary  ; table to search
	jsr get_table_index
	ld a,255
	cp b
	jp z, $f?
	ld a,b  ;store word id so we can score it
	ld (wordId),a
	;match word to objects
	call score_objects
	ld hl,tempIndex	;increment search index
	inc (hl)
	ld a,(hl)
	ld hl,(endIx) ;did we hit end of words to score?
	cmp (hl)
	jp nz,$lp?
	jp $x?
$f?	
	ld a,1
	ld (encodeFail),a
 	jsr bad_word	; what is the src
$x?
	ret
	
;checks if a noun mapped to more than 1 object
;set encodeFail to 1 on fail	
*MOD
disambigute
	call get_max_score
	call get_max_count
	ld a,(maxScoreCount)
	cp 1
	jp z,$x?
	ld a,1
	ld (encodeFail),1
	ld hl,whichone
	call OUTLINCR
$x?	ret

;sets the score for the best match	
*MOD
get_max_score
	ld a,0
	ld (maxScore),a
	ld ix,0
_lp
	ld	a,(ix_scores)
	cp #INVALID
	jp z,$s?
	ld hl,maxScore
  	cp (hl)
	bcs $c?  ; jmp on <
	jp z,$c? ; jmp on =
	ld (maxScore),a
	;lower byte of ix is the object with the score
	push ix
	pop bc
	ld a,c
	ld (maxScoreObj),a
	jp $c?
$s? ld a,0
	ld (ix+scores),a ; set INVALID score to 0
$c?	inc ix
	push ix;get lo byte of ix
	pop bc
	ld a,c
	ld hl,(NumObjects)
	cp (hl)
	jp nz,$lp?	
	ret

;sets number of	objects who have the max score
*MOD
get_max_count	
	ld a,0
	ld (maxScoreCount),a
	ld ix,scores
$lp?
	ld a,(ix)
	cp maxScore
	jp nz,$s?  ; jmp on <=
	ld hl,maxScoreCount	
	inc (hl)	
$s?	
	inc ix	;hit end of table?
	push ix
	pop bc
	ld a,c
	cp (NumObjects)
	jp nz,$lp?	
	ret

*MOD
;loops over every object in the obj_word_table
;if the word id stored in WordId maps to it,
;the object is scored
*MOD
score_objects
	ld ix,obj_word_table
	ld a,0
	push af ; push loop counter
_lp	
	pop af ; restore loop counter
	cp (NumObjects)
	jp z,$x?
	inc a
	push af  ; save loop counter
	ld a,(ix)
 	ld (objToScore),a
	;does the word apply to the object
	call does_wrd_match_obj ; 
	ld a,(wordIdMatch)
	cp 0
	jp z,$n?
	call score_object
	jp $c?
$n?	ld a,objToScore
	ld d,0
	ld e,a
	ld iy,de
	ld a,INVALID
	ld (iy+scores),a
$c?	inc ix
	inc ix
	inc ix
	inc ix
	jmp $lp?
$x?	ret

*MOD
;sets (some variable) if the word in (worId)
;applies to the object currently in (objToScore)
;loop is needed to check for synonyms
;sets (wordIdMatch) to a 1 or 0
does_wrd_match_obj
	push ix
	ld a,0	;clear flag
	ld (wordIdMatch)
	ld de,4
$lp?
	ld a,(ix) ; get obj id
	cp 255	
	jp z,$n?	;hit end of table
	cp (objToScore)
	jp nz,$c?
	ld a,(ix+1)
	cp (wordId)
	jp z,$y?
	ld a,(ix+2)
	cp (wordId)
	jp z,$y?
	ld a,(ix+3)
	cp (wordId)
	jp z,$y?
$c?	ld de,4		;move to next table entry
	add ix,de
	jp $lp?
$y?	ld a,1
	ld (wordIdMatch),a
$n?	pop ix
	ret

*MOD 
score_object
	ld a,(objToScore)
	ld d,0	 ; turn obj into 2 byte offset
	ld e,a
	ld hl,scores
	add hl,de
	ld a,(hl)
	cp INVALID ; don't score objects previously marked as INVALID
	jp z, $x?
	inc (hl) ; give potential matches 1 point  
	call get_player_room ; result in a
	ld c,a
	ld a,(objToScore)
	ld b,a
	call b_visible_to_c ; result in 'a'
 	cp 0
	jp $x?
	inc (hl)  ; add one more to the score 
$x?	ret
	
tempIndex db 0	
whichone db "I DON'T KNOW WHICH ONE YOU MEAN.",0