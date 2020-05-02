;lrs rand for z80

LEFT_BIT equ 16
RIGHT_BIT equ 4
RAND_MASK equ 20 ; LEFT_BIT + RIGHT_BIT
 


;generates a random number and mods it by 'b'
;and returns it in 'a'
*MOD
rmod
		push bc
		call rand
		ld a,(urand)
		call modulus ; now mod it by 'b' (leave result in 'a')
		pop bc
		ret	

;mods a by b		
*MOD	
modulus 	cp b
			jp c,$x?
			sub b
			jp modulus
$x?			ret

;div a by b		
*MOD	
div 		
			push de
			ld d,0
$dvlp?		cp b
			jp c,$x?
			sub b
			inc d
			jp $dvlp?
$x?			ld a,d
			pop de
			ret

		
*MOD
rand
		ld a,(random)
		and RAND_MASK
		cp LEFT_BIT
		jp z,$po?
		cp RIGHT_BIT
		jp z,$po? 
		ld a,(random) 
		srl a	;   just shift (pad with 0)	
		jp $x?
$po?	ld a,(random)
		srl a	;	pad with a 1
		add a,128 ; stick a 1 on the left 
$x?		ld (random),a
		dec a
		ld (urand),a
		ret
		
random DB 255
urand DB 0