;6502 parse routines

;kbBufLo EQU kbdbuf%256
;kbBufHi EQU kbdbuf/256

;clr_buffr
;clr_buffr
;sets page to all 0s
;registers are not preserved
 
clr_buffr
		ldy #0
		lda #0
:lp		sta kbdbuf,y
		iny
		cpy #80
		beq :x
		jmp :lp
:x		rts
		

;clears the buffer where the words will
;be stored
	
clr_words
		lda #0
		ldy #0
:lp		sta word1,y
		iny
		cpy #128  ; 4 32 byte words
		beq :x
		jmp :lp
:x		lda #255	
		sta sentence
		sta sentence+1
		sta sentence+2
		sta sentence+3		
		rts

;breaks up the user input into words
find_words
	rts
	
;tries to match words to object id numbers
encode_sentence
	pha
	lda #0				; clear flag
	sta encodeFailed
	lda #<verb_table	   ; setup search table
	sta tableAddr
	lda #>verb_table
	sta tableAddr+1    
	lda #<word1
	sta strDest
	lda #>word1
	sta strDest+1
	lda #10
	sta cmpLen
	jsr get_entry_id	; result to word1
	lda wrdId
	cmp #255
	beq bad_verb     ;print "I don't know the verb '"
	sta sentence
	lda word2 ;					; verify
    cmp #0	
	beq :x
	lda #<word2						;verify wrd 2
	sta strDest				    ;set string to find
	lda #>word2					
	sta strDest+1
	lda #<dictionary				;set up table addr
	sta tableAddr			
	lda #>dictionary
	sta tableAddr+1	
	jsr get_word_index
	lda strIndex
	sta sentence+1
	lda strIndex  ; reload to set flags?
	cmp #255
	beq bad_dobj
	lda word3 ;					; if no prep -> done
	beq :x									; get index of prep
	lda word4 ;					; verify word 4
	bne :c
	jmp missing_noun
	jmp :x
:c	lda #<word4						;verify wrd 2
	sta strDest				    ;set string to find
	lda #>word4					
	sta strDest+1
	lda #<dictionary				;set up table addr
	sta tableAddr			
	lda #>dictionary
	sta tableAddr+1	
	jsr get_word_index
	lda strIndex
	sta sentence+3
	cmp #255
	beq bad_iobj 
:x	pla
	rts

	
	
;this is not a function! it must
;pull all the regs pushed by encode_sentence
bad_verb
		lda #1
		sta encodeFailed
		lda #<badverb	 ;print "I don't know the verb '"
		sta strAddr
		lda #>badverb
		sta strAddr+1		
		jsr printstr
		lda #<word1
		sta strAddr
		lda #>word1
		sta strAddr+1
		jsr printstr ; ; 'print the verb'
		lda #<endquote
		sta strAddr
		lda #>endquote
		sta strAddr+1		
		jsr printstrcr
		pla
		rts

bad_dobj
		lda #1
		sta encodeFailed
		lda #<badword	 ;print "I DONT' RECOGNIZE"...
		sta strAddr
		lda #>badword
		sta strAddr+1		
		jsr printstr
		lda #<word2
		sta strAddr
		lda #>word2
		sta strAddr+1
		jsr printstr ; ; 'print the verb'
		lda #<endquote
		sta strAddr
		lda #>endquote
		sta strAddr+1		
		jsr printstrcr
		pla
		rts

bad_iobj
		lda #1
		sta encodeFailed
		lda #<badword	 ;print "I DONT' RECOGNIZE"...
		sta strAddr
		lda #>badword
		sta strAddr+1		
		jsr printstr
		lda #<word4
		sta strAddr
		lda #>word4
		sta strAddr+1
		jsr printstr ; ; 'print the verb'
		lda #<endquote
		sta strAddr
		lda #>endquote
		sta strAddr+1		
		jsr printstrcr
		pla
		rts		

