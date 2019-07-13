;inventory6502.asm


;see if there are any items
;if so list them, and their nested contents
	 
inventory_sub
		lda #PLAYER_ID
		jsr has_visible_child
		lda visibleChild
		cmp #0
		beq :ni
		lda #<carrying
		sta strAddr
		lda #>carrying
		sta strAddr+1
		jsr printstrcr
		lda #PLAYER_ID
		jsr list_items		; list_items will pull
		jmp :x
:ni		lda #<emptyhanded
		sta strAddr
		lda #>emptyhanded
		sta strAddr+1
		jsr printstrcr
:x		rts
	

;object in 'a' has a visible child
;registers are preserved
 
has_visible_child
	    pha
		sta parentId		
		pha
		txa ; save regs
		pha
		tya
		pha
		
		lda tableAddr ;save table
		pha
		lda tableAddr+1
		pha
		
		
		lda #0		; clear flag
		sta visibleChild		

		lda parentId
		cmp #PLAYER_ID
		beq :srch
		
		;if the parent is closed, we can stop now
		lda parentId
		ldx #SUPPORTER
		jsr get_obj_prop
		cmp #1
		beq :srch
		
		lda parentId
		ldx #CONTAINER
		jsr get_obj_prop
		cmp #0
		beq :x
		;object is a container
		lda parentId
		ldx #OPEN
		jsr get_obj_prop
		cmp #0
		beq :x
		
		;otherwise search the table
:srch	
		lda #<obj_table	; setup object table
		sta tableAddr
		lda #>obj_table
		sta tableAddr+1
		
:lp		ldy #0
		lda (tableAddr),y
		cmp #255
		beq :x
		ldy #HOLDER_ID
		lda (tableAddr),y
		cmp parentId
		bne :c
		ldy #PROPERTY_BYTE_1
		lda (tableAddr),y
		and #SCENERY_MASK
		cmp #1
		beq :c
		lda #1
		sta visibleChild
		jmp :x
:c		jsr next_entry
		jmp :lp
:x		pla ; restore table
		sta tableAddr+1
		pla 
		sta tableAddr		
		pla ;restore registers
		tay
		pla
		tax
		pla
		pla 
		sta parentId
		rts

;lists item names
;and recurses down through the object tree
;the parent is on the top of the stack
 
list_items
		pha 
		sta parentId  ; save parent
		lda tableAddr
		pha
		lda tableAddr+1
		pha		
		lda #<obj_table	; setup object table
		sta tableAddr
		lda #>obj_table
		sta tableAddr+1
:lp		lda parentId
		pha
		ldy #0
		lda (tableAddr),y
		cmp #255
		bne :g
		jmp :x ;done
:g		ldy #HOLDER_ID
		lda (tableAddr),y
		cmp parentId
		bne :c
		
		ldy #PROPERTY_BYTE_1 ;don't list scenery items
		lda (tableAddr),y
		and #SCENERY_MASK
		cmp #0
		bne :c
		
		lda tableAddr	;save table (lo)
		pha
		lda tableAddr+1 	;save table (hi)
		pha
		ldy #0				;reload id
		lda (tableAddr),y
	 
		jsr indent
		pha
		lda #<leadingA
		sta strAddr
		lda #>leadingA
		sta strAddr+1
		jsr printstr
		pla
		jsr print_obj_name
		pla 
		sta tableAddr+1	;restory table (hi)
		pla 
		sta tableAddr	;restory table (lo)		
		jsr print_adj
		jsr printcr
		
		jsr supporter_or_open_container
		lda showContents
		cmp #0
		beq :c
		lda (tableAddr),y ; reload id 
		jsr has_visible_child
		lda visibleChild
		cmp #0
		beq :c
		jsr print_list_header
		
		lda parentId
		pha
		ldy #0				;set the new parent id
		lda (tableAddr),y
		sta parentId 
		inc indentLvl
		jsr list_items ; recurse
		dec indentLvl
		pla
		sta parentId
				
:s		nop	;
:c		jsr next_entry
		pla
		sta parentId
		jmp :lp
:x		pla ; pull parent temp
		pla				;restor table
		sta tableAddr+1
		pla
		sta tableAddr
		pla 
		sta parentId	;restore parent
		rts

get_sub
		lda sentence+1		 ; is it portable?
		ldx #PORTABLE
		jsr get_obj_prop
		cmp #0
		bne :c
		jsr thats_not_something
		jmp :x
:c		lda sentence+1  ; check mass
		ldy #MASS
		jsr get_obj_attr
		sta temp
		lda invWeight
		adc temp
		cmp maxWeight
		bcc :y
		lda #<tooHeavy
		sta strAddr
		lda #>tooHeavy
		sta strAddr+1
		jsr printstrcr
		jmp :x
:y		lda sentence+1
		ldx #PLAYER_ID
		ldy #HOLDER_ID
		jsr set_obj_attr ; change holder
		lda sentence+1
		ldx #255
		ldy #INITIAL_DESC_ID
		jsr set_obj_attr ; unset initial description		
		lda #<taken
		sta strAddr
		lda #>taken
		sta strAddr+1
		jsr printstrcr
:x		rts
		
	 
drop_sub
		lda sentence+1
		ldx #SCENERY_MASK
		jsr get_obj_prop
		cmp #1	
	    beq :s
		
		jsr get_player_room ;put obj in player room
		
		lda sentence+1
		ldx playerRoom
		ldy #HOLDER_ID
		jsr set_obj_attr
		
		;print done
		lda #<dropped
		sta strAddr
		lda #>dropped
		sta strAddr+1
		jsr printstrcr
		
		jmp :x
:s	
		;print error message (can't drop a body part)
		lda #<impossible
		sta strAddr
		lda #>impossible
		sta strAddr+1
		jsr printstrcr
	
:x		rts

 
indent
		pha
		lda indentLvl
:lp		cmp #0
		beq :x
		pha
		lda #<space
	    sta strAddr
		lda #>space
	    sta strAddr+1
		jsr printstr		
		pla
		sec
		sbc #1
		jmp :lp	
:x		pla
		rts
	
;computes the weight of the player's inventory	
 
inv_weight
		lda #0
		sta invWeight
		lda #<obj_table
		sta tableAddr
		lda #>obj_table
		sta tableAddr+1

		lda #PLAYER_ID ; set parent
		sta parent

:lp		ldy #0		
		lda (tableAddr),y

		cmp #0			;offscreen?
		beq :c
		cmp #PLAYER_ID	;player?
		beq :c
		cmp #255		;end of table?
		beq :x
		
		lda tableAddr  ; save table
		pha
		lda tableAddr+1
		pha

		ldy #0		
		lda (tableAddr),y
		sta child
		jsr check_ancestor  ; does player have it?

		pla					; restore table
		sta tableAddr+1
		pla
		sta tableAddr
 		
		lda ancestorFlag  
		
		cmp #0		
		beq :c		; no

		ldy #MASS	; add it's mass to total weight
		clc
		lda (tableAddr),y
		adc invWeight
		sta invWeight
		
:c		jsr next_entry
		jmp :lp
:x		rts

invWeight DFB 0
	DFB 0
emptyhanded ASC "You are empty handed."
	DFB 0
carrying ASC "You are carrying:"
	DFB 0
leadingA ASC "A "
	DFB 0	
taken ASC "Taken."
	DFB 0
dropped ASC "Dropped."
	DFB 0
space ASC " "
	DFB 0
tooHeavy ASC "Your load is too heavy."	
	DFB 0
	
visibleChild DFB 0
indentLvl DFB 0	
parentId DFB 0
maxWeight DFB 25