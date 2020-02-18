;Z80Parser

;exsists already
;tokenize input
;get verb
;get_verb_id();
;verbId
;numWords
;prepFound
;get_word_id

;tokenize
*MOD
parse
	push de
	push hl
	ld a,0
	ld (ambigFail),a
	ld (wordIdFail),a
	ld a,255		; clear the sentence
	ld (Sentence),a
	ld (Sentence+1),a
	ld (Sentence+2),a
	ld (Sentence+3),a
	call tokenize
	ld a,(TokFail)
	cp 1
	jp z,$x?
;	call dump_words
	call fix_verb
	call get_verbs_id
	ld a,(VerbId)
	cp INVALID
	jp z,$bv?
 	call find_prep
	call map_words
	;ld a,(MapFail)
	;cp 1
;	ld hl,parsedone
;	call OUTLINCR
	jp $x?
$bv?
	ld hl,badverbstr
	call OUTLIN
	ld de,(WordPtrs)
	push de
	pop hl
	call OUTLIN
	ld hl,period
	call OUTLINCR
$x?	pop hl	
	pop de
	ret




; scans the input buffer and builds a table of word pointers
; in WordPtrs and sets NumWords
*MOD
tokenize
		push bc
		push de
		push hl
		push ix
		push iy	
		ld a,0
		ld (hitEnd),a	; hitEnd = 0
		ld (prepFound),a
		ld (NumWords),a
		ld a,0			; TokFail = 0
		ld (TokFail),a
		ld de,0  ; WordIndex = 0
		ld (WordIndex),de
		ld ix,INBUF ; startPtr = WordPtrs
		call move_first ; skip any whitespace to 1st word
		ld a,(ix)
		cp 0
		jr nz,$lp?	 ; what the 1st non space a char?
		ld hl,pardonstr
		call OUTLINCR
		ld a,1			; TokFail = 1
		ld (TokFail),a
		jr $x?
$lp?	call move_to_end
		push iy ; save end ptr
		;is word at ix and article?
		ld iy,article_table
		call get_table_index
		ld a,b
		cp 255
		jp nz,$s?  ; if found in table, don't save it 	
		; save word
		ld hl,WordPtrs ; index = WordPtrs + WordIndex
		ld de,(WordIndex)
 		add hl,de
		push ix
		pop bc
		ld a,c
		ld (hl),a ; WordPtrs[index] = ix // save the word ptr
		inc hl
		ld a,b
		ld (hl),a ; lo-byte
		inc de		; WordIndex++;	
		inc de		; WordIndex++;	
		ld (WordIndex),de
$s?		pop iy  ;  restore end ptr
		ld a,(hitEnd)
		cp 0
		jr nz,$x?  ; if hit_end !=0 -> done
		call move_to_start ; position ix at start of next word 
		jp $lp?
$x?		ld a,(WordIndex)
		sra a
		ld (NumWords),a
		pop iy
		pop ix
		pop hl
		pop de
		pop bc
		ret

;positions ix at the first non-space
*MOD
move_first
$lp?	ld a,(ix)
		cp 20h
		jr nz,$x?
		inc ix
		jr $lp?
$x?	ret


;skips over spaces until ix points
;to a non space
;sets ix	
*MOD
move_to_start
		push af
		push iy
		pop ix
		inc ix
$lp		ld a,(ix)
		cp 20h 		; space?
		jr z,$cnt?	; quit
		cp 0 		; null?
		jr z,$cnt?	; quit
		jr $x?
$cnt?	inc ix		;next char
		jr $lp		;repeat
$x?		push ix	;copy ix to iy
		pop iy	;iy needs to catch up
		pop af
		ret

;Moves iy to the 1st space or null at the end of 
;a word.  
;Sets iy
;if null is hit, hit_end is set to 1
*MOD
move_to_end
			push af
			push ix ; iy=ix
			pop iy
$lp?		ld a,(iy)	; get char
			;call atoupper
			;ld (iy),a
			cp 20h		; space?
			jr z,$x?
			cp 0		; null
			jr z, $he?
			inc iy
			jr $lp?
$he?    	ld a,1
			ld (hitEnd),a
$x?			ld a,0
			ld (iy),a  ; null terminate the word
			pop af
			ret	

			
