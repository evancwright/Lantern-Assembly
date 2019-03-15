/*Text adventure shell
 *Evan C. Wright
 *2018-2019
 */


#include <cmoc.h>
#include "coco.h"
#include "decbfile.h"
#include "VerbDefs.h"
#include "cocokb.h"
#include "CocoVGA.h"
#include "checks.h"
#include "dskcon-standalone.h"

//#define KYBD_BUFFER 733 /*global input buffer */
#define EOL 1 
#define TRUE 1
#define FALSE 0
#define BOOL unsigned char
#define BYTE unsigned char
#define OBJ_ENTRY_SIZE 19 /*each object is 19 bytes*/
#define OFFSCREEN 0
#define PLAYER_ID 1
 
/*prop numbers*/
#define NO_OBJECT  255
#define INVALID 255
#define ANY_OBJECT  254
#define WILDCARD 254

#define MAX_INV_WEIGHT 10
#define tokenize_input strtok


#define OBJ_ID  0
#define HOLDER_ID  1
#define INITIAL_DESC_ID   2
#define DESC_ID  3
#define FALSE 0
#define TRUE 1
#define NEWLINE 0x0A
#define BYTE unsigned char
#define byte unsigned char

#include "defs.h"  // coco defs
 
#define disableInterrupts() asm("ORCC",  "#$50")
#define enableInterrupts()  asm("ANDCC", "#$AF")
 
 
#define NORTH  4
#define SOUTH  5
#define EAST  6
#define WEST  7
#define NORTHEAST  8
#define SOUTHEAST  9
#define SOUTHWEST  10
#define NORTHWEST  11
#define UP  12
#define DOWN  13
#define ENTER  14
#define OUT  15
#define MASS  16

#define OBJ_ENTRY_SIZE  19
#define PROPERTY_BYTE_1  17
#define PROPERTY_BYTE_2  18
/*byte 1 */

#define SCENERY  1 
#define SUPPORTER  2
#define CONTAINER  3
#define TRANSPARENT  4
#define OPENABLE  5
#define OPEN  6
#define LOCKABLE  7
#define LOCKED  8
#define PORTABLE  9
#define BACKDROP  10
#define WEARABLE  11
#define BEING_WORN   12
#define BEINGWORN   12
#define LIGHTABLE  13
#define LIT  14
#define EMITTING_LIGHT  14
#define DOOR  15
#define UNUSED  16

#define SCENERY_MASK  1
#define SUPPORTER_MASK  2
#define CONTAINER_MASK  4
#define TRANSPARENT_MASK  8
#define OPENABLE_MASK  16
#define OPEN_MASK  32
#define LOCKABLE_MASK  64
#define LOCKED_MASK  128
#define OPEN_CONTAINER  OPEN_MASK+CONTAINER_MASK
#define PORTABLE_MASK  256
#define USER_3_MASK  512
#define WEARABLE_MASK  1024
#define BEINGWORN_MASK  2048
#define USER_1_MASK  4096
#define LIT_MASK  8192	
#define EMITTING_LIGHT_MASK  8192
#define DOOR_MASK  16348
#define USER_2_MASK 32768
   
   
#define BUILT_IN_VARS 5
   
BYTE temp;
BYTE temp2;

BYTE LCase = FALSE;
char UCaseBuffer[INBUF_SIZE];

DECBDrive drives[4];
unsigned int numDrives=4;
 
typedef struct PREAMBLE
{
	BYTE type;
	BYTE dataHi;
	BYTE dataLo;
	BYTE execHi;
	BYTE execLo;
}PREAMBLE;

typedef struct _WordEntry 
{
	BYTE id;
	char *wrd;
} WordEntry;

typedef struct _Object
{
	BYTE attrs[17];
	unsigned short flags;
} Object;

typedef struct Sentence
{
	BYTE verb;
	BYTE dobj;
	BYTE prep;
	BYTE iobj;
	void (*handler)();
} Sentence;

