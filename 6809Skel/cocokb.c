/*coco keyboard / printing routines*/
void printstr(const char *str)
{
	char *ptr = (char*)str;
	
	while (*ptr != 0)
	{
		int len = NextWordLen(ptr);
		if (len < CharsLeft())
		{
			ptr = printwrd(ptr);
		}	
		else
		{
			carriage_return();
			ptr = SkipWhiteSpace(ptr);			
			ptr = printwrd(ptr);
		}
	}
}

/*prints the next word including any leading white space*/ 
char* printwrd(char *str)
{
	int pastWord = FALSE;
	
	while (*str != 0)
	{
		if (*str == NEWLINE)
		{
			carriage_return();	
		}
		else if (  (*str == ' ' || *str == SPACE) && pastWord == TRUE )
		{
			break;
		}
		else
		{
			char c = *str;
			
			if (c != ' ' && c != SPACE)
				pastWord = TRUE; /* hit a letter */
			
			
			if (c >= 0x20 && c < 0x40)
				c += 0x40;
		
			*cursor = c;
			cursor++;			
		}
		
		str++;

//		break;
	} 
	return str;
}

void readlinenb()
{
	memset(Line,0,32);
	LineIndex = 0;
	char *startPtr = cursor;
	BYTE done = FALSE;
	int c = 0;
	
	char *start = cursor;
	while (!done)
	{
		*cursor = cursors[c];
		ticks++;
		if (ticks == 25)
		{
			c++;
			if (c==2) c = 0;
			ticks = 0;
		}
		
		if (c == NUM_CURSORS) c = 0;
		 
		for (BYTE i=0; i < 8; i++) //there is a problem with the loop!!!!! 64 works 128 hangs
		{
			BYTE col = PollKbCol( colBits[i] ); //invert bits
			col = 255 - col;

			
			int vbit=0;
			for (BYTE j = 1; j <= 64 ; j*= 2)
			{		
 
				if (col == j)
				{//key is down
			
					if (keyStatus[vbit][i] == FALSE)
					{//it wasn't down before
						char ch = matrix[vbit][i];
						
						if (ch == 0) continue;
						
						//handle enter / backspace here
						if (ch == DELETE)
						{
							*cursor = SPACE;
							Line[LineIndex]=0;
							if (cursor > start)
							{
								cursor--;
								*cursor = SPACE;
								
								LineIndex--;
								Line[LineIndex]=0;
								
							}
						}
						else if (ch == ENTER)
						{
							*cursor = SPACE;
							Line[LineIndex]= 0;
							carriage_return();		
							done = TRUE;
						}
						else if (ch != SHIFT)
						{//regular key
							if (shift_down())
							{
								*cursor = get_shifted_key(ch);
								Line[LineIndex]= ch;
							}
							else
							{ 
								*cursor = ch;
								Line[LineIndex]= ch;
							}
							
							LineIndex++;
							cursor++;
						}
					}
					
					keyStatus[vbit][i]=TRUE;
					break;
	
				}
				else
				{
					keyStatus[vbit][i]=FALSE;
				}
				vbit++;
			}
		}
	}
	printstr("OK\n");
}

asm BYTE PollKbCol(byte col)
{
    asm
    {
        ldb     3,s     // U not pushed because of 'asm' function modifier
        stb     $FF02
        ldb     $FF00
    }	
}

void carriage_return()
{
	cursor =  (char*)((( (short)cursor - 0x0400) / scrWidth ) * scrWidth);
	cursor += 0x0400;
	if ((short)cursor >= (short)lastLine)
	{
		scroll();
		cursor = (char*)lastLine;
	}
	else
	{
		cursor += scrWidth;
	}
		
}

void scroll()
{
	
	for (int i=0; i < scrHeight-1; i++)
	{
		memcpy( (char*)(0x400 + i*scrWidth), (char*)(0x0400 + (i+1)*scrWidth), scrWidth); //move a line 
	}
	
	//now clear the bottom line
	memset((char*)(0x400 + (scrHeight-1)*scrWidth), SPACE, scrWidth );
	
	//cursor must now be on the last line
	cursor = (char*)lastLine;
		
}

void cls()
{
	memset(0x400, SPACE, scrHeight * scrWidth);
	cursor = 0x0400;
}

BYTE get_shifted_key(BYTE ch)
{
	if (ch == 0x71) return EXCL;  // 0 
	if (ch == 0x72) return QUOT;
	if (ch == 0x73) return LBS;
	if (ch == 0x74) return DOLLAR;
	if (ch == 0x75) return PCT;
	if (ch == 0x76) return AMP;
	if (ch == 0x77) return TICK;
	if (ch == 0x78) return LPAREN;
	if (ch == 0x79) return RPAREN;
	if (ch == COMMA) return 0x76; // <  
	if (ch == PERIOD) return 0x7C; // < 
	if (ch == FWD_SLASH) return 0x7F; // > 
	if (ch == SEMICOLON) return 0x6B; // +
	if (ch == MINUS) return 0x7D; // =
	if (ch == COLON) return 0x6A; // *
	return ch;
}

int NextWordLen(char *word)
{
	char *ptr = word;
	
	/* skip any white space */
	if (*ptr == ' ')
	{
		while (*ptr == ' ' && *ptr != 0)
			ptr++;
	}
 
	/* now move to end of word */
	while (*ptr != ' ' && *ptr != 0)
		*ptr++;
	
	return (ptr - word);
}

int CharsLeft()
{
	return scrWidth - (((short)cursor-0x0400)%scrWidth);
}

BYTE shift_down()
{
		return keyStatus[6][7] == TRUE;
}

char *SkipWhiteSpace(char *ptr)
{
	while (*ptr == ' ')	
		ptr++;
	return ptr;
}