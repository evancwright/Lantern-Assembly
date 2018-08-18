 /*8086 Game Shell - Evan Wright, 2018*/
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "VerbDefs8086.h"
#include "Strings8086.h"
#include "PrepTable8086.h"
#include "Dictionary8086.h"
#include "NogoTable8086.h"
#include "Events.h"

unsigned short stackp;

extern const int ObjectWordTableSize;
extern const int NumObjects;

extern char ObjectData[];
extern unsigned char ObjectWordTableData[];
char Scores[128]; /* object scores for word matching*/

typedef  unsigned char BOOL;

#include "Defs.h"
#include "Welcome8086.c"


#define TRUE 1
#define FALSE 0
#define WILDCARD 254
#define INVALID 255

#pragma pack(0)
typedef struct ObjectEntry
{
	unsigned char attrs[17];
	unsigned short flags;	
} ObjectEntry;

#pragma pack(0)
typedef struct WordEntry 
{
	char id;
	char *word;
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
	void (*handler)();
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
char *WordPtrs[10];
char VerbBuffer[80];

Sentence *BeforeTable;
Sentence *InsteadTable;
Sentence *AfterTable;
WordEntry *VerbTable;
VerbCheck *VerbCheckTable;


BOOL Handled=0;
int NumWords=0;
char *wordPointers[10];
const int BufSize=80;
char Buffer[80];
ObjectEntry * ObjectTable;
ObjectWordEntry *ObjectWordTable;

const int NumArticles = 4;
char *ArticleTable[] = {"A","AN","THE","OF"};

unsigned short PropMasks[] = {0,1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768};
char * propNames[] = {
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
void dump_flags();
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
void list_any_contents(unsigned char objectId);
void get_obj_name(unsigned char objectId, char *buffer);
void get_room_name(unsigned char objectId, char *buffer);
void print_obj_contents(unsigned char objectId);
void __cdecl set_obj_prop(unsigned short objNum, unsigned short propNum, unsigned short val);
void __cdecl set_obj_attr(unsigned short objNum, unsigned short propNum, unsigned short val);
void enter_object(unsigned char tgtRoom, int dir);
void score_objects(unsigned char wordId);

BOOL parse_and_map();
BOOL can_see();
BOOL parse();
BOOL map();
BOOL check_rules();
BOOL check_see_dobj();
BOOL check_dobj_supplied();
BOOL check_iobj_supplied();
BOOL check_dobj_portable();
BOOL check_dobj_visible();
BOOL check_dobj_closed();
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
void __cdecl print_table_entry(unsigned short entryNum, const char **table);
int max_score_matches(int score);

#include "CheckTable8086.h"
unsigned char done=FALSE;
unsigned char score=0;
unsigned char health=100;
unsigned char gameOver=0;
unsigned char turnsWithoutLight=0;
#include "UserVars8086.c"
#include "Events8086.h"
#include "BeforeTable8086.c"
#include "InsteadTable8086.c"
#include "AfterTable8086.c"
#include "event_jumps_8086.c"

int main(int argv, char **argc)
{
	unsigned int size = BufSize;
	init();
	printf("\x1b[2J"); //cls
	printf("\x1b[2;0H"); //position cursor
	draw_status_bar();
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
		
		/* parse a line */
	//	if (parse()==TRUE)
		{
			printf("\n");
			if (parse_and_map()==TRUE)
			{
				Col=0;
				if (check_rules()==TRUE)
				{
					execute();
				}
			}
//			else
//				printf("mapping failed.\n");
		}
//		exit(0);	
	}

	return 0;
}
/*
BOOL parse()
{
	int i=0;
	int prepIndex = -1;
	char  *delim =" ";
	char *token;
	DobjPtr = 0;
	IobjPtr = 0;
	PrepPtr = 0;
	NumWords=0;
	token = strtok(Buffer, delim);
   //clear word pointers
   for (i=0; i < NumWords; i++)
   {
	   WordPtrs[i]=0;
   }
   
   // walk through other tokens
   while( token != NULL ) {
//      printf("token: %s\n", token);
	  if (!is_article(token))
	  {
		  WordPtrs[NumWords] = token;
		  NumWords++;
	  }		  
      token = strtok(NULL, delim);
   }	
    if (NumWords == 0)
   {
	   printf("Beg pardon?\n");
	   return FALSE;
   } 
   
   memset(VerbBuffer,0,80);
   strcpy(VerbBuffer,WordPtrs[0]);
   //collapse the verb
   if (NumWords > 1)
   {
	   if (is_prep(WordPtrs[1]))
	   {
	//	   printf("%s is a prep\n", WordPtrs[1]);
		   strcat(VerbBuffer," ");
		   strcat(VerbBuffer,WordPtrs[1]);
		//   printf("Verb is now %s\n", VerbBuffer);
		   //move all pointers down one
		   for (i=1; i < NumWords-1;i++)
		   {
			   WordPtrs[i] =WordPtrs[i+1];
		   }
		   WordPtrs[NumWords-1]=0; //erase last entry
		   NumWords--;
	   } 
	   else
	   {
		  // printf("{%s} is not a prep\n", WordPtrs[1]);
	   }
   }
   
   if (NumWords==1)
	   return TRUE;
   
   //is there a prep
   
   DobjPtr = WordPtrs[1];
   //printf("dobj=%s\n",DobjPtr);
   for (i=1; i < NumWords; i++)
   {
	   if(is_prep(WordPtrs[i]))
	   {
			prepIndex=i;
			IobjPtr = WordPtrs[i+1];
			PrepPtr = WordPtrs[i];
	//		printf("prep=%s\n",PrepPtr);
		//	printf("iobj=%s\n",IobjPtr);
			break;
	   }
   }
   return TRUE;
}
*/
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
}