;this is not a function! it must
;pull all the regs pushed by encode_sentence
		
missing_noun
		lda #<nonoun	 ;print "MISSING NOUN"...
		sta strAddr
		lda #>nonoun
		sta strAddr+1		
		jsr printstrcr
		lda #1
		sta encodeFailed
		pla
		rts
		

dont_see
		lda #1
		sta encodeFailed
		lda #<dontsee	 ;print "YOU DON'T SEE THAT."
		sta strAddr
		lda #>dontsee
		sta strAddr+1		
		jsr printstrcr
		rts
	
	
;make sure any words were actually mapped
;return if they weren't
validate_encoding
	rts

 
	
;this function shifts the letters in the input down
;
;precondition: tableAddr points to the start of the word	
	
remove_articles
		pha
		txa
		pha
		tya
		pha
		lda #<kbdbuf ;  put kb buff in tableAddr
		sta tableAddr
		lda #>kbdbuf ;  set up addr  in $200
		sta tableAddr+1		
		ldy #0
:lp1	jsr mov_to_next_word ;  move to start of word (space)
:lp2	lda (tableAddr),y  ; is char at word start a null
		cmp #0 ;null
		beq :x
 		jsr mov_to_word_end	 ;  move to end of word1
		jsr is_article ;  is it 'noise'?
		lda strIndex
		cmp #255 ;  shift down by wrdEnd letters
		beq :c
		jsr shift_down ; collapse the sentence to squish out the article
		jmp :lp2
:c		jsr catch_up ; advance to next word
		jmp :lp1
:x 		pla
		tay
		pla
		tax
		pla
		rts

;this subroutine shifts the sentence by 
;repeatedly calling shift_left 
;the number is shifts is read from wrdEnd

shift_down
		pha
		lda wrdEnd
:lp		jsr shift_left
		sec
		sbc #1
		cmp #255 ; >=0 
		beq :x
		jmp :lp 
:x		pla
		rts
		
;shifts the 1st word out of the input buffer		

collapse_buffer
		pha
		lda #<kbdbuf
		sta tableAddr
		lda #>kbdbuf
		sta tableAddr+1
		jsr shift_down
		pla
		rts
		
;shifts the input buffer left by 1		
	
shift_left
		pha
		tya 
		pha
		ldy #0
:lp	    iny 
		lda (tableAddr),y
		dey
		sta (tableAddr),y
		cmp #0
		beq :x
		iny
		jmp :lp
:x 		pla
		tay
		pla
		rts
		
;positions the strAddr table at the start of the next word in the buffer
;used to skip white space

mov_to_next_word
		pha 
		tya
		pha
		ldy #0
:lp		lda (tableAddr),y 
		cmp #$20 ; space
		beq :c		
		jmp :x
:c		jsr inc_tabl_addr
		jmp :lp
:x		pla
		tay
		pla
		rts

;moves to the end of the 1st word in the buffer
;sets wrdEnd (index)

mov_to_end_of_first_word
		pha 
		tya
		pha
		ldy #0
:lp		lda buffer,y 
		cmp #$20 ; space
		beq :x		
		cmp #0 ; null
		beq :x		
		iny 
		jmp :lp
:x		sty wrdEnd
		pla
		tay
		pla
		rts		
		
		
;moves to 1st null or space past $tableAddr
;wrdEnd is set
;tableAddr is not affected
mov_to_word_end
		; while not at space or null, go
		pha 
		tya
		pha
		ldy #0
:lp		lda (tableAddr),y 
		cmp #$20 ; space
		beq :x		
		cmp #0 ; null
		beq :x
		iny
		jmp :lp
:x		sty wrdEnd	;
		pla ;restore tableAddr
		tay
		pla
		rts

;sets strIndex to the index of the
;word in strDest in the prep table or
;255 if not found
;article

