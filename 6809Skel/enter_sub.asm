;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; enter_sub
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
enter_sub
	pshs d,x,y
	lda sentence+1
	ldb #OBJ_ENTRY_SIZE
	mul
	tfr d,x
	leax obj_table,x
	leax ENTER,x
	lda ,x
	cmpa #$ff
	bne @s
	ldx #notenterable
	jsr PRINT
	jsr PRINTCR
	bra @x
@s  ldx #obj_table
	leax OBJ_ENTRY_SIZE,x
	leax HOLDER_ID,x
	sta ,x			;set player's new room
    jsr look_sub
@x	puls y,x,d	
	rts
	
	
notenterable	.strz "YOU CAN'T ENTER THAT."