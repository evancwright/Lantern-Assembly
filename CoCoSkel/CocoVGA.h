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

void InitCocoVGA();

unsigned char RegVals[] = { 0,EDIT_MASK,0,FONT,0,0,0,0,MODE_64_COL };