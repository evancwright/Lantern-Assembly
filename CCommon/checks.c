

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

BOOL check_see_iobj()
{
	BYTE playerRoom = ObjectTable[PLAYER_ID].attrs[HOLDER_ID];
	if (is_visible_to(playerRoom, IobjId)==0)
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

BOOL check_weight()
{
	BYTE w = ObjectTable[DobjId].attrs[MASS];
	
	if (get_inv_weight((BYTE)PLAYER_ID) + w > MAX_INV_WEIGHT)
	{
		printstr("Your load is too heavy.\n");
		return FALSE;
	}
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


BOOL check_dobj_visible()
{
	if (!is_visible_to(PLAYER_ID,DobjId))		
	{
		printstr("You don't see that here.\n");
		return FALSE;
	}
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
	if (PrepId == INVALID)
	{
		printstr("Missing preposition.\n");
		return FALSE;
	}
	return TRUE;
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


BOOL check_light()
{
	if(can_see() == 0)
	{
		printstr("It's too dark.\n");
		return FALSE;
	}	
	return TRUE;
}


BOOL check_put()
{
	if (PrepId == 0) //in
	{
			short flags = ObjectTable[DobjId].flags;
			flags = flags & CONTAINER_MASK;
			if (flags == 0)
			{
				printstr("You can't put things in that.\n");
				return FALSE;
			}
			
			if (!is_open(IobjId))
			{
				printstr("It's closed.\n");
				return FALSE;
			}
	}
	else if (PrepId == 6)//on
	{
			short flags = ObjectTable[DobjId].flags;
			flags = flags & SUPPORTER_MASK;
			if (flags == 0)
			{
				printstr("You find no suitable surface.\n");
				return FALSE;
			}
	}
	return TRUE;
}

