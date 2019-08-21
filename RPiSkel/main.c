/*text adventure shell
 *Evan Wright
 *2018-2019
 */




#pragma pack(0)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stack>
#include "defs.h"
#include "VerbDefs.h"
   
BYTE temp;
BYTE temp2;
int scrWidth = 80;
  

#include "common.h"
#include "checks.h"

extern const int DictionarySize;
extern const char *Dictionary[];

char Buffer[256]; 
char UCaseBuffer[256];
char VerbBuffer[55];
char *words[10];
char NumWords=0;
char *startPtr;


short param_stack_pop();
void set_var(const char *name, short value);
void draw_status_bar();
void clear_buffers();

BYTE get_verb_id(char *verb);
BOOL word_matches_object(int wordId, int objectId);
unsigned char max_score_object(int max);

void dump_obj_table();			
void sethpos();
void setvpos();
void dump_matches();

void collapse_verb();
void quit_sub();
void printstr(const char*);
void try_default_sentence();

void print_word(char *wrd);
void score_objects(unsigned char wordId);
BYTE stricmp(const char * str1,const char * str);
BYTE verb_to_dir(BYTE verbId);

BOOL score_object(int startIndex, int endIndex, unsigned char *objId);
BOOL check_rules();

void print_cr();
void print_string_formatted(char *);

BYTE get_object_attr(BYTE obj, BYTE attrNum);
BYTE get_object_prop(BYTE obj, BYTE propNum);
void set_object_attr(BYTE objNum, BYTE attrNum, BYTE  val);
void set_object_prop(BYTE objNum, BYTE propNum, BYTE val);
void purloin();

//void to_upper(char *s);
void fix_endianess();
BYTE rand8(BYTE divisor);
const int NumArticles = 4;
const char *articles[] = { "A","AN","THE","OF" };
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


int Col = 0;
unsigned char *DobjPtr = 0;
unsigned char *PrepPtr = 0;
//char *WordPtrs[10];



BYTE maxScoreCount=0;
BYTE maxScoreObj=INVALID;
BYTE hpos;
BYTE vpos;
BYTE ScrWidth=32;
BYTE MaxScore=0;
BYTE MaxScoreObj=0;
BYTE MaxScoreCount=0;

char * nogo_table;  /* defined in ASM file */

//char *DescriptionTable;
/*end externs*/

ObjectWordEntry *ObjectWordTable;
WordEntry *VerbTable;
Object *ObjectTable = 0;
VerbCheck *VerbCheckTable=0;
Sentence *BeforeTable;
Sentence *InsteadTable;
Sentence *AfterTable;

BOOL done = FALSE;
BOOL Handled=FALSE;

BYTE lowerCase=FALSE;

std::stack<short> param_stack;
short param1,param2,param3;

#include "NogoTable.h"
#include "Welcome.c"


extern const int NumObjects;
extern const int ObjectWordTableSize;

/*group save data together*/


/*built in vars*/
BYTE score=0;
BYTE turnsWithoutLight=0;
BYTE gameOver=FALSE;
BYTE moves=0;
BYTE health=100;
BYTE answer=0;

#include "UserVars.c"
#include "Events.h"
#include "VerbTable.c"
#include "CheckTable.h"
#include "Strings.h"

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
"USER1",
"LIT",
"DOOR",
"USER2"
};

BYTE scores[128];


int main()
{
	printf("\x1b[2J"); //cls
	printf("\x1b[2;0H"); //position cursor583
	
	
	init();

	printf("\n");
 	printf("%s\n", WelcomeStr);
	printf("%s\n", AuthorStr);
	printf("\n");
 
	look_sub();
	
	while (!done)
	{
		draw_status_bar();

		/* read a line */
		size_t len=255;
		char *line=Buffer;
		printf(">");
		/*gets(Buffer);*/
		clear_buffers();

		getline(&line, &len,stdin); /* reads into global input buffer */
		line[strlen(line)-1]=0;
//		strncpy(Buffer,line,255);  copying buffer onto itself!
		
		
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
		
		if (stricmp(Buffer,"score")==0)
		{
			sprintf(Buffer,"Your score is %d/100.\n",score);
			printf(Buffer);
			continue;
		}
		
		/* parse a line */
 
		 
		printf("\n");
		hpos=0;
		if (parse_and_map()==TRUE)
		{
			Col=0;
			if (check_rules()==TRUE)
			{
				execute();
				moves++;
			}
		}
  
	}

	return 0;
}