void get_room_name(unsigned char objectId, char *buffer)
{
	if (can_see()==0)
	{
		strcpy(buffer,"DARKNESS");
	}
	else
	{
		int i=0;
		int len=0;
		get_obj_name(objectId,buffer);
		for (i=0;i<len;i++)
		{
			buffer[i] = toupper(buffer[i]);
		}
	}
}

/*map the parsed words to object ids*/ 
/*
BOOL map()
{
	int v = get_verb_id(VerbBuffer);
	if (v == INVALID)
	{
		printf("I don't know the verb '%s'\n", VerbBuffer);
		return FALSE;
	}
	VerbId = v;
	DobjId = INVALID;
	PrepId = INVALID;
	IobjId = INVALID;
	
	if (DobjPtr != 0)
	{
		DobjId = word_to_object_id(DobjPtr);
		if (DobjId == INVALID)
		{
//			printf("(Unable to map direct object %s.)\n", DobjPtr);
			printf("I don't know the word %s.\n", DobjPtr);
			return FALSE;
		}
	}
	
	if (IobjPtr != 0)
	{
		PrepId = get_word_id(WordPtrs[2], PrepTable, PrepTableSize);
		IobjId = word_to_object_id(IobjPtr);
		if (IobjId==INVALID)
		{
//			printf("(Unable to map indirect object %s.)\n", IobjPtr);
			printf("I don't know the word %s.\n", IobjPtr);
			return FALSE;
		}
	}
	
//	printf("VerbId=%d",VerbId);
//	printf("DobjId=%d",DobjId);
//	printf("PrepId=%d",PrepId);
//	printf("IobjId=%d",IobjId);
//	printf("\n");
	return TRUE;
} 
*/

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

/*assume checks have been passed*/
void execute()
{
	/*before*/
	if (try_sentence(BeforeTable,BeforeTableSize, FALSE)==FALSE)
	{
		try_sentence(BeforeTable,BeforeTableSize, TRUE);
	}
	
	if (try_sentence(InsteadTable,InsteadTableSize, FALSE) == FALSE)
	{
		if (try_sentence(InsteadTable,InsteadTableSize, TRUE)==FALSE)
		{
			try_default_sentence();	
			
			if (Handled==0)
			{
				printf("I don't understand.\n");
			}
		}
		
	}

	/*after*/
	if (!try_sentence(AfterTable,AfterTableSize, FALSE))
	{
		try_sentence(AfterTable,AfterTableSize, TRUE);
	}
	
	run_events();

	draw_status_bar();
}

