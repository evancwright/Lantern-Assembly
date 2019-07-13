;save/restore routines for Apple2
PRODOS EQU $BF00

MLI EQU $BF00 ; PRODOS MACHINE LANGUAGE INTERFACE
FCREATE EQU $C0
FDESTROY EQU $C1
FGETINFO EQU $C4
FOPEN EQU $C8
FCLOSE EQU $CC
FWRITE EQU $CB
FREAD EQU $CA
SET_PREFIX EQU $C6
FILE_NOT_FOUND EQU $46
TEXT_FILE EQU $04
BINARY_FILE EQU $06
NORMAL_ACCESS EQU $C3
STANDARD_FILE EQU $01


save_sub
	lda #0
	sta ioErrFlg
	jsr get_slot_num
	lda ioErrFlg
	bne :x
	lda #<saving ; print the prompt
	sta strAddr
	lda #>saving
	sta strAddr+1
	jsr printstrcr
	jsr destroy_file
	jsr create_file
    jsr open_file
	jsr write_file
	jsr close_file
	lda #<done	; print "done"
	sta strAddr
	lda #>done
	sta strAddr+1
	jsr printstrcr
:x	rts

 
restore_sub
	lda #0
	sta ioErrFlg
	jsr get_slot_num
	lda ioErrFlg
	cmp #0
	bne :x
	lda #<restoring ; print the prompt
	sta strAddr
	lda #>restoring
	sta strAddr+1
	jsr printstrcr
	jsr open_file
	lda ioErrFlg
	bne :x
	jsr read_file
	jsr close_file
	jsr look_sub
:x	rts	

 
get_slot_num
	lda #<selSlotMsg ; pick slot
	sta strAddr
	lda #>selSlotMsg
	sta strAddr+1
	jsr printstrcr
	jsr readkb
	lda $200
	cmp #176 ; a >= 30  
	bcc :err ; kb  < 30 
	cmp #186  ; <= '9'? 
	bcs :err ;  ? < 9  carry set means < 9
	jmp :x
:err	
	sta ioErrFlg  ; put non zero in flag
	lda #<badSlotMsg
	sta strAddr
	lda #>badSlotMsg
	sta strAddr+1		
	jsr printstrcr
	rts
:x	sta nameBuf+12
	rts
	
;destroys the file name whose
;name is in the buffer.
;called as part of recreating a file
;when it is written to.
;errors are not checked for. An error
;will occur on the first save trying to
;destroy a file that doesn't exist
destroy_file	
	jsr MLI
	DFB FDESTROY
	DW destroyBlock 
	rts
	
 
create_file	
	jsr MLI
	DFB FCREATE
	DW createParams
	bcs :ferr
	rts
:ferr	
	sta ioErrFlg
	jsr print_io_err
	rts	
	
	
;** Open an existing file   
;command number $C8
;parameters:     
; 0      (number-of-parameters) (3)      _required_
; +1     (pointer to pathname)           _required_
; +3     (pointer to i/o buffer)         _required_**
; +5     (reference number, 0, 1, 2)     _required_ (result)
;opens a file for reading/writing
 
open_file
	jsr MLI
	DFB FOPEN
	DW openParams 
	bcs :ferr
	rts
:ferr
	sta ioErrFlg
	jsr print_open_err
	rts

; write data
write_file
	lda fRef ; set fileRef
	sta writeParams+1
	jsr PRODOS
	DB FWRITE 	 ; ProDOS command number = C8 (read)
    DW writeParams ; address of parameter table, lo/hi	
	bcs :err
	rts
:err
	sta ioErrFlg
	jsr print_io_err
	rts
	
 
; write data
 
read_file
	lda fRef ; set fileRef
	sta writeParams+1
	jsr PRODOS
	DB FREAD 	 ; ProDOS command number = C8 (read)
    DW writeParams ; address of parameter table, lo/hi	
	bcs :err
	rts
:err
	sta ioErrFlg
	jsr print_io_err
	rts
	
 
close_file
	lda fRef
	sta closeRef
	jsr MLI
	DFB FCLOSE
	DW closeParams
	bcs :ferr
	rts
:ferr
	sta ioErrFlg
	jsr print_close_err
	rts

	
print_io_err
	lda #<ioErrMsg
	sta strAddr
	lda #>ioErrMsg
	sta strAddr+1		
	jsr printstrcr
	rts

