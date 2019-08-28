;6502 table  routines

 

;get_table_index
;tries to look up a word's id in a table 
;that where the entries have ids
;the word to find is stored in the
;zero page variable strDest
;table addr is stored in tableAddr
;result is stored in tableIndex
	 
get_entry_id
		pha
		txa
		pha
		tya
		pha
		ldx #255	;set index to 'not found'	
		stx wrdId
		ldx #0  ; loop counter
:lp		ldy #0
		lda (tableAddr),y	;
		cmp #255 	; hit end?
		beq :x
		jsr inc_tabl_addr ; skip id byte
		jsr tab_addr_to_str_src ; position str src at string
		jsr streq6
		cmp #1
		beq :y
		jsr next_string		; skip to the next entry
		jmp :lp
:y		jsr dec_tabl_addr ; back up to the id byte
		ldy #0
		lda (tableAddr),y
		sta wrdId
:x		pla 
		tay
		pla
		tax
		pla
		rts

 		
;assumes the zero-page address tableAddr
;the addr of the string to find must be in 
;the strDest 0 page var
;has been set by the caller.
;the address in that location is modified by this routine
;no registers are modified
;tableIndex is set as a post condition (255=not found) 
 
get_word_index
		pha
		txa
		pha
		tya
		pha
		ldx #255	;set index to 'not found'	
		stx strIndex
		ldx #0  ; loop counter
:lp		ldy #0
		lda (tableAddr),y	;
		cmp #255
		beq :x
		cmp #0
		beq :x		
 		jsr tab_addr_to_str_src  ; put table addr into strSrc
		jsr streq6 ; do they match? (compares strSrc to StrDest)
		cmp #1
		bne :c
		stx strIndex
		jmp :x
:c		jsr next_string
		inx ; increment loop counter
		jmp :lp
:x		pla
		tay
		pla
		tax
		pla
		rts
		
;skips to the next table entry in 
;the string table stored in 
;tableAddr
inc_tabl_addr
		pha
		clc
		lda #1 ; add 1 to skip length byte and null
		adc tableAddr ; add to lo byte
		sta tableAddr ; store in lo byte
		lda #0
		adc tableAddr+1 ; add carry to hi byte
		sta tableAddr+1 ; store hi byte 		
		pla
		rts

;decrementes the address in tableAddr
;this is used to 'back up' to the id  
;tableAddr
;NOT TESTED YET
dec_tabl_addr
		pha
		sec
		lda tableAddr ; add 1 to skip length byte and null
		sbc #1 ; add to lo byte
		sta tableAddr ; store in lo byte
		lda tableAddr+1 ; add carry to hi byte
		sbc #0
		sta tableAddr+1 ; store hi byte 		
		pla
		rts

;this function returns the id of the object
;whose word id is supplied in register 'a'
;the result is stored in objId
;registers are preserved		
 
get_object_id
		sta objId
		pha
		tax
		pha
		tay
		pha
		lda #>obj_word_table
		sta tableAddr+1
		lda #<obj_word_table
		sta tableAddr
:lp		ldy #0
		lda (tableAddr),y	;get the id
		cmp #255
		beq :ntfnd
		ldy #1
		lda (tableAddr),y
		cmp objId
		beq :found
		ldy #2
		lda (tableAddr),y
		cmp objId
		beq :found
		ldy #3
		lda (tableAddr),y
		cmp objId
		beq :found
:c		jsr inc_tabl_addr ; skip to next entry
		jsr inc_tabl_addr
		jsr inc_tabl_addr
		jsr inc_tabl_addr
		jmp :lp
:found	;jsr visible_ancestor ; if it isn't visible, skip it
		jsr in_player_room
		lda visibleAncestorFlag
		cmp #1
		bne :c   ; go back and try again
		ldy #0
		lda (tableAddr),y	;get the id
:ntfnd	sta objId
		pla
		tay
		pla
		tax
		pla
		rts
		
;skips to the next table entry in 
;the string table stored in 
;tableAddr
next_string
		pha	; save a
		tya ; save y
		pha
		ldy #0
		;add length to table ptr
		clc 
		lda (tableAddr),y ; get len referenced by 0 page addr
		adc tableAddr
		sta tableAddr ; store in lo byte
		;add carry to hi byte
		lda #0
		adc tableAddr+1 ; add carry to hi byte
		sta tableAddr+1 ; store hi byte 
		;now add two to account for the len and null bytes
		clc 
		lda tableAddr
		adc #2
		sta tableAddr ; add to lo byte
		;add carry to the hi byte
		lda tableAddr+1
		adc #0
		sta tableAddr+1 ; store hi byte 
		pla 	;restor y
		tay
		pla	;restor a
		rts

strIndex DB 0		
;objId DFB 0  ; defined in printing 6502.asm
wrdId DB 0