void try_default_sentence()
{
	Handled = TRUE;
//	printf("looking for a default match. verb id=%d\n", VerbId);
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
	{	printf("Bye.\n");
		exit(0);
	}
	else
	{
//		printf("couldn't find a default handler.\n");
		Handled = FALSE;
	}
//	if (VerbId == UNWEAR_VERB_ID)
	//	unwear_sub();


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
			//	printf("Executing a custom event with wildcards.\n");
				(*table[i].handler)();
			//	printf("Done.\n");
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
			//		printf("Executing a custom event. Addr=%x\n", table[i].handler);
					(*table[i].handler)();
			//		printf("Done.\n");
					result=TRUE;
					break;
				}
		}
	}
	
	return result;
} 

void look_sub()
{
	int i=2;
	int roomId=INVALID;
	unsigned char initialDesc;
	BOOL canSee=FALSE;
	char name[40];
	char roomName[40];
	
	get_room_name(ObjectTable[PLAYER_ID].attrs[HOLDER_ID],roomName);
	
	printf("%s\n",roomName);
	
	if (can_see()==0)
	{	
		printf("It is pitch dark.\n");
		return;
	}
	else
	{
		unsigned short roomId = ObjectTable[PLAYER_ID].attrs[HOLDER_ID];
		unsigned short descId = ObjectTable[roomId].attrs[DESC_ID];
		//print_table_entry(descId, StringTable);
		print_string(descId);
		printf("\n");
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
				printf("\n");
			}
			else
			{
				if (get_obj_prop(i,SCENERY)==0)
				{
					get_obj_name(i,name);
					printf("There is a %s here.\n", name);
				}
			}
			
			list_any_contents(i);
		}
	}
}

void examine_sub()
{
	print_table_entry(ObjectTable[DobjId].attrs[DESC_ID],StringTable);
	printf("\n");
	list_any_contents(DobjId);
}

BOOL is_open_container(unsigned char objectId)
{
	char name[80];
	memset(name,0,80);
	if (get_obj_prop(objectId,CONTAINER)==1 && get_obj_prop(objectId,OPEN)==1)
	{
		get_obj_name(objectId,name);
//		printf("%s is an open container.\n",name);
		return TRUE;
	}	
	return FALSE;
}


BOOL is_closed_container(unsigned char objectId)
{
	if (get_obj_prop(objectId,CONTAINER)==1 && get_obj_prop(objectId,OPEN)==0)
		return TRUE;
	return FALSE;
}

void move_sub()
{
	unsigned char tgtRoom=INVALID;
	int dir=0;
	int room = ObjectTable[PLAYER_ID].attrs[HOLDER_ID];
	dir = verb_to_dir(VerbId);
	
//	printf("current room is %d\n", room);
	tgtRoom = ObjectTable[room].attrs[dir];
	enter_object(tgtRoom, dir);
}

void enter_sub()
{
	enter_object(DobjId, ENTER);
}

void enter_object(unsigned char tgtRoom, int dir)
{
	
	//printf("target room = %d\n",tgtRoom);
	
	if (tgtRoom > 127)
	{
		int msgId = (255 - tgtRoom)+1;
		//printf("printing nogo message %d\n", msgId);
		print_table_entry(msgId,NogoTable); 
		printf("\n");
	}
	else
	{
		if (is_door(tgtRoom)==TRUE)
		{
			if (is_closed(tgtRoom)==TRUE)
			{
				char name[80];
				get_obj_name(tgtRoom,name);
				printf("The %s is closed.\n",name);
				return;
			}
			else
			{
			//	printf("passing through a door\n");
				tgtRoom = ObjectTable[tgtRoom].attrs[dir];	/*move through door to room on other side*/
			}
		}
//		else
//		{
//			printf("%d is not a door\n", tgtRoom);
//		}
		
		//if the object has an 'enter' treat the object l
		if (ObjectTable[tgtRoom].attrs[ENTER] != INVALID)
		{
//			printf("entering inside %d\n", tgtRoom);
			tgtRoom = ObjectTable[tgtRoom].attrs[ENTER];
		}
		
		ObjectTable[PLAYER_ID].attrs[HOLDER_ID]=tgtRoom;
		look_sub();		
	}
	
}

