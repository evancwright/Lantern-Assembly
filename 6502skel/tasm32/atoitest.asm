;
; To assembly this, either use the zxasm.bat file:
;
; zxasm hello
;
; or... assemble with the following options:
;
; tasm -80 -b -s hello.asm hello.p
;
;==============================================
;    ZX81 assembler 'Hello World' 
;==============================================
;
;defs
#include "zx81defs.asm"
;EQUs for ROM routines
#include "zx81rom.asm"
;ZX81 char codes/how to survive without ASCII
#include "charcodes.asm"
;system variables
#include "zx81sys.asm"

;the standard REM statement that will contain our 'hex' code
#include "line1.asm"

;------------------------------------------------------------
; code starts here and gets added to the end of the REM 
;------------------------------------------------------------

;back to BASIC	
;converts text in a buffer to an integer
;this function takes the address of the rightmost
;hl address of rightmost byte
;c number of bytes in the buffer
;result is returned in bc
main:
    ld hl, buffer ; addr of rightmost char
    ld bc, $02
    add hl, bc
    ld c, $03 ; num chars
    call  atoi; should convert to 103d ->bc
    ;ld a, c
    ;cp 103
    ;ret z
    
    ld a, c
    ld hl, (D_FILE)
    ld bc, 10
    add hl, bc
   
    call itoa;
    
    
    ;jp main
    ret
    

    
;converts text in a buffer to an integer
;this function t akes the address of the rightmost
;hl address of rightmost byte
;c number of bytes in the buffer
;result is returned in bc
atoi:
    ;bc will be the sum
    ;de will be the place value (power of 10)
    ;hl will contain the src address
    ;a will be loop counter
    ld a, c    
    ld bc, $0000
    ld de, $0001
atoiloop:
    push af ; save loop counter
    push hl ; save src addr (free up hl)
    push bc ; save sum (free up bc)
    
    ld c, (hl)
    call char_to_num;
    ld a, c
    cp $FF
    jp z, invalid
    
    ;multiply de * the place value (de)
    push de
    call Mul8 ; HL=DE*A
    pop de
    
    ;move temp to bc
    ld b, h
    ld c, l
    
    ;add to the sum
    pop hl ; restore sum to hl
    add hl, bc
    ld b, h ; copy sum back into bc
    ld c, l
    
    ;multiply the place value x 10
    ld a, 10
    call Mul8 ; HL=DE*A
    ld d, h
    ld e, l
    
    pop hl ; restore addr to read from
    dec hl
    
    pop af ; restore loop counter
    dec a  ; dec loop counter
    jp nz, atoiloop;

    ;finished loop - number was valid
 ;   ld hl, $01 return code
 ;   push hl
    ret
invalid:
    pop bc ;restore stack
    pop hl
    pop af
;    ld bc, $FFFF return code
;  push bc
    ret

;take char in c
;puts code into c
;c = $FF if char is invalid
char_to_num:
    push af
    push de
    push hl
         
    ld e, $1C   ; subtract off $1C to convert it to a number
    ld a, c     ; load char into accumulator
    sub e   ;subract $1C from char
    jp m, badchar  ; char was less than "0"
    
    ; char is still loaded into d
    ; load char code for "9"
    ; subtract that from the char
    ld d, a;  
    ld a, $09 ; char code for 9
    sub d;
    jp m, badchar; char was greater than "9"
    
    ;char (in d) is valid and is 0-9
    ld c, d;
    jp goodchar
badchar:
    ld c, $ff
goodchar:
    pop hl
    pop de
    pop af
    ret


Mul8:                            ; this routine performs the operation HL=DE*A
  ld hl,0                        ; HL is used to accumulate the result
  ld b,8                         ; the multiplier (A) is 8 bits wide
Mul8Loop:
  rrca                           ; putting the next bit into the carry
  jp nc,Mul8Skip                 ; if zero, we skip the addition (jp is used for speed)
  add hl,de                      ; adding to the product if necessary
Mul8Skip:
  sla e                          ; calculating the next auxiliary product by shifting
  rl d                           ; DE one bit leftwards (refer to the shift instructions!)
  djnz Mul8Loop
  ret
;this subroutine will convert a number in 'a' to a chars
;a - the number to convert
;hl - the result will be placed in memory at the destination address (right justified)
itoa:
    ;push af
    ld c, a
    ld d, 10
    call C_Div_D ; puts remainder in a
    
    ;convert a to a char code
    ld e, a; save quotient
    push bc ; save quotient
    add a, $1c ; convert remainder to a char code
    ld (hl), a ; store char
    dec hl
    
    pop bc  ; retore queotient  
    ld a, c
    cp 0 ;if a is 0, well are done
    jp nz, itoa
    ret
    
 
;this code taken from http://z80-heaven.wikidot.com/math#toc39    
C_Div_D:
;Inputs:
;     C is the numerator
;     D is the denominator
;Outputs:
;     A is the remainder
;     B is 0
;     C is the result of C/D
;     D,E,H,L are not changed
;
    ld b,8
    xor a
    sla c
    rla
    cp d
    jr c,$+4
    inc c
    sub d
    djnz $-8
    ret
 ;include our variables
;#include "vars.asm"
buffer:
    DEFB $1D, $1C, $1F ; "103"

; ===========================================================
; code ends
; ===========================================================
;end the REM line and put in the RAND USR line to call our 'hex code'
#include "line2.asm"

;display file defintion
#include "screen.asm"               

;close out the basic program
#include "endbasic.asm"