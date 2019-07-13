;6502 wear_sub

wear_sub
	; is it already worn?
	lda sentence+1
	ldx #BEINGWORN
	jsr get_obj_prop
	cmp #1
	beq already_worn
	
	; set worn bit
	lda sentence+1
	ldx #BEINGWORN
	ldy #1
	jsr set_obj_prop
	
	;move it to player's top level
	;inventory
	lda sentence+1
	ldx #HOLDER_ID
	ldy #PLAYER_ID
	jsr set_obj_attr
	
	;print 'done'
	lda #<done
	sta strAddr	
	lda #>done
	sta strAddr+1
	jsr printstr	
:x	rts

already_worn
	lda #<alreadyWorn
	sta strAddr	
	lda #>alreadyWorn
	sta strAddr+1
	jsr printstr
	rts

;if an object's parent isn't the player
;it's wear bit is set to 0	
;called after every turn
 
unwear_sub
	lda #<obj_table
	sta tableAddr
	lda #>obj_table
	sta tableAddr+1
	
:lp ldy #OBJ_ID
	;hit end?
	lda (tableAddr),y
	cmp #255
	beq :x
	
	;it its holder the player?
	ldy #HOLDER_ID
	lda (tableAddr),y
	cmp #PLAYER_ID
	beq :c
	
	;no. clear wear bit
	ldy #0
	lda (tableAddr),y
	ldx #BEINGWORN
	jsr set_obj_prop
	
:c	jsr next_entry
	jmp :lp
:x	rts
	
alreadyWorn ASC "You're already wearing it."
	DB 0
