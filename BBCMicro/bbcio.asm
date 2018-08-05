;bbc test

#define OSBYTE $FFF4  
#define OSWRCH $FFEE 
#define OSRDCH $FFE0
#define OSNEWL $FFE7

#define PAGE_107 $6B00

;zero page &70 to 8F

	.module 
getline
	ldy #0
	lda #'>'
	jsr OSWRCH
_lp	jsr OSRDCH
	jsr OSWRCH
	cmp #13 ; CR
	beq _x
	sta buffer,y
	iny 
	jmp _lp
_x	lda #0
	sta buffer,y
	jsr OSNEWL
	rts	

printcr
	jsr OSNEWL
	rts
	
	;string  addr must be in strlo,strhi
	.MODULE printline
printline
printstr
	ldy #0
_lp	lda ($strAddr),y
	cmp #0
	beq _x
	jsr OSWRCH
	iny
	jmp _lp 
_x	lda #' '
	jsr OSWRCH
	rts	


cls
	rts
	
print_title_bar
	rts

printsp
	rts
	
message .text "PLS ENTER A MESSAGE",0

buffer
kbdbuf
	.fill 80,0
.end