;save/restore routines for Apple2
#define PRODOS $BF00

#define MLI  $BF00 ; PRODOS MACHINE LANGUAGE INTERFACE
#define FCREATE $C0
#define FDESTROY $C1
#define FGETINFO $C4
#define FOPEN $C8
#define FCLOSE $CC
#define FWRITE $CB
#define FREAD $CA
#define SET_PREFIX $C6
#define FILE_NOT_FOUND $46
#define TEXT_FILE $04
#define BINARY_FILE $06
#define NORMAL_ACCESS $C3
#define STANDARD_FILE $01

save_sub
	lda #0
	sta ioErrFlg
	lda #saving%256 ; print the prompt
	sta strAddr
	lda #saving/256
	sta strAddr+1
	jsr printstrcr
	jsr destroy_file
	jsr create_file
    jsr open_file
	jsr write_file
	jsr close_file
	lda #done%256	; print "done"
	sta strAddr
	lda #done/256
	sta strAddr+1
	jsr printstrcr
	rts

	.module restore_sub
restore_sub
	lda #restoring%256 ; print the prompt
	sta strAddr
	lda #restoring/256
	sta strAddr+1
	jsr printstrcr
	jsr open_file
	jsr read_file
	jsr close_file
	jsr look_sub
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
	.db FDESTROY
	.dw destroyBlock 
	rts
	
	.module	create_file	
create_file	
	jsr MLI
	.db FCREATE
	.dw createParams
	bcs _ferr
	rts
_ferr	
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
	.module open_file
open_file
	jsr MLI
	.db FOPEN
	.dw openParams 
	bcs _ferr
	rts
_ferr
	sta ioErrFlg
	jsr print_open_err
	rts

; write data
write_file
	lda fRef ; set fileRef
	sta writeParams+1
	jsr PRODOS
	.byte FWRITE 	 ; ProDOS command number = C8 (read)
    .word writeParams ; address of parameter table, lo/hi	
	bcs _err
	rts
_err
	sta ioErrFlg
	jsr print_io_err
	rts
	
 
; write data
	.module read_file
read_file
	lda fRef ; set fileRef
	sta writeParams+1
	jsr PRODOS
	.byte FREAD 	 ; ProDOS command number = C8 (read)
    .word writeParams ; address of parameter table, lo/hi	
	bcs _err
	rts
_err
	sta ioErrFlg
	jsr print_io_err
	rts
	
	.module close_file
close_file
	lda fRef
	sta closeRef
	jsr MLI
	.db FCLOSE
	.dw closeParams
	bcs _ferr
	rts
_ferr
	sta ioErrFlg
	jsr print_close_err
	rts

	
print_io_err
	lda #ioErrMsg%256
	sta $strAddr
	lda #ioErrMsg/256
	sta $strAddr+1		
	jsr printstrcr
	rts

print_open_err
	lda #opnErrMsg%256
	sta $strAddr
	lda #opnErrMsg/256
	sta $strAddr+1		
	jsr printstrcr
	rts
	
print_fnf_err
	lda #fnfMsg%256
	sta $strAddr
	lda #fnfMsg/256
	sta $strAddr+1		
	jsr printstrcr
	rts	

print_close_err
	lda #closeErrMsg%256
	sta $strAddr
	lda #closeErrMsg/256
	sta $strAddr+1		
	jsr printstrcr
	rts
	
destroyBlock
	.db 1
	.dw nameLen
	
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
	.db 7
	.dw nameLen  ; len + buffer
	.db NORMAL_ACCESS
	.db BINARY_FILE
	.dw 0  ; aux type?
	.db STANDARD_FILE
	.dw 0  ; create date
	.dw 0  ; create time

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
	 .db 3  ; param count
	 .dw nameLen
	 .db 00,9E  ; buffer
fRef .db 0 ; fileRef
	

closeParams
	.db 1   ; param count
closeRef
	.db 0

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
	.db 4
	.db 0 ; fileRef (filled in by write call)
	.dw beginData
	.dw endData-beginData
	.dw 0
	
 
  	
fnf	.text "FILE NOT FOUND."
	.byte 0		
selslot	.text "SELECT A SLOT[1-5]."
	.byte 0		
saving	.text "SAVING..."
	.byte 0		
restoring	.text "RESTORING..."
	.byte 0  
	
diskbuf .byte 0 ; just read one byte at a time	
	
fnfMsg .text "FILE NOT FOUND."
			.byte 0			
ioErrMsg .text "I/O ERR."
			.byte 0	
opnErrMsg .text "OPEN ERR."
			.byte 0	
closeErrMsg .text "CLOSE ERR."
			.byte 0				
ioErrFlg .byte 0 
			
nameLen .db 13
nameBuf .text "/SYSTEM/SAVE0"			
nameEnd
			 	