

/*  write a saved game file 
    Right now it just tries to create the file, then close it
*/
DECBRecordFile file;
BYTE driveNum=0;
BYTE slotNum=0;
BYTE err = DECB_OK;
word dataLen=0;
const char *fileName1="SAVE1VAR.DAT"; 
const char *fileName2="SAVE1TAB.DAT";

BOOL get_file_name()
{
		printstr("Unregistering drives\n");
	decb_unregisterAllDrives();
	
	printstr("Enter a drive:");
	readlinenb();
	driveNum = Buffer[0] - 112; //atoi
 
	printstr("Enter save slot # (0-9):");
	readlinenb();
	slotNum = Buffer[0] - 112; //atoi
 
	fileName1[4] = slotNum;
	fileName2[4] = slotNum;
	
	sprintf(Buffer, "Using drive: %d\n",driveNum);
	printstr(Buffer);
	printstr("Using filename SAVEGAME.DAT\n");
	sprintf(Buffer,"%s",fileName1);  //hard coded for now
	
	/* figure out size of data to write */
	dataLen=NumUserVars + BUILT_IN_VARS;
	
	sprintf(UCaseBuffer,"var data=%u\n",dataLen);
	printstr(UCaseBuffer);
	
	err = decb_init(drives,numDrives);
	if(err != DECB_OK)
	{
		sprintf(UCaseBuffer,"DECB init failure. err %u\n",err); 
		printstr(UCaseBuffer);		
		return FALSE;	
	}
	
	//must be called after decb_init
	decb_setDskConAddresses(dskcon_processSector, (DECBDskConVariables *) &DCOPC); 

    //for (driveNo = 0; driveNo < numDrives++;driveNo)
	err = decb_registerDrive((byte) driveNum);
	if (err != DECB_OK)
	{
		sprintf(Buffer,"FAILED TO REGISTER DRIVE %u\n", driveNum);
		printstr(Buffer);
		
		sprintf(Buffer,"Error code %u\n", err);
		printstr(Buffer);
		
		return FALSE;
	}

	return TRUE;
}
 
void save_sub()
{	
	
	if (!get_file_name())
	{
		return;
	}
	
	/* delete existing file */
	decb_kill(driveNum, fileName1);	
	
	printstr("Drives registered\n");
	sprintf(UCaseBuffer,"Creating file %s\n", Buffer);
	printstr(UCaseBuffer);	
	 
	err = decb_createRecordFile(&file, driveNum, fileName1, 0, dataLen);
 
	if(err != DECB_OK)
	{
		sprintf(UCaseBuffer,"Unable to create file. err %d\n",err); 
		printstr(UCaseBuffer);		
		return;	
	}
	
	printstr("Writing variables\n");	
	err = decb_writeRecord(&file, &score, 0); /* write record 0 */
	
	if (err  != DECB_OK )
	{
		sprintf(UCaseBuffer,"Unable to write record. err %d\n",err); 
		printstr(UCaseBuffer);		
		return;	
	}
	
	printstr("Variables saved.\n");
	
	err == decb_closeRecordFile(&file);
	
	if ( err != DECB_OK)
	{
		sprintf(UCaseBuffer,"Unable to close record. err %d\n",err); 
		printstr(UCaseBuffer);		
		return;	
	} 
	 
	printstr("File closed.\nSaving object table\n");
	
	/* now save the object table */
	decb_kill(driveNum, fileName2);	
	
	err = decb_createRecordFile(&file, driveNum, fileName2, 0, OBJ_ENTRY_SIZE);
 
	if(err != DECB_OK)
	{
		sprintf(UCaseBuffer,"Unable to create file. err %d\n",err); 
		printstr(UCaseBuffer);		
		return;	
	}

	/* write each record */
	for (int i=0; i < NumObjects; i++)
	{
		err = decb_writeRecord(&file, (byte*)&ObjectTable[i], i);
	
		if (err  != DECB_OK )
		{
			sprintf(UCaseBuffer,"Unable to write record. err %d\n",err); 
			printstr(UCaseBuffer);		
			break;	
		}
	}
	
	err == decb_closeRecordFile(&file);
	
	if ( err != DECB_OK)
	{
		sprintf(UCaseBuffer,"Unable to close record. err %d\n",err); 
		printstr(UCaseBuffer);		
		return;	
	}
	
	printstr("File closed.\n");
	
	decb_shutdown();

}


void restore_sub()
{
 	if (!get_file_name())
		return;

	err = decb_openRecordFile(&file, driveNum, fileName1, 0, dataLen);
 
	if(err != DECB_OK)
	{
		sprintf(UCaseBuffer,"Unable to open file. err %d\n",err); 
		printstr(UCaseBuffer);		
		return;	
	}
	
	printstr("reading variables\n");	
	err = decb_readRecord(&file, &score, 0);  /* read record 0 */
	
	if (err  != DECB_OK )
	{
		sprintf(UCaseBuffer,"Unable to read record. err %d\n",err); 
		printstr(UCaseBuffer);		
		return;	
	}
	
	printstr("Variables loaded.\n");
	
	err == decb_closeRecordFile(&file);
	
	if ( err != DECB_OK)
	{
		sprintf(UCaseBuffer,"Unable to close record. err %d\n",err); 
		printstr(UCaseBuffer);		
		return;	
	} 
	 
	printstr("File closed.\n");
	
	/* load load the object table */
	
	printstr("Variables loaded.\nloading obj table\n");
	
	/* open the object table file */
	err = decb_openRecordFile(&file, driveNum, fileName2, 0, OBJ_ENTRY_SIZE);
 
	if(err != DECB_OK)
	{
		sprintf(UCaseBuffer,"Unable to open file. err %d\n",err); 
		printstr(UCaseBuffer);		
		return;	
	}
	
	/* read each record */
	for (int i=0; i < NumObjects; i++)
	{
		err = decb_readRecord(&file, (byte*)&ObjectTable[i], i);
	
		if (err  != DECB_OK )
		{
			sprintf(UCaseBuffer,"Unable to read record  %d. err %d\n",i,err); 
			printstr(UCaseBuffer);		
			break;	
		}
	}

	
	err == decb_closeRecordFile(&file);
	
	if ( err != DECB_OK)
	{
		sprintf(UCaseBuffer,"Unable to close record. err %d\n",err); 
		printstr(UCaseBuffer);		
		return;	
	} 
	 
	printstr("File closed.\n");

	decb_shutdown();
	
	look_sub();
	
}
