;6502 parse routines

#define kbBufLo kbdbuf%256
#define kbBufHi kbdbuf/256

;clr_buffr
;sets page to all 0s
;registers are not preserved
	.module clr_buffr
clr_buffr
		ldy #0
		lda #0
_lp		sta kbdbuf,y
		iny
		cpy #80
		beq _x
		jmp _lp
_x		rts
		

;clears the buffer where the words will
;be stored
	.module clr_words
clr_words
		lda #0
		ldy #0
_lp		sta $word1,y
		iny
		cpy #128  ; 4 32 byte words
		beq _x
		jmp _lp
_x		lda #255	
		sta $sentence
		sta $sentence+1
		sta $sentence+2
		sta $sentence+3		
		rts

;breaks up the user input into words
find_words
	rts
	
;tries to match words to object id numbers
	.module encode_sentence
encode_sentence
	pha
	lda #0				; clear flag
	sta encodeFailed
	lda #verb_table%256	   ; setup search table
	sta $tableAddr
	lda #verb_table/256 	    
	sta $tableAddr+1    
	lda #word1%256
	sta strDest
	lda #word1/256
	sta $strDest+1
	lda #10
	sta cmpLen
	jsr get_entry_id	; result to word1
	lda $wrdId
	cmp #255
	beq bad_verb     ;print "I don't know the verb '"
	sta $sentence
	lda $word2 ;					; verify
    cmp #0	
	beq _x
	lda #word2%256						;verify wrd 2
	sta $strDest				    ;set string to find
	lda #word2/256					
	sta $strDest+1
	lda #dictionary%256				;set up table addr
	sta $tableAddr			
	lda #dictionary/256
	sta $tableAddr+1	
	jsr get_word_index
	lda $strIndex
	sta $sentence+1
	lda $strIndex  ; reload to set flags?
	cmp #255
	beq bad_dobj
	lda $word3 ;					; if no prep -> done
	beq _x									; get index of prep
	lda $word4 ;					; verify word 4
	bne _c
	jmp missing_noun
	jmp _x
_c	lda #word4%256						;verify wrd 2
	sta $strDest				    ;set string to find
	lda #word4/256					
	sta $strDest+1
	lda #dictionary%256				;set up table addr
	sta $tableAddr			
	lda #dictionary/256
	sta $tableAddr+1	
	jsr get_word_index
	lda $strIndex
	sta $sentence+3
	cmp #255
	beq bad_iobj 
_x	pla
	rts

	
	
;this is not a function! it must
;pull all the regs pushed by encode_sentence
bad_verb
		lda #1
		sta encodeFailed
		lda #badverb%256	 ;print "I don't know the verb '"
		sta $strAddr
		lda #badverb/256
		sta $strAddr+1		
		jsr printstr
		lda #word1%256
		sta $strAddr
		lda #word1/256
		sta $strAddr+1
		jsr printstr ; ; 'print the verb'
		lda #endquote%256
		sta $strAddr
		lda #endquote/256
		sta $strAddr+1		
		jsr printstrcr
		pla
		rts

bad_dobj
		lda #1
		sta encodeFailed
		lda #badword%256	 ;print "I DONT' RECOGNIZE"...
		sta $strAddr
		lda #badword/256
		sta $strAddr+1		
		jsr printstr
		lda #word2%256
		sta $strAddr
		lda #word2/256
		sta $strAddr+1
		jsr printstr ; ; 'print the verb'
		lda #endquote%256
		sta $strAddr
		lda #endquote/256
		sta $strAddr+1		
		jsr printstrcr
		pla
		rts

bad_iobj
		lda #1
		sta encodeFailed
		lda #badword%256	 ;print "I DONT' RECOGNIZE"...
		sta $strAddr
		lda #badword/256
		sta $strAddr+1		
		jsr printstr
		lda #word4%256
		sta $strAddr
		lda #word4/256
		sta $strAddr+1
		jsr printstr ; ; 'print the verb'
		lda #endquote%256
		sta $strAddr
		lda #endquote/256
		sta $strAddr+1		
		jsr printstrcr
		pla
		rts		

