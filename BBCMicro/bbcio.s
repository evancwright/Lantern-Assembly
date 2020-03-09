;bbc test

OSBYTE EQU $FFF4

charout1	EQU $FFEE 
cout1	EQU $FFEE 
OSWRCH EQU $FFEE 

OSRDCH EQU $FFE0
OSNEWL EQU $FFE7


;zero page &70 to 8F

readkb
getline
	ldy #0
	lda #'>'
	jsr OSWRCH
:lp	jsr OSRDCH
	jsr OSWRCH
	cmp #13 ; CR
	beq :x
	sta buffer,y
	iny 
	jmp :lp
:x	lda #0
	sta buffer,y
	jsr OSNEWL
	rts	

printcr
	jsr OSNEWL
	rts
	
	;string  addr must be in strlo,strhi
 
;clr_words
;		lda #0
;		ldy #0
;:lp		sta word1,y
;		iny
;		cpy #128  ; 4 32 byte words
;		beq :x
;		jmp :lp
;:x		lda #255	
;		sta sentence
;		sta sentence+1
;		sta sentence+2
;		sta sentence+3		
;		rts
 
;printline
;;printstr
;	ldy #0
;:lp	lda ($strAddr),y
;	cmp #0
;	beq :x
;	jsr OSWRCH
;	iny
;	jmp :lp 
;:x	lda #' '
;	jsr OSWRCH
;	rts	

ask
	jsr clr_buffr
    jsr readkb	
	lda #<kbdbuf ; setup string source
	sta strDest
	lda #>kbdbuf
	sta strDest+1
	lda #<string_table ; 
	sta tableAddr
	lda #>string_table
	sta tableAddr+1
	jsr get_word_index
	lda strIndex
	sta answer
	rts

cls
	rts
	
print_title_bar
	rts

printsp
	rts
	
message ASC 'PLS ENTER A MESSAGE'
	DB 0

buffer
kbdbuf
	DS 80  ; reserve 80 zeros
