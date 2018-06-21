;input routines for ZX Spectrum
;(c) Evan Wright, 2017

;reads a single char and stores it in the
;keyboard input buffer
readkb
       ld hl,23560         ; LAST K system variable.
       ld (hl),0           ; put null value there.
loop   ld a,(hl)           ; new value of LAST K.	   
       cp 0                ; is it still zero
       jr z,loop           ; yes, so no key pressed.
	   ret
		
		