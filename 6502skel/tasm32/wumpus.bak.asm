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
;    ZX81 Wumpus
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

    ld hl, welcome;
    call printline
    call scroll
    ld hl, welcome2;
    call printline
    call scroll
    
    ld hl, welcome3;
    call printline
    call scroll

    call set_up_game
    
mainloop:
    
    
    
getchar:
    
    ld de, kbstatus
    call readkeyboard ;put the keycode in the address stored in de
    
    ;now we can check kbstatus
    ;if no key was pressed, the both bytes will be $ff
    
    ld a, (kbstatus)
    inc a
    push af
    cp 0
    call z, clearflag; set the flag saying we can take a key
    pop af
    cp 0
    jp z, getchar; ; no key pressed
 
    ;if a key is already down jump to getchar
    ld a, (keydown)
    cp 1
    jp z, getchar;  a key was pressed but it was a repeat
    
    ;setkey down
    ld a, 1
    ld (keydown), a
    
    ;call findchar (ROM) to get the key code
    ld bc, (kbstatus)
    call FINDCHR; takes code in bc and returns addr of code in hl
    ld a, (HL) ; store returned code in a
    
    ;was quit key pressed
    cp $36; code for 'q'
    ret z
    
    ;was the enter key pressed?
    cp $76
    jp nz, noenter
    
    ;enter was pressed process the input
    ld a, (inputstate) 
    cp 0 ; m or s option was previously entered
    push af; save a + f
    call z, handle_command_input ; was m or s pressed?
    pop af; restore flags
    cp 1 ; m or s option was previously entered
    push af ;save flags
    call z, handle_room_input
    pop af ; restore
    cp 2
    jp nz, skipquit
    
    ;did the player hit the 'n' key
    ;if so return (we're done)
    ld a, (buffer)
    cp _N
    ret z
    ;if we got here player didn't quit
    ;reset the game
    call set_up_game;


skipquit:
    
    ;is the player dead?
    ld a, (gameover)
    cp 1
    jp nz, notdead
    
    call clearbuf; ;not source of crash
    call prompt_play_again;
    
notdead:   
    jp mainloop;
    
noenter:    
    ;was del key pressed?
    cp $77
    jp nz, noclear;
    call clearbuf;
    jp printbuf; 
    ;
noclear:   

     
skip:
 
    ;then put that key code in the text buffer
;    push af
    ld bc, (bufferix)
    ld e,a
    ld a,c
    cp 5
    jp z, fullbuf
    ld a, e; copy char back 
    ld hl, buffer
    add hl, bc
    ld (hl), a;put char in buffer
    
    ;and increment the count
    ld bc, (bufferix); 
    inc bc
    ld (bufferix), bc; store it back
fullbuf:
printbuf:    
    ;print the buffer
 ;   ld hl, (D_FILE)
 ;   ;ld bc, 661
 ;   ld bc, 628 
 ;   add hl, bc 
 ;   ld d, h
 ;   ld e, l
    ld hl, buffer
    call printline
    
    jp mainloop ; end of main loop

promptcommand:
    ;print the buffer
    ld hl, msprompt
    call printline
    call scroll
    ret
   
promptroom

    ;print the room message prompt
    ld hl, roomprompt
    call printline
    call scroll    
    ret
    
prompt_play_again:
    
    ;set the flag saying that we are accepting y/n input
    ld a, 2
    ld (inputstate), a

    ;print the buffer
    ld hl, playagainprompt
    call printline
    call scroll
    ret

;----------------------------
;THIS ROUTINE CALL KSCAN AT 02BB, THEN STORES
;THE STATUS CODE IN THE ADDRESS STORED IN DE
readkeyboard: ; 40A0
    push hl    ;save HL to stack
    push bc    ;save BC
    push de
    call KSCAN    ;call ROM subroutine at address 02BB, result put in HL
    pop de
    ld b, h  ;move hl to bc (because we're about to need HL)
    ld c, l
    ld h, d  ;copy kb status flag address into HL (so we can store it)
    ld l, e
    ld (hl), c ;store B in (HL)
    inc l
    ld (hl), b ;store C in (HL)+1
    pop bc
    pop hl
    ret
    
;sets the key down flag to 0
clearflag:
    push af
    push hl
    ld a, 0
    ld (keydown), a
    pop hl
    pop af
    ret

;accepts the address of the text to print in hl, and the D_FILE location to print in DE
;printing stops when the char 0xFF is hit
printline:
    push bc
    push af
    push hl
    ld hl, (D_FILE)
    ld bc, 661
    add hl, bc 
    ld d, h
    ld e, l
    pop hl
prloop:    
    ld a, (hl)  ; //get a char
    cp $ff      ; hit the end?
    jp z, done
    ld (de), a; copy char in 'a' to D_FILE
    inc hl ; increment addr to copy to
    inc de ; get addr of next cha racter
    jp prloop
done:
    pop af
    pop bc
    ret

clearbuf:
    ld de, (D_FILE)
    ld hl, 661
    add hl, de
    ld d, h
    ld e, l
    
    ld a, 0
    ld b, 10
    
    ld hl, buffer
    
clrloop:
    ld c, $ff
    ld (hl), c ; put endline in buffer
    inc hl
    push hl ; save hl ()
    ld c, $00
    ld h, d ; move de to hl
    ld l, e
    ld (hl), c ; put space on screen
    inc hl; inc dest address
    ld d,h  ; store it back in de
    ld e,l
    pop hl
    inc a; inc lp counter
    cp b; done?
    jp nz, clrloop
    ;set buffer ix to 
    ld a, 0
    ld (bufferix), a; set buffer index = 0
    ld (bufferix+1), a; set buffer index = 0
    ret

;this subroutine takes a 8-bit number and a location to print it at
;bc = number to convert
;hl = address to store it at
;de = # of characters in buffer
indextotext:
    add hl, de ; addr to store
    ld d, h
    ld e, l
    ;lots of stuff missing
invalidroom:
    ld bc, 0
    push bc ;store return code on stack
    ret
print_current_room:
    ;print the buffer
    ld hl, currentrooomtext
    call printline
    
    ;copy in the room number
    ld hl, (D_FILE)
    ld bc, 678 ; 621 + 17
    add hl, bc 
    
    push hl ; move hl into de
    ld hl, (currroomaddr)
    pop de
    
    ldi ; copy the room label from hl (memory) to screen (de)
    ldi    
     
    call scroll
    ret
    
;this subroutine checks for hazards in the room the player
;has just moved into
handle_hazards:    
    call get_flags_byte; a
    push af
    ;check for wumpus
    and 1
    jp z, no_wumpus_death
    ;wumpus death
    ld hl, playereatenmessage
    call printline;
    
    ld a, 1
    ld (gameover), a
    call scroll
    pop af
    ret
no_wumpus_death:    
    ;check for pit
    pop af
    push af
    and 16
    jp z, no_pit_death
    ld hl, pitdeathmessage
    call printline;
    call scroll
    ld a, 1
    ld (gameover), a
    pop af
    ret
no_pit_death:
    pop af
;    call print_tunnels; calls scroll
;    call print_flags;
    ret
    
print_tunnels:
    ;print the buffer
    ld hl, tunnelstext
    call printline
    
    ;11,15,22
    ld de, (currroomaddr) ; load addr of byte with tunnel
    inc de
    inc de
   

    ld hl, (D_FILE) ;1st
    ld bc, 673
    add hl, bc
    ld a, (de)
    push de
    call itoa
    pop de
    
    ld hl, (D_FILE) ;2nd
    ld bc, 677
    add hl, bc
    inc de
    ld a, (de)
    push de
    call itoa
    pop de
    
    ld hl, (D_FILE) ;3rd
    ld bc, 684
    add hl, bc
    inc de
    ld a, (de)
    call itoa
    call scroll
    ret
    
get_flags_byte:
    ld hl, (currroomaddr) ; load addr of byte with tunnel
    ld de, 5 ; 5 byte offset
    add hl, de
    ld a, (hl) ; get flags bytes
    ret
;prints bat, wumpus, and draft messages
print_flags:
    call get_flags_byte
    push af ; save flags
    and 32
    jp z, nopit;
    ld hl, pitwarning
    call printline
    call scroll
nopit:
    pop af ; restore flag byte
    push af ; save it
    and 8
    jp z, nobats;
    ld hl, batswarning
    call printline
    call scroll
nobats:
    pop af; restore flag byte
    push af
    and 2; bit 2 = next to wumpus
    jp z, nowumpus;
    ld hl, wumpuswarning
    call printline
    call scroll
nowumpus:
    pop af;
    ret

;this subroutine scrolls the display file up (assumes its full)
scroll:
    ld de, (D_FILE)
    inc de ; don't overwrite 1st cr in d_file
    ld h, d ; de -> hl
    ld l, e
    ld bc, 33; 33 chars per line
    add hl, bc; hl is next line
    ld b,0
    ld c, 21; bc no contains loop counter (20 lines)
 
scrloop:
    push bc ; save loop counter
    ld bc, 33; 33 chars per line
    ldir ; copies hl to de until bc is 0
    pop bc ; restore loop counter
    dec c
    ld a, c
    cp 0 ; is loop done
    jp nz, scrloop
    ret
    
handle_command_input:

    ;save the command that was entered
    ;make sure buffer[0] is m or s
    ld a, (buffer)
 
    ;now that we saved the buffer, we can clear it
    push af
    call scroll;
    call clearbuf;
    pop af
    
    cp $32 ;  'm'
    jp z, validcommand
    cp $38 ;  's'
    jp z, validcommand 

;bad command
    call promptcommand;
    ret    ; valid input was not entered
    
validcommand:    
    ld (command), a ;store command
    
    ;set the flag that we are taking room input
    ld a, $01
    ld (inputstate),a
    
    call promptroom;
    ret    

;convert the room that was enter to an int
;this function t akes the address of the rightmost
;hl address of rightmost byte
;c number of bytes in the buffer
;result is returned in bc

handle_room_input:
    ;set up hl to be the buffer addr + num chars entered
    ld hl, buffer
    ld bc, (bufferix)
    ;ld c,b
 
    ld d, 0
    ld e, c
    add hl, de
    dec hl
    call atoi ; result in bc
    
    call validate_move;
    cp 0
    jp z, invalid_room

    ld a, c
;    dec a
    ld (roomentry), a
    
    call scroll;
    
    ;now we have to look at what the last option was
    ld a, (command)
    cp $32
    push af
    call z, move_player
    pop af ; load flags back
    cp $38
    call z, shoot_arrow
    ;did moving the player result in death?
    ld a, (gameover)
    cp 1
    ret z
    
    ;reset input state to taking a command
    ld a, 0
    ld (inputstate), a
    
    call scroll    
    call clearbuf;
    call promptcommand;
    ret
invalid_room:
    call scroll    
    call clearbuf;
    call print_tunnels;
    call promptroom;
    ret
 
shoot_arrow
    ld hl, shootarrowmessage
    call printline
    call scroll
    
    ;set the game over flag
    ld a, 1
    ld (gameover), a
    
    
    ;was the wumpus in that room
    ld a, (roomentry)
    ld c, a
    call get_room_ptr ; result in hl
    ld de, 5 ; 5 byte offset
    add hl, de
    ld a, (hl) ; get flags bytes
    and 1
    jp nz, arrow_hit
arrow_miss:
    ld hl, playereatenmessage
    call printline
    call scroll
    ret
arrow_hit:
    ld hl, victorymessage
    call printline
    call scroll
    ret
    
;this subrountine converts the room number its address
;the address is returned in hl
set_room_addr
    push af
    push bc
    push de
    push hl
    ld a, (curroom) ; room number (1 based)
    dec a
    ld d, 0
    ld e, a
    ld a, 6; size of room in bytes (2 byte name, 3 rooms, 1 flags)
    call DE_Times_A ; result in hl now add it to base
    ld bc, room1; load base addr
    add hl, bc ; add offset to base
    
    push hl ;switch hl, bc'
    push bc
    pop hl
    pop bc
    ld hl, currroomaddr
    ld (hl), c
    inc hl
    ld (hl), b
    pop hl
    pop de
    pop bc
    pop af
    ret
;this subroutine checks if the player can go in specified direction
;c - the room to move to
validate_move:
    ld hl, (currroomaddr)
    inc hl
    inc hl
    ld b, 3
validate_move_loop:    
    ld a, (hl)
    cp c
    jp z, valid_move
    inc hl
    djnz validate_move_loop
    ld a, 0
    ret
valid_move:
    ld a, 1
    ret
;moves the player to the selected room
move_player:
    ;make sure the selected room is attached to the current room
    ld a, (roomentry)
    ld (curroom), a
    call set_room_addr

;    call scroll
    call print_current_room;

    call handle_hazards

    ;is the player dead?
    ld a, (gameover)
    cp 1
    ret z
    
    ; print tunnel
    call print_tunnels
    call print_flags
    ret
;
;compute the pointer for the room
;room number in register c
;address returned in hl
get_room_ptr:
    push af
    push bc
    push de
    dec c
    ld d, 0
    ld e, c ;room number
    ld a, 6 ; size of room data
    call DE_Times_A ; result in HL
    ld de, room1
    add hl, de
    pop de
    pop bc
    pop af
    ret

    
set_up_game:
    
    ;clear buffer
    call clearbuf
    
    ;clear death byte
    ld a, 0
    ld (gameover), a

    ;clear the last commadn
    ld (command), a
    ld (inputstate), a

    ;put player at start
    ld a, 1
    ld (curroom), a

    call set_room_addr
    
;    call random_20 ; put random in a
    ld c, 1; wumpus bit
    ld a, 2; 
    call set_room_flag  ; room in c, flag in a

;    call random_20 ; put random in a
    ld c, 4; bat bit
    ld a, 4; 
    call set_room_flag  ; room in c, flag in a

 ;   call random_20 ; put random in a
    ld c, 4; bat bit
    ld a, 6; 
    call set_room_flag  ; room in c, flag in a

 ;   call random_20 ; put random in a
    ld c, 16;pit bit
    ld a, 15;  
    call set_room_flag  ; room in c, flag in a

 ;   call random_20 ; put random in a
    ld c, 16;  pit bit
    ld a, 16;  room#    
    call set_room_flag  ; room in c, flag in a
    
    call scroll
    call print_current_room;
    call print_tunnels; calls scroll
    call print_flags;
    call promptcommand

    ret
;This subroutine set the flag in a room then sets teh flags in the adjacent rooms
;a contains room number to set flag for
;c contains the bit flag to OR onto the room
;1 = wumpus | 2 = next to wumpus | 4 = bat | 8 = next to bats | 16 = pit | 32 = next to pit
set_room_flag:
    
    ;convert it to a ptr
     
    push bc
    ld c, a
    call get_room_ptr ; takes # in c, puts addr in hl
    pop bc
    push hl; save room address
    
    ld d, 0
    ld e, 5; add 5 bytes to get the flags byte
    add hl, de
    
    ;set the requested bit
    ld a, (hl)
    or c
    ld (hl), a; store the bat bit
    
    ;shift the bit left and appy the flag to the adjacent rooms
    sla c
    pop hl; restore room address for subroutine
    call set_adjacent_room_flags
    
    ret
;This subroutine set the flags adjacent in the room adjacent to one that has bats
;addr of room is in hl
;c = value to OR onto the flags
set_adjacent_room_flags:
    ;add 2 bytes to room addr to get to the adjacent rooms
    inc hl
    inc hl
    ;loop three times
    ld b, 3 ; loop counter
flag_loop:
    push hl; save addr of adjacent room byte
    push bc; save loop counter
    ld c, (hl);get the number of the room that is adjacent to hl
    
    ;convert it to a ptr
    call get_room_ptr ; addr in hl
    
    ld d,0;add five bytes to get the flags offset
    ld e,5
    add hl, de
    ld a, (hl) ; get the flags byte
    pop bc ; restore loop counter or bit to OR
    or c ; set bit
    ld (hl), a ;store it back
    pop hl ;restore addr of adjacent room byte
    
    inc hl ; increment src add
    djnz flag_loop
    ret
    
DE_Times_A:
;Inputs:
;     DE and A are factors
;Outputs:
;     A is not changed
;     B is 0
;     C is not changed
;     DE is not changed
;     HL is the product
;Time:
;     342+6x
;
     ld b,8          ;7           7
     ld hl,0         ;10         10
       add hl,hl     ;11*8       88
       rlca          ;4*8        32
       jr nc,$+3     ;(12|18)*8  96+6x
         add hl,de   ;--         --
       djnz $-5      ;13*7+8     99
     ret             ;10         10    
Multiply:                        ; this routine performs the operation HL=D*E
  ld hl,0                        ; HL is used to accumulate the result
  ld a,d                         ; checking one of the factors; returning if it is zero
  or a
  ret z
  ld b,d                         ; one factor is in B
  ld d,h                         ; clearing D (H is zero), so DE holds the other factor
MulLoop:                         ; adding DE to HL exactly B times
  add hl,de
  djnz MulLoop
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
    
    pop hl ; restore addr
    dec hl
    
    pop af ; restore loop counter
    dec a
    jp nz, atoiloop;

    ;finished loop - number was valid
  ;  ld hl, $01
 ;   push hl
    ret
invalid:
    pop bc
    pop hl
    pop af
;    ld bc, $FFFF
;  push bc
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

;return a random number < 20 in a
random_20
    ld a, r;
    and $7f ;01111111
    ld c, 20
toobig:
    sub c
    jp m, rnd_done ; jump on no minus sign
    jp toobig;
rnd_done:
    add a, c
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;VARIABlES;;;;;;;;;;;;;;;;;;;;;;;;;    
kbstatus:
    DEFB $ff, $ff;
keydown:
    DEFB $00;
buffer:
    DEFB $ff, $ff, $ff, $ff, $ff, $ff,$ff, $ff,$ff, $ff; storage for the 2 keyboard code bytes
bufferix:
    DEFB $00, $00
inputstate:
    DEFB $00 ; 0 = accepting m | s,  1 = accepting room | 2 = accepting y/n
command:
    DEFB $00 ;   m = move s = shoot
curroom:
    DEFB $01 ;  
roomentry:
    DEFB $00    
currroomaddr:
    DEFB $00, $00
gameover:
    DEFB $00
welcome:
    DEFB _W, _E, _L, _C, _O, _M, _E, $00, _T, _O, $00, _H, _U, _N, _T, $00, _T, _H, _E, $00, _W, _U, _M, _P, _U, _S, $FF;
welcome2:
    DEFB _O, _R, _I, _G, _I, _N, _A, _L, $00, _V, _E, _R, _S, _I, _O, _N, $00, _B, _Y, $00, _G, _R, _E, _G, $00, _Y, _O, _B, $FF
welcome3:
    DEFB _Z, _X, _8, _1, $00, _P, _O, _R, _T, $00, _B, _Y, $00, _E, _V, _A, _N, $00, _C, $1B, $00, _W, _R, _I, _G, _H, _T, $00, _2, _0, _1, _5, $FF
msprompt:
    DEFB $32, $34, $3B, $2A, $00, $34, $37, $00, $38, $2D, $34, $34, $39, $0F, $00, $10, $32, $1A, $38, $11, $FF;
roomprompt:
    DEFB $3C, $2D, $2E, $28, $2D, $00, $37, $34, $34, $32, $0F, $00, $00, $00, $00, $FF;
playagainprompt:
    DEFB _P, _L, _A, _Y, $00, _A, _G, _A, _I, _N, _QM, _OP, _Y, _CM, _N, _CP, $FF
currentrooomtext:
    DEFB $3E, $34, $3A, $00, $26, $37, $2A, $00, $2E, $33, $00, $37, $34, $34, $32, $00, $00, $00, $FF
tunnelstext:
    DEFB $39, $3A, $33, $33, $2A, $31, $38, $00, $39, $34, $00, $00, $00, $1A, $00, $00, $00, $1A, $26, $33, $29, $00, $00, $00, $FF 
batswarning:
;    DEFB $39, $3A, $33, $33, $2A, $31, $38, $00, $39, $34, $00, $00, $00, $1A, $00, $00, $00, $1A, $26, $33, $29, $00, $00, $00, $FF 
    DEFB $38, $36, $3A, $2A, $26, $30, $16, $27, $26, $39, $38, $00, $33, $2A, $26, $37, $27, $3E, $00, $02, $06, $00, $02, $06, $FF
pitwarning:
;    DEFB $39, $3A, $33, $33, $2A, $31, $38, $00, $39, $34, $00, $00, $00, $1A, $00, $00, $00, $1A, $26, $33, $29, $00, $00, $00, $FF 
    DEFB $11, $11, $11, $29, $37, $26, $2B, $39, $11, $11, $11, $FF
wumpuswarning:
    DEFB _AS,_AS,_AS,_I, $00, $38, $32, $2A, $31, $31, $00, $26, $00, $3C, $3A, $32, $35, $3A, $38, _AS,_AS,_AS,$FF
pitdeathmessage:
    DEFB _AS, _AS, _AS, $26, $26, $26, $26, $26, $26, $26, $26, $16, $35, $2E, $39, _AS, _AS, _AS, $FF
bats_fly_message:
    DEFB _B, _A, _T, _S, $00, _H, _A, _V, _E, $00, _F, _L, _O, _W, _N, $00, _Y, _O, _U , $00, _T, _O, $00, _R, _O, _O, _M, $00, $00, $00, $FF    
playereatenmessage:
    DEFB _AS, _AS, _AS, _T, _H, _E, $00, $_W, _U, _M, _P, _U, _S, $00, _A, _T, _E, $00, _Y, _O, _U, _AS, _AS, _AS, $FF
shootarrowmessage:
    DEFB _AS, _AS, _AS, _T, _H, _W, _A, _N, _G, _AS, _AS, _AS, $FF
victorymessage:
    DEFB _AS, _AS, _AS, _Y, _O, _U, $00, _K, _I, _L, _L, _E, _D, $00, _T, _H, _E, $00, _W, _U, _M, _P, _U, _S, _AS, _AS , _AS, $FF
;2byte label, three bytes for the number of the connecting rooms, one byte for flags
;bits from left to right
; |0|0|next to pit|has pit|next to bats|has bats|next to wumpus|has wumpus|
room1:
    DEFB $00, $1D, $02, $05, $06, $00
room2:
    DEFB $00, $1E, $01, $03, $08, $00 
room3:
    DEFB $00, $1F, $02, $04, $0A, $00
room4:
    DEFB $00, $20, $04, $05, $12, $00
room5:
    DEFB $00, $21, $01, $04, $14, $00 
room6:
    DEFB $00, $22, $01, $07, $0F, $00
room7:
    DEFB $00, $23, $06, $08, $0F, $00 
room8:
    DEFB $00, $24, $07, $09, $02, $00
room9:
    DEFB $00, $25, $08, $0A, $11, $00 
room10:
    DEFB $1D, $1C, $03, $09, $0B, $00 
room11:
    DEFB $1D, $1D, $0A, $0C, $12, $00 
room12:
    DEFB $1D, $1E, $04, $0B, $0D, $00 
room13:
    DEFB $1D, $1F, $0C, $0E, $13, $00
room14:
    DEFB $1D, $20, $05, $0D, $0F, $00
room15:
    DEFB $1D, $21, $06, $0E, $14, $00
room16:
    DEFB $1D, $22, $07, $12, $14, $00
room17:
    DEFB $1D, $23, $09, $10, $12, $00
room18:
    DEFB $1D, $24, $0B, $11, $13, $00 
room19:
    DEFB $1D, $25, $0D, $12, $14, $00 
room20:
    DEFB $1E, $1C, $0E, $10, $13, $00 
    
;delaycounter:
;    DEFB $80; 128d
    
    
; ===========================================================
; code ends
; ===========================================================
;end the REM line and put in the RAND USR line to call our 'hex code'
#include "line2.asm"

;display file defintion
#include "screen.asm"               

;close out the basic program
#include "endbasic.asm"