;inventory6502.asm


;see if there are any items
;if so list them, and their nested contents
	.module inventory_sub
inventory_sub
		lda #PLAYER_ID
		jsr has_visible_child
		lda $visibleChild
		cmp #0
		beq _ni
		lda #carrying%256
		sta $strAddr
		lda #carrying/256
		sta $strAddr+1
		jsr printstrcr
		lda #PLAYER_ID
		jsr list_items		; list_items will pull
		jmp _x
_ni		lda #emptyhanded%256
		sta $strAddr
		lda #emptyhanded/256
		sta $strAddr+1
		jsr printstrcr
_x		rts
	

;object in 'a' has a visible child
;registers are preserved
	.module has_visible_child
has_visible_child
	    sta $parentId
		pha
		txa
		pha
		tya
		pha
		
		lda $tableAddr ;save table
		pha
		lda $tableAddr+1
		pha
		
		lda #0		; clear flag
		sta visibleChild		
		
		;if the parent is closed, we can stop now
		lda parentId
		ldx #SUPPORTER
		jsr get_obj_prop
		cmp #1
		beq _srch
		
		lda parentId
		ldx #CONTAINER
		jsr get_obj_prop
		cmp #1
		bne _srch
		
		lda parentId
		ldx #OPEN
		jsr get_obj_prop
		cmp #0
		beq _x
		
		;otherwise search the table
_srch	
		lda #$obj_table%256	; setup object table
		sta $tableAddr
		lda #$obj_table/256
		sta $tableAddr+1
		
_lp		ldy #0
		lda ($tableAddr),y
		cmp #255
		beq _x
		ldy #HOLDER_ID
		lda ($tableAddr),y
		cmp $parentId
		bne _c
		ldy #PROPERTY_BYTE_1
		lda ($tableAddr),y
		and #SCENERY_MASK
		cmp #1
		beq _c
		lda #1
		sta visibleChild
		jmp _x
_c		jsr next_entry
		jmp _lp
_x		pla ; restore table
		sta $tableAddr+1
		pla 
		sta $tableAddr		
		pla ;restore registers
		tay
		pla
		tax
		pla
		rts

;lists item names
;and recurses down through the object tree
;the parent is on the top of the stack
	.module list_items
list_items
		sta $parentId
		lda #$obj_table%256	; setup object table
		sta $tableAddr
		lda #$obj_table/256
		sta $tableAddr+1
_lp		ldy #0
		lda ($tableAddr),y
		cmp #255
		beq _x
		ldy #HOLDER_ID
		lda ($tableAddr),y
		cmp $parentId
		bne _c
		
		ldy #PROPERTY_BYTE_1 ;don't list scenery items
		lda ($tableAddr),y
		and #SCENERY_MASK
		cmp #0
		bne _c
		
		lda $tableAddr	;save table (lo)
		pha
		lda $tableAddr+1 	;save table (hi)
		pha
		ldy #0				;reload id
		lda ($tableAddr),y
		jsr indent
		pha
		lda #leadingA%256
		sta strAddr
		lda #leadingA/256
		sta strAddr+1
		jsr printstr
		pla
		jsr print_obj_name
		pla 
		sta $tableAddr+1	;restory table (hi)
		pla 
		sta $tableAddr	;restory table (lo)		
		jsr print_adj
		jsr printcr

		jsr supporter_or_open_container
		lda showContents
		cmp #0
		beq _c
		jsr has_visible_child
		lda visibleChild
		cmp #0
		beq _c
		jsr print_list_header
		lda $tableAddr	;save table (lo)
		pha
		lda $tableAddr+1 	;save table (hi)
		pha		
		lda parentId 	; save parent id
		pha
		ldy #0				;set the new parent id
		lda ($tableAddr),y
		sta parentId 
		inc indentLvl
		jsr list_items ; recurse
		dec indentLvl
		pla		   ; restore parent id
		sta parentId
		pla 
		sta $tableAddr+1	;restore table (hi)
		pla 
		sta $tableAddr	;restore table (lo)		

