/*  binfile.h - Support for Disk Extended Color Basic's BIN file format.

    By Pierre Sarrazin <http://sarrazip.com/>
    This file is in the public domain.
*/

/*  Support for reading BIN files on a CoCo.
    See bin_loadBinFile().
*/

#include <coco.h>


typedef BOOL (*bin_SectorLoadFunction)(byte sectorBuffer[256], void *userData);


typedef struct
{
    byte code;  // 0 = block, 0xFF = end header
    word n0;    // if block, then length of block in bytes
    word n1;    // if block, then destination address of block; if end, then entry point
} bin_Header;

typedef void (*bin_HeaderCallback)(bin_Header *header, void *userData);


// Loads a BIN file.
// sectorLoadFunction: Pointer to a function that loads the next sector
//                     of the BIN file. Must not be null.
// headerCallback: Optional pointer to a function that will be called
//                 each time a BIN file 5-byte header is encountered,
//                 including the file-ending header. May be null.
// sectorBuffer: Memory to be used to store a sector. This memory may be
//               discarded after this function is done.
// userData: Pointer that will be called to (*sectorLoadFunction)() and
//           to (*headerCallback)(). May be null.
// entryPoint: If not null, points to a void * that will receive the
//             entry point defined by the last header of the file.
// Returns TRUE upon success, FALSE otherwise.
// Upon failure, (*sectorLoadFunction)() should store the particular
// cause of error so that the caller of bin_loadBinFile() can issue a
// proper error message.
//
BOOL bin_loadBinFile(bin_SectorLoadFunction sectorLoadFunction,
                     bin_HeaderCallback headerCallback,
                     byte sectorBuffer[256],
                     void *userData,
                     void **entryPoint);
