;;;;;;;;;;;;;;;;;;;;;;;;;;;
;utils.asm 
;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRINT_CRLF equ $B958  ; PRINT CARRIAGE RETURN TO CONSOLE OUT

;PRINT equ $bb9c	;	Out String: Prints ASCIIZ string ptd to by X to DEVN
PRINT equ printstrf
INPUT_LINE equ $A390

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;print_table_entry
;
;prints the text for a word in a table 
; p1,2 (address of table)
; p3 index
;[length (minus null)][null terminated text]
;
;this function cleans up the stack
;this routine is called by print_object_name
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_table_entry
	pshs a,x,y
	ldx -3,u
@lp	cmpa -1,u  ;set loop counter to 0
	beq @d
	lda ,x		;get length byte
	leax a,x	;skip past text (add it to x)
	leax 1,x	;skip null
	inca 
	bra @lp
@d  jsr PRINT   ; x should now be 1 byte behind str 
	pulu y		; clean up the user stack
	pulu a
	puls y,x,a
	rts
	