typedef struct _ObjectWordEntry
{
	BYTE id;
	BYTE word1;
	BYTE word2;
	BYTE word3;
} ObjectWordEntry;

typedef struct _VerbCheck
{
	BYTE verbId;
	BOOL (*check)();
} VerbCheck;



char VerbBuffer[55];
char *words[10];
char NumWords=0;
char *startPtr;

#include "main.h"
#include "common.h"

//char *ucase_string(char *str);
const char *articles[] = {"A","AN","THE","OF"};
const char* preps[] = {"IN","ON","UNDER","AT"};
//
unsigned short PropMasks[] = {0,1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768};

BYTE dobjScore;
BYTE iobjScore;
BYTE DobjId;
BYTE IobjId;
BYTE PrepId;
BOOL DobjSupplied = FALSE;
BOOL IobjSupplied = FALSE;
BYTE VerbId = INVALID;
BYTE PrepIndex=0;
BYTE isAmbiguous = FALSE;

BYTE maxScoreCount=0;
BYTE maxScoreObj=INVALID;
BYTE ScrWidth=32;
BYTE MaxScore=0;
BYTE MaxScoreObj=0;
BYTE MaxScoreCount=0;

char * nogo_table;  /* defined in ASM file */

//char *DescriptionTable;
/*end externs*/

char *Buffer;  /*make this point to global input buffer*/
ObjectWordEntry *ObjectWordTable;
WordEntry *VerbTable;
Object *ObjectTable = 0;
VerbCheck *VerbCheckTable=0;
Sentence *BeforeTable;
Sentence *InsteadTable;
Sentence *AfterTable;

BOOL done = FALSE;
BYTE BufSize = 255;
BOOL Handled=FALSE;
 
BYTE lowerCase=FALSE;
#include "EventIncludes.h"


#include "StringTable.h"
#include "NogoTable.h"
#include "Welcome.c"

/*group save data together*/

#include "ObjectTable.c"
/*built in vars*/
BYTE score=0;
BYTE turnsWithoutLight=0;
BYTE gameOver=FALSE;
BYTE moves=0;
BYTE health=100;
#include "UserVars.c"

#include "ObjectWordTable.c"
#include "VerbTable.c"
#include "CheckTable.h"
#include "PrepTable.h"
#include "Dictionary.h"

#include "BeforeTable.c"
#include "InsteadTable.c"
#include "AfterTable.c"

const char * propNames[] = {
"INVALID!",
"SCENERY", 
"SUPPORTER",
"CONTAINER",
"TRANSPARENT",
"OPENABLE",
"OPEN",
"LOCKABLE",
"LOCKED",
"PORTABLE",
"BACKDROP",
"WEARABLE",
"BEINGWORN",
"LIGHTABLE",
"LIT",
"DOOR",
"UNUSED"
};

interrupt asm void irqISR()
{
    asm
    {
        ldb     $FF03
        bpl     @done           // do nothing if 63.5 us interrupt
        ldb     $FF02           // 60 Hz interrupt. Reset PIA0, port B interrupt flag.
		lbsr    dskcon_irqService      /* uncommented per pierre */
@done
    }
}

 

BYTE scores[128];