is_article
		pha
		tya
		pha
	    ldy wrdEnd ; get index of white space/null at end
		lda  (tableAddr),y; save old terminator (space? null?)
		pha  ; save it
		lda tableAddr  ;save old tableAddr (lo)
		pha
		lda tableAddr+1 ; (hi)
		pha
		lda #0
		sta  (tableAddr),y  ; repace it with null (for strcmp)
		lda tableAddr+1  ; set up word to find's addr
		sta strDest+1
		lda tableAddr
		sta strDest					
		lda #>article_table  ; set up table to search
		sta tableAddr+1
		lda #<article_table
		sta tableAddr
		jsr get_word_index
		pla 				;restore prev tableAddr (hi)		
		sta tableAddr+1
		pla 				;restore prev tableAddr (lo)
		sta tableAddr
		pla ; restore char (space or null)
		sta (tableAddr),y
		pla ; restore registers
		tya
		pla
		rts


;sets strIndex to the index of the
;word in keybd buffer is in the prep table or
;255 if not found
;assumes word is null terminated
;article
 
is_preposition
		pha
		lda #<kbdbuf
		sta strDest	; set table to search
		lda #>kbdbuf
		sta strDest+1
 		lda #>prep_table  ; set up table to search
		sta tableAddr+1
		lda #<prep_table
		sta tableAddr
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
	lda tableAddr
	adc wrdEnd
	sta tableAddr
	lda tableAddr+1
	adc #0
	sta tableAddr+1
	pla
	tay
	pla
	rts
		
;this function copies the verb into word1 
;if the second word is a preposition, that word is copied, too
;precondition: the input buffer is shifted down
;registers are preserved
	
get_verb
		pha
		txa 
		pha
		tya
		pha
		ldy #0
:lp1	lda buffer,y			;copy 1st word to word1
		sta word1,y
		iny
		cmp #0
		beq :shft1
		cmp #32	;space
		beq :shft1
		jmp :lp1
:shft1	sty wrdEnd			; shift keyboard buffer left	
		sty firstWrdLen
		lda #<kbdbuf				; set address to shift from
		sta tableAddr
		lda #>kbdbuf
		sta tableAddr+1		
		dec wrdEnd
		jsr shift_down
		tya  ; save y (y->x)
		tax  ;
		cmp #0	; bail if no second word
		beq :x	
		ldx #0	;start over at beginning of buffer
		stx wrdEnd
:lp2	lda buffer,x			;find end of 2nd word
		cmp #32 ; space
		beq :out
		sta word1,y
		inc wrdEnd
		inx 
		iny
		cmp #0
		beq :out
		jmp :lp2	
:out	pha   ; save whitespace char
		lda #0
		sta buffer,x  ; null terminate the 2nd word
		jsr is_preposition ; (uses tableAddr as src)
		pla 		; replace whitespace char
		sta buffer,x  ; replace whitespace char
		lda strIndex
		cmp #255
		bne :prp 		; if a prep, shift input down
		ldy firstWrdLen 	; else null terminate 1st word
		dey
		lda #0
		sta word1,y
		jmp :x
:prp	lda #<kbdbuf			; set address to shift from
		sta tableAddr
		lda #>kbdbuf
		sta tableAddr+1		
		jsr shift_down
;		ldy wrdEnd		; else pull null at end of 1st wrd
;		lda #0
;		sta word1,y
 		;shift down the part that's not the verb
:x		pla
		tay
		pla
		tax
		pla
		rts


get_nouns
		pha
		txa
		pha
		tya
		pha
		jsr mov_to_end_of_first_word
		lda buffer ; hit end?
		cmp #0
		beq :x
		ldx #0
:lp		lda buffer,x
		cmp #32 ; space?
		beq :out
		cmp #0 ; null?
		beq :x
		sta word2,x
		inx
		jmp :lp
		pla 		; restore old word end marker
		sta buffer,y
:out    jsr collapse_buffer ; shift input down over space		
		jsr get_preposition
