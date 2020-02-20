/* sets all the scores back to 0 */

//#define DEBUG_MAPPING

void clear_scores()
{
	unsigned char i=0;
	MaxScore=0;
	MaxScoreCount=0;

	for (; i < 128; i++)
		scores[i]=0;
}
 
/*copies the 1st word into the verb buffer
if the 2nd word is a prep, it is appended to
the verb buffer*/
void get_verb()
{
	unsigned char i=1;
	 
	strcpy(VerbBuffer, words[0]);
 	
	if (NumWords > 1)
	{
		BYTE id = is_prep(words[1]);
		if (id != INVALID)
		{
#ifdef DEBUG_MAPPING			
			printf("Appending preposition.");
#endif
			strcat(VerbBuffer," ");	
			strcat(VerbBuffer,words[1]);
#ifdef DEBUG_MAPPING
			printf("Verb is %s\n",VerbBuffer);
#endif
			/* shift words down */
			for (i=1; i < NumWords; i++)
			{
				words[i] = words[i+1];
			}
			NumWords--;
		}
	}
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
	unsigned char i=0;
	char *tablePtr = (char*)ObjectWordTable;
	
	for (; i < ObjectWordTableSize; i++)
	{
		if (scores[i] != INVALID)
		{
			BYTE id = tablePtr[0];
			
			if (tablePtr[1] == wordId ||
				tablePtr[2] == wordId ||
				tablePtr[3] == wordId) 
			{
			
				scores[id]++;				
#ifdef DEBUG_MAPPING
				printf("Object %d,%d is a match\n", i, ObjectWordTable[i].id);
#endif
				/*if it's visible, add another point!*/
				if (is_visible_to(ObjectTable[PLAYER_ID].attrs[HOLDER_ID],(BYTE)id))
				//if (is_visible_to(PLAYER_ID,(BYTE)id))
				//if (is_visible((BYTE)id))
				{
#ifdef DEBUG_MAPPING
				printf("Object %d is visible\n", i);
#endif
					scores[id]++;
				}	
			}
	 
			tablePtr += 4;  /* id plus up to three words */
		}			
	}
}

/* sets the index of PrepIndex if found */ 
BOOL found_prep()
{
//	printstr("Looking for prep\n");
	int i=2;
	PrepIndex=0;
	
	for (i=2; i < NumWords; i++)
	{
		BYTE id = is_prep(words[i]);
		if (id != INVALID)
		{
//			printstr("found prep\n");
			PrepIndex = (BYTE)i;
			PrepId = id;
			return TRUE;
		}
	}
 
	return FALSE;
}


/*
* gets the max score 
* sets maxScoreObj
* sets maxScoreCount
*/
void get_max_score()
{
	BYTE i=0;
	BYTE max = 0;
	MaxScore = 0;
	MaxScoreCount = 0; /*how many matches for max*/
	MaxScoreObj = 0;
	
	for (; i < ObjectWordTableSize; i++)
	{
		if (scores[i] == INVALID)
			scores[i]=0;
	
#ifdef DEBUG_MAPPING
		if (scores[i] != 0)	
			printf("Object %d is possible match %d\n", i,scores[i]);
#endif

		if (scores[i] > MaxScore)
		{ /* new best match */
			MaxScore = (BYTE)scores[i];
#ifdef DEBUG_MAPPING
			printf("New max score is %d\n", MaxScore);
#endif			
			MaxScoreObj = ObjectWordTable[i].id;
		}
				
	}

#ifdef DEBUG_MAPPING	
	printf("%d is max score\n", MaxScore);
	printf("object %d is best match\n", MaxScoreObj);
#endif
	//count the number with the max score
	for (i=0; i < ObjectWordTableSize; i++)
	{
		if (scores[i] == MaxScore) 
			MaxScoreCount++;
	}

#ifdef DEBUG_MAPPING		
	printf("%d is max score object\n", MaxScoreObj);
	printf("Max score count = %d.\n", MaxScoreCount);
#endif
	
}


/*returns true if objectId is visible to the player*/
BOOL is_visible(BYTE objectId)
{
	BYTE parent;
	Object *objPtr = &ObjectTable[objectId];
	
	
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
	}
	
	return FALSE;	
}

