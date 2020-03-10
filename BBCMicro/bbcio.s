;bbc test

OSBYTE EQU $FFF4

charout1	EQU $FFEE 
cout1	EQU $FFEE 
OSWRCH EQU $FFEE 

;charout1  EQU $40EE 
;cout1 EQU $40EE
;OSWRCH EQU $40EE 

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
	;enter?
	cmp #13 ; CR
	beq :x
	;delete
	cmp #$7F ; DELETE
	bne :ch
	lda #0
	sta buffer,y ; null current char
	;do we have room do back up?
	cpy #0
	beq :lp
	dey ;
	sta buffer,y ; null out previous char
	jmp :lp
:ch	sta buffer,y
	iny 
	jmp :lp
:x	lda #0
	sta buffer,y
	jsr OSNEWL
	rts	

printcr
	jsr OSNEWL
	lda #scrWdth
	sta charsLeft
	rts
		

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
	pha
	lda spcChar
	jsr cout1
	pla
	rts
	
message ASC 'PLS ENTER A MESSAGE'
	DB 0

buffer
kbdbuf
	DS 80  ; reserve 80 zeros
