;;;;;;;;;;;;;;;;;;;;;;;;;;
;vars.asm
;;;;;;;;;;;;;;;;;;;;;;;;;;

 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;user stack contains return var (1 byte)
;user stack contains addr   (2 bytes)
;user stack contains value  (1 byte)
;0 or 1 is returned on the stack
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
testvar
	pshs d,x,y
	ldb #0
	sta 3,u ; set return code
	ldx 1,u ; load var address
	lda ,x	; load var value
	cmpa ,u	; compare it to val on stack
	beq @x
	ldb #1
@x	leau 3,u ; pop 2 params (3 bytes total)
	stb ,u   ; store ret val
	puls y,x,d
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;set var
;stack contains addr of var (2 bytes)
;stack contains addr of val (1 byte)  on top
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
setvar
	pshs d,x,y
	pulu a
	pulu x
	sta ,x
	puls y,x,d
	rts	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;stack contains addr of var (2 bytes)
;stack contains addr of val (1 byte)  on top
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
addtovar
	pshs d,x,y
	pulu a
	pulu x
	adda ,x
	sta ,x
	puls y,x,d
	rts	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;built-in vars
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NumBuiltInVars .db 5
moves .db 0
health .db 100
turnsWithoutLight .db 0 
gameOver .db 0
score .db 0
prev_room .db 0 ; other shells don't have this