BOOL can_see()
{
	BYTE i=2;
	BYTE roomId = INVALID;
#ifdef DEBUG_MAPPING
	printf("Player is in room %d", ObjectTable[PLAYER_ID].attrs[HOLDER_ID]);
#endif
	
	if (emitting_light(ObjectTable[PLAYER_ID].attrs[HOLDER_ID]))
	{
#ifdef DEBUG_MAPPING
	printf("Player's room is emitting light");
#endif
		return TRUE;
	}
	
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
		ObjectTable[DobjId].attrs[HOLDER_ID] = PLAYER_ID; 
		ObjectTable[DobjId].attrs[INITIAL_DESC_ID] = INVALID;  //clear initial desc
		printstr("Taken.\n");
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
//	printstr("Done.\n");
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

	if (is_open_container(objectId)==TRUE)
	{
		if ( has_visible_children(objectId) == TRUE)
		{
			memset(name,0,80);
			get_obj_name(objectId,name);
			sprintf(Buffer,"The %s contains:\n", name);
			printstr(Buffer);
			print_obj_contents(objectId);
		}
/*		else
		{
			sprintf(Buffer,"You find nothing.\n");
			printstr(Buffer);
		}*/
	}
	else if (is_supporter(objectId)==TRUE)
	{
		if (has_visible_children(objectId) == TRUE)
		{
			memset(name,0,80);
			get_obj_name(objectId,name);
			sprintf(Buffer,"On the %s is:\n", name);
			printstr(Buffer);
			print_obj_contents(objectId);
		}
		
		/*
		else
		{
			memset(name,0,80);
			get_obj_name(objectId,name);
			sprintf(Buffer,"There is nothing on the %s.\n", name);
			printstr(Buffer);
		}
		*/
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
char buf[40];
	ObjectTable = (Object*)ObjectData;
	ObjectWordTable = (ObjectWordEntry*)ObjectWordTableData;
	VerbCheckTable = (VerbCheck*)VerbCheckTableData;
//	fix_endianess();
	init_verb_table();
	init_verb_checks();
	init_before_functions();
	init_instead_functions();
	init_after_functions();

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
	if (roomId == objectId)
		return false;
	
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


BOOL emitting_light(unsigned char objId)
{
	return get_object_prop(objId,LIT);
}


/*prints the entryNumth string from the table*/
void print_table_entry(BYTE entryNum, const char *table[])
{
	char *str = (char*)table[entryNum];
	printstr(str);
	 
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
			
			if (get_object_prop(i,SCENERY)==0)
			{
				if (has_visible_children(i))
				{
					list_any_contents(i);
				}
			}
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
			return (BYTE)i;
		}
	}
	return INVALID;
}
/*
BYTE get_prep_id(char *wordPtr)
{
	BYTE i=0;
	for (; i < PrepTableSize; i++) 
	{
		if (stricmp(wordPtr, (char*)PrepTable[i])==0)
			return i;
	}
	return INVALID;
}
*/
/*assume checks have been passed*/
void execute()
{
	Handled = FALSE;
	/*before*/
//	printstr("executing before...\n");
	if (try_sentence(BeforeTable,BeforeTableSize, FALSE)==FALSE)
	{
		try_sentence(BeforeTable,BeforeTableSize, TRUE);
	}

	/*instead or default */
	//printstr("trying instead...\n");
	if (try_sentence(InsteadTable,InsteadTableSize, FALSE) == FALSE)
	{//exact matches
		if (try_sentence(InsteadTable,InsteadTableSize, TRUE)==FALSE)
		{//wildcards
#ifdef DEBUG
			printstr("trying default...\n");			
#endif
			try_default_sentence();				//default handling
		}		
	}

	/*after*/
	//printstr("trying after...\n");
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
#ifdef DEBUG
	printstr("running events\n");
#endif
		run_events();
#ifdef DEBUG
	printstr("events run\n");
#endif
		
		if (can_see())
			turnsWithoutLight=0;
		else
			turnsWithoutLight++;
	}
	
//	draw_status_bar();
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