int main()
{
	//
	 
	decb_shutdown();
	
	//loader disabled the interrupts
	setISR(IRQ_VECTOR, irqISR);
    
	//do this before reenabling interrupts
	
	dskcon_init(dskcon_nmiService);
	
	
    enableInterrupts();

 
	
	lastLine = 15*32 + 0x0400;
	Buffer = Line;	
	clsfs();
	unsigned int size = BufSize;
	init(); //setup tables
 
	printstr("COCO-VGA INSTALLED? (Y/N)");
	readlinenb();
	
	if (Buffer[0] == 'y' || Buffer[0]=='Y')
	{
		InitCocoVGA();
	}
	printstr("\n"); //make room for status bar
	 
	
 	printstr( WelcomeStr );
	printstr("\n");
	printstr( AuthorStr );
	printstr("\n\n");
 
	look_sub();
	dump_dict();
 	
	while (!done)
	{
		/* read a line */
		draw_status_bar();
		
		printstr(">");
		 
		clear_buffers();
				
		readlinenb(); /* reads into global input buffer */
	
		if (stricmp(Buffer,"flags")==0)
		{
			dump_flags();
			continue;
		}
		
		if (stricmp(Buffer,"goto")==0)
		{
			dbg_goto();
			continue;
		}
	
		if (stricmp(Buffer,"purloin")==0)
		{
			purloin();
			continue;
		}
		
		if (strlen(Buffer)==0)
		{
			printstr("Pardon?\n");
			continue;
		}
		
		if (strcmp(Buffer,"score")==0 || strcmp(Buffer,"SCORE")==0)
		{
			sprintf(Buffer,"Your score is %d/100.\n",score);
			printstr(Buffer);
			continue;
		}
		
		
		
		/* parse a line */
	//	if (parse()==TRUE)
		{
			printstr("\n");
			if (parse_and_map()==TRUE)
			{
				if (check_rules()==TRUE)
				{
					execute();
				}
			}
//			else
//				printf("mapping failed.\n");
		}
 	
	}

	return 0;
}


void clear_buffers()
{
	PrepId = INVALID;
	DobjId = INVALID;
	IobjId = INVALID;
	
	char *buffer = Line;
	
 	for (int i=0; i < INBUF_SIZE; i++)
		buffer[i]=0;
	
	for (int i=0; i < 55; i++)
		VerbBuffer[i]=0;
	for (int i=0; i < 10; i++)
		words[i]=0;
	NumWords=0;
}




/*puts startPtr at the next word
  by skipping over nulls (white space)
/*if a EOL is encountered, false is returned*/
 BYTE move_start()
 {
	  while (*startPtr == 0)
	  {		
		  startPtr++;
	  }
	  /* startPtr now points to a letter or and EOL*/
	  if (*startPtr == EOL)
			return FALSE;
	  return TRUE;
 }

/*skips over letters until a null or 1 is hit*/
void move_end()
{
	while (*startPtr != 0 && *startPtr != EOL)
		startPtr++;
}


/* puts the start addr of each word into the table */
void strtok()
{
	startPtr = Buffer;
	/*replaces each space with a null*/
	while (*startPtr != 0)
	{
		if (*startPtr == ' ')
			*startPtr=0;
		startPtr++;
	}
	*startPtr = EOL; /* terminate with something other than a null */
	
	startPtr = Buffer;
	
	while (startPtr != 1)
	{
		if (!move_start())
			break;
		
//		printstr("Word: %s\n", startPtr);
		if (!is_article_np())
		{
			words[NumWords] = startPtr;
			NumWords++;
		}
//		else
//		{
			//printstr("skipping article\n");
	//	}
		move_end();
		
		if (*startPtr == EOL)
		{	
			*startPtr = 0; /*replace the null*/
			break;
		}
	}
	
	//sprintf(UCaseBuffer,"Numwords=%d\n", NumWords);
	//printstr(UCaseBuffer);
}

/*returns TRUE if the two strings are equal
compares until a space or null is hit
*/
BOOL streq(char *str1, char *str2)
{
	while (1)
	{	
		if (*str1 == *str2)
		{
			if (*str1 == ' ' || *str2 == 0)
				break;
			str1++;
			str2++;
		}
		else 
		{/*they aren't equal. Are they both terminators?*/
			if (*str1 == 0 && *str2 == ' ')
				break;
			if (*str1 == ' ' && *str2 == 0)
				break;
			return FALSE;
		}
	}
	
	return TRUE;
}
 







 

/*move2s ptr to first space or null*/

void move_word_end(char **ptr)
{
	while (**ptr != ' ' && **ptr != 0)
	{
		*ptr++;
	}
}

 

