 /*8086 Game Shell - Evan Wright, 2018*/
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "VerbDefs.h"
#include "Strings.h"
#include "PrepTable.h"
#include "Dictionary.h"
#include "NogoTable.h"
#include "Events.h"
//#define DEBUG
//#define DEBUG_MAPPING

unsigned short stackp;

extern const int ObjectWordTableSize;
extern const int NumObjects;

extern char ObjectData[];
extern unsigned char ObjectWordTableData[];

#define  BOOL unsigned char
#define BYTE unsigned char
BYTE scores[256];
//typedef unsigned char BYTE;

#include "Defs.h"
#include "Welcome.c"


#define TRUE 1
#define FALSE 0
#define true 1
#define false 0
#define WILDCARD 254
#define INVALID 255
#define KBBUF	$02dd	; keyboard buffer 

#define MAX_INV_WEIGHT 10

#pragma pack(0)
typedef struct Object
{
	unsigned char attrs[17];
	unsigned short flags;	
} Object;

#pragma pack(0)
typedef struct WordEntry 
{
	BYTE id;
	char *wrd;
} WordEntry;

#pragma pack(0)
typedef struct ObjectWordEntry
{
	unsigned char id;
	unsigned char word1;
	unsigned char word2;
	unsigned char word3;
} ObjectWordEntry;

#pragma pack(0)
typedef struct Sentence
{
	unsigned char verb;
	unsigned char dobj;
	unsigned char prep;
	unsigned char iobj;
	void ( *handler)();
} Sentence;

#pragma pack(0)
typedef struct VerbCheck
{
	unsigned char verbId;
	BOOL (*check)();
} VerbCheck;


int Col=0;
unsigned char *DobjPtr=0;
unsigned char *PrepPtr=0;
unsigned char *IobjPtr=0;
unsigned char VerbId=255;
unsigned char DobjId=255;
unsigned char PrepId=255;
unsigned char IobjId=255;
unsigned char DobjSupplied=0;
unsigned char IobjSupplied=0;

char VerbBuffer[55];

Sentence *BeforeTable;
Sentence *InsteadTable;
Sentence *AfterTable;
WordEntry *VerbTable;
VerbCheck *VerbCheckTable;


BOOL Handled=0;
int NumWords=0;
char *wordPointers[10];
const int BufSize=80;
char Buffer[256];
char UCaseBuffer[256]; 
char *words[10];
Object * ObjectTable;
ObjectWordEntry *ObjectWordTable;


char *articles[] = {"A","AN","THE","OF"};

unsigned short PropMasks[] = {0,1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768};

char * propNames[] = {
"INVALID!",
"SCENERY", 
"SUPPORTER",
"CONTAINER",
"USER3",
"OPENABLE",
"OPEN",
"LOCKABLE",
"LOCKED",
"PORTABLE",
"USER3",
"WEARABLE",
"BEINGWORN",
"USER1",
"LIT",
"DOOR",
"USER2"
};


void init();
void look_sub();
void examine_sub();
void execute();
void inventory_sub();
void __cdecl move_sub();
void get_sub();
void drop_sub();
void wear_sub();
void put_sub();
void unwear_sub();
void open_sub();
void dump_flags();
void dump_sentence_table();
void dbg_goto();
void purloin();
void close_sub();
void save_sub();
void restore_sub();
void quit_sub();
void enter_sub();
void run_events();
void init_verb_table();
void dump_obj_table();
void dump_obj_word_table();
void init_before_functions();
void init_instead_functions();
void init_after_functions();
void init_verb_checks();
void draw_status_bar(); 
char toupper(char c);
void scroll();
void print_word(char* w);
void collapse_verb();
void __cdecl print_cr();
void __cdecl print_string(unsigned short entryId);
void __cdecl print_var(unsigned short var);
void __cdecl print_obj_name(unsigned short objId); 
void list_any_contents(unsigned char objectId);
void get_obj_name(unsigned char objectId, char *buffer);
void get_room_name(unsigned char objectId, char *buffer);
void print_obj_contents(unsigned char objectId);
void __cdecl set_obj_prop(unsigned short objNum, unsigned short propNum, unsigned short val);
void __cdecl set_obj_attr(unsigned short objNum, unsigned short propNum, unsigned short val);
void enter_object(unsigned char tgtRoom, BYTE dir);
void score_objects(unsigned char wordId);
void look_in_sub();
void printstr(char *str);


