/*  loader.c

    By Pierre Sarrazin <http://sarrazip.com/>
    This file is in the public domain.
*/

#include "coco.h"
#include "decbfile.h"
#include "binfile.h"
#include "dskcon-standalone.h"

#include "defs.h"


#define BIG_APP_FILENAME "GAME.DAT"


word timer;  // 60ths of a second, incremented by IRQ
 
byte *scrnPos;  // current address to write to in the 32x16 screen


interrupt asm void irqISR()
{
    asm
    {
_dskcon_irqService IMPORT
        ldb     $FF03
        bpl     @done           // do nothing if 63.5 us interrupt
        ldb     $FF02           // 60 Hz interrupt. Reset PIA0, port B interrupt flag.
        lbsr    _dskcon_irqService
;
        ldd     :timer
        addd    #1
        std     :timer
@done
    }
}


// Installs irqISR() as the IRQ service routine and dskcon_nmiService() as the NMI routine.
// Enters all RAM mode.
// Checks that the CoCo has 64K of RAM and if not, returns.
// Moves the stack pointer near the end of the 64K.
//
// Calls (*mainProgram)() with the address of the new program start.
// That function must never return.
//
// CAUTION: Do not call functions like printf() and putchar()
// because they rely on Basic's character output routine.
// Either redirect their output (see the CMOC manual) or
// code alternative printing functions.
//
void moveProgramAndRun(void (*mainProgram)(void *newProgramStart))
{
    // Initialize the primitive 32x16 screen printing routine(s),
    // then redirect printf() et al. to it.
    //
	
    scrnPos = 0x0400;
    ConsoleOutHook origHook = setConsoleOutHook(consoleOutHook);

    // WIDTH 32:
    //
    if (isCoCo3)
        width(32);
    else
        cls(255);

    disableInterrupts();

    // Enter all RAM mode (already the case on a CoCo 3).
    //
    if (!isCoCo3)
        asm("CLR", "$FFDF");

    // Check that the CoCo has 64K.
    {
        byte *upperMem = (byte *) RAM_END - 1;
        //printf("  ADDRESS USED: %p\n", upperMem);
        byte origByte = *upperMem;
        *upperMem = origByte + 111;  // add some random number
        byte newByte = *upperMem;
        byte have64K = (newByte != origByte);
        if (have64K)
            *upperMem = origByte;
        else
        {
            setConsoleOutHook(origHook);
            if (!isCoCo3)
                asm("CLR", "$FFDE");  // go back to ROM mode
            enableInterrupts();
            return;
        }
    }

    #ifdef ERASE_ORIGINAL
    // Useful to prove that Basic is not used from this point on.
    memset((void *) 0x8000, 0x39, (void *) (RAM_END - 0x8000));
    #endif

    // Compute the new program start and end.
    //
    char *newProgramEnd = (char *) STACK_TOP;
    char *origProgramEnd;
    asm
    {
        leax    program_end,pcr
        stx     :origProgramEnd
    }

    // Adjust the main program address and the program start to the move.
    //
    unsigned numBytesForward = newProgramEnd - origProgramEnd;
    mainProgram += numBytesForward;

    // Redirect IRQ to the new address of irqISR().
    //
    setISR(IRQ_VECTOR, irqISR + numBytesForward);

    dskcon_init(dskcon_nmiService + numBytesForward);

    char *origProgramStart;

    // Move the stack to the end of the main 64K.
    // Move the program and the global variables to just before the new
    // stack space (newProgramEnd).
    // Assumes that the writable global variables are between program_start
    // and program_end.
    //
    asm
    {
        lds     #RAM_END                // new bottom of stack

        leax    program_start,pcr       // original start is end address of copy loop
        stx     :origProgramStart
        leax    program_end,pcr         // copy what is below this address
        ldy     :newProgramEnd          // to below this address in high RAM
@initNoBasic_copyProg:
        ldd     ,--x                    // copy from end to start (may copy 1 extra byte)
        std     ,--y
        cmpx    :origProgramStart                      // reached program_start?
        bhi     @initNoBasic_copyProg   // loop if not
    }

    // Enable interrupts now that the IRQ and NMI vectors have been set up.
    // The NMI will be used while loading the big app from the disk.
    //
    enableInterrupts();

    (*mainProgram)(origProgramStart + numBytesForward);
}


// CAUTION: This function does NOT check for the end of the screen.
//
asm void consoleOutHook()
{
    asm
    {
        pshs    x,b                     // must be preserved
        ldx     :scrnPos
        cmpa    #13
        beq     @newline
;
        bsr     @convertASCIITo6847Code
        sta     ,x+                     // no check for end of screen
        bra     @done
;
@convertASCIITo6847Code
        cmpa    #64
        blo     @typo                   // typographical char
        cmpa    #96
        blo     @conversionDone         // upper-case letter
        cmpa    #128
        bhs     @conversionDone         // graphical char
        suba    #96                     // lower-case letter
@conversionDone
        rts
@typo
        adda    #64
        rts
;
@newline
        tfr     x,d
        andb    #$E0                    // carriage return
        addd    #32                     // line feed
        tfr     d,x
@done
        stx     :scrnPos
        puls    b,x
    }
}


