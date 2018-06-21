;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;PARSER SUBROUTINES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WORD_SPACES EQU 5
WORD_SIZE EQU 32
SPACE EQU 0x20 
PLAYER EQU 1
OFFSCREEN EQU 0

parse
;	jsr copy_data ; just for testing
	jsr tokenize
	jsr compress_verb
	rts

 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;nulls out the 50 characters in the
;5x10 buffer for the words in the
;sentence entered by the user
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
clear_buffers
	ldx #0
	lda #0
	ldy #word1
@lp	sta ,y+
	cmpy #(hit_end-1) ; hit end of buffer?
	bne @lp
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; scans until a non-space or null is found
; sets hit_end if null is found
; search starts at addr stored in x
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
find_start
	clr hit_end
@lp lda ,x+
	sta first_char
	cmpa #0x20	; space?
	beq @lp
	cmpa #0 ; null?
	bne @x	; not null, we're done 
	lda #1	; hit null
	sta hit_end
@x	leax -1,x ; back up one byte (to count for x+)
	stx word_start
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; scans until a space or null is found
; sets the hit_end byte to 1 if a null is hit
; search starts at word_start.
; end is replaced a null
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
find_end
	lda #0	;assume we won't hit null
	sta hit_end 
	ldx word_start
@lp	lda ,x+
	cmpa #0x20 ; space
	beq @x	; hit a space, done
	cmpa #0 ; null?
	bne @lp	; no keep, scanning 
	lda #1	; hit null, set flag
	sta hit_end
@x	stx word_end
	lda #0		; replace end with null terminator
	sta -1,x
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; compress_verb
; checks to see if the 2nd word is a prep
; if it is, that word is concatenated onto 
; the first work.  This accomodates verbs 
; like "look at"
; registers an unaffected
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
compress_verb
	pshs d,x,y
	ldx #word2
	ldy #prep_table
	jsr word_in_table
	pulu a
	cmpa #1 
	bne @x			; not a prep, we're done
	ldx #word1		
	stx word_start
	jsr find_end	; find end (sets word_end)
	ldy word_end
	leay -1,y
	sty word_end
	lda [word_end]	; test - make sure its a null
	lda #0x20 		; replace null with space
	sta [word_end]
	ldy word_end    ; set location to copy from
	leay 1,y		; move past the space
	ldx #word2		; set location to copy to (y)
	jsr strcpy		; copy word 2 to end of word 1
	ldx	#0			; shift all words down (move each byte 32 down)
@lp	lda word3,x		; grab a byte 
	sta word2,x  	; store it
	leax 1,x		; go to next byte
	cmpx #(WORD_SIZE*(WORD_SPACES-1))
	bne @lp			
	lda word_count				;dec word_count
	deca 
	sta word_count
@x	puls d,y,x
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; strcpy
; moves the string from wrd_start to wrd_end
; to the buffer stored in y
; tbd: limit the number of chars copied
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
strcpy_old
	pshs y
	ldx word_start
@lp	lda ,x+
	sta ,y+
	cmpx word_end
	bne @lp
	puls y
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; strcpy
; copies string from x to y
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
strcpy
	pshs x,y
@lp	lda ,x+
	sta ,y+
	cmpa #0 ; was last char a null
	beq @x
	bra @lp
@x	puls y,x
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;streq - test two strings for equality
;
;	x,y contain strings to compare
;	assumes strings are is null terminated
;	registers are clobbered
;	1 or 0 is put on user stack
;
;   cmpare two chars.
;   are they equal?
;	if no - return 0
;	if null - return 1
;   if not null loop 
;   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
streq
	pshs x,y
@lp	lda ,x			; get char
	cmpa ,y		; are chars equal?
	bne @n			; no - return 0	
	cmpa #0			; equal. null?
	beq @y			; yes (both nulls), push 1 and return
	leax 1,x		; go to next char
	leay 1,y
	bra @lp				
@y  lda #1			; push 1 and return
	bra @x
@n 	lda #0  		; push 0 and return
@x	pshu a
	puls y,x
	rts	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;word_in_table