void tokenize_input()
{
	int i = 0;
	char *token = 0;
	const char *delim = " ";

	NumWords = 0;
	/*clear word pointers*/
	for (i = 0; i < 10; i++)
	{
		words[i] = 0;
	}

	token = strtok(Buffer, " ");

	/* walk through other tokens */
	while (token != NULL)
	{
		if (!is_article(token))
		{
			words[NumWords] = token;
			NumWords++;
		}
		
		token = strtok(NULL, delim);
	}

}


/*loops over a range of words and tries to map the result to objId*/
BOOL score_object(int startIndex, int endIndex, unsigned char *objId)
{
	int maxScore = 0;
	int wordId = INVALID;
	int i = startIndex;

	memset(scores, 0, NumObjects); //clear scores

	for (; i < endIndex; i++)
	{
		//		printf("scoring word %s\n", WordPtrs[i]);
		wordId = get_word_id(words[i], Dictionary, DictionarySize);
		if (wordId == INVALID) {
			printf("I don't know the word '%s'\n", words[i]);
			return FALSE;
		}
		score_objects(wordId);
	}

	get_max_score(); /*sets MaxScore*/
	maxScore = MaxScore; /* ugh */
	if (max_score_matches(maxScore) > 1)
	{
		if (any_visible())
		{
			printf("I don't know which one you mean.\n");
		}
		else
		{
			printf("You don't see that.\n");
		}
		return FALSE;
	}

	*objId = max_score_object(maxScore);
	return TRUE;
}


