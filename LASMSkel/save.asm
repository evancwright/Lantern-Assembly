;save restore code

save_sub
	;hl = start addr
	;de = end addr
	ld hl,SAVESTART
	ld de,SAVEEND
	save
	ret


*MOD
restore_sub
	;hl = start addr
	ld hl,SAVESTART
	ld de,SAVEEND
	restore	
	call look_sub
@x	ret