BYTE get_object_prop(BYTE o, BYTE p);
BYTE get_object_attr(BYTE o, BYTE p);

BOOL parse_and_map();
BOOL can_see();
BOOL parse();
BOOL map();
BOOL check_move();
BOOL check_put();
BOOL check_rules();
BOOL check_see_dobj();
BOOL check_see_iobj();
BOOL check_dobj_supplied();
BOOL check_iobj_supplied();
BOOL check_dobj_portable();
BOOL check_weight();
BOOL check_dobj_visible();
BOOL check_dobj_closed();
BOOL check_dobj_lockable();
BOOL check_dobj_wearable();
BOOL check_have_dobj();
BOOL check_dont_have_dobj();
BOOL check_iobj_open();
BOOL check_light();
BOOL check_dobj_open();
BOOL check_dobj_opnable();
BOOL check_iobj_container();
BOOL check_not_self_or_child();
BOOL check_dobj_unlocked();
BOOL check_prep_supplied();
BOOL any_visible();
BOOL is_article(char *word);
BOOL emitting_light(unsigned char objId);
BOOL is_prep(char *word);
BOOL is_open(unsigned char objectId);
BOOL is_closed(unsigned char objectId);
BOOL is_door(unsigned char objectId);
BOOL is_open_container(unsigned char objectId);
BOOL is_supporter(unsigned char objectId);
BOOL is_container(unsigned char objectId);
BOOL is_closed_container(unsigned char objectId);
BOOL is_ancestor(unsigned char parent, unsigned char child);
BOOL is_visible_to(unsigned char roomId, unsigned char objectId);
BOOL try_sentence(Sentence *table, int tableSize, BOOL wildcards) ;
BOOL has_visible_children(unsigned char objectId);
BOOL score_object(int startIndex, int endIndex, unsigned char *objId);
unsigned char get_verb_id(char *verb);
unsigned char get_word_id(char *wordPtr, const char **table, int tableSize);
//unsigned char get_string_id(unsigned short entryNum, char *table[]);
unsigned char verb_to_dir(unsigned char);
unsigned char word_to_object_id(char *word);
unsigned char max_score_object(int score);
unsigned short __cdecl get_obj_prop(unsigned short object, unsigned short prop);
unsigned short __cdecl get_obj_attr(unsigned short object, unsigned short prop);
unsigned char noun_to_object_id(unsigned char wordId);
void try_default_sentence();
void print_table_entry(BYTE entryNum, const char **table);
int max_score_matches(int score);

BYTE get_inv_weight(BYTE obj);

#include "CheckTable.h"
BYTE done=FALSE;
BYTE score=0;
BYTE health=100;
BYTE gameOver=0;
BYTE turnsWithoutLight=0;
BYTE answer=0;
BYTE moves=0;

BYTE MaxScore=0;
BYTE MaxScoreObj=0;
BYTE MaxScoreCount=0;

BYTE dobjScore;
BYTE iobjScore;
BYTE DobjId;
BYTE IobjId;
BYTE PrepId;
int PrepIndex=0;
BYTE isAmbiguous = FALSE;
 

#include "UserVars.c"
#include "Events.h"
#include "BeforeTable.c"
#include "InsteadTable.c"
#include "AfterTable.c"
#include "event_jumps.c"

int main(int argv, char **argc)
{
	unsigned int size = BufSize;
	init();
	printf("\x1b[2J"); //cls
	printf("\x1b[2;0H"); //position cursor
	
 	printf("%s\n",WelcomeStr);
	printf("%s\n",AuthorStr);
	printf("\n");
//	dump_obj_table();			
	//dump_obj_word_table();		
	//	dump_instead_table();
	
	look_sub();
	
	while (!done)
	{
		/* read a line */
		draw_status_bar();
	
		printf(">");
		gets(Buffer);
		
		if (strcmp(Buffer,"flags")==0)
		{
			dump_flags();
			continue;
		}
		
		if (strcmp(Buffer,"goto")==0)
		{
			dbg_goto();
			continue;
		}
	
		if (strcmp(Buffer,"purloin")==0)
		{
			purloin();
			continue;
		}
		
		if (strcmp(Buffer,"score")==0)
		{
			printf("Your score is %d/100.\n",score);
			continue;
		}

		if (strcmp(Buffer,"sentences")==0)
		{
			dump_sentence_table();
			continue;
		}

		
		/* parse a line */
	//	if (parse()==TRUE)
		{
			printf("\n");
			Col=0;
			if (parse_and_map()==TRUE)
			{
				
				if (check_rules()==TRUE)
				{
#ifdef DEBUG
				  printf("trying to run %d,%d,%d,%d\n",
				  VerbId,DobjId,PrepId,IobjId);
#endif
					execute();
					moves++;
				}
			}
//			else
//				printf("mapping failed.\n");
		}
//		exit(0);	
	}

	return 0;
}
    

