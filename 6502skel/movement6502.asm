;movement routines

	.module move_player
move_player
		jsr verb_to_direction ; puts dir in y
		jsr get_player_room 
		jsr get_obj_attr ; obj=a attr=y  (get room's property)
		sta newRoom
		cmp #127 
		bcs _ng
		ldx #DOOR
		jsr get_obj_prop   ; door?
		cmp #0
		beq _go
		lda $newRoom; it's a door get the direction the door leads
		ldy direction
		jsr get_obj_attr
		sta doorDirection
		lda $newRoom	; now see if the door is open/closed_door
		ldx #OPEN
		jsr $get_obj_prop
		cmp #1
	    bne _cd	
		lda doorDirection
		sta $newRoom		; fall through to go
_go		lda #PLAYER_ID
		ldx $newRoom; new room
		ldy #HOLDER_ID
		jsr set_obj_attr
		;jsr player_can_see (done in main)
		jsr look_sub
		jmp _x
_ng		jsr print_nogo_msg
	    jmp _x		
_cd		jsr closed_door
_x		rts
		
		
		
closed_door
		lda #the%256
		sta strAddr
		lda #the/256
		sta strAddr+1
		jsr printstr ; print 'THE '
		lda newRoom
		jsr print_obj_name
		lda #isclosed%256
		sta strAddr
		lda #isclosed/256
		sta strAddr+1
		jsr printstrcr ; print ' IS CLOSED.'
		rts

;returns move direction in a and also stores
;it in $direction

	.module verb_to_direction
	.module verb_to_direction
verb_to_direction
		pha
		clc
		lda sentence
		adc #4
		sta direction
		tay
		pla
		rts
		

the .text "THE "
.byte 0 
isclosed .text "IS CLOSED."
.byte 0 
direction .byte 0
doorDirection .byte 0
newRoom .byte 0
