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
start:
    ld hl, buffer
    ld de, 2
    add hl, de
    ld c, 4
    call atoi
    pop bc
    jp start
;converts text in a buffer to an integer
;this function takes the address of the rightmost
;hl address of rightmost byte
;de
;c number of bytes in the buffer
;result is returned in bc
atoi:
    ;bc will be the counter
    ;hl will contain the src address
    ld bc, 0

atoiloop:
    ld d, (hl)  ; get a char
    ld e, $1C   ; subtract off $1C to convert it to a number
    ld a, d     ; load char into accumulator
    sub e   ;subract $1C from char
    jp m, invalid  ; char was less than "0"
    
    ; char is still loaded into d
    ; load char code for "9"
    ; subtract that from the char
    ld d, a;  
    ld a, $09 ; char code for 9
    sub d;
    jp m, invalid; char was greater than "9"
    
    ;char (in d) is valid
    ld e, d
    ld d, 0
    
    ;multiply de * the place value
    push hl; src addr
    ld a, 10
    call Mul8 ; HL=DE*A
    
    ld d ,h
    ld e ,l
    
    ;add to the sum
    add bc, hl
    pop hl
    
    dec hl
    dec c
    jp nz, atoiloop;
    
invalid:
    pop de
    ld bc, 0
    push bc
    ret
valid:

    ;pad remaining chars with space
;    ld a, c
;    cp 0
;    jp z, nospaces
;spaces:
;    ld a, $00
;    ld (hl), $00; space
;    dec c
;    dec hl
;    jp nz, spaces
;nospaces:
    ld bc, 1
    push bc
    ret


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

 ;include our variables
;#include "vars.asm"
buffer:
    DEFB $1D,$26,$26 ; "103"

; ===========================================================
; code ends
; ===========================================================
;end the REM line and put in the RAND USR line to call our 'hex code'
#include "line2.asm"

;display file defintion
#include "screen.asm"               

;close out the basic program
#include "endbasic.asm"