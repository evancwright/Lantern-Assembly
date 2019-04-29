;z80 - print returns
;these are long jumped to, not 'called'

;print_ret_pardon
;	ld hl,pardon
;	call OUTLINCR
;	ret
;
;print_ret_no_io
;	ld hl,missing_io 
;	call OUTLIN
;	call printcr
;	ret
;	
	
;print_ret_bad_verb
;	ld hl,badverb
;	call OUTLIN
;	ld hl,word1
;	call OUTLIN
;	ld hl,period
;	call OUTLINCR
;	ret

;print_ret_bad_do
;	ld hl,badnoun
;	call OUTLIN
;	ld hl,word2
;	call OUTLIN
;	ld hl,period
;	call OUTLIN	
;	call printcr
;	ret

;print_ret_bad_io
;	ld hl,badnoun
;	call OUTLIN
;	ld hl,word4
;	call OUTLIN
;	ld hl,period
;	call OUTLIN	
;	call printcr
;	ret

;print_ret_dont_see
;	ld hl,dontsee
;	call OUTLINCR
;	ret	

;print_ret_donthave
;	ld hl,donthave
;	call OUTLINCR
;	ret

;print_ret_not_openable
;	ld hl,cantopen
;	call OUTLINCR
;	ret
	
	
	
pitchdark DB "It is pitch dark.",0h
dontsee  DB "You don't see that.",0h
donthave DB "You don't have that.",0h
cantopen DB "You can't open that.",0h
badnoun DB "I don't know the word '",0h ; null	
badverb DB "I don't know the verb '", 0 ; null	
missing_io DB "Looks like you are missing a second noun.", 0h
pardon DB "Pardon?",3fh,0 ; null
period DB "'.", 0 ; null
		