;if the 2nd word is a prep, concat verb is called			
*MOD
fix_verb
		ld a,(NumWords)
		cp 1
		jp z,$x?
		ld iy,prep_table
		ld ix,(WordPtrs+2)
		call get_table_index ; result in b
		ld a,b
		cp INVALID
		jp z,$x?
;		ld hl,twowordverb
;		call OUTLINCR
		call concat_verb
		;dump verb for debugging
$x?	;	ld hl,verbis
	;	call OUTLINCR
	;	ld hl,(WordPtrs)
	;	call OUTLINCR
		ret
 
;Concats word2 2 onto word 1 then calls shift_down
concat_verb
		push de
		push hl
		push ix					; 2nd word was a prep
		push iy
		ld ix,(WordPtrs)
		call move_to_end
		ld a,20h ; space
		ld (iy),a ; overwrite null with space
		inc iy 	  ;move past space
		ld ix,(WordPtrs+2)
		call strcpyi ; copies ix -> iy
		ld ix,(WordPtrs) ; print verb
		push ix
		pop hl
		;call OUTLINCR
		call shift_down 
		pop iy
		pop ix
		pop hl
		pop de
		ret			

		
;moves all ptrs from WordPtrs[2] down one index and decrements the number of words		
*MOD		
shift_down
		push bc
		push hl
		push ix
		push iy		
		ld a,(NumWords)
		ld c,a
		ld a,1
		ld ix,WordPtrs+2
		ld iy,WordPtrs+4
$lp?	cp c  ; done?
		jr z,$x?
;		ld hl,shifting
;		call OUTLINCR
		ld b,(iy)		; WordPtrs[i] = WordPtrs[i+1] - first byte
		ld (ix),b
		inc ix
		inc iy
		ld b,(iy)		; WordPtrs[i] = WordPtrs[i+1] - second byte		
		ld (ix),b		
		inc ix
		inc iy
		inc a
		jr $lp?
$x?		ld a,(NumWords)	; NumWords--
		dec a			
		ld (NumWords),a
		pop iy
		pop ix
		pop hl
		pop bc
		ret

		
;set PrepIndex, PrepFound, and Sentence+2		
;no registers modified
*MOD
find_prep
		push bc
		push ix
		push iy
		ld a,(NumWords)
		cp 1
		jp z,$x?
		cp 2
		jp z,$x?		
		ld iy,prep_table
		ld ix,WordPtrs+4
		ld a,2
$lp?	ld c,a ; save loop counter
		push ix  ; save word table ptr
		ld a,(ix+1)
		ld h,a
		ld a,(ix)
		ld l,a
		push hl ; word ptr to ix
		pop ix 
		call get_table_index ; result in b
		pop ix ; restore word table ptr
		ld a,b  ; test result of table search
		cp INVALID
		jr z,$c? ; not a prep
;		ld hl,foundPrepStr
;		call OUTLINCR
		ld a,b  ; store prep id
		ld (sentence+2),a
		ld a,c  ; restore loop counter (prep index)
		ld (PrepIndex),a
		ld a,1
		ld (PrepFound),a
		jr $x?   ; done
$c?		ld a,c  ; restore loop counter
		inc ix	; ptr++
		inc ix
		inc a 	; i++
		push af
		ld a,(NumWords)
		ld c,a
		pop af
		cp c
		jp z,$x?
		jr $lp?
$x?		pop iy
		pop ix
		pop bc
		ret

;debug function to dump word table
*MOD
dump_words
		push af
		push bc
		push ix
		push iy
		ld ix,WordPtrs
		ld a,(NumWords)
		ld c,a
		ld a,0
$lp?	ld b,a ; save a
		ld a,(ix+1)
		ld h,a
		ld a,(ix)
		ld l,a	
		call OUTLINCR
		ld a,b ; restore a
		inc a
		inc ix
		inc ix
		cp c ; (NumWords)
		jr z,$x?
		jr $lp?
$x?		pop iy
		pop ix
		pop bc
		pop af
		ret
		



;maps the words to objects to get dobj and iobj
;assumes prepId,verbId have already been found
;sets mapFail to 1 on failure
*MOD
map_words
		push hl
