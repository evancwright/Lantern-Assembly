;intro6502.asm
;Evan Wright (c) 2017

show_intro
		jsr printcr
		jsr printcr
		
		lda #<welcome
		sta strAddr
		lda #>welcome
		sta strAddr+1
		jsr printstrcr
		jsr printcr

		lda #<author
		sta strAddr
		lda #>author
		sta strAddr+1
		jsr printstrcr
		jsr printcr

		lda #<version
		sta strAddr
		lda #>version
		sta strAddr+1
		jsr printstrcr
		jsr printcr
		rts
		