:x		pla
		tay
		pla
		tax
		pla
		rts

;called by get_prep
;assumes there is a word to read
 
get_indirect_obj
		pha
		txa
		pha
		ldx #0
:lp		lda buffer,x
		cmp #32 ; space?
		beq :x
		cmp #0 ; null?
		beq :x
		sta word4,x
		inx
		jmp :lp
:x		pla
		tax
		pla
		rts


;examines (and discards) words until a 
;preposition is hit. If one is found, it is
;stored and get_indirect_obj is called.
;If a preposition isn't hit
;the input buffer will be left as 'null'

get_preposition
		pha
		txa
		pha
		tya 
		pha
:lp		lda buffer
		cmp #0
		beq :x
		jsr mov_to_end_of_first_word
		ldy wrdEnd
		lda buffer,y ; get and save 
		pha 
		lda #0
		sta buffer,y ; null terminate word
		jsr is_preposition
		pla
		sta buffer,y ; restore null/white space'
		lda strIndex
		cmp #255			
		bne :cpyprp				; it was a prep, copy it to word 3
		jsr collapse_buffer			; shift all words down
;		jsr get_indirect_obj  ; this looks questionable
		jmp :lp
:cpyprp sta sentence+2
		ldx #0
:lp2	lda buffer,x		
		cmp #32 ; space?
		beq :io
		cmp #0 ; null?
		beq :x ;  ; should display and error message 
		sta word3,x		
		inx
		jmp :lp2
:io		jsr collapse_buffer  ;
		jsr get_indirect_obj		
:x		pla
		tay
		pla
		tax
		pla
		rts

		
		
;converts apple text to ascii
;addr to convert is in strSrc
;registers are preserved
	
toascii
		pha
		tay
		pha
		ldy #0
:lp		lda buffer,y
		cmp #$8D
		bne :s
		lda #0
		sta buffer,y
		jmp :x
:s		cmp #0
		beq :x
		cmp #$A0 ; space?
		bne :g
		lda #$20
		jmp :h
:g		cmp #$C1
		bmi :c
		cmp #$DA
		bpl :c
		and #$3F
		clc
		adc #64
:h		sta buffer,y
:c		iny 
		jmp :lp
:x		pla
		tay
		pla
		rts

no_input
		lda #<pardon
		sta strAddr
		lda #>pardon
		sta strAddr+1
		jsr printstrcr
		rts 

;this function maps words to their object
;ids.  If no visible object is found, the
;noun is set to 255 (couldn't be mapped)
	
map_nouns
		lda sentence+1
		cmp #255
		beq :x
:do		jsr get_object_id	
		lda objId
		sta sentence+1
:io		lda sentence+3
		cmp #255
		beq :x
		jsr get_object_id
		lda objId
		sta sentence+3
:x		rts

 
check_mapping
	lda word2
	cmp #0
	beq :x
	lda #255  ; word1 was entered, was it recognized?
	cmp sentence+1
	bne :w3
	jsr dont_see
	jmp :x
:w3	lda word4
	cmp #0
	beq :x
	lda #255  ; word1 was entered, was it recognized?
	cmp sentence+3
	bne :x
	jsr dont_see
:x	rts
		
word1 DS 32
word2 DS 32
word3 DS 32
word4 DS 32


sentence DB 255,255,255,255
pardon  ASC "PARDON?"
	DB 0
badword  DB "I DON'T KNOW THE WORD '"
	DB 0
badverb ASC "I DON'T KNOW THE VERB '"
	DB 0
nonoun ASC "IT LOOKS LIKE YOU'RE MISSING A NOUN."
	DB 0
dontsee ASC "YOU DON'T SEE THAT."
	DB 0
endquote ASC "'"
	DB 0
wrdEnd 	 DB 0 ;  how many bytes past start
isNoise DB	0	;
firstWrdLen DB 0;
encodeFailed DB 0
