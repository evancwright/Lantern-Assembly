/*defs for cocokb.b */
#define FALSE 0
#define TRUE 1
#define NEWLINE 0x0A
#define BYTE unsigned char
#define byte unsigned char
#define RETURN 10
#define LF 13
#define SHIFT 15
#define DELETE 8
#define SPACE 96 //hex 40
#define COMMA 108
#define PERIOD 110
#define COLON 122
#define SEMICOLON 123
#define NUM_CURSORS 10
#define MINUS 109
#define FWD_SLASH 111
#define disableInterrupts() asm("ORCC",  "#$50")
#define enableInterrupts()  asm("ANDCC", "#$AF")
#define UPKY 0
#define DWN 0
#define RT 0
#define EXCL 0x61
#define LBS 0x63
#define QUOT 0x62
#define TICK 0x67
#define PCT 0x65
#define LPAREN 0x68
#define RPAREN 0x69
#define DOLLAR 0x64
#define AMP 0x66
#define INBUF_SIZE 255
void carriage_return();

asm BYTE PollKbCol(BYTE col);
void printstr(const char *str);
char* printwrd(char *str);
void scroll();
void clsfs(); /* full screen cls */
void readlinenb();
void fix_spaces();
int CharsLeft();
int NextWordLen(char *);
BYTE shift_down();
BYTE get_shifted_key(BYTE ch);
char *SkipWhiteSpace(char *ptr);

char Line[INBUF_SIZE];
int LineIndex=0;

short scrHeight = 16;
short scrWidth = 32;
short lastLine = 15*32 + 0x0400;
short scrSize = 16*32;
char *cursor = 0x0400;
unsigned char ticks = 0;
BYTE keyDown = FALSE;
 
char cursors[] = { ' ', 96 };

unsigned char matrix[8][8] = {
	{'@', 'A', 'B', 'C', 'D', 'E', 'F', 'G'},
	{'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O'},
	{'P', 'Q', 'R', 'S' ,'T', 'U', 'V', 'W'},
	{'X', 'Y', 'Z', UPKY, DWN, DELETE, RT, SPACE},
	//numbers start at 81 decimal
	{0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77},  //can also be !/1 "/2 #/3 $/4 %/5 &/6 '/7
	{0x78, 0x79, COLON, SEMICOLON, COMMA, MINUS, PERIOD, FWD_SLASH }, // (/8 )/9 */: +/; </, =/- >/. ? /
	{RETURN, 0, 0, 0, 0, 0, 0, SHIFT}, //enter clr es/br alt ctrl F1 F2 shifts
	{0,0,0,0,0,0,0,0} //enter clr es/br alt ctrl F1 F2 shifts
	};

BYTE keyStatus[8][8] = {
	{0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0},  //can also be !/1 "/2 #/3 $/4 %/5 &/6 '/7
	{0,0,0,0,0,0,0,0}, // (/8 )/9 */: +/; </, =/- >/. ? /
	{0,0,0,0,0,0,0,0}, //enter clr es/br alt ctrl F1 F2 shifts
	{0,0,0,0,0,0,0,0} //enter clr es/br alt ctrl F1 F2 shifts
	};	
	
unsigned char colBits[] = { 0xFE, 0xFD, 0xFB, 0xF7, 0xEF, 0xDF, 0xBF, 0x7F  };
