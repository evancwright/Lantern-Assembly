; TRS-80 SAVE TEST
; Assemble with: z80asm -nh save.asm

;KEYIN EQU	0040H - defined in main
;CRTBYTE EQU  0033H - defined in main

	;CLS EQU 01C9H
 		
save_sub
	call open_file
	call write_data
	call close_file
	ret	

*MOD
restore_sub
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
	jp c,$bf?
	cp 54d; 'ascii '6'
	jp nc,$bf?

	
	ld hl, FCB+4
	ld (hl),a    ; overwrite char in filename
	
	ld hl,FCB
	call OUTLINCR
	
	; open the files	
	ld de,FCB ;Point to the File Control Block
	ld hl,IOBUF ;Point to the disk file I/O buffer
	ld b,0 ;Specify the Logical Record Length (255)
	call 4420h ; call open/create new sub
	call nz,IOERR ;Transfer on a returned error
	jp $x?
$bf?	ld hl,BADSLOT ; print welcome,author,version
	call OUTLINCR
	inc sp
	inc sp
	ret
IOERR
  	add 65  ; convert err to an ascii letter
	call CRTBYTE
	ld hl,IOERRSTR ; print err msg
	call OUTLINCR	
$x?	ret

*MOD
close_file

	; @CLOSE SVC-60 Close an open disk file	
	ld de,FCB ;Point to the open File Control Block
	;ld a,SVCCLOSE ;Identify the SVC
	;rst 40 ;Invoke the SVC
	call 4428h ; close
	jp nz,IOERR ;Transfer on a returned error
	ld hl,DONE
	call OUTLINCR
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
	
IORES DB 0
IOERRSTR DB "I/O ERROR",0		
 
;FILE CONTROL BLOCK IS A 32 BYTE BLOCK
;WITH THE FILE NAME FOLLOWED BY AN EXT CHAR

FCB
	DB "SAVE0/SAV:0",03h
	DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		
GETOFNAME DB "Enter save slot(1-5):",0
	db 0

BADSLOT DB "bad slot number",0

WRITING DB "SAVING...",0
LOADING DB "LOADING...",0
IOBUF 
;	DC 256,0ah ; must be 256	END START		
	DS 256	
	
