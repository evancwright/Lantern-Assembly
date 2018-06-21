;intro6502.asm
;Evan Wright (c) 2017

show_intro
		jsr printcr
		jsr printcr
		
		lda #welcome%256
		sta strAddr
		lda #welcome/256
		sta strAddr+1
		jsr printstrcr
		jsr printcr

		lda #author%256
		sta strAddr
		lda #author/256
		sta strAddr+1
		jsr printstrcr
		jsr printcr

		lda #version%256
		sta strAddr
		lda #version/256
		sta strAddr+1
		jsr printstrcr
		jsr printcr
		rts
		