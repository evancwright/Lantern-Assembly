;sentences running routines
*MOD
;NOTES: handled vs. action_run
;handled: reset each time
;action_run: cumulative
;calls run_actions...
;   which calls run_actions_ and run_wildcards
;runs built-in verbs and custom actions
run_sentence
		;clear the handled flag
		ld a,0
		ld (handled),a
		;run checks (these return if not met)		
		ld ix,check_table
$lp?	ld a,(ix)
		cp 255
		jp z,$d?
		ld a,(sentence)
		cp (ix) ; compare to verb
		jp nz,$c?
		ld a,1			;flag handled 
		ld (handled),a
		ld hl,$nxt? ; put return address for "call"
		push hl  ; "call" to check rountine
		ld l,(ix+1)
		ld h,(ix+2)
		jp (hl)
$nxt?
$c?		inc ix	; skip to next entry
		inc ix
		inc ix
		jp $lp?
$d?		nop;
		;run before
		ld ix,preactions_table
		call run_actions
		;run instead
		ld ix,actions_table
		call run_actions
		ld a,(action_run)
		cp 1
		call nz,run_default_sentence
		;run 'after' actions
		ld ix,postactions_table
		call run_actions
		 
		;was it handled?
		ld a,(handled)
		cp 1
		jp z,$x?
		ld hl,confused
		call OUTLINCR
$x?		ret

;actions table in ix
;post condition: action_run = 1
;if a sentence was run
;if an exact match isn't found,
;an attempt is match to find and run
;a wildcard match using the same table
*MOD
run_actions
	push ix
	push iy
	ld iy,sentence
	call run_actions_
	
	ld a,(action_run)
	cp 1
	jp z,$x?
	
	pop iy		;reload ix,iy
	pop ix
	push ix
	push iy
	
	ld iy,wildcards
	call run_wildcards	
$x?	pop iy
	pop ix
	ret

;runs exact match sentences  (all 4 words) 
;from the table pointed to by ix
;sets both handled and action_run?
*MOD
run_actions_
		push bc
		push de
		push hl
		push ix 
		push iy 
		ld a,0				; clear flag
		ld (action_run),a
;		ld iy,sentence
		ld de,6 	;size of entry
@lp?	ld a,(ix)	; load verb from table
		cp 0ffh		; hit end of table
		jp z,$x? 
		cp (iy)		; verb match
		jp nz,$c?
		ld a,(ix+1)
		cp (iy+1)				
		jp nz,$c?			; d.o.'s don't match
		ld a,(ix+2)
		cp (iy+2)		
		jp nz,$c?			; preps don't match
		ld a,(ix+3)
		cp (iy+3)		
		jp nz,$c?			; i.o. 's don't match
		ld a,1
		ld (handled),a
		push ix	; ix -> hl
		pop hl
		inc hl	; move 4 bytes to sub routine
		inc hl
		inc hl
		inc hl
		ld e,(hl)
		inc hl
		ld d,(hl)
		push de	; de -> hl
		pop hl 
     	ld bc,$nxt?      ; push return addr on stack
		push bc
		jp (hl)			; return will pop stack
$nxt?	ld a,1
		ld (action_run),a
		ld (handled),a
		jp $x?				; done 
$c?		add ix,de			; skip to next entry 
		jp @lp?
$x?		pop iy
		pop ix
		pop hl
		pop de
		pop bc
		ret

action_run DB 0
*MOD
run_default_sentence
		push bc
		push de
		push hl
		ld ix,sentence_table
$lp?	ld de,3		; reload de
		ld a,(ix)
		cp 0ffh ; end?
		jp z,$x?
		ld hl,sentence
		cp (hl)		; equal to verb?
		jp nz,$c?
		ld a,1
		ld (handled),a
		push ix	; ix -> hl
		pop hl
		inc hl		;skip 1 byte to function address
		ld e,(hl)
		inc hl
		ld d,(hl)
		push de	; de -> hl
		pop hl
     	ld bc,$nxt?      ; push return addr on stack
		push bc
		jp (hl)			; return will pop stack
$nxt?	ld de,3		; reload de
$c?		add ix,de		;skip to next
		jp $lp?
$x?		pop hl
		pop de
		pop bc
		ret


;ix contains sentence table addr
;if a sentence is run, action_run
;is set to 1

*MOD
run_wildcards
	push af
	push de
	push hl
	push iy
	
	ld	iy,sentence
	
	;save old sentence
	ld  a,(iy+1)
	ld (wildcards+1),a 
	ld  a,(iy+3)
	ld (wildcards+3),a 
	
$lp?	
		ld a,(ix)
		cp 255		; hit end of table?
		jp z,$x?
		
		cp (iy) ; verb match?
		jp nz, $c?
		
		ld a,(ix+2)
		cp (iy+2) ; prep match?
		jp nz, $c?
		
		;does the sentence have a wildcard in the dobj?
		ld a,(ix+1)
		cp ANY_OBJECT
		jp nz,$sk?
		ld a,254		; put the '*' in the do
		ld (sentence+1),a
$sk?
		;does the sentence have a wildcard in the iobj?
		ld a,(ix+3)
		cp ANY_OBJECT
		jp nz,$s2?
		ld a,254		; put the '*' in the io
		ld (sentence+3),a
$s2?		
		;now see if they match
		ld a,(ix+1)	;compare do
		cp (iy+1)
		jp nz, $c?
		
		ld a,(ix+3)	; compare io
		cp (iy+3)
		jp nz, $c?

		;if here, we have a match	
		
		push ix	; ix -> hl
		pop hl
		
		inc hl	; move 4 bytes to sub routine
		inc hl
		inc hl
		inc hl
		ld e,(hl)
		inc hl
		ld d,(hl)
		push de	; de -> hl
		pop hl
		
		;replace the wildcards with 
		;the actual objects
		ld a,(wildcards+1)
		ld (sentence+1),a
		ld a,(wildcards+3)
		ld (sentence+3),a
		
     	ld bc,$nxt?      ; push return addr on stack
		push bc
		jp (hl)			; return will pop stack
$nxt?	ld a,1
		ld (action_run),a
		ld (handled),a
		jp $x?
		
$c?		;restore sentence	
		ld a,(wildcards+1)
		ld (sentence+1),a
		
		ld a,(wildcards+3)
		ld (sentence+3),a
		
		ld de,6 ; skip and repeat
		add ix,de 
		jp $lp?
		
$x?		pop iy
		pop hl
		pop de
		pop af
		ret

confused DB "I don't understand.",0h
wildcards DB 0,0,0,0
handled DB 0  ; whether default or user sentence was run