void save_sub()
{
	FILE * fp;
	printf("Enter a file name (no extension).\n");
	gets(Buffer);
	fp = fopen(Buffer,"wb");
	
	if (!fp)
	{
		printf("Unable to open file.\n");
	}
	else
	{
		fwrite(&done,1, 5+NumUserVars,fp);
		fwrite(ObjectTable,1,NumObjects*OBJ_ENTRY_SIZE,fp);
		fclose(fp);
		printf("Saved.\n");
	}
}

void restore_sub()
{
	FILE *fp=NULL;
	printf("Enter a file name (no extension).\n");
	gets(Buffer);
	fp = fopen(Buffer,"rb");
	
	if (!fp)
	{
		printf("Unable to open file.\n");
	}
	else
	{
		fread(&done,1,5+NumUserVars,fp);
		fread(ObjectTable,1,NumObjects*OBJ_ENTRY_SIZE,fp);
		fclose(fp);
		printf("Restored.\n");
		look_sub();
	}
}

void quit_sub()
{
	printf("Goodbye.\n");
	done = TRUE;
}
  
void set_obj_attr(unsigned short objNum, unsigned short attrNum, unsigned short  val)
{
#ifdef DEBUG
	printf("setting attr:  %d.%d to %d\n", objNum,attrNum,val);
#endif
	ObjectTable[objNum].attrs[attrNum] = (unsigned char)val;
#ifdef DEBUG
	printf("set\n");
#endif	
}

void set_obj_prop(unsigned short objNum, unsigned short propNum, unsigned short val)
{
	unsigned short mask;
	unsigned short temp;
#ifdef DEBUG
	printf("setting prop:  %d.%d(%s) to %d\n", objNum,propNum,propNames[propNum],val);
	printf("current flags=%u\n", ObjectTable[objNum].flags);
#endif
	mask = PropMasks[propNum];
	temp = ObjectTable[objNum].flags;
	
#ifdef DEBUG	
	printf("mask=%u\n", mask);
#endif
	if (val == 0)
	{//clear it
		mask = 65535 - mask; /* flip it */
///		printf("flipped mask=%u\n", mask);	
		temp = temp & mask;
	}
	else
	{//set it
		temp = temp | mask;
	}
	
	ObjectTable[objNum].flags = temp;
//	printf("flags are now =%u\n", ObjectTable[objNum].flags);
#ifdef DEBUG
	printf("bit flag set\n");
#endif
}

unsigned short get_obj_attr(unsigned short obj, unsigned short attrNum)
{
	//char name[80];
	//get_obj_name(obj,name);
//printf("getting attr:  %d (%s).%d (%s)\n", obj,name,attrNum,attrNames[attrNum]);
	return (unsigned short) ObjectTable[obj].attrs[attrNum];
}

//prop is 1-15 



unsigned short get_obj_prop(unsigned short obj, unsigned short propNum)
{
	//char name[80];
	unsigned short temp  = ObjectTable[obj].flags & PropMasks[propNum];
	//get_obj_name(obj,name);
	
	//printf("getting prop:  %d(%s).%d(%s) \n", obj,name,propNum,propNames[propNum]);
	
	if (temp == 0)
		return 0;
	return 1;
}

void print_string(unsigned short entryNum)
{
	char buf[256];
	char *token=0;
	char *delim  = " ";
	
	if (entryNum < StringTableSize)
	{
		//print_table_entry(entryNum, StringTable);
		char *s = (char*)StringTable[entryNum];
		strcpy(buf,s);
		token = strtok(buf, delim);
	
		while( token != NULL ) 
		{	
			print_word(token);
			token = strtok(NULL, delim);
		}
	}
	else
	{
		printf("ERROR! Invalid string id %d\n", entryNum);
	}
}
 