void clear_buffers()
{
	PrepId = INVALID;
	DobjId = INVALID;
	IobjId = INVALID;
	
	memset(Buffer,0,80);		
	memset(VerbBuffer,0,55);
	NumWords=0;
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
 

void print_cr()
{
	printf("\n");
	Col=0;
}


/*tokenizes the string and prints it out one word at a time*/
void print_string(BYTE entryNum)
{
	char *token=0;
	const char *delim  = " ";
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



void print_word(char* w)
{
	int len = 0;
	int rem = 0;
	len = strlen(w);
	rem = scrWidth-Col;
	
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




/*looks at the verb buffer and attempts to find a match in the verb table*/
/*verb has an id, a length, and is null terminated.
 *the last verb has an id of 255
 */

BYTE get_verb_id(char *verb)
{
	int i = 0;
	for (i = 0; i < NumVerbs; i++)
	{
		/*		printf("verb %d=%s\n",i,VerbTable[i].word); */
		if (stricmp(verb, VerbTable[i].wrd) == 0)
		{
			return VerbTable[i].id;
		}
	}
	return INVALID;
}


void quit_sub()
{
	printf("Goodbye.\n");
	done = TRUE;
	exit(0); //don't process events
}



/*
BOOL check_see_dobj()
{
	BYTE playerRoom = ObjectTable[PLAYER_ID].attrs[HOLDER_ID];
	if (is_visible_to(playerRoom, DobjId)==0)
	{
		printf("You don't see that.\n");
		return FALSE;
	}
	return TRUE;
}
/*

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

BOOL check_dobj_lockable()
{
	char name[80];
	
	short flags = ObjectTable[DobjId].flags;
 	flags = flags & LOCKABLE_MASK;
 	if ( flags == 0 )
	{
		get_obj_name(DobjId,name);
		printf("You can't lock or unlock that.\n");
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
		printf("You'd look rediculous.\n");
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
		printf("The %s already is open.\n",name);
		return FALSE;
	}
	return TRUE;
}

BOOL check_weight()
{
	BYTE w = ObjectTable[DobjId].attrs[MASS];
	
	if (get_inv_weight((BYTE)PLAYER_ID) + w > MAX_INV_WEIGHT)
	{
		printf("Your load is too heavy.\n");
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
//	if (DobjSupplied == 255)
	if (DobjId == INVALID)
	{
		printf("Missing noun.\n");
		return FALSE;
	}
	return TRUE;
}

BOOL check_iobj_supplied()
{
	if (IobjId	== INVALID)
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
*/


//#include "checks.c" 

 
void draw_status_bar()
{
	//save cursor
	printf("\x1b[s");
	//goto top left
	printf("\x1b[0;0f");
	printf("\x1b[47m"); //white background

	for (int i=0; i < 80; i++)
	{
		printf(" ");
	}
	//back to top left
	printf("\x1b[0;0f");
	//set background to black
	printf("\x1b[40m");
	// inverse mode
	printf("\x1b[7m");
	char buffer[80];
	get_room_name(ObjectTable[PLAYER_ID].attrs[HOLDER_ID], buffer);
	printf(buffer);
	printf("\x1b[0;50f");
	sprintf(buffer,"Score: %d/100",score);
	printf(buffer);
	printf("\x1b[0;70f");
	sprintf(buffer,"Moves: %d",moves);
	printf(buffer);
	printf("\x1b[0m"); //clear invese 
	printf("\x1b[u");
}

void printcr()
{
	printf("\n");
	hpos=0;
}


void fix_endianess()
{
}	

char to_uchar(char ch)
{
	if (ch >= 97 && ch <= 122)
	{
		return ch - 32;
	}
	
	return ch;
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


BYTE rand8(BYTE divisor)
{
	return (BYTE)rand() % divisor;
}





short param_stack_pop()
{
	short top = param_stack.top();
	param_stack.pop();
	return top;
}

/*if needed, turn verbs like 'look at' into one word*/
void collapse_verb()
{
	int i = 1;
	//	printf("Num words=%d\n", NumWords);
	strcpy(VerbBuffer,words[0]);
	if (NumWords > 1)
	{
		if (is_prep(words[1]))
		{
			strcat(VerbBuffer, " ");
			strcat(VerbBuffer, words[1]);

			for (i = 1; i < NumWords - 1; i++)
			{
				words[i] = words[i + 1];
			}
			words[NumWords - 1] = 0; /*erase last entry*/
			NumWords--;
		}
	}
	//	printf("verb=%s\n",VerbBuffer);
}

/*returns the object with the supplied score*/
unsigned char max_score_object(int max)
{
	int i=0;
	for (i=0; i < NumObjects; i++)
	{
		if (scores[i] == max)
			return i;
	}
	return INVALID;
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
			if (scores[i] != INVALID)
			{
	//	 			printf("Word %d matches object %d\n", wordId,i);
					scores[i]+=1;
					
					if (is_visible_to(playerRoom,i))
						scores[i]+=1;
			}
 		}
		else
		{
			scores[i] = INVALID; /*can't be this object*/
		}
	}
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



#include "event_jumps.c"


void save_sub()
{
	char buf[80];
	char *line = buf;
	size_t len = 80;
	printf("Enter file name:");
	getline(&line,&len,stdin);
	buf[strlen(buf)-1]=0;
	strcat(buf,".sav");
	FILE *fp = fopen(buf,"w");
	if (fp != 0)
	{
		fwrite(ObjectTable, sizeof(Object) * NumObjects, 1, fp);
		//write built in vars
		fwrite(&score, sizeof(score), 1, fp);
		fwrite(&moves, sizeof(moves), 1, fp);
		fwrite(&health, sizeof(health), 1, fp);
		fwrite(&turnsWithoutLight, sizeof(turnsWithoutLight), 1, fp);
		//write user vars
		fwrite(&turnsWithoutLight+sizeof(score), sizeof(turnsWithoutLight), NumUserVars, fp);	
		fclose(fp);
		printf("game saved.\n");
	}
}

void restore_sub()
{
	char buf[80];
	char *line = buf;
	size_t len = 80;
	printf("Enter file name:");
	getline(&line,&len,stdin);
	buf[strlen(buf)-1]=0;
	strcat(buf,".sav");
	FILE *fp = fopen(buf,"rb");
	if (fp != 0)
	{
		fread(ObjectTable, sizeof(Object) * NumObjects, 1, fp);
		//write built in vars
		fread(&score, sizeof(score), 1, fp);
		fread(&moves, sizeof(moves), 1, fp);
		fread(&health, sizeof(health), 1, fp);
		fread(&turnsWithoutLight, sizeof(turnsWithoutLight), 1, fp);
		//write user vars
		fread(&turnsWithoutLight+sizeof(score), sizeof(turnsWithoutLight), NumUserVars, fp);	
		fclose(fp);
		
		look_sub();
	}
}


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


/*used to read input from player*/
void ask()
{
	char buf[80];
	char *line = buf;
	size_t len=80;
	getline(&line, &len,stdin); /* reads into global input buffer */
	line[strlen(line)-1]=0;  /* remove newline */
	answer = get_word_id(line,StringTable,StringTableSize);
}

void printstr(const char *s)
{
	printf("%s",s);
}

#include "PrepTable.h"
#include "Events.c"
//#include "common.c"