;	/* are there any more words after the verb? */
;	if (NumWords > 1)
		ld a,(numWords)
		cp a,1
		jp z,$nmw? ; equal is not gt
;	{
;		/* is there a prep? */
		;BOOL prep = found_prep(); //sets prepIndex and id
		ld a,(prepFound)
		cp a,0
		jp z,$on? ; one noun
;		if (prep == TRUE)
;		{/* score do and io */			
			;PrepId  = get_prep_id(words[PrepIndex]);
		call score_noun1
	; score words 1 to prepIndex -1 		
	;did the score fail because a word could n't be mapped?
		ld a,(wordIdFail)
		cp a,1
		jp z,$x? ; fail->quit
		ld a,(ambigFail)
		cp a,1 
		jp z,$x? ; fail->quit
$na?	; noun1 was successfully mapped		
		ld a,(MaxScoreObj) ; save noun1
		ld (DobjId),a
		; /*now score noun 2*/
		call score_noun2
		;don't care it if failed. fail flags are set
		jp $x?
;	}				
;IobjId = MaxScoreObj;
;		}
;		else
;		{ /* just score dobj */
$on?		; there is only 1 noun
		call score_only_noun
		jp $x? ; don't worry about fail. flags are set
;		}
$c4?
;		}
;	}
;	return TRUE;
;}
$nmw?   ; now more words
$x? 	pop hl
		ret	

;checks the wordId in b against the objectWord table and scores matches
;if the word doesn't apply to an object
;the score is set to 255
;if the word does apply to an object and the object wasn't previously marked invalid, 1 is added to the score
;scores synonyms as well
;calls inc_score (to check if it is visible as well)
;if object is visible, it is scored higher
;score table.
;Synonyms won't "unscore" and object
;b contains id of word to map to an object
;called from score_words
;calls inc_score
*MOD
score_word
		push bc
		push de
		push hl
		push iy
		ld a,(NumObjects)
		ld c,a  ; end of table
		ld a,0
		ld iy,score_table  ; addr in score table to set / clear
$lp?	ld d,a  ; save loop counter
		call does_wrd_match_obj  ; a = object , b = word  
		cp 0
		jr z,$n? 
 		call inc_score
		jr $c?
$n?		
 		call invalidate_score
$c?		ld a,d  ; restore loop counter
		inc a
		inc iy
		cp c  ; end of table?
		jr nz,$lp?
		pop iy
		pop hl
		pop de
		pop bc
		ret

*MOD
;if the word in B matches the object in A
;A is set to 1, else 0
does_wrd_match_obj
	push bc
	push de
	push hl
	push ix 
	ld c,b  ;word id in c
    ld b,a  ;obj id in b
 	ld de,4
	ld ix,obj_word_table
$lp? 
	ld a,(ix) ; get obj id
	cp 255	
	jr z,$n?	;hit end of table
	cp b
	jr nz,$c?   ; object doesn't match, continue
	ld a,(ix+1)  
	cp c  ; == wordId?
	jr z,$y?
	ld a,(ix+2)
	cp c ; == wordId?
	jr z,$y?
	ld a,(ix+3)
	cp c ; == wordId?
	jr z,$y?
$c?	add ix,de ; de = 4
	jp $lp?
$y?	ld a,b
;	call itoa
;	ld hl,itoabuffer
;	call OUTLIN
;	ld hl,isamatch
;	call OUTLINCR
	ld a,1
	jr $x?
$n?	ld a,0
$x?	pop ix
	pop hl
	pop de
	pop bc
	ret
		
;score all words (for sentences that have no prep)
*MOD
score_only_noun	
;		ld hl,onenoun
;		call OUTLINCR
		ld a,1
		ld (startIndex),a
		ld a,(NumWords)
		dec a
		ld (endIndex),a
		call score_words
		;did it fail because of an unrecognized word?
		ld a,(wordIdFail)
		cp 1
		jp z,$x?
		call disambiguate
		ld a,(ambigFail)
		cp a,1
		jp z,$x?
		call save_noun1
$x?		ret

;returns the status of the parse in a
*MOD 
check_parse_fail
		ld a,(verbId)
		cp INVALID
		jr z,$f?
		ld a,(wordIdFail)
		cp 1
		jr z,$f?
		ld a,(ambigFail)
		cp 1
		jr z,$f?
		ld a,0 ; OK
		jr $x?		
