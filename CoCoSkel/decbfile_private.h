#ifndef _H_decbfile_private_
#define _H_decbfile_private_


#include "decbfile.h"

extern word decb_numRegisteredDrives;
extern word decb_driveArrayCapacity;
extern DECBDrive *decb_drives;
extern void (*decb_dskcon_routine)(void);
extern DECBDskConVariables *decb_dskcon_variables;


DECBDrive *
decb_getDrive(byte decbDriveNo);


byte
decb_getRecordOffsets(DECBRecordFile *recFile, word recordIndex,
                      word *sectorIndex, byte *byteOffsetInSector);

byte
decb_truncateOpenFileInGranules(DECBFile *file,
                                byte numGranulesWithSuccessor,
                                byte numSectorsInLastGranule,
                                word numBytesUsedInLastSector);

byte
decb_getDirEntryFromUnnormalizedFilename(byte driveNo, const char *filename,
                                         byte dirSectorBuffer[256],
                                         byte *dirSectorNum,
                                         DECBDirEntry **dirEntry);

byte
decb_getNumGranulesInFile(byte driveNo, byte firstGranule,
                          byte *lastFileGranule, word *numSectors);


#endif  /* _H_decbfile_private_ */
