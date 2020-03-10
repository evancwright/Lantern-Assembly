save_sub
	lda #<notimpl
	sta strAddr
	lda #>notimpl
	sta strAddr+1
	jsr printstrcr
   rts
   
restore_sub
	lda #<notimpl
	sta strAddr
	lda #>notimpl
	sta strAddr+1
	jsr printstrcr
   rts

notimpl ASC 'Not implemented.'
	DB 0