void __cdecl print_cr()
{
	printf("\n");
	Col=0;
}

//prints var as text
void __cdecl print_var(unsigned short var)
{
	printf("%d",var);
}

#include "ObjectTable.c"
#include "ObjectWordTable.c"
#include "VerbTable.c"
 
void draw_status_bar()
{
	int i=0;
	int len=0;
	int roomId=0;
	char name[80];
	char topline[81];
	char scorebuf[10];
	topline[80]=0;
	roomId = ObjectTable[PLAYER_ID].attrs[HOLDER_ID];
	get_room_name(roomId,name);
	len = strlen(name);
	for (i=0; i < len; i++)
	{
		name[i]=toupper(name[i]);
	}
	printf("\x1b[s"); //save cursor
	printf("\x1b[0;0H"); //homme
	
	sprintf(topline,"##### %s ", name );
	len = strlen(topline);
	for (i=len; i < 64; i++)
	{
		strcat(topline,"#");
	}
	strcat(topline," SCORE:");
	memset(scorebuf,0,10);
	sprintf(scorebuf,"%3d/100 #",score);
	strcat(topline,scorebuf);
	printf(topline);
	printf("\x1b[u"); //restore cursor
}

char toupper(char ch)
{
	if (ch >= 'a' && ch <= 'z')
	{
		return ch-32;
	}
	return ch;
}

void scroll()
{
	
}


void print_word(char* w)
{
	int len = 0;
	int rem = 0;
	len = strlen(w);
	rem = 80-Col;
  
	if (*w == '\n' || *w == '\r')
	{//cr
		printf("\n");
		Col=0;
	}
	else if ((len+1) < rem)
	{//enough room for word + space
		printf("%s",w);
		Col = Col+len;
		
		if (w[len-1] != '\n')
		{
			printf(" ");
			Col++;
		}
		
	}	
	else if (len==rem)
	{//just enough room for word
		printf("%s",w);
		Col=0;
	}
	else
	{ //not enough room left (print nl + word + space);
		printf("\n%s ",w);
		Col=len+1;
	}
}

 

void tokenize_input()
{
	int i=0;
	char *token=0;
	char *delim = " ";	
	
	NumWords=0;
	/*clear word pointers*/
   for (i=0; i < 10; i++)
   {
	   words[i]=0;
   }

	token = strtok(Buffer, delim);
   
   /* walk through other tokens */
   while( token != NULL ) 
   {
//	  printf("%s\n",token);
	  if (!is_article(token))
	  {
		  words[NumWords] = token;
		  NumWords++;
	  }		  
      token = strtok(NULL, delim);
   }
}

void printstr(char *str)
{
	char *token=0;
	char *delim  = " ";
	char buf[256];
	//printf("printing: %s\n", str);
	//print_table_entry(entryNum, StringTable);
	strcpy(buf,str);
	token = strtok(buf, delim);

	while( token != NULL ) 
	{	
		print_word(token);
		token = strtok(NULL, delim);
	}
}

BYTE get_object_prop(BYTE o, BYTE p)
{
	return (BYTE) get_obj_prop(o,p);
}

BYTE get_object_attr(BYTE o, BYTE p)
{
	return (BYTE) get_obj_attr(o,p);
}

void set_object_attr(BYTE o, BYTE a, BYTE v)
{
	set_obj_attr(o,a,v);
}

void set_object_prop(BYTE o, BYTE p, BYTE v)
{
#ifdef DEBUG
	printf("setting prop %d,%d to %d\n", o, p, v);
#endif
	set_obj_prop(o,p,v);
#ifdef DEBUG
	printf("prop set\n");
#endif
}

 

void fix_endianess()
{
}	

void ask()
{
	gets(Buffer);
	answer=get_word_id(Buffer, StringTable, StringTableSize);

}

void dump_sentence_table()
{
	int i=0;
	for (; i < InsteadTableSize;i++)
	{
		
		printf("%d:%d,%d,%d,%d->%x\n",
			i+1,
			InsteadTable[i].verb,
			InsteadTable[i].dobj,
			InsteadTable[i].prep,
			InsteadTable[i].iobj,
			InsteadTable[i].handler
			);
	}
	
	printf("There are %d sentences.\n", InsteadTableSize);
	
}

#include "checks8086.c"
#include "Events.c"
#include "Common8086.c"


