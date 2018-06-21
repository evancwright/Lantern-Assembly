;save/restore routines for Apple2
#define PRODOS $BF00

; $C0  =  create a new file  
; $C1  =  destroy an existing file
; $C4  =  get file info (a dummy command, do not use)
; $C8  =  open a file (reference numbers 0, 1, or 2)
; $CA  =  read from a file
; $CB  =  write to a file
; $CC  =  close a file
; $CE  =  position file marker
save
	lda #saving%256 ; print the prompt
	sta strAddr
	lda #saving/256
	sta strAddr+1
	jsr printstrcr
    jsr open_file
	jsr write_file
	jsr close_file
	lda #done%256	; print "done"
	sta strAddr
	lda #done/256
	sta strAddr+1
	jsr printstrcr
	rts

;** Open an existing file   
;command number $C8
;parameters:     
; 0      (number-of-parameters) (3)      _required_
; +1     (pointer to pathname)           _required_
; +3     (pointer to i/o buffer)         _required_**
; +5     (reference number, 0, 1, 2)     _required_ (result)
open_file
	lda 3
	sta numparams
	lda #filename%256 ; file path to open
	sta $params+1
	lda #filename/256
	sta $params+2
	lda #diskbuf%256	; io buffer
	sta $params+3
	lda #diskbuf/256
	sta $params+4
	lda #0
	sta $params+5   ; file ref num
	jsr PRODOS
	.byte $C8 	 ; ProDOS command number = C8 (read)
    .word params ; address of parameter table, lo/hi
	rts

; write data
write_file
	lda #$04
    sta numparams	;store number of params
	lda #beginData%256 ;store the buffer
	sta $params+1
	lda #beginData/256
	sta $params+2
	sec ; subtract end from start
	lda #endData%256
	sbc #beginData%256
	sta params+3
	lda #endData/256
	sbc #beginData/256
	sta params+4	
	jsr PRODOS
	.byte $C8 	 ; ProDOS command number = C8 (read)
    .word params ; address of parameter table, lo/hi	
	rts
	
; closes the open file
close_file
	lda 1
	sta numparams
	lda fileref
	sta params+1
	jsr PRODOS
	.byte $CC
	.word params ; address of parameter table, lo/hi
    rts 
  	
fnf	.text "FILE NOT FOUND."
	.byte 0		
selslot	.text "SELECT A SLOT[1-5]."
	.byte 0		
saving	.text "SAVING..."
	.byte 0		
 
params  
numparams 		.byte 0 ; 
				.byte 0 ;
				.byte 0 ;
				.byte 0 ;
fileref			.byte 0 ; filled in by ProDos
	
diskbuf .byte 0 ; just read one byte at a time	

filename .text "SAVE0.SAV"
	.byte 0 