void get_sub()
{
	printf("Taken.\n");
	ObjectTable[DobjId].attrs[HOLDER_ID] = PLAYER_ID; 
	ObjectTable[DobjId].attrs[INITIAL_DESC_ID] = INVALID;  //clear initial desc
}

void drop_sub()
{
	printf("Dropped.\n");
	ObjectTable[DobjId].attrs[HOLDER_ID] = ObjectTable[PLAYER_ID].attrs[HOLDER_ID];
}

void put_sub()
{
	if (is_supporter(IobjId)==FALSE && is_open_container(IobjId) == FALSE)
	{
		printf("You can't do that.\n");
		return;
	}
	printf("Done.\n");
	ObjectTable[DobjId].attrs[HOLDER_ID] = IobjId;
}

void open_sub()
{
	char name[80];
	printf("Opened.\n");
	set_obj_prop(DobjId, OPEN, 1);
	get_obj_name(DobjId, name);
	if (has_visible_children(DobjId)==TRUE)
	{
		printf("Opening the %s reveals:\n",name);
		print_obj_contents(DobjId);
	}
	
}

void close_sub()
{
	printf("Closed.\n");
	set_obj_prop(DobjId, OPEN, 0);
}

void wear_sub()
{
	char name[80];
	memset(name,0,80);
	get_obj_name(DobjId,name);
	printf("You put on the %s.\n", name);
	set_obj_prop(DobjId, BEINGWORN, 1);
}