;
;x contains address of word
;y contains start of table
;returns 1 or 0 on the user stack
;the index is stored in table_index
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
word_in_table
	clr	table_index ;set index to #ff (invalid)
@lp	leay 1,y 		;increment y to skip length byte
	pshs x,y		; save regs
	jsr streq  		;compare
	pulu a  		; pull result into reg a
	puls y,x		; restore regs
	cmpa #1			;check result
	beq @y			;equal! set flag and quit
	inc table_index ;
	leay -1,y		;back up to get amt to skip
	lda ,y			;get the length at that byte
	leay a,y		;skip ahead by that amount
	leay 2,y		;account for 1st byte and null at end
	lda ,y			;is that byte 0 (the end of the list)
	cmpa #0			
	bne	@lp			;if no, keep checking
	lda #0			;not found, return 0
@y  pshu a 			;push return val onto stack
	;sta in_tbl		;debug
@x	rts		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;word_in_table
;
;x contains address of word
;y contains start of table
;returns ff or the user index on the stack
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_word_index
	pshs d,x,y			;save a
	lda #0			;assume not found
	pshu a			; push return code
@lp	leay 1,y 		;increment y to skip length byte
	pshs x,y		; save regs
	jsr streq  		;compare
	pulu a  		; pull result into reg a
	puls y,x		; restore regs
	cmpa #1			;check result
	beq @x			;equal! set flag and quit
	inc 0,u			;inc loop counter
	leay -1,y		;back up to get amt to skip
	lda ,y			;get the length at that byte
	leay a,y		;skip ahead by that amount
	leay 2,y		;account for 1st byte and null at end
	lda ,y			;is that byte 0 (the end of the list)
	cmpa #0			
	bne	@lp			;if no, keep checking
	lda #$ff			;not found...
	sta 0,u			;put ff into our return var
@x	puls y,x,d
	rts
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;tokenize
;breaks up the text in "input" into words
;stored in the buffers
;y is used to hold the string storage location
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
tokenize
	jsr clear_buffers
	clr word_count	
	ldy #word1			;set place to put strings
	;ldx #input			;load pos of str to scan
	ldx #KBBUF
	stx word_start	
@lp	jsr find_start
	lda hit_end
	cmpa #1				; hit end (no more wrds)
	beq @x
	jsr find_end		; scan to end
	pshu x,y
	ldx word_start
	ldy #article_table	; is the word an article?
	jsr word_in_table	; 
	pulu a				; get rslt
	pulu y,x
	cmpa #1				; was it an article?
	beq @lp				; yes, skip and go to next word
	pshu x
	ldx word_start
	jsr strcpy			; copies x to y
	pulu x
	inc word_count 		; inc word count
	leay 32,y			; move location to store str by (WORD_SIZE)
	lda hit_end			; hit end?
	cmpa #1
	beq @x				; yes - done	
	lda #WORD_SPACES	; have we used all the storage locations
	cmpa word_count
	beq @x				;out of spaces for words 
	bra @lp
@x	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;get_verbs_id
;
;return id# of verb in word1 or -1 (ff)
;
;table format
;id,lenght,text+null
;0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
get_verbs_id
	pshs a,x,y
	ldx #verb_table
	ldy #word1
@lp	leax 1,x	;skip id byte
	lda 0,x		;get length
	cmpa #0		;hit end of table?
	beq @nf		; not found
	leax 1,x	;skip length byte
	jsr streq	;equal?
	pulu a		
	cmpa #1
	bne @sk		
	leax -2,x	;back up to id byte
	lda 0,x		;get it and return it
	bra @x
@sk	lda -1,x	;back up to length byte
	leax a,x	;skip text
	leax 1,x	;skip null byte
	bra @lp
@nf	lda #$ff		;put -1 on stack and return
@x	pshu a
	puls y,x,a
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; b contains the id of the word to find the object for. 
; The object id is returned on the user stack.  
; ff is returned if the object is not found.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_obj_id
	pshs a,x,y
	ldy #obj_word_table
	lda #$ff		; ff is 'not found'
	pshu a		; push return value onto stack
	pshu b		; save id param onto stack (local var)
