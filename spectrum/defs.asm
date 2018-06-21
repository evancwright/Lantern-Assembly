;defs.asm
;program defs for ZX Spectrum

UPRSCRN	equ 2
OPNCHL equ 5633 ; sets output channel
PRNSTR equ 8252 ; string in de, len in bc
NEWLINE equ 13  ; cr
SETXY equ 22 ; control char. next 2 bytes are y,x
CHAROUT equ 16 ; rst CHAROUT will output a char to channel
;SCREEN equ 
;SCRSIZE