_s		nop	;
_c		jsr next_entry
		jmp _lp
_x		rts

	.module get_sub		
get_sub
		lda $sentence+1		 ; is it portable?
		ldx #PORTABLE
		jsr get_obj_prop
		cmp #0
		bne _c
		jsr thats_not_something
		jmp _x
_c		lda $sentence+1  ; check mass
		ldy #MASS
		jsr get_obj_attr
		sta temp
		lda invWeight
		adc temp
		cmp maxWeight
		bcc _y
		lda #tooHeavy%256
		sta strAddr
		lda #tooHeavy/256
		sta strAddr+1
		jsr printstrcr
		jmp _x
_y		lda $sentence+1
		ldx #PLAYER_ID
		ldy #HOLDER_ID
		jsr set_obj_attr ; change holder
		lda $sentence+1
		ldx #255
		ldy #INITIAL_DESC_ID
		jsr set_obj_attr ; unset initial description		
		lda #taken%256
		sta strAddr
		lda #taken/256
		sta strAddr+1
		jsr printstrcr
_x		rts
		
	.module drop_sub
drop_sub
		lda $sentence+1
		ldx #SCENERY_MASK
		jsr get_obj_prop
		cmp #1	
	    beq _s
		
		jsr get_player_room ;put obj in player room
		
		lda $sentence+1
		ldx $playerRoom
		ldy #HOLDER_ID
		jsr set_obj_attr
		lda #dropped%256
		
		;print done
		sta strAddr
		lda #dropped/256
		sta strAddr+1
		jsr printstrcr
		
		jmp _x
_s	
		;print error message (can't drop a body part)
		lda #impossible%256
		sta strAddr
		lda #impossible/256
		sta strAddr+1
		jsr printstrcr
	
_x		rts

	.module indent
indent
		pha
		lda indentLvl
_lp		cmp #0
		beq _x
		pha
		lda #space%256
	    sta strAddr
		lda #space/256
	    sta strAddr+1
		jsr printstr		
		pla
		sec
		sbc #1
		jmp _lp	
_x		pla
		rts
	
;computes the weight of the player's inventory	
	.module inv_weight
inv_weight
		lda #0
		sta invWeight
		lda #obj_table%256
		sta $tableAddr
		lda #obj_table/256
		sta $tableAddr+1

		lda #PLAYER_ID ; set parent
		sta parent

_lp		ldy #0		
		lda ($tableAddr),y

		cmp #0			;offscreen?
		beq _c
		cmp #PLAYER_ID	;player?
		beq _c
		cmp #255		;end of table?
		beq _x
		
		lda $tableAddr  ; save table
		pha
		lda $tableAddr+1
		pha

		ldy #0		
		lda ($tableAddr),y
		sta child
		jsr check_ancestor  ; does player have it?

		pla					; restore table
		sta $tableAddr+1
		pla
		sta $tableAddr
 		
		lda ancestorFlag  
		
		cmp #0		
		beq _c		; no

		ldy #MASS	; add it's mass to total weight
		clc
		lda ($tableAddr),y
		adc invWeight
		sta invWeight
		
_c		jsr next_entry
		jmp _lp
_x		rts

invWeight .byte 0
	.byte
emptyhanded .text "YOU ARE EMPTY HANDED."
	.byte 0
carrying .text "YOU ARE CARRYING:"
	.byte 0
leadingA .text "A "
	.byte 0	
taken .text "TAKEN."
	.byte 0
dropped .text "DROPPED."
	.byte 0
space .text " "
	.byte 0
tooHeavy .text "YOUR LOAD IS TOO HEAVY."	
	.byte 0
	
visibleChild .byte 0
indentLvl .byte 0	
parentId .byte 0
maxWeight .byte 25