@ol	lda #1 		; inner loop counter (1 to skip id byte)
@il	ldb a,y		; get word #
	cmpb 0,u	; is b equal to param?
	bne @sk			
    ldb ,y		; get the id
	pshu b 					; push (object)
	jsr get_player_room		; and leave it on stack
	jsr is_visible_child_of 
	test ,u  ; test result
	pshs cc
	leau 1,u ; pop stack
	puls cc  
	beq @sk  ; test result of is_visible
	stb 1,u	; store id of word in return var 
	bra @x
@sk inca 
	cmpa #4		; (id byte + 3 cells) 
	bne @il
	leay 4,y 	; advance to next row
	lda ,y
	cmpa #$ff
	beq @x
;	puls a		; pop outer loop counter
;	inca 		; inc outer loop counter	
;	cmpa obj_table_size	; see if we hit end of table
;	bne @ol
	bra @ol
@x  pulu a 		; user param on stack
	puls y,x,a
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;find_prep_index
;
;this function returns the index of the preposition on
;the user stack.  If the
;sentence doesn't contain one, then 0 is returned.  This
;is used to figure out what type of sentence the player 
;has entered
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
find_prep_index
	pshs a,x,y
	lda #0
	pshu a	;assume not found
	lda #2
	ldx #word3  ;prep can't be in word 1 or 2
@lp	pshs y,x,a
	ldy #prep_table
	jsr get_word_index
	puls a,x,y
	pulu b		;get return code	
	cmpb #$ff		;found?
	beq @sk
	stb prep_id		;store prep id in sentence data
	stb sentence+2
	sta 0,u		;store index in local var
	bra @x
@sk leax 32,x	;skip word
	inca 
	cmpa #5		;number of word slots
	bne @lp
@x	puls y,x,a
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Sets all sentence data bytes to #ff
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
clear_sentence
	pshs a,x,y
	ldx #sentence
	lda #$ff
	sta ,x+
	sta ,x+
	sta ,x+
	sta ,x+
	puls y,x,a	
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;validate do
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
validate_do	
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;sets x to word#1 + a *32
;used to set the print position
;before called a printret error
;message
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
set_word_addr
	ldx #word1
	jsr a_times_32
	leax a,x 
	rts
	
;assumes sentence has already been parsed
;and verb has been compressed
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;if (prep found) {
;	find do and io
;} else {
;	if (wordcount > 1)
;		find # of do
;}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
encode_sentence	
	pshs d,x,y
	lda word1
	cmpa #0
	lbeq print_ret_pardon
	jsr clear_sentence
	jsr get_verbs_id		;
	pulu a				; clear return val
	cmpa #$ff
	lbeq print_ret_bad_verb	;
	sta sentence		; store verb id
	jsr find_prep_index	; is there a prep in this sentence?
	pulu a				;pull and store result
	cmpa #0		;was there a prep?
	;sta prep_index		
	beq @np
	;lda table_index 	;store prep id (was set by find_prep_index)
	;sta sentence+2		;put prep# in sentence
	;lda prep_index		;get prep index so we can 
	deca				;isolate nouns
	pshs a				;save word index
	jsr lookup_word
	puls a				;restore it
	nop					;need to load address of word
	pulu b				;get return from loopup word
	jsr set_word_addr   ;print word at word#1 * 32
	cmpb #$ff			;was it found in dictionary?
	lbeq print_ret_bad_noun ;
	;tfr a,b				;lookup routine uses b as its param
	jsr get_obj_id		;get the object it belongs to
	pulu a
	sta sentence+1		;store direct object
	nop	; now validate io
	lda word_count		;io will be in wc-1
	deca
	jsr lookup_word
	jsr set_word_addr   ;set address of noun to print
	pulu b				;get return code from lookup
	ldx #word4			;load verb to print if not matched
	cmpb #$ff			;was it found
	lbeq print_ret_bad_noun	;
	jsr get_obj_id		;get the object it belongs to
	pulu a
	sta sentence+3		;store io
	cmpa #ff			; obj might not be visible
	lbeq print_ret_no_see
	bra @dn