;this is not a function! it must
;pull all the regs pushed by encode_sentence
		
missing_noun
		lda #nonoun%256	 ;print "MISSING NOUN"...
		sta $strAddr
		lda #nonoun/256
		sta $strAddr+1		
		jsr printstrcr
		lda #1
		sta encodeFailed
		pla
		rts
		

dont_see
		lda #1
		sta encodeFailed
		lda #dontsee%256	 ;print "YOU DON'T SEE THAT."
		sta $strAddr
		lda #dontsee/256
		sta $strAddr+1		
		jsr printstrcr
		rts
	
	
;make sure any words were actually mapped
;return if they weren't
validate_encoding
	rts

 
	
;this function shifts the letters in the input down
;
;precondition: tableAddr points to the start of the word	
	.module remove_articles
remove_articles
		pha
		txa
		pha
		tya
		pha
		lda #kbBufLo ;  put kb buff in tableAddr
		sta $tableAddr
		lda #kbBufHi ;  set up addr  in $200
		sta $tableAddr+1		
		ldy #0
_lp1	jsr mov_to_next_word ;  move to start of word (space)
_lp2	lda ($tableAddr),y  ; is char at word start a null
		cmp #0 ;null
		beq _x
 		jsr mov_to_word_end	 ;  move to end of word1
		jsr is_article ;  is it 'noise'?
		lda $strIndex
		cmp #255 ;  shift down by wrdEnd letters
		beq _c
		jsr shift_down ; collapse the sentence to squish out the article
		jmp _lp2
_c		jsr catch_up ; advance to next word
		jmp _lp1
_x 		pla
		tay
		pla
		tax
		pla
		rts

;this subroutine shifts the sentence by 
;repeatedly calling shift_left 
;the number is shifts is read from wrdEnd
	.module shift_down
shift_down
		pha
		lda $wrdEnd
_lp		jsr shift_left
		sec
		sbc #1
		cmp #255 ; >=0 
		beq _x
		jmp _lp 
_x		pla
		rts
		
;shifts the 1st word out of the input buffer		
	.module collapse_buffer
collapse_buffer
		pha
		lda #kbBufLo
		sta $tableAddr
		lda #$kbBufHi
		sta $tableAddr+1
		jsr shift_down
		pla
		rts
		
;shifts the input buffer left by 1		
	.module shift_left
shift_left
		pha
		tya 
		pha
		ldy #0
_lp	    iny 
		lda ($tableAddr),y
		dey
		sta ($tableAddr),y
		cmp #0
		beq _x
		iny
		jmp _lp
_x 		pla
		tay
		pla
		rts
		
;positions the strAddr table at the start of the next word in the buffer
;used to skip white space
	.module mov_to_next_word
mov_to_next_word
		pha 
		tya
		pha
		ldy #0
_lp		lda ($tableAddr),y 
		cmp #$20 ; space
		beq _c		
		jmp _x
_c		jsr $inc_tabl_addr
		jmp _lp
_x		pla
		tay
		pla
		rts

;moves to the end of the 1st word in the buffer
;sets wrdEnd (index)
	.module mov_to_end_of_first_word
mov_to_end_of_first_word
		pha 
		tya
		pha
		ldy #0
_lp		lda buffer,y 
		cmp #$20 ; space
		beq _x		
		cmp #0 ; null
		beq _x		
		iny 
		jmp _lp
_x		sty $wrdEnd
		pla
		tay
		pla
		rts		
		
		
;moves to 1st null or space past $tableAddr
;wrdEnd is set
;tableAddr is not affected
	.module mov_to_word_end
mov_to_word_end
		; while not at space or null, go
		pha 
		tya
		pha
		ldy #0
_lp		lda ($tableAddr),y 
		cmp #$20 ; space
		beq _x		
		cmp #0 ; null
		beq _x
		iny
		jmp _lp
_x		sty $wrdEnd	;
		pla ;restore tableAddr
		tay
		pla
		rts

;sets strIndex to the index of the
;word in strDest in the prep table or
;255 if not found
;article
	.module is_article
