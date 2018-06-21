;events6502.asm
;(c) Evan Wright, 2017
;provides a subroutine wrapper around the events

	.module do_events
do_events
.include "event_jumps_6502.asm"
		rts
