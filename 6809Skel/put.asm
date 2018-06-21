;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;put_routines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
put_sub
	pshs d,x,y
	lda sentence+1
	cmpa #$ff
	lbeq print_ret_bad_put_command
	lda sentence+3
	cmpa #$ff
	lbeq print_ret_bad_put_command
	nop	; check if the player has the d.o.
	nop	; check if the player sees the i.o	
	nop	; is this in or on? 
	lda sentence+2
	cmpa #0	; id of "IN"
	bne @s1
	jsr put_in_sub
	bra @x
@s1	cmpa #6	; id of "ON"
	bne @s2
	jsr put_on_sub
	bra @x
@s2	lbeq print_ret_dont_understand
@x	puls y,x,d
	rts

put_in_sub	
	lda sentence+1
	pshs a
	;getting an attr
	puls a ; pull object #
	pshu a ; push it onto param stack
	lda #1 ; holder
	pshu a
	jsr get_object_attr
	pulu a ; move rslt from user stack to sys stack
	pshs a
	;constant
	lda #1
	pshs a
	;!=
	puls a
	sta temp
	puls a
	cmpa temp
	tfr cc,a
	coma ; flip bits
	anda #4 ; isolate z flag
	lsra ; z-> position 0
	lsra
	pshs a
	puls a ; pop condition
	cmpa #1
	.byte 27h ; enter if-body
	.byte 03 ; beq 3
	jmp @@bb
	;print statement
	ldx #nohave ; YOU DON'T HAVE THAT.
	jsr PRINT
	jsr PRINTCR
	jmp @@ab
@@bb
	lda sentence+3
	pshs a
	;getting a property
	lda #3 ; container
	pshu a ; property param is on bottom
	puls a ; pull object #
	pshu a ; push it object param stack (param on top)
	jsr get_object_prop ; result -> A
	pshs a ; pop it, then push it into sys stack
	;constant
	lda #1
	pshs a
	;==
	puls a
	sta temp
	puls a
	cmpa temp
	tfr cc,a
	anda #4 ; isolate z flag
	lsra ; z-> position 0
	lsra
	pshs a
	puls a ; pop condition
	cmpa #1
	.byte 27h ; enter if-body
	.byte 03 ; beq 3
	jmp @@db
	lda sentence+3
	pshs a
	;getting a property
	lda #6 ; open
	pshu a ; property param is on bottom
	puls a ; pull object #
	pshu a ; push it object param stack (param on top)
	jsr get_object_prop ; result -> A
	pshs a ; pop it, then push it into sys stack
	;constant
	lda #0
	pshs a
	;==
	puls a
	sta temp
	puls a
	cmpa temp
	tfr cc,a
	anda #4 ; isolate z flag
	lsra ; z-> position 0
	lsra
	pshs a
	puls a ; pop condition
	cmpa #1
	.byte 27h ; enter if-body
	.byte 03 ; beq 3
	jmp @@fb
	;print statement
	ldx #the
	jsr PRINT
	lda sentence+3
	pshu a
	jsr print_obj_name
	ldx #isclosed ; IT IS CLOSED.
	jsr PRINT
	jsr PRINTCR
	jmp @@eb
@@fb
	lda sentence+1
	pshs a
	lda sentence+3
	pshs a
	;writing a set attribute statement
	puls b ; pull value (rhs)
	puls a ; pull obj # (lhs)
	pshu a ; push obj # param
	lda #1 ; push attr index
	pshu a ; push attr # param
	pshu b ; push value param
	jsr set_object_attr
	;print statement
	ldx #done ; DONE.
	jsr PRINT
	jsr PRINTCR
@@eb
	jmp @@cb
@@db
	;print statement
	ldx #notcontainer ; YOU CAN'T PUT THINGS IN THAT.
	jsr PRINT
	jsr PRINTCR
@@cb
@@ab
	rts

put_on_sub
	pshs d,x,y
	lda sentence+3
	ldb #OBJ_ENTRY_SIZE
	mul
	tfr d,x
	leax obj_table,x
	lda PROPERTY_BYTE_1,x
	anda #SUPPORTER_MASK
	cmpa #0
	lbeq  print_ret_not_supporter
	nop	; move the object
	lda sentence+1 ; move the object
	pshu a
	lda sentence+3
	pshu a
	jsr move_object
	ldx #done
	jsr PRINT
	jsr PRINTCR
	puls y,x,d
	rts
	
done .strz "DONE."	