$f?		ld a,1
$x?		ret
	
save_noun1
		ld a,(MaxScoreObj) ; save the id that was mapped
		ld (DobjId),a
;		ld hl,noun1is
;		call OUTLIN
;		call itoa
;		ld hl,itoabuffer
;		call OUTLINCR
		ret


save_noun2
		ld a,(MaxScoreObj) ; save the id that was mapped
		ld (IobjId),a
;		ld hl,noun2is
;		call OUTLIN
;		call itoa
;		ld hl,itoabuffer
;		call OUTLINCR
		ret
		
;scores noun1 to the prep index
*MOD
score_noun1
		push bc
		push hl
;		ld hl,nounone
;		call OUTLINCR
		ld a,1
		ld (startIndex),a
		ld a,(prepIndex)
		dec a
		ld (endIndex),a
		call score_words
		;were the words recognized?
		ld a,(wordIdFail)
		cp 1
		jp z,$x?
		call disambiguate
		ld a,(ambigFail)
		cp a,1
		jp z,$x?
		call save_noun1
$x?		pop hl
		pop bc
		ret

;set (MaxScoreObj) to the object whose score matches (maxScore)
*mod
get_mapped_obj
		push bc
		push ix
		ld a,(maxScore)
		ld b,a
		ld a,(NumObjects)
		ld c,a
		ld a,0
		ld ix,score_table
$lp?	push af ; save loop counter
		ld a,(ix)  ; get score
		cp b ; == maxScore?
		jr nz,$c?
		pop af
		ld (MaxScoreObj),a
		jp $x?
$c?		pop af
		inc ix
		inc a ; hit end?
		cp c
		jr nz,$lp?
$x?		pop ix
		pop bc
		ret
		
;scores prepIndex to last word
*mod
score_noun2
		push bc
;		ld hl,nountwo
;		call OUTLINCR
		ld a,(prepIndex)
		inc a
		ld (startIndex),a
		ld c,a
		ld a,(numWords)
		dec a
		ld (endIndex),a
		call score_words
		;did it fail because of an unrecognized word
		ld a,(wordIdFail)
		cp 1
		jp z,$x? 
		call disambiguate
		ld a,(ambigFail)
		cp a,1
		jp z,$x?
		call save_noun2		
		pop bc
$x?	ret
	
;if the noun is ambiguous ambigFail is set to 1
;and a message is printed
;a is clobbered
*mod
disambiguate
		call get_max_score
		call get_max_score_count	; what if the score was 0?????!!!
		ld a,(MaxScoreCount)
		cp 1 
		jp z,$na?  ; not ambigious
		ld a,1
		ld (ambigFail),a
		call ambiguous_msg ; prints fail message
$na?	call get_mapped_obj
		ret
	
;Sets the score for the object reference by iy
;to 255 (invalid)
*mod
invalidate_score
		push af
		push bc
		push de
		push hl
		ld a,(iy)
		ld d,0	 ;put object into de, then ix
		ld e,a
		ld hl,score_table ; base address
		add hl,de
		push hl
		ld a,(hl) ; if the score isn't 0, invalidate it
		cp INVALID	
		jr z,$skp?
		cp 0
		jr nz,$skp?
;		ld hl,notmatch
;		call OUTLIN
;		ld a,(iy)  ; reload object id
;		call itoa
;		ld hl,itoabuffer
;		call OUTLINCR
$skp?	pop hl
		ld (hl),INVALID ; set the score to INVALID
		pop hl
		pop de
		pop bc
		pop af
		ret

;Adds 1 to the score for an object
;referenced by iy if the object's score
;hasn't been flagged as invalid
;y c
*mod
inc_score
		push af
		ld a,(iy) ; get the score
		cp INVALID ; if INVALID, quit
		jp z,$x?
		inc a
		ld (iy),a ; write score 
$x?		pop af
		ret

		
		
;sets the score table to all zeroes
*mod
clear_scores
		push af
		push bc
		push iy
		ld a,(NumObjects)
		ld b,a
		ld a,0
		ld iy,score_table
$lp?	ld (iy),a ; zero it out
		inc iy
		djnz $lp?
		pop iy
		pop bc
		pop af
		ret

