;doeventsZ80.asm

*MOD
do_events
*INCLUDE event_jumps_Z80.asm
	call player_has_light
	cp 1
	jp z,$y?
	ld a,(turnsWithoutLight)
	inc a
	ld (turnsWithoutLight),a
	jp $x?
$y?	ld a,0
	ld (turnsWithoutLight),a
$x?	ret