#if 0
// Carriage return in 32x16 screen.
//
void cr()
{
    scrnPos &= ~31;
}
#endif


typedef struct
{
    struct DECBFile file;
    word sectorIndex;
    word numSectorsInFile;
    void *programEnd;
} SectorReader;


void SectorReader_init(SectorReader *reader)
{
    reader->sectorIndex = 0;
    reader->numSectorsInFile = 0;
    reader->programEnd = 0;
}


byte loadSector(byte sectorBuffer[256], void *userData)
{
    SectorReader *reader = (SectorReader *) userData;

    byte *pctScrnPos = scrnPos;
    printf("%3u%%", (reader->sectorIndex + 1) * 100 / reader->numSectorsInFile);
    scrnPos = pctScrnPos;  // move cursor back to percentage position

    byte err = decb_readSector(&reader->file, sectorBuffer, reader->sectorIndex);
    ++reader->sectorIndex;
    return err == DECB_OK;
}


void processHeader(bin_Header *header, void *userData)
{
    if (header->code == 0xFF)  // if last header
        return;  // don't care

    SectorReader *reader = (SectorReader *) userData;
    void *endAddr = (void *) (header->n1 + header->n0);  // block address + length
    if (endAddr > reader->programEnd)
        reader->programEnd = endAddr;
}


// If this function returns, the load has failed.
//
void loadBigAppFile()
{
    SectorReader reader;
    SectorReader_init(&reader);

    // Open the app file, which contains the actual "big" program.
    //
    byte err = decb_openSectorFile(&reader.file, 0, BIG_APP_FILENAME);
    if (err != DECB_OK)
    {
        printf("FAILED TO OPEN %s\n", BIG_APP_FILENAME);
        return;
    }

    void *endOfFreeMem = (void *) RAM_END - STACK_SPACE - GRAPHICS_SPACE;

    // Get length of file to load.
    //
    byte lastFileGranule;
    word numSectors;
    (void) decb_getNumGranulesInOpenFile(&reader.file, &lastFileGranule, &numSectors);
    //printf("LAST GRAN: %u; %u SECTORS\n", lastFileGranule, numSectors);
    printf("LOADING %u KB: ", (numSectors + 3) / 4);

    reader.numSectorsInFile = numSectors;

    byte sectorBuffer[256];
    void *entryPoint;
    if (! bin_loadBinFile(loadSector, processHeader, sectorBuffer, &reader, &entryPoint))
    {
        printf("FAILED TO READ %s\n", BIG_APP_FILENAME);
        return;
    }
    printf("ENTRY POINT: %p\n", entryPoint);
    byte *writePtr = (byte *) reader.programEnd;

    if (decb_closeSectorFile(&reader.file) != DECB_OK)
    {
        printf("FAILED TO CLOSE %s\n", BIG_APP_FILENAME);
        return;
    }

    printf("LOAD FINISHED AT %p\n", writePtr);
	decb_shutdown();
	
    // Initialize system variables for sbrk() and sbrkmax().
    //
    asm
    {
program_break   IMPORT
end_of_sbrk_mem IMPORT
        ldx     :writePtr
        stx     program_break,pcr
        ldx     :endOfFreeMem
        stx     end_of_sbrk_mem,pcr
    }
    //printf("SBRKMAX: %u\n", sbrkmax());

    // Execute the big app.
    //
    printf("EXECUTING...\n");

    disableInterrupts();
    asm
    {
        jmp     APP_START
    }
}


// This function is executed AFTER the program has been moved to upper RAM.
//
void loadBigApp(void *newProgramStart)
{
    #ifdef ERASE_ORIGINAL
//    memset(0x2800, 0x39, 0x2000);  // erase original copy of this program (optional)
    #endif

    setConsoleOutHook(consoleOutHook);  // re-hook to adjust global CHROUT variable

    //printf("PROGRAM MOVED AT %p\n", newProgramStart);

    // Initialize the sector file I/O library.
    //
    DECBDrive drives[NUM_DISK_DRIVES];
    decb_init(drives, NUM_DISK_DRIVES);
    word driveNo;
    for (driveNo = 0; driveNo < NUM_DISK_DRIVES; ++driveNo)
        if (decb_registerDrive((byte) driveNo) != DECB_OK)
        {
            printf("FAILED TO REGISTER DRIVE %u\n", driveNo);
            break;
        }

    if (driveNo == NUM_DISK_DRIVES)  // if no error
    {
        // Have the decb_*() functions use dskcon() from dskcon.h
        // and the DC* variables also in that file. Those variables
        // must be in the same order as in Disk Basic.
        //
        decb_setDskConAddresses(dskcon_processSector, (DECBDskConVariables *) &DCOPC);

        loadBigAppFile();  // upon success, does not return
    }

    printf("FAILED TO START THE APPLICATION\n");

    // The load has failed. Hang.
    for (;;)
        ;
}


int main()
{
    initCoCoSupport();
    moveProgramAndRun(loadBigApp);  // does not return when successful
    printf("THIS PROGRAM REQUIRES\n64K OF RAM.\n");
    return 1;
}
