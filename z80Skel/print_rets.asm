;z80 - print returns
;these are long jumped to, not 'called'

print_ret_pardon
	ld hl,pardon
	call OUTLIN
	call printcr
	ret

print_ret_no_io
	ld hl,missing_io 
	call OUTLIN
	call printcr
	ret
	
	
print_ret_bad_verb
	ld hl,badverb
	call OUTLIN
	ld hl,word1
	call OUTLIN
	ld hl,period
	call OUTLIN	
	call printcr
	ret

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

print_ret_dont_see
	ld hl,dontsee
	call OUTLIN
	call printcr
	ret	

print_ret_donthave
	ld hl,donthave
	call OUTLIN
	call printcr
	ret

print_ret_not_openable
	ld hl,cantopen
	call OUTLIN
	call printcr
	ret
	
	
	
pitchdark DB "IT IS PITCH DARK.",0h
dontsee  DB "YOU DON'T SEE THAT.",0h
donthave DB "YOU DON'T HAVE THAT.",0h
cantopen DB "THAT'S N0T SOMETHING YOU CAN OPEN.",0h
badnoun DB "I DON'T RECOGNIZE THE WORD '",0h ; null	
badverb DB "I DON'T KNOW THE VERB '", 0 ; null	
missing_io DB "IT LOOKS LIKE YOU ARE MISSING THE OBJECT OF THE PREPOSITION.", 0h
pardon DB "PARDON",3fh,0 ; null
period DB "'.", 0 ; null
		
