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
	BOOL pastWord = FALSE;
	
	while (*str != 0)
	{
		
		unsigned char c = *str;
		
		if (c == 0x20) //convert inverted spaces to spaces
			c = 0x60;
		
		if (c == RETURN || c == LF)
		{
			carriage_return();	
			str++;	//skip the char
		}
		else if (  c == 0x60  && pastWord )
		{/* the space after a word. Stop here*/
			break;
		}
		else
		{ /*print chars and leading white space*/
			
			if (c != 0x020 && c != 0x60) //spaces
			{
				pastWord = TRUE; /* hit a letter */
			}		
				
			c = fix_case(c);	//convert 97+ to uppercase if no lower case
			
			//invert punctuation
			if (lowerCase == FALSE)
			{
				if (c >= 0x20 && c < 0x40) //32 to 64
					c += 0x40; //add 96
			}
			 
			*cursor = c;
			cursor++;			
			str++;	
		}
		 
//		break;
	} 
	return str;
}

void readlinenb()
{
	memset(Line,0,INBUF_SIZE);
	LineIndex = 0;
	char *startPtr = cursor;
	BYTE done = FALSE;
	int c = 0;
	
	clear_buffers();
	
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
						unsigned char ch = matrix[vbit][i];
						
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
						else if (ch == RETURN || ch == LF)
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
								ch = get_shifted_key(ch);
							}
							
							*cursor = to_lchar(ch);
							Line[LineIndex]= ch;
								
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
	
	fix_spaces();
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
	
	for (int i=1; i < scrHeight-1; i++) //start at 1 to not clobber the status bar
	{
		memcpy( (char*)(0x400 + i*scrWidth), (char*)(0x0400 + (i+1)*scrWidth), scrWidth); //move a line 
	}
	
	//now clear the bottom line
	memset((char*)(0x400 + (scrHeight-1)*scrWidth), SPACE, scrWidth );
	
	//cursor must now be on the last line
	cursor = (char*)lastLine;
		
}

/* full screen cls */
void clsfs()
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

/*returns the length of the next word including any leading white space*/
int NextWordLen(char *wrd)
{
	char *ptr = wrd;
	
	/* skip any white space */
	if (*ptr == 0x20) //starts with space
	{
		while ( *ptr == 0x20  && *ptr != 0)
			ptr++;
	}
 
	/* now move to end of word */
	while (*ptr != 0x20 && *ptr != 0)
		*ptr++;
	
	return (ptr - wrd);
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
	while (*ptr == 0x20 || *ptr == 0x60)	
		ptr++;
	return ptr;
}

/*converts chars to uppercase for comparison*/
char to_uchar(char ch)
{
	//convert lower to upper
	if (ch >= 97 && ch <= 122)
	{
		return ch - 32;
	}
	return ch;
}

/*converts chars to lowercase for output with CoCo VGA installed*/
char to_lchar(char ch)
{
	//convert lower to upper
	if (lowerCase)
	{
		if (ch >= 64 && ch <= 90)
		{
			return ch - 64;
		}
	}
 
	return ch;
}

/* lower to upper if no CoCo VGA */
char fix_case(char ch)
{
	if (lowerCase)
	{
		if (ch >= 97 && ch <= 122)
		{
			return ch - 96;
		}		
	}
	else
	{
		//convert lower to upper
		if (ch >= 97 && ch <= 122)
		{
			return ch - 32;
		}
	}
	
	return ch;
}

/* converts spaces from 96 to 32 */
void fix_spaces()
{
	char *str= Line;
	
	while (*str != 0)
	{
		if (*str == 96) 
			*str = 32;
		str++;
	}
}