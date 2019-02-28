/* Cocovga support.c */
/* Code pilfered from CocoVGA.com */
 
/* we'll use 0x0400 (page 2) for the register values (program is at C00)*/
/* we'll use 0x0400 (page 2) as the video page*/
#define FONT 0x02
#define EDIT_MASK 0x81
#define MODE_64_COL 0x02

#define NUM_REG_VALS 9

#define CLR_SAM_0 0xFFC6 
#define CLR_SAM_1 0xFFC8 
#define CLR_SAM_2 0xFFCA
#define CLR_SAM_3 0xFFCC
#define CLR_SAM_4 0xFFCE
#define CLR_SAM_5 0xFFD0
#define CLR_SAM_6 0xFFD2

#define SET_SAM_0 0xFFC7 
#define SET_SAM_1 0xFFC9 
#define SET_SAM_2 0xFFCB
#define SET_SAM_3 0xFFCD
#define SET_SAM_4 0xFFCF
#define SET_SAM_5 0xFFC1
#define SET_SAM_6 0xFFC3

void InitCocoVGA()
{
	/* 1.  Set up a 512-byte-aligned memory region with register values you want to stream into CoCoVGA. For this example, 
we are arbitrarily selecting address $7C00 as the start address. */
	 
	 
	unsigned char RegVals[] = { 0,EDIT_MASK,0,FONT,0,0,0,0,MODE_64_COL };
	
	memcpy( (char*)0x400, RegVals, NUM_REG_VALS);  //page 7f = all ones
	 
	/* 2.  Wait for VSYNC, which signals the start of the vertical blanking region. */
	asm 
	{
		PSHS CC     ; save CC
		ORCC #$50   ; mask interrupts
		LDA  $FF03 
		PSHS A      ; save PIA configuration 
		LDA  $FF03
		ORA  #$04   ; ensure PIA 0B is NOT setting direction
		STA  $FF03
		LDA  $FF03 
		ANDA #$FD   ; vsync flag - trigger on falling edge
		STA  $FF03
		LDA  $FF03
		ORA  #$01   ; enable vsync IRQ (although interrupt itself will be ignored via mask)
		STA  $FF03
		LDA  $FF02  ; clear any pending VSYNC
L1:		LDA  $FF03  ; wait for flag to indicate...
		BPL  L1     ; ...falling edge of FS (Field Sync)
		LDA  $FF02  ; clear VSYNC interrupt flag
	}
		
	
	/*3.  During VSYNC, point SAM to 512 byte page set up in step 1 (via SAM page select registers $FFC6-$FFD3). For this
example, this page is at $7C00. Divide by 512 to get page number:
    $FC00/512 = $3E = 011 1110
SAM page selection is performed by writing a single address to set or clear each bit. In this case we want to 
clear bits 0 and 6, so write to even addresses for those, and write to odd addresses to set bits 1 through 5. */

	/*400hex = page 2 = 0000010 */
	 
	asm 
	{  
		LDA #1
		sta CLR_SAM_0
		sta SET_SAM_1
		sta CLR_SAM_2
		sta CLR_SAM_3
		sta CLR_SAM_4
		sta CLR_SAM_5
		sta CLR_SAM_6
	}
	
		
	/*4. Also during VSYNC, write 6847 VDG combination lock via PIA1B ($FF22) bits 7:3. */
	asm 
	{
		LDA  $FF22  ;get current PIA value
		ANDA  #$07  ;mask off bits to change
		ORA   #$90  ;set combo lock 1
		STA  $FF22  ;write to PIA
		ANDA  #$07  ;mask off bits to change
		ORA   #$48  ;set combo lock 2
		STA  $FF22  ;write to PIA
		ANDA  #$07  ;mask off bits to change
		ORA   #$A0  ;set combo lock 3
		STA  $FF22  ;write to PIA
		ANDA  #$07  ;mask off bits to change
		ORA   #$F8  ;set combo lock 4
		STA  $FF22  ;write to PIA
	}
	/*5.   
	 Still during VSYNC, configure VDG and SAM back to mode 0. (In this case, the desired CoCoVGA register page to program is 0.)	
	*/
	asm 
	{
    LDA  $FF22  ;get current PIA value
    ANDA  #$07  ;mask off bits to change
    ORA   #$00  ;select CoCoVGA register page 0
    STA  $FF22  ;write to PIA
    STA  $FFC0  ;clear SAM_V0
    STA  $FFC2  ;clear SAM_V1
    STA  $FFC4  ;clear SAM_V2
	}
	/*6. Wait for next VSYNC while SAM and VDG stream in the entire page of register values to CoCoVGA and CoCoVGA 
displays the previous frame of video.*/
	
	asm
	{
L2:	  LDA  $FF03  ;wait for flag to indicate...
		BPL  L2     ;...falling edge of FS (Field Sync)
		LDA  $FF02  ;clear VSYNC interrupt flag
		PULS A      ;from stack... 
		STA  $FF03  ;...restore original PIA configuration
		PULS CC     ;restore ability to see interrupts
	}
	
	/*7. Point SAM page select to video page you want to display. For this example, let's assume that this is at $E00
which (divided by 512 bytes) is page 7. */
	/* we're going to use 400 hex = page 2*/
	
	memset( CLR_SAM_0, 0x01, 1 );
	memset( SET_SAM_1, 0x01, 1 );  
	memset( CLR_SAM_2, 0x01, 1 );
	memset( CLR_SAM_3, 0x01, 1 );
	memset( CLR_SAM_4, 0x01, 1 );
	memset( CLR_SAM_5, 0x01, 1 );
	memset( CLR_SAM_6, 0x01, 1 );	

	/*8.   Program SAM and VDG to the appropriate video mode. As the final gate to enabling 64-column text mode, CoCoVGA
recognizes the VDG's only 2kB mode, CG2 ($2).*/
	asm
	{
		LDA  $FF22  ; get current PIA value
		ANDA  #$0F  ; mask off bits to change
		ORA   #$A0  ; set VDG to CG2
		STA  $FF22  ; write to PIA
		STA  $FFC0  ; clear SAM_V0
		STA  $FFC3  ; set SAM_V1
		STA  $FFC4  ; clear SAM_V2
	}
	
	lowerCase = TRUE;
	cursors[0] = 31;
	cursors[1] = 32;
	scrWidth = 64;
	scrHeight = 32;
	lastLine = 31 * 64 + 0x0400;
	clsfs();
}