@np	lda word_count		;sentence is either verb or verb + obj
	cmpa #1
	beq @dn		;noe 
	lda woerd_count		; get pos of of d.o.
	deca
	jsr lookup_word
	pulu a	
    ldx #word2
	cmpa #$ff			;was it found?
	lbeq print_ret_bad_noun ;
	tfr a,b				;lookup routine uses b as its param
	jsr get_obj_id		;get the object it belongs to
	pulu a
	sta sentence+1		;store id of d.o.
	cmpa #ff
	lbeq print_ret_no_see
@dn	nop ; run check rules
	ldx #check_table
@lp	lda ,x
	cmpa #255
	beq @bf
	cmpa sentence  ; get verb
	bne @c
	jsr [1,x] ; jump to the subroutine
	pulu b    ;check status
	cmpb #0
	bne @c
	bra @x
@c	leax 3,x	;skip 3 bytes (the size of an entry)
	bra @lp
	nop ; run 'before' rules
@bf	ldx #preactions_table
 	jsr run_actions
	pulu a
	nop ; check the return code?
	ldx #actions_table
	jsr run_actions
	pulu a
	cmpa #1 ; if handled skip default handling
	beq @s
	jsr run_sentence ; run the sentence
@s	nop ; run 'after' rules
	ldx #postactions_table
	jsr run_actions	;
	pulu a
	jsr do_events
@x	puls y,x,d
	rts	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;looks up the word at wc-1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
lookup_word 
	jsr a_times_32		;get word offset
	ldx #word1
	leax a,x
	ldy #dictionary		;need to get i.o., too	 
	jsr get_word_index	;check dictionary and leave it on the user stack
	rts
	
a_times_32
	lsla				;x32 to get the offset of the word
	lsla				;x32 to get the offset of the word
	lsla				;x32 to get the offset of the word
	lsla				;x32 to get the offset of the word
	lsla				;x32 to get the offset of the word
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;create_property_mask
;assumes prop# is on user stack
;value is returned on the user stack
;for properties # greater than 16, the msb is
; created.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
create_property_mask
	pshs a,b
	pulu a 	; get prop #
	cmpa #9 ; is mask >= 9
	blo @lp
	suba #8 ; -8 to make val <= 8
	ldb #1	; load mask with a '1' to shift left
@lp	cmpa #1	;done?
	bra @x	;done looping
	deca	;dec loop counter
	aslb		;shift left
	bra @lp
@x  pshu b	; push return code
	puls b,a
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; returns the propert for the object on the 
; user stack. the value will be either 1 or 0
; 1-object id
; 2-property number
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_object_property
	pshs d,x,y
	lda 1,u	; id
	ldb 0,u	; property mask
	ldx #obj_table
@lp	cmpa #0			;loop to correct offset
	beq @d
	leax OBJ_ENTRY_SIZE,x
	deca
	bra @lp
@d	andb (OBJ_ENTRY_SIZE-2),x		;skip over to property bytes
	cmpb #9	; props >=9 are stored 
	blo @lo
	andb ,x 		;load the byte
	bra @x
@lo	nop	; AND higher byte
	leax 1,x		;shift to 	
@x	andb ,x 		;load the byte
	pulu a			;clear 
	pulu a 			;clear 
	cmpb #0 
	beq @z
	ldb  #1
@z	pshu b			;put return val on stack
	puls y,x,d
	rts
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;jumps to the subroutine for the verb the
;player typed in.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
run_sentence
	nop	;	try the custom actions
	nop	;	try the default actions
	ldx #sentence_table
@lp	lda ,x
	cmpa #$ff	;hit end of table
	beq @x
	cmpa sentence
	bne @sk
	jsr [1,x]
	bra @x
@sk	leax 3,x	; skip to next handler
	bne @lp
@x	rts

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
prep_index .db 0	
prep_id .db 0
sentence_type .db 0	
sentence .db 255,255,255,255