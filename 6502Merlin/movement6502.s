;movement routines

 
move_player
		jsr verb_to_direction ; puts dir in y
		jsr get_player_room 
		jsr get_obj_attr ; obj=a attr=y  (get room's property)
		sta newRoom
		cmp #127 
		bcs :ng
		ldx #DOOR
		jsr get_obj_prop   ; door?
		cmp #0
		beq :go
		lda newRoom	; it's a door get the direction the door leads
		ldy direction
		jsr get_obj_attr
		sta doorDirection
		lda newRoom	; now see if the door is open/closed_door
		ldx #OPEN
		jsr get_obj_prop
		cmp #1
	    bne :cd	
		lda doorDirection
		sta newRoom		; fall through to go
:go		lda #PLAYER_ID
		ldx newRoom	; new room
		ldy #HOLDER_ID
		jsr set_obj_attr
		;jsr player_can_see (done in main)
		jsr look_sub
		jmp :x
:ng		jsr print_nogo_msg
	    jmp :x		
:cd		jsr closed_door
:x		rts
		
		
		
closed_door
		lda #<the
		sta strAddr
		lda #>the
		sta strAddr+1
		jsr printstr ; print 'The '
		lda newRoom
		jsr print_obj_name
		lda #<isclosed
		sta strAddr
		lda #>isclosed
		sta strAddr+1
		jsr printstrcr ; print ' is closed.'
		rts

;returns move direction in a and also stores
;it in $direction


verb_to_direction
		pha
		clc
		lda sentence
		adc #4
		sta direction
		tay
		pla
		rts
		

the ASC "The "
	DB 0 
isclosed ASC "is closed."
	DB 0 
direction DB 0
doorDirection DB 0
newRoom DB 0