print_open_err
	lda #<opnErrMsg
	sta strAddr
	lda #>opnErrMsg
	sta strAddr+1		
	jsr printstrcr
	rts
	
print_fnf_err
	lda #<fnfMsg
	sta strAddr
	lda #>fnfMsg
	sta strAddr+1		
	jsr printstrcr
	rts	

print_close_err
	lda #<closeErrMsg
	sta strAddr
	lda #>closeErrMsg
	sta strAddr+1		
	jsr printstrcr
	rts
	
destroyBlock
	DFB 1
	DW nameLen
	
;    7   6   5   4   3   2   1   0
;    +---+---+---+---+---+---+---+---+
;  0 | param_count = 7               |
;    +---+---+---+---+---+---+---+---+
;  1 | pathname               (low)  |
;  2 | (2-byte pointer)       (high) |
;    +---+---+---+---+---+---+---+---+
;  3 | access         (1-byte value) |
;    +---+---+---+---+---+---+---+---+
;  4 | file_type      (1-byte value) |
;    +---+---+---+---+---+---+---+---+
;  5 | aux_type               (low)  |
;  6 | (2-byte value)         (high) |
;    +---+---+---+---+---+---+---+---+
;  7 | storage_type   (1-byte value) |
;    +---+---+---+---+---+---+---+---+
;  8 | create_date          (byte 0) |
;  9 | (2-byte value)       (byte 1) |
;    +---+---+---+---+---+---+---+---+
;  A | create_time          (byte 0) |
;  B | (2-byte value)       (byte 1) |
;    +---+---+---+---+---+---+---+---+	
createParams
	DFB 7
	DW nameLen  ; len + buffer
	DFB NORMAL_ACCESS
	DFB BINARY_FILE
	DW 0  ; aux type?
	DFB STANDARD_FILE
	DW 0  ; create date
	DW 0  ; create time

;   7   6   5   4   3   2   1   0
;    +---+---+---+---+---+---+---+---+
;  0 | param_count = 3               |
;    +---+---+---+---+---+---+---+---+
;  1 | pathname               (low)  |
;  2 | (2-byte pointer)       (high) |
;    +---+---+---+---+---+---+---+---+
;  3 | io_buffer              (low)  |
;  4 | (2-byte pointer)       (high) |
;    +---+---+---+---+---+---+---+---+
;  5 | ref_num       (1-byte result) |
;    +---+---+---+---+---+---+---+---+	
openParams
	 DFB 3  ; param count
	 DW nameLen
	 HEX 00,9E  ; buffer
fRef DFB 0 ; fileRef
	

closeParams
	DFB 1   ; param count
closeRef
	DFB 0

; 7   6   5   4   3   2   1   0
;    +---+---+---+---+---+---+---+---+
;  0 | param_count = 4               |
;    +---+---+---+---+---+---+---+---+
;  1 | ref_num        (1-byte value) |
;    +---+---+---+---+---+---+---+---+
;  2 | data_buffer            (low)  |
;  3 | (2-byte pointer)       (high) |
;    +---+---+---+---+---+---+---+---+
;  4 | request_count          (low)  |
;  5 | (2-byte value)         (high) |
;    +---+---+---+---+---+---+---+---+
;  6 | trans_count            (low)  |
;  7 | (2-byte result)        (high) |
;    +---+---+---+---+---+---+---+---+
writeParams
	DFB 4
	DFB 0 ; fileRef (filled in by write call)
	DW beginData
	DW endData-beginData
	DW 0
	
 
  	
 	
selSlotMsg ASC "Select a slot number [0-9]."
	DFB 0		
saving	ASC "Saving..."
	DFB 0		
restoring	ASC "Restoring..."
	DFB 0  
	
diskbuf DFB 0 ; just read one byte at a time	
	
fnfMsg ASC "FILE NOT FOUND."
	DFB 0			
ioErrMsg ASC "I/O ERR."
	DFB 0	
opnErrMsg ASC "OPEN ERR."
	DFB 0	
closeErrMsg ASC "CLOSE ERR."
	DFB 0				
badSlotMsg ASC "BAD SLOT."
	DFB 0	
ioErrFlg DFB 0 
			
nameLen DFB 13
nameBuf ASC "/SYSTEM/SAVE0"			
nameEnd
			 	