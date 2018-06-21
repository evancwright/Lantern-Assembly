

;a contains obj id
;y contains attr id#
;registers are clobbered
;result in a
	.module get_obj_attr
get_obj_attr
		tax 
		lda #$obj_table%256
		sta $tableAddr
		lda #$obj_table/256
		sta $tableAddr+1
_lp		cpx #0		
		beq _x
		clc
		lda $tableAddr
		adc #OBJ_ENTRY_SIZE
		sta $tableAddr
		lda $tableAddr+1
		adc #0
		sta $tableAddr+1
		dex
		jmp _lp
_x		lda ($tableAddr),y
		rts

;a contains obj id
;x contains new value
;y contains attr id#
	.module set_obj_attr
set_obj_attr
		pha
		lda #obj_table%256
		sta $tableAddr
		lda #obj_table/256
		sta $tableAddr+1   
		pla
_lp		cmp #0				; loop through table to correct entry
		beq _x
		jsr next_entry
		sec
		sbc #1
		jmp _lp
_x		txa
		sta ($tableAddr),y
		rts

;skips ahead one entry in the object table		
next_entry
		pha
		clc
		lda $tableAddr
		adc #OBJ_ENTRY_SIZE
		sta $tableAddr
		lda $tableAddr+1
		adc #0
		sta $tableAddr+1
		pla
		rts		
		
;get a property bit on an object
;a=object
;x=property (1-16)
;the subroutine figures out 
	.module get_obj_prop
get_obj_prop
		jsr get_property_byte
		ldx $property
		and $maskTable,x   ; mask off bit
	    cmp #0			   ; make byte a 1 or 0	
		beq _x
		lda #1
_x      rts

;set a property bit on an object to a 1
;a=object
;x=property (1-16)
;y=value		
	.module set_obj_prop
set_obj_prop 
			cpy #1
			beq _set_bit 
			jmp _clr_bit
_set_bit	jsr get_property_byte ; set table position and mask
			ldy propByteOffset
			lda ($tableAddr),y ; get byte
			ora $propMask  ; set bit
			sta ($tableAddr),y	; write it back
			jmp _x
_clr_bit	jsr get_property_byte ; set table position and mask
			sec
			lda #$ff		;invert the mask
			sbc $propMask
			sta $propMask
			lda $propByte	;reload the data byte
			and $propMask   ;clear the bit
			ldy $propByteOffset
			sta ($tableAddr),y  ;write the byte back
_x			rts
		
		
		
;get a property bit on an object
;a=object
;x=property (1-16)
;byte returned in 'a'		
		.module get_property_byte
get_property_byte
		pha
		stx $property
		lda $maskTable,x
		sta $propMask
		pla
		ldy #0   ; property 0 (any would work)
		jsr get_obj_attr  ; position tableAddr at object's data
		ldy #PROPERTY_BYTE_1 ; get the byte the bit is in
		ldx $property
		cpx #9
		bmi _t
		ldy #PROPERTY_BYTE_2
_t		sty $propByteOffset
		lda ($tableAddr),y
		sta $propByte;
		rts
	
 
holderAttr .byte 0
descAttr .byte 0
initialDescAttr .byte 0

property .byte 0		
propByte .byte 0
propMask .byte 0
propByteOffset .byte 0
maskTable .byte 0,1,2,4,8,16,32,64,128,1,2,4,8,16,32,64,128  ; converts prop #'s to their masks