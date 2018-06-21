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
    ld hl, (D_FILE)
    ld bc, 5
    add hl, bc
    ld a, 0
    call  itoa; should convert to $09
    jp main
    
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