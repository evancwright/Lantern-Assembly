
;converts the variable pointed to in strSrc
;to ASCII in the buffer
;precondition: value to print is stored in Divisor
itoa
	;save the zero page var were going to using
	lda strAddr+1
	pha 
	lda strAddr
	pha 
	; push a null terminator
 	lda #0
	pha 
	;divide by 10, push remainder
 	lda divisor
	ldy #10
	jsr div
	lda remainder
	clc		; convert to a char
	adc #48  
	pha  ; push char
:lp	lda divResult ; reload and convert remaining digits
	beq :p  ; done - pop and print
	jsr div
	lda remainder
	clc		; convert to a char
	adc #48  
	pha  ; push char
	jmp :lp
:p  ;pop the stack into the buffer
	ldy #0
:l2	pla 
	sta itoaBuf,y
	cmp #0  ; was the stored char a null?
	beq :x  ; if yes, all chars popped
	iny
	jmp :l2
	;print the string
:x	lda #<itoaBuf 
	sta strAddr
	lda #>itoaBuf 
	sta strAddr+1
	;	jsr printf_word
	jsr printstr
	;restore the zero page var
	pla 
	sta strAddr
	pla 
	sta strAddr+1
	rts

itoaBuf DS 3
		DB 0