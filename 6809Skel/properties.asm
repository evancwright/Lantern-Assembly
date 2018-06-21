;properties
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; returns the property for the object on the 
; user stack. the value will be either 1 or 0
; 1(top)-object id
; 2-property number
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;get_object_prop
;	pshs d,x,y
;	lda 0,u	; id
;	ldb 1,u	; property mask
;	ldx #obj_table
;@lp	cmpa #0			;loop to correct offset
;	beq @d
;	leax OBJ_ENTRY_SIZE,x
;	deca
;	bra @lp
;@d	andb (OBJ_ENTRY_SIZE-2),x		;skip over to property bytes
;	cmpb #9	; props >=9 are stored 
;	blo @lo
;	andb ,x 		;load the byte
;	bra @x
;@lo	nop	; AND higher byte
;	leax 1,x		;shift to 	
;@x	andb ,x 		;load the byte
;	pulu a			;clear param
;	pulu a 			;clear param
;	cmpb #0 
;	beq @z
;;	ldb  #1
;@z	pshu b			;put return val on stack
;	puls y,x,d
;	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; returns the property for the object on the 
; user stack. the value will be either 1 or 0
; 1(top)-object id
; 2-property number
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_object_prop
	pshs b,x,y
	lda ,u ; get object id
	ldb #OBJ_ENTRY_SIZE
	mul
	tfr d,x
	leax obj_table,x
	leax (OBJ_ENTRY_SIZE-2),x ; move to props
	lda 1,u ; get prop#
	cmpa #8 
	beq @b ; =8? 
	bcs @b ; <8?
	leax 1,x ; move to byte two
@b	lda #0 ; padding
	ldb 1,u ; property #
	tfr d,y
	lda mask_table,y ; load mask_table
	anda ,x ; AND it against data byte
	cmpa mask_table,y ; is it a 1?
	tfr cc,a ; turn z flag into result in A
	anda #4 ; mask off cc
	lsra
	lsra
	leau 2,u ; reset user stack
	puls y,x,b
	rts	

;set_object_prop
;params are on user stack
; top = object #id
; under that = prop# ( 0 - 15)
; under that = value (0 or 1)
set_object_prop
	lda ,u
	ldb #OBJ_ENTRY_SIZE
	mul
	tfr d,x
	leax obj_table,x ; add the offset to the table
	lda 1,u ; get prop#
	cmpa #9
	bcc @byte2 ;  attr >  8
@byte1 ; add offset to byte
   leax PROPERTY_BYTE_1,x ; 1 - 8
   bra @set		
@byte2	; 9 - 16
   leax PROPERTY_BYTE_2,x
@set ; x contains addr of property byte
	lda #0
	ldb 1,u ; bit position
	tfr d,y ; y now has index into mask table
	ldb 2,u ; get value to set bit to 
	cmpb #0
	beq @clrit	
@setit
	lda ,x  ; get the value
	ora mask_table,y ; set bit
	sta ,x ; write it back
	bra @out 
@clrit
	lda mask_table,y
	coma  ; invert mask
	anda ,x
	sta ,x
@out 
	leau 3,u  ; reset stack
	rts

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;get_object_attr
;params are on user stack
;top  param is attr to get 
;next param is obj id
;result is left on user stack
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_object_attr
	pshs d,x,y
	lda 1,u	; id
	ldb #OBJ_ENTRY_SIZE
	mul
	tfr d,x
	leax obj_table,x
	lda #0	 		
	ldb 0,u ; prop id
	tfr d,y	
	leax b,x			;add attr offset to x
	lda ,x			;get the value
	pulu b			; delete param (leave 2nd on stack for return val)
	sta ,u
	puls y,x,d
	rts	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;set_object_attr
;params are on user stack
;top param is new value
;next param is attr to set 
;next is object #
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
set_object_attr
	pshs d,x,y
	lda 2,u	;id	
	ldb #OBJ_ENTRY_SIZE
	mul
	tfr d,x
	leax obj_table,x
	ldb 1,u ; get attr #
	leax b,x ; get offset
	ldb ,u
	stb ,x  ; write new value
	leau 3,u ; pop all 3 params
	puls y,x,d
	rts
	
;properties
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;create_property_mask
;assumes prop# is on user stack
;value is returned on the user stack
;for properties # greater than 16, the msb is
; created.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;create_property_mask
;	pshs a,b
;	pulu a 	; get prop #
;	cmpa #9 ; is mask >= 9
;	blo @lp
;	suba #8 ; -8 to make val <= 8
;	ldb #1	; load mask with a '1' to shift left
;@lp	cmpa #1	;done?
;	bra @x	;done looping
;	deca	;dec loop counter
;	aslb		;shift left
;	bra @lp
;@x  pshu b	; push return code
;	puls b,a
;	rts

mask_table
	.db 0 ; PADDING 
	.db SCENERY_MASK ; 1 
	.db SUPPORTER_MASK ;  2
	.db CONTAINER_MASK ; 4
	.db FLAMMABLE_MASK ;8  NOT USED
	.db OPENABLE_MASK  ;16	
	.db OPEN_MASK ;32
	.db LOCKABLE_MASK ;64
	.db LOCKED_MASK ;128
	.db PORTABLE_MASK ;1
	.db BACKDROP_MASK  ;2
	.db WEARABLE_MASK  ;4 
	.db BEINGWORN_MASK ;8
	.db LIGHTABLE_MASK ;16
	.db LIT_MASK  ;32	
	.db DOOR_MASK  ;64
	.db UNUSED_MASK ;128