BOOL try_sentence(Sentence *table, int tableSize,  BOOL matchWildcards)
{
//	printf("sentence:%d,%d,%d,%d\n",VerbId,DobjId,PrepId,IobjId);
	int i=0;
	BOOL result = FALSE;
	for (i=0; i < tableSize; i++)
	{

//	printf("table:%d,%d,%d,%d\n",table[i].verb,table[i].dobj,table[i].prep,table[i].iobj);
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
//					printstr("Executing a custom event.\n");
//					printf("addr %x\n", (*table[i].handler) );

//_asm
//{
//	mov stackp,sp ;
//}
//					printf("before: sp=%u\n",stackp);
					(*table[i].handler)();
//_asm
//{
//	mov stackp,sp ;
//}
//					printf("after: sp=%u\n",stackp);

//					printstr("Done.\n");
					Handled = TRUE;
					result=TRUE;
					break;
				}
		}
	}
	
	return result;
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

void try_default_sentence()
{
	
	BOOL prevHandled = Handled;
	BOOL defaultHandled = TRUE;
	//sprintf(Buffer,"looking for a default match. verb id=%d\n", VerbId);
	//printstr(Buffer);
	if (VerbId == GET_VERB_ID)
		get_sub();
	else if (VerbId == LOOK_VERB_ID)
		look_sub();
	else if (VerbId == DROP_VERB_ID)
		drop_sub();
	else if (VerbId == PUT_VERB_ID)
	{	
		//printstr("default_put\n");
		put_sub();	
	}
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
		quit_sub();
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

/*
 * For this function to be called
 * check move must have passed
 */
void move_sub()
{
//	printstr("moving");
	BYTE tgtRoom=INVALID;
	BYTE dir=0;
	BYTE room = ObjectTable[PLAYER_ID].attrs[HOLDER_ID];
	dir = verb_to_dir(VerbId);

#ifdef DEBUG_MAPPING	
	printf("current room is %d\n", room);
	printf("dir =  %d\n", dir);
#endif
	tgtRoom = ObjectTable[room].attrs[dir];

#ifdef DEBUG_MAPPING	
	printf("Target room = %d\n", tgtRoom);
#endif
	
	if (is_door(tgtRoom) == TRUE)
	{
#ifdef DEBUG_MAPPING	
	printf("Target room %d is a door\n", tgtRoom);
#endif
		tgtRoom = ObjectTable[tgtRoom].attrs[dir];
	}
	
#ifdef DEBUG_MAPPING
		printf("Player moved to room %d\n", tgtRoom);
#endif
		ObjectTable[PLAYER_ID].attrs[HOLDER_ID]=tgtRoom;
		look_sub();		
	
}

/*
 *Check_move will have been called prior to this function
 *being called.
 */

void enter_sub()
{
	ObjectTable[PLAYER_ID].attrs[HOLDER_ID]=DobjId;
#ifdef DEBUG_MAPPING
	printf("Player moved to room %d\n", DobjId);
#endif
	look_sub();		
}


void enter_object(BYTE tgtRoom, BYTE dir)
{
#ifdef DEBUG_MAPPING
	printf("enter target room = %d\n",tgtRoom);
#endif
	
//		else
//		{
//			printstr("%d is not a door\n", tgtRoom);
//		}
		/*
		//if the object has an 'enter' treat the object l
		if (ObjectTable[tgtRoom].attrs[ENTER] > 127)
		{
#ifdef DEBUG_MAPPING
			printf("entering inside %d\n", tgtRoom);
#endif
			tgtRoom = ObjectTable[tgtRoom].attrs[ENTER];
		}
		*/
		
		ObjectTable[PLAYER_ID].attrs[HOLDER_ID]=tgtRoom;
#ifdef DEBUG_MAPPING
		printf("Player moved to room %d\n", tgtRoom);
#endif
		look_sub();		
	
	
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

void dump_matches()
{
	BYTE i=0;
	char buf[80];
	
	for (; i < NumObjects; i++)
	{
		if (scores[i]==MaxScore)
		{
			get_obj_name(i,buf);
	//		printstr("match:%s\n",buf);
		}
	}
}


BYTE get_inv_weight(BYTE obj)
{
	BYTE i=2;
	BYTE sum=0;
	for (; i < NumObjects; i++)
	{
		if (is_ancestor(obj,i))
		{
			sum += ObjectTable[i].attrs[MASS];
		}
	}		
	return sum;
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
		if (stricmp(VerbBuffer,VerbTable[i].wrd)==0)
		{
			return VerbTable[i].id;
		}
	}
	return INVALID;
}


/* returns true if the word at startPtr is in the article list */
BOOL is_prep(char *wrd)
{
	short i=0;
	for (; i < PrepTableSize; i++)
	{
		if (stricmp(wrd,PrepTable[i])==0)
		{
			return (BYTE)i;
		}
	}
	
	return INVALID;
}


BOOL parse_and_map()
{
	short i=0;
	BYTE wordId;
	DobjId = INVALID;
	PrepId = INVALID;
	IobjId = INVALID;
	clear_scores();
 
	tokenize_input();
	
	if (NumWords == 0)
	{
		printstr("Pardon?\n");
		return FALSE;
	}
	
	get_verb(); /*get 1st word and prep if supplied */
	
	VerbId = get_verb_id();

#ifdef DEBUG_MAPPING	
	printf("Verb Id=%d\n",VerbId);
#endif
	
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
		BOOL prep = found_prep(); //sets prepIndex and id
		if (prep == TRUE)
		{/* score do and io */
			
			//PrepId  = get_prep_id(words[PrepIndex]);
			
			for (i = 1; i < PrepIndex; i++)
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
				if (max_score_matches(MaxScore) > 1)
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
				printstr("I don't know which one you mean.\n");
				//dump_matches();
				return FALSE;
			}
			
			DobjId = MaxScoreObj;
//			printstr("dobj is %d\n",MaxScoreObj);
			//sprintf(UCaseBuffer,"Noun 1: %d\n",DobjId);
			//printstr(UCaseBuffer);
			/*now score io*/
#ifdef DEBUG_MAPPING
			printf("Scoring noun2\n");
#endif
			clear_scores();
			for (i = PrepIndex+1; i < NumWords; i++)
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
			if (max_score_matches(MaxScore) > 1)
			{
				if (any_visible())
				{
					printstr("I don't know which one you mean.\n");
				}
				else
				{
					printstr("You don't see that.\n");
				}
				return FALSE;
			}			
			IobjId = MaxScoreObj;
			//sprintf(UCaseBuffer,"Noun 2: %d\n",IobjId);
			//printstr(UCaseBuffer);
			//printstr("iobj is %d\n",MaxScoreObj);

		}
		else
		{ /* just score dobj */
			for (i = 1; i < NumWords; i++)
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
	
//	printf("Sentence: %d,%d,%d,%d\n", VerbId, DobjId, PrepId, IobjId);
	return TRUE;
}



void dump_dict()
{/*
	for (int i=0; i < DictionarySize; i++)
	{
		printstr("%s|\n",Dictionary[i]);
	}
	*/
	
}


//returns whether or not any of the mapped objects were visible
BOOL any_visible()
{
	BYTE i =0;
	for (; i < NumObjects; i++)
	{
		if (scores[i] > 0)
		{
			if (is_visible(i))
			{
				return TRUE;
			}
		}			
	}
	return FALSE;
}

/* returns true if the word at startPtr is in the article list */
BOOL is_article(char *wordPtr)
{
	short i=0;
	for (; i < 3; i++)
	{
		if (stricmp(wordPtr, (char*)articles[i]) == 0)
		{
			return TRUE;
		}
	}
	return FALSE;
}

/*returns number of objects matching the max score*/
int max_score_matches(int max)
{
	int i=0;
	int count=0;
	for (i=0; i < NumObjects; i++)
	{
		if (scores[i] == max)
			count++;
	}
//	printf("After parsing, there are %d matches.\n", count);
	return count;
}

void print_obj_name(unsigned short id)
{
	get_obj_name(id, Buffer);
	printstr(Buffer);
}

/*propNum is 1-15 */


void dump_owt()
{
    int i=0;
	printf("duping OWT\n");
	for(i=0; i < ObjectWordTableSize;i++)
	{
		printf("%d,%d,%d,%d\n",ObjectWordTable[i].id,
	ObjectWordTable[i].word1,
	ObjectWordTable[i].word2,
	ObjectWordTable[i].word3);

	}	
}

