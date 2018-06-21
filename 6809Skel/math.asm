;mod10

;a contains value
;b contains mod
mod8
	pshs x,y
	pshu b
@lp	cmpa ,u
	bmi @x
	suba ,u ; subtract value
	bra @lp
@x  leau 1,u ; remove val we pushed
	puls y,x
	rts

;16 bit mod
;top of stack is number
;under it is divisor
;the result is returned on the stack
mod2b
	pshs d,x,y
	pulu d ; get number
@lp cmpd ,u
	bcs @x
	subd ,u
	bra @lp
@x	pulu x	; pop divisor
	pshu d ; put result on stack
	puls y,x,d
	rts
		
;divide a by b
;result in a
div8
	pshs x,y
	pshu b  ; push divisor
	ldb #0  ; pushs result
	pshu b  ; 
@lp cmpa 1,u
    bmi @x
	suba 1,u
	inc  ,u ; 
	bra @lp
@x  lda ,u  ; put result in reg a
	leau 2,u ; pop 2 params leaving result on stack
	puls y,x
	rts

