/*Text adventure shell
 *Evan C. Wright
 *2018-2019
 */


#include <cmoc.h>
#include "coco.h"
#include "decbfile.h"
#include "VerbDefs8086.h"
#include "cocokb.h"
#include "CocoVGA.h"
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
#define BACKDROP_MASK  512
#define WEARABLE_MASK  1024
#define BEINGWORN_MASK  2048
#define LIGHTABLE_MASK  4096
#define LIT_MASK  8192	
#define EMITTING_LIGHT_MASK  8192
#define DOOR_MASK  16348
#define USER_2 32768
   
   
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
#include "Welcome8086.c"

/*group save data together*/

#include "ObjectTable8086.c"
/*built in vars*/
BYTE score=0;
BYTE turnsWithoutLight=0;
BYTE gameOver=FALSE;
BYTE moves=0;
BYTE health=100;
#include "UserVars8086.c"

#include "ObjectWordTable.c"
#include "VerbTable8086.c"
#include "CheckTable8086.h"
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

 

BYTE scores[255];

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

BOOL parse_and_map()
{
	BYTE wordId;
	PrepId = INVALID;
	clear_scores();
	
	strtok();
	get_verb(); /*get 1st word and prep if supplied */
	
	VerbId = get_verb_id();
	//printf("Verb Id=%d\n",VerbId);
	if (VerbId == INVALID)
	{
		sprintf(Buffer,"I don't know the verb: %s\n",VerbBuffer);
		printstr(Buffer);
		return FALSE;
	}
	
	/* are there any more words */
	if (NumWords > 1)
	{
		/* is there a prep */
		BOOL prep = found_prep();
		if (prep == TRUE)
		{/* score do and io */
			
			PrepId  = get_prep_id(words[PrepIndex]);
			
			for (short i = 1; i < PrepIndex; i++)
			{
				wordId = get_word_id(words[i],Dictionary,DictionarySize);
				
				if (wordId == INVALID) 
				{
					sprintf(UCaseBuffer,"I don't know the word: %s\n",words[i]);
					printstr(UCaseBuffer);
					return FALSE;
				}
				//sprintf(UCaseBuffer,"word id is: %d\n",wordId);
				//printstr(UCaseBuffer);
				score_word(wordId);
			}
			
			/*find best match*/
			//printstr("Scoring dobj\n");
			get_max_score();					
			if (MaxScoreCount > 1)
			{
				printstr("I don't know which one you mean.\n");
				//dump_matches();
				return FALSE;
			}
			
			DobjId = MaxScoreObj;
//			printstr("dobj is %d\n",MaxScoreObj);
			//sprintf(UCaseBuffer,"Noun 1: %d\n",DobjId);
			//printstr(UCaseBuffer);
			/*now score io*/
			//printstr("Scoring noun2\n");
			clear_scores();
			for (short i = PrepIndex+1; i < NumWords; i++)
			{
			//	sprintf(UCaseBuffer,"Examining word %s\n", words[i]);
			//	printstr(UCaseBuffer);
				wordId = get_word_id(words[i],Dictionary,DictionarySize);
				
				if (wordId == INVALID) 
				{
					sprintf(UCaseBuffer,"I don't know the word: %s\n",words[i]);
					printstr(UCaseBuffer);
					return FALSE;
				}
				//sprintf(UCaseBuffer,"Word id was : %d\n",wordId);
				//printstr(UCaseBuffer);
				score_word(wordId);
			}
			
			/*find best match*/
			get_max_score();					
			if (MaxScoreCount > 1)
			{
				printstr("I don't know which one you mean.\n");
				dump_matches();
				return FALSE;
			}
			
			IobjId = MaxScoreObj;
			//sprintf(UCaseBuffer,"Noun 2: %d\n",IobjId);
			//printstr(UCaseBuffer);
			//printstr("iobj is %d\n",MaxScoreObj);

		}
		else
		{ /* just score dobj */
			for (short i = 1; i < NumWords; i++)
			{
				//sprintf(UCaseBuffer,"scoring word: %s.\n", words[i]);
				//printstr(UCaseBuffer);
				
				wordId = get_word_id(words[i],Dictionary,DictionarySize);
				
				if (wordId == INVALID) 
				{
					sprintf(UCaseBuffer,"I don't know the word: %s\n",words[i]);
					printstr(UCaseBuffer);
					return FALSE;
				}
				
				score_word(wordId);
			}
		
			/*find best match*/
			get_max_score();					
			if (MaxScoreCount > 1)
			{ 
				printstr("I don't know which one you mean.\n");
				//dump_matches();
				return FALSE;
			}
			DobjId = MaxScoreObj;
			//printstr("dobj is %d\n",MaxScoreObj);
		}
	}
	return TRUE;
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


/*copies the 1st word into the verb buffer
if the 2nd word is a prep, it is appended to
the verb buffer*/
void get_verb()
{
	strcpy(VerbBuffer, words[0]);
	//printstr("1st word is %s\n",VerbBuffer);
	if (NumWords > 1)
	{
		if (is_prep(words[1]))
		{
//			printstr("Appending preposition.");
			strcat(VerbBuffer," ");	
			strcat(VerbBuffer,words[1]);
//			printstr("Verb is %s\n",VerbBuffer);
			/* shift words down */
			for (short i=1; i < NumWords; i++)
			{
				words[i] = words[i+1];
			}
			NumWords--;
		}
	}
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

/* returns true if the word at startPtr is in the article list */
BOOL is_article()
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

/* returns true if the word at startPtr is in the article list */
BOOL is_prep(char *wrd)
{
	for (short i=0; i < PrepTableSize; i++)
	{
		if (stricmp(wrd,PrepTable[i])==0)
		{
			return TRUE;
		}
	}
	return FALSE;
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
		if (!is_article())
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
 
/* sets the index of PrepIndex if found */ 
BOOL found_prep()
{
//	printstr("Looking for prep\n");
	PrepIndex=0;
	for (int i=2; i < NumWords; i++)
	{
		if (is_prep(words[i]))
		{
		//	printstr("Found prep in index %d\n",i);
			PrepIndex = (BYTE)i;
			return TRUE;
		}
	}
//	printstr("no prep found.\n");
	return FALSE;
}

void clear_scores()
{
	MaxScore=0;
	MaxScoreCount=0;
	for (short i=0; i < 255; i++)
		scores[i]=0;
}

/*
*if the word doesn't apply to an object
*the score is set to 255
*if the word does apply to an object and the object wasn't previously marked invalid, 1 is added to the score
*scores synonyms as well
*if object is visible, it is scored higher
*/
void score_word(BYTE wordId)
{
	char *tablePtr = (char*)ObjectWordTable;
	
	for (char i=0; i < ObjectWordTableSize; i++)
	{
		if (scores[i] != INVALID)
		{
			BYTE id = tablePtr[0];
			
			if (tablePtr[1] == wordId ||
				tablePtr[2] == wordId ||
				tablePtr[3] == wordId) 
			{
			
				scores[id]++;				
//				printstr("Object %d,%d is a match\n", i, ObjectWordTable[i].id);
				
				/*if it's visible, add another point!*/
				if (is_visible_to(ObjectTable[PLAYER_ID].attrs[HOLDER_ID],(BYTE)id))
					scores[id]++;
				
			}
	 
			tablePtr += 4;  /* id plus up to three words */
		}			
	}
}

/*
* gets the max score 
* sets maxScoreObj
* sets maxScoreCount
*/
void get_max_score()
{
	BYTE max = 0;
	MaxScore = 0;
	MaxScoreCount = 0; /*how many matches for max*/
	MaxScoreObj = 0;
	
	for (BYTE i=0; i < ObjectWordTableSize; i++)
	{
		if (scores[i] == INVALID)
			scores[i]=0;
		
//		if (scores[i] != 0)
//			printstr("Object %d is possible match %d\n", i,scores[i]);
		
		if (scores[i] > MaxScore)
		{ /* new best match */
			MaxScore = scores[i];
			MaxScoreObj = ObjectWordTable[i].id;
		}
	}
	
//	printstr("%d is max score\n", MaxScore);
//	printstr("object %d is best match\n", MaxScoreObj);
	
	//count the number with the max score
	for (char i=0; i < ObjectWordTableSize; i++)
	{
		if (scores[i] == MaxScore) MaxScoreCount++;
	}
	
//	printstr("%d is max count\n", MaxScoreObj);
}


 

/*move2s ptr to first space or null*/

void move_word_end(char **ptr)
{
	while (**ptr != ' ' && **ptr != 0)
	{
		*ptr++;
	}
}

 

/*looks at the verb buffer and attempts to find a match in the verb table*/
/*verb has an id, a length, and is null terminated.
 *the last verb has an id of 255
 */
BYTE get_verb_id()
{
	int i=0;
	for (i=0; i < NumVerbs; i++)
	{
//		printstr("verb %d=%s\n",i,VerbTable[i].word);
		if (stricmp(VerbBuffer,VerbTable[i].wrd)==0)
		{
			return VerbTable[i].id;
		}
	}
	return INVALID;
}

/*returns true if objectId is visible to the player*/
BOOL is_visible(BYTE objectId)
{
	Object *objPtr = &ObjectTable[objectId];
	BYTE parent;
	
	while (1)
	{
		parent = ObjectTable[objectId].attrs[HOLDER_ID];
		
		if (parent == PLAYER_ID) return TRUE;
		
		if (parent == OFFSCREEN) return FALSE;
		
		/*if the parent is closed, return FALSE*/
		if (get_object_prop(parent,OPEN) == FALSE)
		{
			return FALSE;
		}
		
		objectId = parent;
	};
		
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


BOOL can_see()
{
	BYTE i=2;
	BYTE roomId = INVALID;
	
	if (emitting_light(ObjectTable[PLAYER_ID].attrs[HOLDER_ID]))
		return TRUE;
	
	/*are there any objects in open containers or on supports that have the same 
	parent as the player?*/
	roomId = ObjectTable[PLAYER_ID].attrs[HOLDER_ID];
	
	/*print objects in the room*/
	for (i=2; i < NumObjects; i++)
	{
		if (emitting_light(i))
		{
			if (is_visible_to(roomId, i)==1)
			{
				return TRUE;
			}
		}
	}
	return FALSE;
}


void quit_sub()
{
	printstr("Goodbye.\n");
	done = TRUE;
}

BYTE is_supporter(BYTE objectId)
{
	return get_object_prop(objectId, SUPPORTER);
}

BYTE is_container(BYTE objectId)
{
	return get_object_prop(objectId, CONTAINER);
}

void get_sub()
{
	printstr("Taken.\n");
	ObjectTable[DobjId].attrs[HOLDER_ID] = PLAYER_ID; 
	ObjectTable[DobjId].attrs[INITIAL_DESC_ID] = INVALID;  //clear initial desc
}

void drop_sub()
{
	
	if (get_object_prop(DobjId,BEING_WORN))
	{
		unwear_sub();
	}
	
	printstr("Dropped.\n");
	ObjectTable[DobjId].attrs[HOLDER_ID] = ObjectTable[PLAYER_ID].attrs[HOLDER_ID];
	
}

void put_sub()
{
	if (is_supporter(IobjId)==FALSE && is_open_container(IobjId) == FALSE)
	{
		printstr("You can't do that.\n");
		return;
	}
	printstr("Done.\n");
	ObjectTable[DobjId].attrs[HOLDER_ID] = IobjId;
}

void open_sub()
{
	char name[80];
	printstr("Opened.\n");
	set_object_prop(DobjId, OPEN, 1);
	get_obj_name(DobjId, name);
	if (has_visible_children(DobjId)==TRUE)
	{
		sprintf(Buffer,"Opening the %s reveals:\n",name);
		printstr(Buffer);
		print_obj_contents(DobjId);
	}
	
}

void close_sub()
{
	printstr("Closed.\n");
	set_object_prop(DobjId, OPEN, 0);
}

void wear_sub()
{
	char name[80];
	memset(name,0,80);
	get_obj_name(DobjId,name);
	sprintf(Buffer,"You put on the %s.\n", name);
	printstr(Buffer);
	set_object_prop(DobjId, BEINGWORN, 1);
}

void unwear_sub()
{
	char name[80];
	memset(name,0,80);
	get_obj_name(DobjId,name);
	sprintf(Buffer,"You remove the %s.\n", name);
	printstr(Buffer);
	set_object_prop(DobjId, BEING_WORN, 0);
}


void print_string(BYTE entryNum)
{
//	printstr("entryNum=%d\n",entryNum);
	print_table_entry(entryNum, StringTable);
}

void examine_sub()
{
	print_table_entry(ObjectTable[DobjId].attrs[DESC_ID],StringTable);
	printstr("\n");
	list_any_contents(DobjId);
}

void look_in_sub()
{
	if (!is_container(DobjId))
	{
		printstr("You can't see inside that.\n");
	}
	else if (is_closed(DobjId))
	{
		printstr("It's closed.\n");
	}
	else
		list_any_contents(DobjId);
}


void list_any_contents(BYTE objectId)
{
	char name[80];

	if (is_open_container(objectId)==TRUE && has_visible_children(objectId) == TRUE)
	{
		memset(name,0,80);
		get_obj_name(objectId,name);
		sprintf(Buffer,"The %s contains:\n", name);
		printstr(Buffer);
		print_obj_contents(objectId);
	}
	else if (is_supporter(objectId)==TRUE && has_visible_children(objectId) == TRUE)
	{
		memset(name,0,80);
		get_obj_name(objectId,name);
		sprintf(Buffer,"On the %s is:\n", name);
		printstr(Buffer);
		print_obj_contents(objectId);
	}		
}

void print_obj_contents(BYTE objectId)
{
	BYTE i=2;
	for (i=2; i < NumObjects; i++)
	{
		if (ObjectTable[i].attrs[HOLDER_ID] == objectId &&
		get_object_prop(i,SCENERY)==0)
		{
			char name[80];
			memset(name,0,80);
			get_obj_name(i,name);
			sprintf(Buffer,"A %s.", name);
			printstr(Buffer);
			
			if (get_object_prop(i,BEINGWORN)  == TRUE)
			{
				printstr("(being worn)");
			}
			if (get_object_prop(i,LIT) == TRUE)
			{
				printstr("(providing light)");
			}
			printstr("\n");
			list_any_contents(i);	
		}
	}
}


BOOL check_see_dobj()
{
	BYTE playerRoom = ObjectTable[PLAYER_ID].attrs[HOLDER_ID];
	if (is_visible_to(playerRoom, DobjId)==0)
	{
		printstr("You don't see that.\n");
		return FALSE;
	}
	return TRUE;
}

BOOL check_dobj_portable()
{
	short flags = ObjectTable[DobjId].flags;
 	flags = flags & PORTABLE_MASK;
 	if ( flags == 0 )
	{
		printstr("That's not portable.\n");
		return FALSE;
	}
//	printstr("DObj is portable.\n");
	return TRUE;
}

BOOL check_dobj_lockable()
{
	char name[80];
	
	short flags = ObjectTable[DobjId].flags;
 	flags = flags & LOCKABLE_MASK;
 	if ( flags == 0 )
	{
		get_obj_name(DobjId,name);
		printstr("You can't lock or unlock that.\n");
		return FALSE;
	}
	return TRUE;
}

BOOL check_dobj_wearable()
{
	short flags = ObjectTable[DobjId].flags;
	flags = flags & WEARABLE_MASK;

	if (flags == 0)
	{
		printstr("You can't that.\n");
		return FALSE;
	}
	return TRUE;
}

BOOL check_dobj_open()
{
	char name[80];
	
	if (!is_open(DobjId))
	{
		get_obj_name(DobjId,name);
		sprintf(Buffer,"The %s is closed.\n",name);
		printstr(Buffer);
		return FALSE;
	}
	return TRUE;
}

BOOL check_dobj_closed()
{
	char name[80];
	if (is_open(DobjId))
	{
		get_obj_name(DobjId,name);
		sprintf(Buffer, "The %s already is open.\n",name);
		printstr(Buffer);
		return FALSE;
	}
	return TRUE;
}

BOOL check_light()
{
	if(can_see() == 1)
	{
		return 1;
	}	
	return 0;
}

BOOL check_dobj_visible()
{
	return TRUE;
}

BOOL check_dobj_supplied()
{
 
	if (DobjId == INVALID)
	{
		printstr("Missing noun.\n");
		return FALSE;
	}
	return TRUE;
}

BOOL check_iobj_supplied()
{
	if (IobjId	== INVALID)
	{
		printstr("Missing noun.\n");
		return FALSE;
	}
	return TRUE;
}

BOOL check_iobj_open()
{
	char buffer[80];
	short flags = ObjectTable[DobjId].flags;
	flags = flags & OPEN_MASK;

	memset(buffer,0,80);

	if  (flags == 0)
	{
		get_obj_name(IobjId,buffer);
		sprintf(Buffer,"The %s is closed.\n", buffer);
		printstr(Buffer);
		return FALSE;
	}
	return TRUE;
}

BOOL check_dobj_opnable()
{
	short flags = ObjectTable[DobjId].flags;
	flags = flags & OPENABLE_MASK;
	
	if (flags == 0)
	{
		printstr("You can't open that.\n");
		return FALSE;
	}
	return TRUE;
}

BOOL check_prep_supplied()
{
	return (PrepId != INVALID);
}

BOOL check_dobj_unlocked()
{
	short flags = ObjectTable[DobjId].flags;
	flags = flags & LOCKED_MASK;

	if (flags != 0 )
	{
		char name[80];
		get_obj_name(DobjId,name);

		sprintf(Buffer,"The %s is locked.\n",name);
		printstr(Buffer);
		return FALSE;
	}	
	return TRUE;
}

BOOL check_iobj_container()
{
	short flags = ObjectTable[DobjId].flags;
	flags = flags & CONTAINER_MASK;
	if (flags == 0)
	{
		printstr("You can't do that.\n");
		return FALSE;
	}
	return TRUE;
}

BOOL check_have_dobj()
{
	if (is_ancestor(PLAYER_ID,DobjId)==FALSE)
	{
		printstr("You don't have that.\n");
		return FALSE;
	}
	return TRUE;
}

BOOL check_dont_have_dobj()
{
	if (is_ancestor(PLAYER_ID,DobjId)==TRUE)
	{
		printstr("You already have it.\n");
		return FALSE;
	}
	return TRUE;
}

BOOL check_not_self_or_child()
{
	if (DobjId == IobjId || is_ancestor(DobjId,IobjId))
	{
		printstr("That's not possible.\n");
		return FALSE;
	}
		
	return TRUE;
}

BOOL check_rules()
{
	int i=0;
	for (i=0; i < NumVerbChecks; i++)
	{
		if (VerbCheckTable[i].verbId == VerbId)
		{
			if ((*VerbCheckTable[i].check)()==0)
			{
				return FALSE;
			}
		}
	}
	return TRUE;
}


/*
*Sets up pointers to the data tables
*/
void init()
{
	ObjectTable = (Object*)ObjectData;
	ObjectWordTable = (ObjectWordEntry*)ObjectWordTableData;
	VerbCheckTable = (VerbCheck*)VerbCheckTableData;
	fix_endianess();
	init_verb_table();
	init_verb_checks();
	init_before_functions();
	init_instead_functions();
	init_after_functions();
}

BOOL is_ancestor(BYTE parent, BYTE child)
{
	if (child == parent)
		return TRUE;
	
	while (child != 0)
	{
		if (ObjectTable[child].attrs[HOLDER_ID] == parent)
			return TRUE;
		
		child = ObjectTable[child].attrs[HOLDER_ID];
	}
	
	return FALSE;
}


/*concatenates all the words in a object's name into a single buffer*/
void get_obj_name(unsigned char objectId, char *buffer)
{
	 	 
   strcpy(buffer, Dictionary[(int)(ObjectWordTable[(int)objectId].word1)]);
   
   if (ObjectWordTable[objectId].word2 != INVALID)
   {
	  strcat(buffer, " ");
	  strcat(buffer, Dictionary[ObjectWordTable[objectId].word2]);
   }
   
   if (ObjectWordTable[objectId].word3 != 255)
   {
	  strcat(buffer, " ");
	  strcat(buffer, Dictionary[ObjectWordTable[objectId].word3]);
   }
//   ucase_string(buffer);
}

/*prints room desc or too dark message*/
void get_room_name(BYTE objectId, char *buffer)
{
	if (can_see()==0)
	{
		strcpy(buffer,"Darkness");
	}
	else
	{
		int i=0;
		int len=0;
		get_obj_name(objectId,buffer);
	}
}


BOOL is_open(BYTE objectId)
{
	return  get_object_prop(objectId,OPEN);
}

BOOL is_visible_to(BYTE roomId, BYTE objectId)
{
	while (1)
	{
		unsigned char parent = ObjectTable[objectId].attrs[HOLDER_ID];		
		//printstr("in vis loop, %d, %d, %d\n", roomId, parent, objectId);

		if (roomId == objectId)
		{
		//	printstr("found object!\n");
			return TRUE;
		}
		
		if (parent == OFFSCREEN)
		{
//			printstr("hit offscreen\n");
			return FALSE;
		}
		
		if (parent == roomId)
		{
	//		printstr("hit parent=success!\n");
			return TRUE;
		}	
		
		if (is_closed_container(parent))
		{ 
			return FALSE;
		}	
		
		objectId = parent;
		
	}
 
	return TRUE;
}

BOOL has_visible_children(BYTE objectId)
{
	BYTE i=2;
	for (i=2 ; i < NumObjects; i++)
	{
		if (ObjectTable[i].attrs[HOLDER_ID]==objectId &&
		get_object_prop(i,SCENERY)==0 )
		{
			return TRUE;
		}
	}
	
	return FALSE;
}

BOOL is_closed_container(BYTE objectId)
{
	if (get_object_prop(objectId,CONTAINER)==1 && get_object_prop(objectId,OPEN)==0)
		return TRUE;
	return FALSE;
}

BOOL is_open_container(BYTE objectId)
{
	char name[80];
	memset(name,0,80);
	if (get_object_prop(objectId,CONTAINER)==1 && get_object_prop(objectId,OPEN)==1)
	{
		get_obj_name(objectId,name);
		return TRUE;
	}	
	return FALSE;
}


/*prints the entryNumth string from the table*/
void print_table_entry(BYTE entryNum, const char *table[])
{
//	printstr("%s",table[entryNum]);
	char *str = (char*)table[entryNum];
	printstr(str);
	 
}

BOOL emitting_light(unsigned char objId)
{
	return get_object_prop(objId,LIT);
}

/*  peforms a "look" */
void look_sub()
{
	BYTE i=2;
	BYTE roomId=INVALID;
	unsigned char initialDesc;
	BOOL canSee=FALSE;
	char name[40];
	char roomName[40];
	
	get_room_name(ObjectTable[PLAYER_ID].attrs[HOLDER_ID],roomName);
	
	sprintf(Buffer,"%s\n", roomName);
	printstr(Buffer);
	
	if (can_see()==0)
	{	
		printstr("It is pitch dark.\n");
		return;
	}
	else
	{
		BYTE roomId = ObjectTable[PLAYER_ID].attrs[HOLDER_ID];
		BYTE descId = ObjectTable[roomId].attrs[DESC_ID];
		//print_table_entry(descId, StringTable);
		print_string(descId);
		printstr("\n");
	}
	 
	roomId = ObjectTable[PLAYER_ID].attrs[HOLDER_ID];
	
	for	(i=2; i < NumObjects; i++)
	{
		if (ObjectTable[i].attrs[HOLDER_ID] == roomId)
		{ 
			initialDesc = ObjectTable[i].attrs[INITIAL_DESC_ID];
			
			if (initialDesc != INVALID)
			{
				print_table_entry(initialDesc,StringTable);
				printstr("\n");
			}
			else
			{
				if (get_object_prop(i,SCENERY)==0)
				{
					get_obj_name(i,name);
					sprintf(Buffer,"There is a %s here.\n", name);
					printstr(Buffer);
				}
			}
			
			list_any_contents(i);
		}
	}
}

/* returns the id # of a word or 255 if not found*/
BYTE get_word_id(char *wordPtr, const char *table[], int tableSize)
{
	int i=0;
	for (i=0; i < tableSize; i++)
	{
		//printstr("%s:%s\n",wordPtr,table[i]);
		if (stricmp(wordPtr,table[i])==0 ||
			strcmp(wordPtr,table[i])==0)
		{
//			printstr("FOUND MATCH. %d\n",i);
			return (BYTE)i;
		}
	}
//	printstr("Word not found.\n");
	return INVALID;
}

BYTE get_prep_id(char *wordPtr)
{
	for (char i=0; i < 4; i++)
	{
		if (stricmp(wordPtr, (char*)PrepTable[i])==0)
			return i;
	}
	return INVALID;
}

void purloin()
{
	/*
	int id;
	printstr("Which object?");
	gets(Buffer);
	id = word_to_object_id(Buffer);
	if (id != INVALID)
	{
		ObjectTable[id].attrs[HOLDER_ID] = PLAYER_ID;
		look_sub();
	}
	*/
}

void dbg_goto()
{
	/*
	int id=0;
	printstr("Which room?");
	gets(Buffer);
	id = word_to_object_id(Buffer);
	if (id != INVALID)
	{
		ObjectTable[PLAYER_ID].attrs[HOLDER_ID] = id;
		look_sub();
	}
	*/
}


void dump_flags()
{
	/*
	BYTE i=0;
	printstr("enter object number:\n");
	gets(Buffer);
	i = word_to_object_id(Buffer);
	
	printstr("hflags: %x,%x\n", ObjectTable[i].flags/256, ObjectTable[i].flags%256);
	printstr("iflags: %d\n", ObjectTable[i].flags);
	if (get_object_prop(i,SCENERY)==1) printstr("scenery\n");
	if (get_object_prop(i,LIT)==1) printstr("lit\n");
	if (get_object_prop(i,PORTABLE)==1) printstr("portable\n");
	if (get_object_prop(i,LOCKED)==1) printstr("locked\n");
	if (get_object_prop(i,OPEN)==1) printstr("open\n");
	if (get_object_prop(i,CONTAINER)==1) printstr("container\n");
	if (get_object_prop(i,DOOR)==1) printstr("door\n");
	*/
}

/*assume checks have been passed*/
void execute()
{
	/*before*/

	if (try_sentence(BeforeTable,BeforeTableSize, FALSE)==FALSE)
	{
		try_sentence(BeforeTable,BeforeTableSize, TRUE);
	}

	if (try_sentence(InsteadTable,InsteadTableSize, FALSE) == FALSE)
	{//exact matches
		if (try_sentence(InsteadTable,InsteadTableSize, TRUE)==FALSE)
		{//wildcards
			try_default_sentence();				//default handling
		}		
	}

	/*after*/

	if (!try_sentence(AfterTable,AfterTableSize, FALSE))
	{
		try_sentence(AfterTable,AfterTableSize, TRUE);
	}
	
	if (Handled==FALSE)
	{
		printstr("I don't understand.\n");
	}
	else
	{
		run_events();
	}
	
//	draw_status_bar();
}

BOOL try_sentence(Sentence *table, int tableSize,  BOOL matchWildcards)
{
	int i=0;
	BOOL result = FALSE;
	for (i=0; i < tableSize; i++)
	{
		if (matchWildcards)
		{
			unsigned char tempdo = DobjId;
			unsigned char tempio = IobjId;
			if (table[i].dobj == WILDCARD)
				tempdo = WILDCARD;
			if (table[i].iobj == WILDCARD)
				tempio = WILDCARD;
			
			if (VerbId==table[i].verb &&
			tempdo==table[i].dobj &&
			PrepId==table[i].prep &&
			tempio==table[i].iobj)
			{
//				printstr("Executing a custom event with wildcards.\n");
				(*table[i].handler)();
			//	printstr("Done.\n");
				Handled = TRUE;
				result=TRUE;
				break;
			}
		}
		else
		{
			if (VerbId==table[i].verb &&
				DobjId==table[i].dobj &&
				PrepId==table[i].prep &&
				IobjId==table[i].iobj)
				{
		//			printstr("Executing a custom event. Addr=%x\n", table[i].handler);
					(*table[i].handler)();
			//		printstr("Done.\n");
					Handled = TRUE;
					result=TRUE;
					break;
				}
		}
	}
	
	return result;
} 


void try_default_sentence()
{
	BOOL prevHandled = Handled;
	BOOL defaultHandled = TRUE;
//	printstr("looking for a default match. verb id=%d\n", VerbId);
	if (VerbId == GET_VERB_ID)
		get_sub();
	else if (VerbId == LOOK_VERB_ID)
		look_sub();
	else if (VerbId == DROP_VERB_ID)
		drop_sub();
	else if (VerbId == PUT_VERB_ID)
		put_sub();	
	else if (VerbId == OPEN_VERB_ID)
		open_sub();
	else if (VerbId == CLOSE_VERB_ID)
		close_sub();
	else if (VerbId == WEAR_VERB_ID)
		wear_sub();
	else if (VerbId == EXAMINE_VERB_ID)
		examine_sub();
	else if (VerbId == LOOK_IN_VERB_ID)
		look_in_sub();
	else if (VerbId == N_VERB_ID || VerbId == S_VERB_ID|| VerbId == E_VERB_ID ||VerbId == W_VERB_ID
		|| VerbId == NE_VERB_ID || VerbId == NW_VERB_ID || VerbId == SE_VERB_ID 
		|| VerbId == SW_VERB_ID || VerbId == UP_VERB_ID  || VerbId == DOWN_VERB_ID 
		|| VerbId == OUT_VERB_ID
	)
	{
		move_sub();
	}
	else if (VerbId == INVENTORY_VERB_ID)
		inventory_sub();
	else if (VerbId == ENTER_VERB_ID)
		enter_sub();
	else if (VerbId == SAVE_VERB_ID)
		save_sub();
	else if (VerbId == RESTORE_VERB_ID)
		restore_sub();
	else if (VerbId == QUIT_VERB_ID)
	{
		printstr("Cold start machine to reboot.\n");
//		exit(0);
	}
	else
	{
//		printstr("couldn't find a default handler.\n");
		defaultHandled = FALSE;
		
	}
//	if (VerbId == UNWEAR_VERB_ID)
	//	unwear_sub();
	
	if (prevHandled == TRUE || defaultHandled == TRUE) 
		Handled = TRUE;
}

void move_sub()
{
//	printstr("moving");
	BYTE tgtRoom=INVALID;
	BYTE dir=0;
	BYTE room = ObjectTable[PLAYER_ID].attrs[HOLDER_ID];
	dir = verb_to_dir(VerbId);
	
//	printstr("current room is %d\n", room);
	tgtRoom = ObjectTable[room].attrs[dir];
	enter_object(tgtRoom, dir);
}

void enter_sub()
{
	if (get_object_attr(DobjId,ENTER) == 255)
		printstr("You can't enter that.");
	else
		enter_object(DobjId, ENTER);
}

void enter_object(BYTE tgtRoom, BYTE dir)
{
	//printstr("target room = %d\n",tgtRoom);
	
	if (tgtRoom > 127)
	{
		BYTE msgId = (255 - tgtRoom)+1;
//		printstr("printing nogo message %d\n", msgId);
		print_table_entry(msgId, NogoTable); 
		printstr("\n");
	}
	else
	{
		if (is_door(tgtRoom)==TRUE)
		{
			if (is_closed(tgtRoom)==TRUE)
			{
				char name[80];
				get_obj_name(tgtRoom,name);
				sprintf(Buffer,"The %s is closed.\n",name);
				printstr(Buffer);
				return;
			}
			else
			{
			//	printstr("passing through a door\n");
				tgtRoom = ObjectTable[tgtRoom].attrs[dir];	/*move through door to room on other side*/
			}
		}
//		else
//		{
//			printstr("%d is not a door\n", tgtRoom);
//		}
		
		//if the object has an 'enter' treat the object l
		if (ObjectTable[tgtRoom].attrs[ENTER] != INVALID)
		{
//			printstr("entering inside %d\n", tgtRoom);
			tgtRoom = ObjectTable[tgtRoom].attrs[ENTER];
		}
		
		ObjectTable[PLAYER_ID].attrs[HOLDER_ID]=tgtRoom;
		look_sub();		
	}
	
}

BOOL is_door(BYTE objectId)
{
	return get_object_prop(objectId,DOOR);
}

BOOL is_closed(BYTE objectId)
{
	if (get_object_prop(objectId,OPEN))
		return FALSE;
	return TRUE;
}

BYTE verb_to_dir(BYTE verbId)
{
	if (VerbId == N_VERB_ID) return NORTH;
	if (VerbId == S_VERB_ID) return SOUTH;
	if (VerbId == E_VERB_ID) return EAST;
	if (VerbId == W_VERB_ID) return WEST;
	if (VerbId == NE_VERB_ID) return NORTHEAST;
	if (VerbId == NW_VERB_ID) return NORTHWEST;
	if (VerbId == SE_VERB_ID) return SOUTHEAST;
	if (VerbId == SW_VERB_ID) return SOUTHWEST;
	if (VerbId == UP_VERB_ID) return UP;
	if (VerbId == DOWN_VERB_ID) return DOWN;
	if (VerbId == ENTER_VERB_ID) return ENTER;
	if (VerbId == OUT_VERB_ID) return OUT;
	printstr((char*)"Invalid direction in verb_to_dir\n");
	return NORTH;
}


void inventory_sub()
{
	if (has_visible_children(PLAYER_ID) == TRUE)
	{
		printstr("You are carrying:\n");
		print_obj_contents(PLAYER_ID);		
	}
	else 
	{
		printstr("You are empty handed.\n");
	}
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

void dump_dict()
{/*
	for (int i=0; i < DictionarySize; i++)
	{
		printstr("%s|\n",Dictionary[i]);
	}
	*/
	
}

BYTE rand8(BYTE divisor)
{
	return (BYTE)rand() % divisor;
}

void dump_matches()
{
	char buf[80];
	for (BYTE i=0; i < NumObjects; i++)
	{
		if (scores[i]==MaxScore)
		{
			get_obj_name(i,buf);
	//		printstr("match:%s\n",buf);
		}
	}
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



#include "event_jumps_6809.c"

#include "coco_io.c"
#include "cocokb.c"
#include "CocoVGA.c"