;containers6502.asm
;(c) Evan Wright, 2017 

put_sub
		lda $sentence+1
		ldy #HOLDER_ID
		ldx $sentence+3
		jsr set_obj_attr
		jsr print_done
		rts
		
		.module open_sub
open_sub
		lda $sentence+1
		ldx #LOCKED
		jsr get_obj_prop
		cmp #1
		beq _lkd
		lda $sentence+1 ;reload noun
		ldx #OPEN
		ldy #1
		jsr set_obj_prop
		jsr print_done
		
		jsr reveal_items
		
		jmp _x
_lkd	lda #the%256
		sta strAddr
		lda #the/256
		sta strAddr+1
		jsr printstr
	
		lda sentence+1
		jsr print_obj_name
		
		lda #isLocked%256
		sta strAddr
		lda #isLocked/256
		sta strAddr+1
		jsr printstrcr
_x		rts
		
close_sub
		lda $sentence+1
		ldx #OPEN
		ldy #0
		jsr set_obj_prop
		jsr print_done
		rts		
		
lock_sub
		lda $sentence+1
		ldx #LOCKED
		ldy #1
		jsr set_obj_prop
		jsr print_done
		rts
		
unlock_sub
		lda $sentence+1
		ldx #LOCKED
		ldy #0
		jsr set_obj_prop
		jsr print_done
		rts

print_done		
		lda #done%256
		sta strAddr
		lda #done/256
		sta strAddr+1
		jsr printstrcr
		rts

;assumes tableAddr is set to object's addr
;showContents is set
	.module supporter_or_open_container
supporter_or_open_container 
		pha
		tay
		pha
		lda #0
		sta showContents
		lda #0
		sta container
		lda #1
		sta supporter
		ldy #PROPERTY_BYTE_1
		lda ($tableAddr),y
		and #SUPPORTER_MASK
		cmp #SUPPORTER_MASK
		beq _y
		lda #1
		sta container
		lda #0
		sta supporter
		ldy #PROPERTY_BYTE_1
		lda ($tableAddr),y
		and #OPEN_MASK
		cmp #OPEN_MASK
		beq _y
		jmp _x
_y		lda #1
		sta showContents
_x		pla
		tay
		pla
_xc		rts

	.module reveal_items 
reveal_items
		lda sentence+1
		jsr has_visible_child
		lda visibleChild
		cmp #1
		bne _x
		lda #openningThe%256
		sta strAddr
		lda #openningThe/256
		sta strAddr+1
		jsr printstr
		
		lda sentence+1
		jsr print_obj_name
		
		lda #reveals%256
		sta strAddr
		lda #reveals/256
		sta strAddr+1
		jsr printstrcr
	   	
		lda sentence+1
		jsr list_items
_x		rts
			
done .text "DONE."
	.byte 0
isLocked .text "IS LOCKED."
	.byte 0	
openningThe .text "OPENING THE "
	.byte 0	
reveals .text "REVEALS:"
	.byte 0	
	
showContents .byte 0 ; supporter or open container	
container .byte 0 
supporter .byte 0
	