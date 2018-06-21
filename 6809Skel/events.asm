;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;events to run every turn
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
do_events
	pshs d,x,y
	;if player can't see, inc turns without light
	jsr get_player_room ; get room and leave it on stack
	jsr ambient_light 
	pulu a
	cmpa #0
	bne @l
	lda turnsWithoutLight
	inca 
	sta turnsWithoutLight
 	bra @d
@l  lda #0						;set turns w/o light back to 0
	sta turnsWithoutLight
@d  nop ; end else	

;	jsr disolve_salt_sub
	include event_jumps_6809.asm

	jsr unwear_all
	
	puls y,d,x
	rts

	
	
