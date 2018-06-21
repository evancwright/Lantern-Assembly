; TRS-80 SAVE TEST
; Assemble with: z80asm -nh save.asm

KEYIN EQU 40H
CRTBYTE EQU  0033H

	;CLS EQU 01C9H
	ORG 5200H
	
START
	call restore_game
	call save_game
	jp 402DH  ; return when using cmd
		
save_game
	call open_file
	call write_data
	call close_file
	ret	

*MOD
restore_game
	call open_file
	call read_data
	call close_file
	ret
	
*MOD
open_file
	ld hl,GETOFNAME ; print welcome,author,version
	call OUTLINCR
	;read a line
	ld hl,INBUF
	ld b,1 ; BUFSIZE
	ld hl,IOBUF
	ld b,1
	call KEYIN
	ld a,(hl)
	cp 49d; 'ascii '0'
	jp c,$bf
	cp 54d; 'ascii '6'
	jp nc,$bf

	
	ld hl, FCB+4
	ld (hl),a    ; overwrite char in filename
	
	ld hl,FCB
	call OUTLINCR
	
	; open the files
	ld hl,OPNING
	call OUTLINCR
	
	ld de,FCB ;Point to the File Control Block
	ld hl,IOBUF ;Point to the disk file I/O buffer
	ld b,0 ;Specify the Logical Record Length (255)
	call 4420h ; call open/create new sub
	call nz,IOERR ;Transfer on a returned error
	jp $x
$bf	ld hl,BADSLOT ; print welcome,author,version
	call OUTLINCR
	inc sp
	inc sp
	ret
IOERR
  	add a,65  ; convert err to an ascii letter
	call CRTBYTE
	ld hl,IOERRSTR ; print err msg
	call OUTLINCR	
$x	ret

*MOD
close_file
	ld hl,CLSNG ; PRINT "CLOSING"
	call OUTLINCR

	; @CLOSE SVC-60 Close an open disk file	
	ld de,FCB ;Point to the open File Control Block
	;ld a,SVCCLOSE ;Identify the SVC
	;rst 40 ;Invoke the SVC
	call 4428h ; close
	jp nz,IOERR ;Transfer on a returned error
	ret
		
*MOD
OUTLINCR
		push af
		push bc
		push de
		push hl
		push ix
		push iy
$lp?	ld a,(hl)
		cp 0
		jp z,$x?
		inc hl
		call CRTBYTE
		jp $lp?	
$x?		call printcr
		pop iy
		pop ix
		pop hl
		pop de
		pop bc
		pop af
		ret	

;prints a cr (registers are preserved)
printcr
	push af
	push bc
	push de
	push iy
	ld a,0dh ; carriage return
	call CRTBYTE
 	pop iy
	pop de
	pop bc
	pop af

	ret		
	
*MOD
write_data

	ld hl,WRITING  ;print "WRITING"
	call OUTLINCR 
 	
	;write the object table
	ld a,(ObjTblSize)
	ld b,a

	ld ix,obj_table	 
$olp?
	push bc	; save loop counter
	ld b,19 ; size of obj_table rec 
$ilp? 	
	push bc ; save inner
	ld a,(ix)
	call write_byte		
	inc ix	
	pop bc ; restore inner
	djnz $ilp?
	
 	pop bc  ; restore outer loop counter
	djnz $olp?
	
	; get number of built in vars (loop counter)
	ld a,(ix) 
	ld b,a
 	inc ix ; skip over it
	
$bvlp? 	
	push bc ; save inner
	ld a,(ix)
	call write_byte		
	inc ix	
	pop bc ; restore inner
	djnz $bvlp?

	; write user vars (THIS IS A TOTAL DUPLICATE!!!)
	ld a,(ix) ; num vars
	ld b,a
	inc ix	; skip len byte
	
$uvlp? 	
	push bc ; save inner
	ld a,(ix)
	call write_byte		
	inc ix	
	pop bc ; restore inner
	djnz $uvlp?
	
	ret
	
*MOD	
read_data
	ld hl,LOADING  ;print "LOADING"
	call OUTLINCR 
	
	ld a,(ObjTblSize)
	ld b,a
	ld ix,obj_table	 
$olp?
	push bc	; save loop counter
	ld b,19 ; size of obj_table rec 
$ilp? 	
	push bc ; save inner
	call read_byte		
	ld (ix),a  ; overwrite data table
	inc ix	
	pop bc ; restore inner
	djnz $ilp?
	
 	pop bc  ; restore outer loop counter
	djnz $olp?
	
	; read built-in  vars
	ld hl,RDVARS
	call OUTLINCR
	
	ld a,(numBuiltInVars)
 	ld b,a
 	ld ix,builtInVars;
$bvlp? 	
	push bc ; save inner
	call read_byte		
	ld (ix),a
	inc ix	
	pop bc ; restore inner
	djnz $bvlp?

	; read user vars (THIS IS A TOTAL DUPLICATE!!!)
	ld a,(numUserVars) ; size of obj_table rec 
	ld b,a
 	ld ix,userVars;
$uvlp? 	
	push bc ; save loop counter
	call read_byte		
	ld (ix),a	
	inc ix	
	pop bc ; restore loop counter
	djnz $uvlp?
	ret	
	
*MOD
write_byte
	ld de,FCB	;fbc ptr in de
	call 1bh ; put char
	jp z,$x?
	inc sp
	inc sp
	jp IOERR ;Transfer on a returned error
$x?	ret

*MOD
read_byte
	ld de,FCB	;fbc ptr in de
	call 13h ; get char
	jp z,$x?
	inc sp
	inc sp
	jp IOERR ;Transfer on a returned error
$x?	ret
	
INBUF DB 0,0,0
IORES DB 0
IOERRSTR DB "I/O ERROR",0		
BYTES DB 8
DATA DB "abcdABCD",0h

;FILE CONTROL BLOCK IS A 32 BYTE BLOCK
;WITH THE FILE NAME FOLLOWED BY AN EXT CHAR

FCB
	DB "SAVE0/SAV:0",3h
	DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		
GETOFNAME DB "Enter save slot (1-5):",0
	db 0
GETIFNAME DB "Enter restore slot (1-5):",0
	DB 0
BADSLOT DB "bad slot number",0
RDOBJTB DB "reading object table",0
RDVARS DB "reading vars",0

OPNING DB "OPENING FILE...",0
CLSNG DB "CLOSING FILE...",0
WRITING DB "SAVING...",0
LOADING DB "LOADING...",0
IOBUF 
	DC 256,0ah ; must be 256
ObjTblSize 
	db 20	
obj_table
	DC 380,0h ; must be 256 (20 fake objects)
numBuiltInVars db 9
builtInVars
;	db 1,2,3,4,5,6,7,8,9	
;	db 9,8,7,6,5,4,3,2,1
	db 255,255,255,255,255,255,255,255,255
numUserVars db 10
userVars
;	db 9,8,7,6,5,4,3,2,1,0
;	db 0,1,2,3,4,5,6,7,8,9
	db 255,255,255,255,255,255,255,255,255,255
	END START		
	
	