;add 1 to the score for each visible object		
*mod
inc_visible_scores
		push de
		push hl
		push iy
		ld iy,score_table
		ld a,(NumObjects)
		ld d,a
		call get_player_room ; result in a
		ld c,a
		ld b,0 ; b is loop counter and object # 
$lp?	ld a,(iy)  ; if score 0 or INVALID, skip it
		cp 0
		jp z,$c?
		cp INVALID
		jp z,$c?
		call b_visible_to_c
		cp 1
		jp nz,$c?
		ld a,(iy) ; score_table[a]++
		inc a
		ld (iy),a
		ld a,b
;		call print_obj_name
;		ld hl,isvisible
;		call OUTLINCR
$c?		inc iy
		inc b
		ld a,b
		cp d
		jp nz,$lp?
		pop iy
		pop hl
		pop de
		ret
		
;sets maxScore
*mod
get_max_score
		push bc
		push de
		push hl
		push ix
		push iy
		ld a,0
		ld (maxScore),a ; clear max score
		ld a,(NumObjects) ; loop counter
		ld iy,score_table
		ld ix,NumObjects
$lp?	ld c,a  ; save a
		ld a,(iy) ;get scores[i]
		cp 0
		jp z,$c?
		cp INVALID
		jp z,$c?
		ld b,a ; b =  cur score
		ld a,(maxScore)
		cp b  ; score >= max score?
		jp z,$c?
		jp nc,$c?
		ld a,b
		ld (maxScore),a  ; 
$c?		inc iy
		ld a,c	; put loop counter back
		dec a
		cp 0
		jr nz,$lp?
;		ld hl,maxscoreis
;		call OUTLIN
;		ld a,(maxScore)
;		call itoa
;		ld hl,itoabuffer
;		call OUTLINCR
		pop iy
		pop ix
		pop hl
		pop de
		pop bc
		ret
	
;counts how many object have the max score	
;sets MaxScoreCount variable
*mod
get_max_score_count
		push af
		push bc
		push hl
		push ix
		push iy
		ld a,0
		ld (maxScoreCount),a ; clear max score count
		ld a,(NumObjects)
		ld b,a ; b = loop counter
		ld ix,maxScore
		ld iy,score_table
$lp?	ld a,(iy) ; get score
		cp (ix)   ; equal to max score?
		jr nz,$c? ; != max score, skip it
		ld a,(maxScoreCount) ; max score count ++
		inc a
		ld (maxScoreCount),a
$c?		inc iy
		djnz $lp?
;		ld hl,maxcountstr
;		call OUTLIN
;		ld a,(maxScoreCount)
;		call itoa
;		ld hl,itoabuffer
;		call OUTLINCR
		pop iy
		pop ix
		pop hl
		pop bc
		pop af
		ret
	
	
;sets anyVisible variable to 1 if 
;any object with the max score is visible to the player
*mod
any_visible
		push bc
		push hl
		push ix	
		push iy
		call get_player_room
		ld c,a
		ld a,0 ; a = 0 - loop counter
		ld b,a
		ld (anyVisible),a ; clear value
		ld ix,maxScore
		ld iy,score_table
		ld hl,NumObjects
$lp? 	push af  ; save loop counter
		ld a,(iy)
		cp (ix)  ; == maxScore?
		jr nz,$c?  ; skip it 
		call b_visible_to_c ; result in a
		cp 0
		jp z,$c?
		ld (anyVisible),a  ; a =1 
$c?		pop af ; restore loop counter
		inc iy ; next ptr
		inc a  ; loop counter++
		inc b  ; objectId++
		cp (hl)
		jr z,$x?
		jp $lp?
$x?		pop iy
		pop ix
		pop hl
		pop bc
		ret



;scores the words from startIndex to endIndex (inclusive)
;in the pointer table
;calls clear_scores,score_word
*mod
score_words
		push bc
		push hl
		push ix
		push iy
		call clear_scores
		ld a,(startIndex) ; a is loop counterld 
		ld b,0 ; pad
		ld c,a ; put index in bc
		sla c  ; x 2 because pointers are two bytes
		ld ix,WordPtrs ; load base address          
		add ix,bc ; add offset
		ld a,INVALID
		ld c,a  ; c = INVALID
		ld a,(startIndex) ; a is loop counter
		ld iy,dictionary
		