is_article
		pha
		tya
		pha
	    ldy $wrdEnd ; get index of white space/null at end
		lda  ($tableAddr),y; save old terminator (space? null?)
		pha  ; save it
		lda $tableAddr  ;save old tableAddr (lo)
		pha
		lda $tableAddr+1 ; (hi)
		pha
		lda #0
		sta  ($tableAddr),y;  ; repace it with null (for strcmp)
		lda $tableAddr+1  ; set up word to find's addr
		sta $strDest+1
		lda $tableAddr
		sta $strDest					
		lda #article_table/256  ; set up table to search
		sta $tableAddr+1
		lda #article_table%256
		sta $tableAddr
		jsr get_word_index
		pla 				;restore prev tableAddr (hi)		
		sta $tableAddr+1
		pla 				;restore prev tableAddr (lo)
		sta $tableAddr
		pla ; restore char (space or null)
		sta ($tableAddr),y;
		pla ; restore registers
		tya
		pla
		rts


;sets strIndex to the index of the
;word in keybd buffer is in the prep table or
;255 if not found
;assumes word is null terminated
;article
	.module is_preposition
is_preposition
		pha
		lda #kbBufLo
		sta $strDest	; set table to search
		lda #kbBufHi
		sta $strDest+1
 		lda #prep_table/256  ; set up table to search
		sta $tableAddr+1
		lda #prep_table%256
		sta $tableAddr
		jsr get_word_index
  		pla ; restore registers
		rts		


;this subroutine advances table addr by the length of the
;last word so that table addr points to the next word
catch_up
	pha
	tya
	pha
	clc
	lda $tableAddr
	adc $wrdEnd
	sta $tableAddr
	lda $tableAddr+1
	adc #0
	sta $tableAddr+1
	pla
	tay
	pla
	rts
		
;this function copies the verb into word1 
;if the second word is a preposition, that word is copied, too
;precondition: the input buffer is shifted down
;registers are preserved
	.module concat_verb
get_verb
		pha
		txa 
		pha
		tya
		pha
		ldy #0
_lp1	lda buffer,y			;copy 1st word to word1
		sta word1,y
		iny
		cmp #0
		beq _shft1
		cmp #32	;space
		beq _shft1
		jmp _lp1
_shft1	sty $wrdEnd			; shift keyboard buffer left	
		sty firstWrdLen
		lda #kbBufLo				; set address to shift from
		sta $tableAddr
		lda #kbBufHi
		sta $tableAddr+1		
		dec $wrdEnd
		jsr shift_down
		tya  ; save y (y->x)
		tax  ;
		cmp #0	; bail if no second word
		beq _x	
		ldx #0	;start over at beginning of buffer
		stx $wrdEnd
_lp2	lda buffer,x			;find end of 2nd word
		cmp #32 ; space
		beq _out
		sta word1,y
		inc $wrdEnd
		inx 
		iny
		cmp #0
		beq _out
		jmp _lp2	
_out	pha   ; save whitespace char
		lda #0
		sta buffer,x  ; null terminate the 2nd word
		jsr is_preposition ; (uses tableAddr as src)
		pla 		; replace whitespace char
		sta buffer,x  ; replace whitespace char
		lda $strIndex
		cmp #255
		bne _prp 		; if a prep, shift input down
		ldy firstWrdLen 	; else null terminate 1st word
		dey
		lda #0
		sta $word1,y
		jmp _x
_prp	lda #kbBufLo			; set address to shift from
		sta $tableAddr
		lda #kbBufHi
		sta $tableAddr+1		
		jsr shift_down
;		ldy $wrdEnd		; else pull null at end of 1st wrd
;		lda #0
;		sta $word1,y
 		;shift down the part that's not the verb
_x		pla
		tay
		pla
		tax
		pla
		rts

		
	.module get_nouns
get_nouns
		pha
		txa
		pha
		tya
		pha
		jsr mov_to_end_of_first_word
		lda buffer ; hit end?
		cmp #0
		beq _x
		ldx #0