BYTE get_object_attr(BYTE obj, BYTE attrNum)
{
//	char name[80];
//	get_obj_name(obj,name);
//  printstr("getting attr:  %d.%d \n", obj,attrNum);
	return ObjectTable[obj].attrs[attrNum];
}

/*propNum is 1-15 */

BYTE get_object_prop(BYTE obj, BYTE propNum)
{
	char name[80];
	unsigned short temp  = ObjectTable[obj].flags & PropMasks[propNum];
	get_obj_name(obj,name);
	
	if (temp !=0) temp = 1;
	
//	printstr("getting prop:  %d.%d=%d \n", obj,propNum,temp);
	
	return (BYTE)temp;
}

void set_object_attr(BYTE objNum, BYTE attrNum, BYTE  val)
{
//	printstr("setting attr:  %d.%d to %d\n", objNum,attrNum,val);
	ObjectTable[objNum].attrs[attrNum] = (BYTE)val;
}

void set_object_prop(BYTE objNum, BYTE propNum, BYTE val)
{
	unsigned short mask;
	unsigned short temp; 
//	printstr("setting prop:  %d.%d  to %d\n", objNum,propNum,val);
	
	if (val == 0)
	{//clear it
		mask = PropMasks[propNum];
		mask = 65535 - mask; /* flip it */
		temp = ObjectTable[objNum].flags & mask;
		ObjectTable[objNum].flags = temp;
	}
	else
	{//set it
		ObjectTable[objNum].flags |= PropMasks[propNum];		
	}
}


void quit_sub()
{
	printstr("Goodbye.\n");
	done = TRUE;
}

void print_string(BYTE entryNum)
{
//	printstr("entryNum=%d\n",entryNum);
	print_table_entry(entryNum, StringTable);
}


void printcr()
{
	printstr((char*)"\n");
}


void fix_endianess()
{
	for (int i=0; i < NumObjects; i++)
	{
		unsigned short lo = ObjectTable[i].flags%256;
		unsigned hi = ObjectTable[i].flags/256;
		unsigned short s = lo * 256 + hi;
		ObjectTable[i].flags = s;
	}
}	



BYTE stricmp(const char * str1, const char * str2)
{
	int index=0;
	while (1)
	{
		char ch1 = to_uchar(str1[index]);
		char ch2 = to_uchar(str2[index]);
		
		/*equal*/
		if  (ch1 == ch2 && ch1 == 0)
		{
			return 0;  
		}		
		
		if (ch1 != ch2)
		{	
			return 1;
		}
		index++;
	}
}


/* returns true if the word at startPtr is in the article list */
BOOL is_article_np()
{
	for (short i=0; i < 3; i++)
	{
		if (stricmp(startPtr, (char*)articles[i]) == 0)
		{
			return TRUE;
		}
	}
	return FALSE;
}

BYTE rand8(BYTE divisor)
{
	return (BYTE)rand() % divisor;
}


/*
char *ucase_string(char *str)
{
	if (LCase == FALSE)
	{
		BYTE len= (BYTE)strlen(str);
		for (BYTE i=0; i < len; i++)
		{
			str[i] = to_uchar(str[i]);
		}	
	}
	return str;
}
 */
/*draws the infocom style status bar*/
void draw_status_bar()
{
	char *saveCursor = cursor;
	char topLine = ' ';
	if (lowerCase)
		topLine = 176;
		//topLine = 'A' + 64;
	
	memset(0x400, topLine, scrWidth);
	
	get_room_name(ObjectTable[PLAYER_ID].attrs[HOLDER_ID],UCaseBuffer);
	cursor = 0x401;
	printstr(UCaseBuffer);
	
	cursor = (char*)(0x400 + scrWidth - 15);
	sprintf(UCaseBuffer,"SCORE:%d/100",score);
	printstr(UCaseBuffer);
	
	cursor = saveCursor; //restore cursor
}
 // Invoked 60 times per second.
//


#include "event_jumps.c"

#include "coco_io.c"
#include "cocokb.c"
#include "CocoVGA.c"
#include "common.c"
#include "checks.c"