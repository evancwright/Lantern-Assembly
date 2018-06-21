;cocovga uppercase /lower case stuff
;400 - 600 "normal" video memory (512 bytes)
;600 - 800h (COCOVGA registers 512)
;800 - A00h "64 col mode memory" (2k)
;code starts at E00
;prompt_lcase
;	lda #0
;	sta lcase
;	ldx #lcaseprmpt
;	jsr PRINT
;	jsr PRINTCR
;	jsr GETLINE
;	lda KBBUF
;	;cmpa #'y'
;	beq @y
;;	cmpa #'Y'
;	beq @y
;	bra @novga
;@y  lda #1
;	sta lcase
prompt_vga	
	ldx #vgaprmpt
	jsr PRINT
	jsr PRINTCR
	jsr GETLINE
	lda KBBUF	
	cmpa #'n'
	beq @novga
	cmpa #'N'
	beq @novga
	jsr setupvga
@novga 
	rts

;sets up the 512 cocovga buffer
setupvga
	lda #64
	sta scrwidth
	lda #32
	sta scrheight
	lda #31
	sta lastline
	ldy #2048
	sty scrsize
	; step 3
	;During VSYNC, point SAM to 512 byte page set up in step 1
	jsr init_sam
	rts

;sets 46 column mode
init_sam
	pshs d,x,y
	ldx #sam_data
	ldy #600h
	ldb #9
@lp lda ,x+
	sta ,y+
	decb
	beq @x
	bra @lp
	;sam is now setup
	;step 2
@x	pshs cc ;    save CC
    orcc #$50   mask interrupts
    pshs a ;     save PIA configuration
	;	
    lda  $ff03 
    ora  #$04 ;  ensure PIA 0B is NOT setting direction
    sta  $ff03
	;
    lda  $ff03 
    anda #$fd ;  vsync flag - trigger on falling edge
    sta  $ff03
	;
    lda  $ff03
    ora  #$01 ;  enable vsync IRQ (although interrupt itself will be ignored via mask)
    sta  $ff03
	;
    lda  $ff02 ; clear any pending VSYNC
@l1 lda  $ff03 ; wait for flag to indicate...
    bpl  @l1 ;     ...falling edge of FS (Field Sync)
    lda  $ff02 ; clear VSYNC interrupt flag
;3. During VSYNC, point SAM to 512 byte page set up in step 1
	;600h = 6/2 = page 3 = 0000011
	;even clears , odd sets
	sta  $ffC7  ;set SAM_F0
    sta  $ffC9  ;set SAM_F1
    sta  $ffCA  ;clear SAM_F2 (a-b)
    sta  $ffCC  ;clear SAM_F3 (c-d)
    sta  $ffCE  ;clear SAM_F4 (e-f)
    sta  $ffD0  ;clear SAM_F5 (0-1)
    sta  $ffD2  ;clear SAM_F6 (2-3)
;4. Also during VSYNC, write 6847 VDG combination lock via PIA1B ($FF22) bits 7:3.
	lda  $ff22 ; get current PIA value
    anda  #$07 ; mask off bits to change
    ora   #$90 ; set combo lock 1
    sta   $ff22 ; write to PIA
    anda  #$07 ; mask off bits to change
    ora   #$48 ; set combo lock 2
    sta   $ff22 ; write to PIA
    anda  #$07 ; mask off bits to change
    ora   #$A0 ; set combo lock 3
    sta  $ff22 ; write to PIA
    anda  #$07 ; mask off bits to change
    ora  #$F8 ; set combo lock 4
    sta  $ff22 ; write to PIA
;5  Still during VSYNC, configure VDG and SAM back to mode 0. (In this case, the desired CoCoVGA register page to program is 0.)
    lda  $ff22  get current PIA value
    anda #$07  mask off bits to change
    ora  #$00  select CoCoVGA register page 0
    sta  $ff22  write to PIA
    sta  $ffC0  clear SAM_V0
    sta  $ffC2  clear SAM_V1
    sta  $ffC4  clear SAM_V2	
;6. Wait for next VSYNC while SAM and VDG stream in the entire page of register values to CoCoVGA and CoCoVGA 
; displays the previous frame of video.
@l2 lda  $ff03 ; wait for flag to indicate...
    bpl  @l2   ;  ...falling edge of FS (Field Sync)
    lda  $ff02  ;clear VSYNC interrupt flag
    puls a     ; from stack... 
    sta  $ff03  ;...restore original PIA configuration
    puls cc    ; restore ability to see interrupts	
;7 Point SAM page select to video page you want to display. For this example, let's assume that this is at $E00
;which (divided by 512 bytes) is page 7.
;we're using page 2 (400)
    sta  $ffC6  ;clear SAM_F0
    sta  $ffC9  ;set SAM_F1
    sta  $ffCA  ;clear SAM_F2
    sta  $ffCC  ;clear SAM_F3
    sta  $ffCE  ;clear SAM_F4
    sta  $ffD0  ;clear SAM_F5
    sta  $ffD2  ;clear SAM_F6	
;8 Program SAM and VDG to the appropriate video mode. As the final gate to enabling 64-column text mode, CoCoVGA
;recognizes the VDG's only 2kB mode, CG2 ($2).
    lda  $f22  get current PIA value
    anda  #$0f  mask off bits to change
    ora   #$A0  set VDG to CG2
    sta  $FF22  write to PIA
    sta  $FFC0  clear SAM_V0
    sta  $FFC3  set SAM_V1
    sta  $FFC4  clear SAM_V2	
	puls y,x,d
	rts

sam_data
    .byte  0   ; reset register - reset no register banks
    .byte  81h  ;  edit mask - modify enhanced modes and font registers
    .byte  0    ;reserved
    .byte  2    ;font - force lowercase (use #$03 for both lowercase and T1 character set)
    .byte  0    ;artifact
    .byte  0    ;extras
    .byte  0    ;reserved
    .byte  0    ;reserved
    .byte  2    ;enhanced modes - 64-column enable
	
	
lcase .byte  0
scrwidth .byte  32
lastline .byte  15
scrheight .byte  16
lastchar .word  1536
lcaseprmpt	.strz "DO YOU HAVE LOWER CASE?"
vgaprmpt	.strz "DO YOU HAVE A COCOVGA?"
	