$lp?	;need to get contents of ix into ix
		push af ; save loop counter
		push ix ; save table addr
;		ld hl,scoring
;		call OUTLIN ; "Scoring word: "
		ld h,(ix+1)
		ld l,(ix)
;		call OUTLINCR  ; print word being score for debug
		push hl	; hl -> ix
		pop ix
		call get_table_index ; result in b
		pop ix ; restore table addr
		ld a,b
		cp c ; INVALID?
		jp nz,$ok?
		pop af ; restore loop counter
		ld hl,dontknowstr ;print "I don't know the word..."
		call OUTLIN
		ld h,(ix+1)
		ld l,(ix)
		call OUTLIN ; print the word
		ld hl,periodstr
		call OUTLINCR
		ld a,1
		ld (wordIdFail),a
		jp $x?
$ok?	call score_word; word is passed in b
		pop af ; restore loop counter
		ld hl,endIndex
		cp (hl)
		jr nc,$x?
		inc a  
		inc ix ; next word ptr
		inc ix ; ptrs are 2 bytes
		jp $lp?
$x?		call inc_visible_scores  ; +1 to all visible objects
		call any_visible
		pop iy
		pop ix
		pop hl
		pop bc
		ret


;prints the appropriate message about a
;noun being ambigious and sets the fail flag
;if maxscorecount =0 "You don't see that"
;if maxscorecount > 1 "I don't know which one you mean."

*mod
ambiguous_msg
		ld a,(maxScoreCount) 
		cp 0  ; noun combination didn't make sense		
		jp z,$nv?
		;if none visible
		ld a,(anyVisible)
		cp 0  ; multiple objects matched, but none visible
		jp z,$nv?
		;print 'I don't know which one you mean.";;
		ld hl,ambigstr  
		call OUTLINCR
		jr $x?
$nv?	ld hl,dontseestr ;print 'You don't see that.";
		call OUTLINCR
$x?		ret


;a contains val to put in itoabuffer
*MOD
itoa
		push bc
		push iy
		ld c,a
		ld iy,itoabuffer
		ld a,20h ; ASCII Space
		ld (iy),a
		ld (iy+1),a
		ld (iy+2),a
		ld (iy+3),0  ; null terminate buffer
		ld a,c  ; put val back in a
		ld b,10
		ld iy,itoabuffer+2
$lp?	push af ; save number
		call modulus ; result in a
		add a,48 ; convert to ASCII
		ld (iy),a ; store char
		dec iy
		pop af ; restore number
		ld b,10
		call div
		cp 0
		jr nz,$lp?
		pop iy
		pop bc
		ret
	
	
itoabuffer DB 20h,20h,20h,0
	
	
verbId
Sentence DB 0
word1
DobjId 	DB 0
PrepId	DB 0
word2
IobjId	DB 0

hitEnd DB 0
PrepFound DB 0		
PrepIndex DB 0
WordPtrs  DS 20  ; space for ten words
WordIndex DW 0  ;  
NumWords  DB 0  ;		
TokFail   DB 0  ;	did tokenize fail?
twowordverb DB "Two word verb",0
shifting DB "shifting...",0
wordIdFail DB 0
ambigFail DB 0	
startIndex DB 0
endIndex DB 0	
anyVisible DB 0
maxScore DB 0
maxScoreCount DB 0
MaxScoreObj DB 0
score_table DS  128
scoring DB "scoring word:",0
pardonstr DB "Pardon?",0
onenoun DB "one noun",0
nounone DB "noun one",0
nountwo DB "noun two",0
parsedone DB "parse complete",0
badverbstr DB "I don't know the verb '",0
periodstr DB ".",0
dontknowstr DB "I don't know the word ",0
dontseestr DB "You don't see that.",0
ambigstr DB "I don't know which one you mean.",0
foundPrepStr DB "Found a prep.",0
verbis DB "The verb is:",0
isamatch DB " is a match",0
notmatch DB "Invalidating score for obj ",0
maxscoreis DB "Max score is ",0
maxcountstr DB "Max Score Count is ",0
isvisible DB " is visible.",0
noun1is DB "noun1 is ",0
noun2is DB "noun2 is ",0