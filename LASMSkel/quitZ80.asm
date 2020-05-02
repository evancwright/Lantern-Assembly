;

		
quit_sub
	ld hl,bye
	call outlincr
	quit
	ret

bye DB "Ok, fine.",0
	