void unwear_sub()
{
	char name[80];
	memset(name,0,80);
	get_obj_name(DobjId,name);
	printf("You remove the %s.\n", name);
	set_obj_prop(DobjId, OPEN, 1);
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

BOOL is_supporter(unsigned char objectId)
{
	return get_obj_prop(objectId, SUPPORTER);
}

BOOL is_container(unsigned char objectId)
{
	return get_obj_prop(objectId, CONTAINER);
}

BOOL can_see()
{
	int i=2;
	int roomId = INVALID;
	
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

BOOL is_visible_to(unsigned char roomId, unsigned char objectId)
{
	while (1)
	{
		unsigned char parent = ObjectTable[objectId].attrs[HOLDER_ID];		
		//printf("in vis loop, %d, %d, %d\n", roomId, parent, objectId);

		if (roomId == objectId)
		{
		//	printf("found object!\n");
			return TRUE;
		}
		
		if (parent == OFFSCREEN)
		{
//			printf("hit offscreen\n");
			return FALSE;
		}
		
		if (parent == roomId)
		{
	//		printf("hit parent=success!\n");
			return TRUE;
		}	
		
		if (is_closed_container(parent))
		{
		//	printf("parent is a closed container.\n");
			return FALSE;
		}	
		
		objectId = parent;
		
	}
//	printf("%d is visible to %d\n", roomId, objectId);
	return TRUE;
}

BOOL is_prep(char *word)
{
	int i=0;
/*	printf("there are %d preps\n", PrepTableSize); */\
	for (i=0; i < PrepTableSize; i++)
	{
		if (stricmp(PrepTable[i],word)==0)
		{
			return TRUE;
		}
/*		printf("%s != %s\n", PrepTable[i], word); */
	}
	return FALSE;
}

BOOL is_article(char *word)
{
	int i=0;
	for (i=0; i < NumArticles; i++)
	{
		if (stricmp(word,ArticleTable[i])==0)
			return TRUE;
	}
	
	return FALSE;
}



 
/* returns the id # of a word or 255 if not found*/
unsigned char get_word_id(char *wordPtr, const char **table, int tableSize)
{
	int i=0;
	for (i=0; i < tableSize; i++)
	{
		if (stricmp(wordPtr,table[i])==0)
		{
			return i;
		}
	}
	return INVALID;
}



void set_obj_attr(unsigned short objNum, unsigned short attrNum, unsigned short  val)
{
//	printf("setting attr:  %d.%d to %d\n", objNum,attrNum,val);
	ObjectTable[objNum].attrs[attrNum] = (unsigned char)val;
}

void set_obj_prop(unsigned short objNum, unsigned short propNum, unsigned short val)
{
	unsigned short mask;
	unsigned short temp;
//	printf("setting prop:  %d.%d(%s) to %d\n", objNum,propNum,propNames[propNum],val);
	
	if (val == 0)
	{//clear it
		mask = PropMasks[propNum];
		mask = 0xff - mask; /* flip it */
		temp = ObjectTable[objNum].flags | mask;
		ObjectTable[objNum].flags = temp;
	}
	else
	{//set it
		ObjectTable[objNum].flags |= PropMasks[propNum];		
	}
}

unsigned short get_obj_attr(unsigned short obj, unsigned short attrNum)
{
	char name[80];
	get_obj_name(obj,name);
//printf("getting attr:  %d (%s).%d (%s)\n", obj,name,attrNum,attrNames[attrNum]);
	return (unsigned short) ObjectTable[obj].attrs[attrNum];
}

/*prop is 1-15 */

unsigned short get_obj_prop(unsigned short obj, unsigned short propNum)
{
	char name[80];
	unsigned short temp  = ObjectTable[obj].flags & PropMasks[propNum];
	get_obj_name(obj,name);
	
	//printf("getting prop:  %d(%s).%d(%s) \n", obj,name,propNum,propNames[propNum]);
	
	if (temp == 0)
		return 0;
	return 1;
}

void print_string(unsigned short entryNum)
{
//	printf("entryNum=%d\n",entryNum);
	char *token=0;
	char *delim  = " ";
	char buf[256];
	
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

void print_table_entry(unsigned short entryNum, const char **table)
{
//	printf("PRINT TABLE ENTRY %d,%x\n", entryNum,(short)table);
	
	if (table == 0)
	{
		printf("Bad table value, using string table.\n");
		table = StringTable;
	}
	
	printf("%s", table[entryNum]);
}

unsigned char get_verb_id(char *verb)
{
	int i=0;
	for (i=0; i < NumVerbs; i++)
	{
/*		printf("verb %d=%s\n",i,VerbTable[i].word); */
		if (stricmp(verb,VerbTable[i].word)==0)
		{
			return VerbTable[i].id;
		}
	}
	return INVALID;
}

unsigned char noun_to_object_id(unsigned char wordId)
{
	int i=0;
		for (i=0; i < ObjectWordTableSize; i++)
		{
			if (ObjectWordTable[i].word1 == wordId)
				return ObjectWordTable[i].id;
			if (ObjectWordTable[i].word2 == wordId)
				return ObjectWordTable[i].id;
			if (ObjectWordTable[i].word3 == wordId)
				return ObjectWordTable[i].id;
		}
		return INVALID;
}

/*returns true of wordId applies to object objectId*/
BOOL word_matches_object(int wordId, int objectId)
{
	/*need the loop to check for synonyms*/
	int i=0;
	for (; i < ObjectWordTableSize; i++)
	{
		if (ObjectWordTable[i].id == objectId)
		{
			if (ObjectWordTable[i].word1 == wordId)
				return TRUE;
			if (ObjectWordTable[i].word2 == wordId)
				return TRUE;
			if (ObjectWordTable[i].word3 == wordId)
				return TRUE;
		}
	}
	return FALSE;
}
/*
unsigned char get_string_id(unsigned short entryNum, char *table[])
{
	return table[entryNum];
}*/

void print_obj_contents(unsigned char objectId)
{
	int i=2;
	for (i=2; i < NumObjects; i++)
	{
		if (ObjectTable[i].attrs[HOLDER_ID] == objectId &&
		get_obj_prop(i,SCENERY)==0)
		{
			char name[80];
			memset(name,0,80);
			get_obj_name(i,name);
			printf("A %s.", name);
			if (get_obj_prop(i,BEINGWORN)  == TRUE)
			{
				printf("(being worn)");
			}
			if (get_obj_prop(i,LIT) == TRUE)
			{
				printf("(providing light)");
			}
			printf("\n");
			list_any_contents(i);	
		}
	}
}

void list_any_contents(unsigned char objectId)
{
	char name[80];

	if (is_open_container(objectId)==TRUE && has_visible_children(objectId) == TRUE)
	{
		memset(name,0,80);
		get_obj_name(objectId,name);
		printf("The %s contains:\n", name);
		print_obj_contents(objectId);
	}
	else if (is_supporter(objectId)==TRUE && has_visible_children(objectId) == TRUE)
	{
		memset(name,0,80);
		get_obj_name(objectId,name);
		printf("On the %s is:\n", name);
		print_obj_contents(objectId);
	}
 		
}

void inventory_sub()
{
	if (has_visible_children(PLAYER_ID) == TRUE)
	{
		printf("You are carrying:\n");
		print_obj_contents(PLAYER_ID);		
	}
	else 
	{
		printf("You are empty handed.\n");
	}
}

BOOL check_see_dobj()
{
	int playerRoom = ObjectTable[PLAYER_ID].attrs[HOLDER_ID];
	if (is_visible_to(playerRoom, DobjId)==0)
	{
		printf("You don't see that.\n");
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
		printf("That's not portable.\n");
		return FALSE;
	}
//	printf("DObj is portable.\n");
	return TRUE;
}

BOOL check_dobj_wearable()
{
	short flags = ObjectTable[DobjId].flags;
	flags = flags & WEARABLE_MASK;

	if (flags == 0)
	{
		printf("You'd pretty silly wearing that.\n");
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
		printf("The %s is closed.\n",name);
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
		printf("The %s is open.\n",name);
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
	if (DobjSupplied == 0)
	{
		printf("Missing noun.\n");
		return FALSE;
	}
	return TRUE;
}

BOOL check_iobj_supplied()
{
	if (IobjSupplied	== 0)
	{
		printf("Missing noun.\n");
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
		printf("The %s is closed.\n", buffer);
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
		printf("You can't open that.\n");
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

		printf("The %s is locked.\n",name);
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
		printf("You can't do that.\n");
		return FALSE;
	}
	return TRUE;
}

BOOL check_have_dobj()
{
	if (is_ancestor(PLAYER_ID,DobjId)==FALSE)
	{
		printf("You don't have that.\n");
		return FALSE;
	}
	return TRUE;
}

BOOL check_dont_have_dobj()
{
	if (is_ancestor(PLAYER_ID,DobjId)==TRUE)
	{
		printf("You already have it.\n");
		return FALSE;
	}
	return TRUE;
}

BOOL check_not_self_or_child()
{
	if (DobjId == IobjId || is_ancestor(DobjId,IobjId))
	{
		printf("That's not possible.");
		return FALSE;
	}
		
	return TRUE;
}

BOOL is_ancestor(unsigned char parent, unsigned char child)
{
	if (child == parent)
		return TRUE;
	
	while (child != 0)
	{
//		printf("is ancestor..\n");
		if (ObjectTable[child].attrs[HOLDER_ID] == parent)
			return TRUE;
		
		child = ObjectTable[child].attrs[HOLDER_ID];
	}
	
	return FALSE;
}

unsigned char word_to_object_id(char *word)
{		
		int i=0;
		unsigned char wordId = get_word_id(word, Dictionary, DictionarySize);
		
		if (wordId == INVALID)
			return INVALID; 
		
		return noun_to_object_id(wordId);
}

BOOL emitting_light(unsigned char objId)
{
	return get_obj_prop(objId,LIT);
}

BOOL is_open(unsigned char objectId)
{
	return  get_obj_prop(objectId,OPEN);
}

BOOL is_door(unsigned char objectId)
{
	return get_obj_prop(objectId,DOOR);
}

BOOL is_closed(unsigned char objectId)
{
	if (get_obj_prop(objectId,OPEN))
		return FALSE;
	return TRUE;
}

BOOL has_visible_children(unsigned char objectId)
{
	int i=2;
	for (i=2 ; i < NumObjects; i++)
	{
		if (ObjectTable[i].attrs[HOLDER_ID]==objectId &&
		get_obj_prop(i,SCENERY)==0 )
		{
			return TRUE;
		}
	}
	
	return FALSE;
}

unsigned char verb_to_dir(unsigned char verbId)
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
	printf("Invalid direction in verb_to_dir\n");
	return NORTH;
}

void __cdecl print_cr()
{
	printf("\n");
	Col=0;
}

#include "ObjectTable8086.c"
#include "ObjectWordTable.c"
#include "VerbTable8086.c"


void dump_obj_table()
{
	int i,j;
	for (i=0; i < NumObjects; i++)
	{
		for (j=0; j < 17; j++)
		{
			printf("%d ", ObjectTable[i].attrs[j]);
		}
		printf(" flags: %x", ObjectTable[i].flags);
		printf("\n");
	}
}

void dump_obj_word_table()
{
	int i,j;
	for (i=0; i < NumObjects; i++)
	{
		printf("%d,%d,%d,%d\n", ObjectWordTable[i].id, ObjectWordTable[i].word1,ObjectWordTable[i].word2,ObjectWordTable[i].word3);
	}
}

void dump_instead_table()
{
	int i=0;
	for (i=0; i < InsteadTableSize; i++)
	{
		printf("%d,%d,%d,%d:%x\n", 
			InsteadTable[i].verb,
			InsteadTable[i].dobj,
			InsteadTable[i].prep,
			InsteadTable[i].iobj,
			InsteadTable[i].handler);
	}
}

void purloin()
{
	int id;
	printf("Which object?");
	gets(Buffer);
	id = word_to_object_id(Buffer);
	if (id != INVALID)
	{
		ObjectTable[id].attrs[HOLDER_ID] = PLAYER_ID;
		look_sub();
	}
}

void dbg_goto()
{
	int id=0;
	printf("Which room?");
	gets(Buffer);
	id = word_to_object_id(Buffer);
	if (id != INVALID)
	{
		ObjectTable[PLAYER_ID].attrs[HOLDER_ID] = id;
		look_sub();
	}
}


void dump_flags()
{
	int i=0;
	printf("enter object number:\n");
	gets(Buffer);
	i = word_to_object_id(Buffer);
	
	printf("hflags: %x,%x\n", ObjectTable[i].flags/256, ObjectTable[i].flags%256);
	printf("iflags: %d\n", ObjectTable[i].flags);
	if (get_obj_prop(i,SCENERY)==1) printf("scenery\n");
	if (get_obj_prop(i,LIT)==1) printf("lit\n");
	if (get_obj_prop(i,PORTABLE)==1) printf("portable\n");
	if (get_obj_prop(i,LOCKED)==1) printf("locked\n");
	if (get_obj_prop(i,OPEN)==1) printf("open\n");
	if (get_obj_prop(i,CONTAINER)==1) printf("container\n");
	if (get_obj_prop(i,DOOR)==1) printf("door\n");
}

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
	
	if ((len+1) < rem)
	{
		printf("%s ",w);
		Col = Col+len+1;
	}	
	else if (len==rem)
	{
		printf("%s",w);
		Col=0;
	}
	else
	{ //not enough room left
		Col=0;
		printf("\n%s ",w);
		Col=len+1;
	}
}

void init()
{
	ObjectTable = (ObjectEntry*)ObjectData;
	ObjectWordTable = (ObjectWordEntry*)ObjectWordTableData;
	VerbCheckTable = (VerbCheck*)VerbCheckTableData;
	init_before_functions();
	init_instead_functions();
	init_after_functions();
	init_verb_checks(); 
	init_verb_table();
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
	   WordPtrs[i]=0;
   }

	token = strtok(Buffer, delim);
   
   /* walk through other tokens */
   while( token != NULL ) 
   {
  //    printf("token: %s\n", token);
	  if (!is_article(token))
	  {
		  WordPtrs[NumWords] = token;
		  NumWords++;
	  }		  
      token = strtok(NULL, delim);
   }
//   printf("WordCount=%d\n",NumWords);
}

/*if needed, turn verbs like 'look at' into one word*/
void collapse_verb()
{
	int i=1;
//	printf("Num words=%d\n", NumWords);
	if (NumWords > 1)
    {
	   if (is_prep(WordPtrs[1]))
	   {
	 	   printf("%s is a prep\n", WordPtrs[1]);
		   strcat(VerbBuffer," ");
		   strcat(VerbBuffer,WordPtrs[1]);
		   
		   for (i=1; i < NumWords-1;i++)
			{
				WordPtrs[i] =WordPtrs[i+1];
			}
			WordPtrs[NumWords-1]=0; /*erase last entry*/
			NumWords--;
 	   }
	}
	 
	strcpy(VerbBuffer,WordPtrs[0]);
	
//	printf("verb=%s\n",VerbBuffer);
}

/*scores each object if wordId applies to it*/
void score_objects(unsigned char wordId)
{
	int i=0;
	int playerRoom=0;
	playerRoom = ObjectTable[PLAYER_ID].attrs[HOLDER_ID];

	for (i=0; i < NumObjects; i++)
	{
		if (word_matches_object(wordId,i))
		{
			if (Scores[i] != INVALID)
			{
	//	 			printf("Word %d matches object %d\n", wordId,i);
					Scores[i]+=1;
					
					if (is_visible_to(playerRoom,i))
						Scores[i]+=1;
			}
 		}
		else
		{
			Scores[i] = INVALID; /*can't be this object*/
		}
	}
}

int get_max_score()
{
	int i=0;
	int max=0;
	for (i=0; i < NumObjects; i++)
	{
		/*clear invalid flags*/
		if (Scores[i] == INVALID)
			Scores[i]=0;
		
		if (Scores[i] > max)
		{
			max = Scores[i];
		}
	}
	return max;
}

/*returns number of objects matching the max score*/
int max_score_matches(int max)
{
	int i=0;
	int count=0;
	for (i=0; i < NumObjects; i++)
	{
		if (Scores[i] == max)
			count++;
	}
//	printf("After parsing, there are %d matches.\n", count);
	return count;
}

/*returns the object with the supplied score*/
unsigned char max_score_object(int max)
{
	int i=0;
	for (i=0; i < NumObjects; i++)
	{
		if (Scores[i] == max)
			return i;
	}
	return INVALID;
}

/*parses input and determines verb, noun, and prep id numbers*/
BOOL parse_and_map()
{
	int i=0;
	int wordId=0;
	int maxScore=0;
	DobjId=INVALID;
	PrepId=INVALID;
	IobjId=INVALID;
	DobjSupplied=FALSE;
	IobjSupplied=FALSE;
	
	tokenize_input();
	
	if (NumWords==0)
	{
		printf("Pardon?\n");
		return FALSE;
	}
	
	collapse_verb();
	
	VerbId = get_verb_id(VerbBuffer);
	
	if (VerbId == INVALID)
	{
		printf("I don't know the verb '%s'\n", VerbBuffer);
		return FALSE;
	}
	
	if (NumWords==1)
		return TRUE; //nothing left to do
	
	//map noun1 and noun2
	memset(Scores,0,NumObjects); //clear scores

	for (i=1; i < NumWords; i++)
	{	
		if (is_prep(WordPtrs[i]))
		{ 
		//	printf("prep found:%s\n",WordPtrs[i]);

			PrepId = get_word_id(WordPtrs[i],PrepTable,PrepTableSize);
			IobjSupplied=TRUE;
			DobjSupplied=TRUE;
			if (score_object(1,i,&DobjId) == TRUE)
			{
				if (score_object(i+1,NumWords,&IobjId) == TRUE)
				{
					return TRUE;	
				}	
			}					
			return FALSE;
		}
	}
	
	/*no prep found - whole thing is noun1*/
	//printf("no prep found.\n");
	DobjSupplied = TRUE;
	return score_object(1,NumWords,&DobjId);	
}

/*loops over a range of words and tries to map the result to objId*/
BOOL score_object(int startIndex, int endIndex, unsigned char *objId)
{
	int maxScore=0;
	int wordId=INVALID;
	int i=startIndex;

	memset(Scores,0,NumObjects); //clear scores

	for (; i < endIndex ;i++)
	{
//		printf("scoring word %s\n", WordPtrs[i]);
		wordId = get_word_id(WordPtrs[i],Dictionary,DictionarySize);
		if (wordId == INVALID){
			printf("I don't know the word '%s'\n",WordPtrs[i]);
			return FALSE;
		}
		score_objects(wordId);
	}
	
	maxScore = get_max_score();
	if (max_score_matches(maxScore) > 1)
	{
		printf("I don't know which one you mean.\n");
		return FALSE;
	}
	
	*objId = max_score_object(maxScore);
	return TRUE;
}