_lp		lda buffer,x
		cmp #32 ; space?
		beq _out
		cmp #0 ; null?
		beq _x
		sta $word2,x
		inx
		jmp _lp
		pla 		; restore old word end marker
		sta buffer,y
_out    jsr collapse_buffer ; shift input down over space		
		jsr get_preposition
_x		pla
		tay
		pla
		tax
		pla
		rts

;called by get_prep
;assumes there is a word to read
	.module get_indirect_obj
get_indirect_obj
		pha
		txa
		pha
		ldx #0
_lp		lda buffer,x
		cmp #32 ; space?
		beq _x
		cmp #0 ; null?
		beq _x
		sta $word4,x
		inx
		jmp _lp
_x		pla
		tax
		pla
		rts


;examines (and discards) words until a 
;preposition is hit. If one is found, it is
;stored and get_indirect_obj is called.
;If a preposition isn't hit
;the input buffer will be left as 'null'
	.module get_preposition
get_preposition
		pha
		txa
		pha
		tya 
		pha
_lp		lda $buffer
		cmp #0
		beq _x
		jsr mov_to_end_of_first_word
		ldy $wrdEnd
		lda buffer,y ; get and save 
		pha 
		lda #0
		sta buffer,y ; null terminate word
		jsr is_preposition
		pla
		sta buffer,y ; restore null/white space'
		lda $strIndex
		cmp #255			
		bne _cpyprp				; it was a prep, copy it to word 3
		jsr collapse_buffer			; shift all words down
;		jsr get_indirect_obj  ; this looks questionable
		jmp _lp
_cpyprp sta $sentence+2
		ldx #0
_lp2	lda buffer,x		
		cmp #32 ; space?
		beq _io
		cmp #0 ; null?
		beq _x;  ; should display and error message 
		sta $word3,x		
		inx
		jmp _lp2
_io		jsr collapse_buffer  ;
		jsr get_indirect_obj		
_x		pla
		tay
		pla
		tax
		pla
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
_lp		lda buffer,y
		cmp #$8D
		bne _s
		lda #0
		sta buffer,y
		jmp _x
_s		cmp #0
		beq _x
		cmp #$A0 ; space?
		bne _g
		lda #$20
		jmp _h
_g		cmp #$C1
		bmi _c
		cmp #$DA
		bpl _c
		and #$3F
		clc
		adc #64
_h		sta buffer,y
_c		iny 
		jmp _lp
_x		pla
		tay
		pla
		rts

no_input
		lda #$pardon%256
		sta strAddr
		lda #$pardon/256
		sta strAddr+1
		jsr printstrcr
		rts 

;this function maps words to their object
;ids.  If no visible object is found, the
;noun is set to 255 (couldn't be mapped)
	.module map_nouns
map_nouns
		lda $sentence+1
		cmp #255
		beq _x
_do		jsr get_object_id	
		lda $objId
		sta $sentence+1
_io		lda $sentence+3
		cmp #255
		beq _x
		jsr get_object_id
		lda $objId
		sta $sentence+3
_x		rts

	.module check_mapping
check_mapping
	lda word2
	cmp #0
	beq _x
	lda #255  ; word1 was entered, was it recognized?
	cmp sentence+1
	bne _w3
	jsr dont_see
	jmp _x
_w3	lda word4
	cmp #0
	beq _x
	lda #255  ; word1 was entered, was it recognized?
	cmp sentence+3
	bne _x
	jsr dont_see
_x	rts
		
word1 .block 32
word2 .block 32
word3 .block 32
word4 .block 32


sentence .db 255,255,255,255
pardon  .db "PARDON?",0h
badword  .db "I DON'T KNOW THE WORD '",0h
badverb .db "I DON'T KNOW THE VERB '",0h
nonoun .db "IT LOOKS LIKE YOU'RE MISSING A NOUN."
	.db 0
dontsee .db "YOU DON'T SEE THAT."
	.db 0
endquote .db "'",0h
wrdEnd 	 .db 0 ;  how many bytes past start
isNoise .db	0;
firstWrdLen .db 0;
encodeFailed .db 0