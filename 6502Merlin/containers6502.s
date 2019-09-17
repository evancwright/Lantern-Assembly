;containers6502.asm
;(c) Evan Wright, 2017 

put_sub
		lda sentence+1
		ldy #HOLDER_ID
		ldx sentence+3
		jsr set_obj_attr
		jsr print_done
		rts
		

open_sub
		lda sentence+1
		ldx #LOCKED
		jsr get_obj_prop
		cmp #1
		beq :lkd
		lda sentence+1 ;reload noun
		ldx #OPEN
		ldy #1
		jsr set_obj_prop
		jsr print_done
		jsr reveal_items
		jmp :x
:lkd	lda #<the
		sta strAddr
		lda #>the
		sta strAddr+1
		jsr printstr
		lda sentence+1
		jsr print_obj_name		
		lda #<isLocked
		sta strAddr
		lda #>isLocked
		sta strAddr+1
		jsr printstrcr
:x		rts
		
close_sub
	lda sentence+1
	ldx #OPEN
	ldy #0
	jsr set_obj_prop
	jsr print_done
	rts		
		
lock_sub
	lda sentence+1
	ldx #LOCKED
	ldy #1
	jsr set_obj_prop
	jsr print_done
	rts
		
unlock_sub
	lda sentence+1
	ldx #LOCKED
	ldy #0
	jsr set_obj_prop
	jsr print_done
	rts

print_done		
	lda #<done
	sta strAddr
	lda #>done
	sta strAddr+1
	jsr printstrcr
	rts

;assumes tableAddr is set to object's addr
;showContents is set
 
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
		lda (tableAddr),y
		and #SUPPORTER_MASK
		cmp #SUPPORTER_MASK
		beq :y
		lda #1
		sta container
		lda #0
		sta supporter
		ldy #PROPERTY_BYTE_1
		lda (tableAddr),y
		and #OPEN_MASK
		cmp #OPEN_MASK
		beq :y
		jmp :x
:y		lda #1
		sta showContents
:x		pla
		tay
		pla
		rts

 
reveal_items
		lda sentence+1
		jsr has_visible_child
		lda visibleChild
		cmp #1
		bne :x
		lda #<openningThe
		sta strAddr
		lda #>openningThe
		sta strAddr+1
		jsr printstr
		
		lda sentence+1
		jsr print_obj_name
		
		lda #<reveals
		sta strAddr
		lda #>reveals
		sta strAddr+1
		jsr printstrcr
	   	
		lda sentence+1
		jsr list_items
:x		rts
			
done ASC 'Done.'
	DB 0
isLocked ASC 'is locked.'
	DB 0	
openningThe ASC 'Opening the '
	DB 0	
reveals ASC 'reveals:'
	DB 0	
	
showContents DB 0 ; supporter or open container	
container DB 0 
supporter DB 0
	