;CP/M SAVE/RESTORE


DELFILE EQU 19
OPENFILE EQU 15
CLOSEFILE EQU 15
MAKEFILE EQU 22
READSEQ EQU 20
WRITESEQ EQU 21
DMABUF EQU 80h  ;default file / io buffer

*MOD
save_sub
		ld hl,fileprmpt
		call OUTLINCR
		call getlin
		call name_to_fcb
		;delete it in case it exists
		ld hl,deleting
		call OUTLINCR
		ld c,DELFILE
		ld de,FCB
		call BDOS
		;create and open it
		ld hl,creating
		call OUTLINCR
		ld c,MAKEFILE
		ld de,FCB
		call BDOS
		;write each record
		ld a,0     ; set current rec to 0
		ld (crn),a
		ld iy,obj_table  ; save ptr
		ld a,(NumRecs)  ; how many recs to write	
		ld b,a
		call itoa
		ld hl,itoabuffer
		call OUTLINCR
$ol?	push bc ; save loop counter
		push hl
		;fill DMA area with data to save
		ld b,128 ; CP/M has 128 byte records
		ld ix,DMABUF ; dest ptr
$il?	push bc
		ld a,(iy)   ; DMA -> ram
		ld (ix),a  
		inc ix
		inc iy
		pop bc
		djnz $il?
		;write the record
		ld hl,writing
		call OUTLINCR
		ld c,WRITESEQ
		ld de,FCB
		call BDOS
		pop hl
		pop bc ; restore loop counter
		djnz $ol?
		;close the file
		ld hl,closingstr
		call OUTLINCR
		ld c,CLOSEFILE
		ld de,FCB
		call BDOS
		ld hl,saved
		call OUTLINCR
		jp $x?
$fnf?	
		ld hl,notfound
		call OUTLINCR
$x?		ret

*MOD
restore_sub
		;ask user for a file
		ld hl,fileprmpt
		call OUTLINCR
		call getlin;
		call name_to_fcb
		;open it?
		ld a,0     ; set current rec to 0
		ld (crn),a
		ld c,OPENFILE
		ld de,FCB
		call BDOS
		cp INVALID
		jp z,$fnf?
		;read records into DMA
		ld iy,obj_table ; dest addr
		ld a,(NumRecs) ; num recs to read
		ld b,a
		ld hl,numrecsstr
		call OUTLIN
		call itoa
		ld hl,itoabuffer
		call OUTLINCR
$ol?	push bc ; save loop counter		 
		ld c,READSEQ
		ld de,FCB
		call BDOS
		ld ix,DMABUF ; copy data from buffer to object_table and vars
		ld b,128
$il?	ld a,(ix)  ; read a byte from DMA area
		ld (iy),a  ; copy it to program
		inc ix
		inc iy
		djnz $il?
		pop bc  ; restore loop counter
		djnz $ol?
		;close file
		ld hl,closingstr
		call OUTLINCR
		ld c,CLOSEFILE
		ld de,FCB
		call BDOS
		;resume game
		call CLS
		call look_sub
		jp $x?  ; done
$fnf?	
		ld hl,filename
		call OUTLINCR
$x?		ret


;copies the name from the inputbuffer 
;to the file control block
*MOD
name_to_fcb	
	ld bc,8
	ld hl,INBUF
	ld de,filename
	ldir  ; de <- hl 
	ret

fileprmpt DB "Save file:",0
deleting DB "deleting file",0
creating DB "Creating file",0
writing DB "writing rec.",0
closingstr DB "closing file",0
notfound DB "File not found.",0
notopen DB "Unable to open.",0
saved DB "Game saved.",0
numrecsstr DB "num recs:",0

;FYI there is a default FCB at 5CH which is 36 bytes long
FCB  ; file control block   33 bytes
drive DB 0 ; 0 = default 1 = A 2 = B
filename DB "SAVEGAME" ; 8 bytes
fileext DB "SAV"	; 3 bytes
extent DB 0 ;
s1 DB 0 ; 
s2 DB 0 ; set to 0 for open or make - 1 byte
rc DB 0 ; set to 0 to 127  - 1 byte
data DS 16  ; reserved for system USE  - 15 byte
crn DB 0 ; current record to read byte 33


