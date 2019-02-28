/*  decbfile.h - Sector-based read/write DECB file library.

    By Pierre Sarrazin <http://sarrazip.com/>
    This file is in the public domain.

    THERE IS NO WARRANTY AS TO THE RELIABILITY OF THIS LIBRARY.
    Users as advised to make BACKUPS of any file that might come into
    contact with this library.
*/

/*  This is a programming interface to create, write, read and
    delete files using the Disk Extended Color Basic (DECB) format.

    decb_init() must be called before using this library, and
    decb_shutdown() must be called when the caller is done.
    
    The second thing to do is to call decb_registerDrive() to register
    the drive numbers to be used. decb_unregisterDrive() can be used
    to unregister a drive in order to register another one.
    
    The error code DECB_ERR_DRIVE_NOT_REGISTERED will be returned by
    functions of this library when they are told to operate on a drive
    whose number has not been registered.

    Unless stated otherwise, functions that return a byte return
    a DECB_* error code (DECB_OK for success).

    Disk Extended Color Basic must be in memory because decb_dskcon()
    calls the DSKCON routine, unless a different sector access routine
    has been specified with decb_setDskConAddresses().

    QUICK REFERENCE:

    Start and stop the system:
        decb_init()
        decb_shutdown()

    Register and unregister disk drive numbers:
        decb_registerDrive()
        decb_unregisterDrive()
        decb_unregisterAllDrives()

    Create or open a record-file with header:
        decb_createRecordFile()
        decb_openRecordFile()
        decb_writeHeader()
        decb_writeRecord()
        decb_readHeader()
        decb_readRecord()
        decb_truncateOpenRecordFile()
        decb_getNumRecords()
        decb_closeRecordFile()

    Sizing:
        decb_getNumFreeGranules()
        decb_getOpenFileSize()
        decb_getFileSizeFromFilename()

    File operations:
        decb_kill()
        decb_rename()
        decb_copyFile()

    Low-level sector access:
        decb_dskcon()
        decb_setDskConAddresses()

    TERMINOLOGY:

    - File granule index

    This code uses the term "file granule index" to refer to a
    zero-based numbering of granules making up the contents of
    a file. If a file as 23040 bytes, it contains 10 full granules,
    and their indices are 0..9, regardless of where in the FAT those
    10 granules are allocated. Those 10 granules could be allocated
    at entries 67, 66, ..., 58 of the FAT, so granule 67 on the
    disk would be "file granule index" 0 in the file contents,
    while granule 58 on the disk would be "file granule index" 9
    in the file contents.

    - FAT entry index

    A position in the FAT, i.e., 0..DECB_MAX_NUM_GRANULES-1.

    - FAT entry

    An element of the FAT: either the "FAT entry index" of the
    granule that follows in a file's granule chain, or a number
    between 0xC1 and 0xC9 (inclusively) whose lower nybble is the
    number of sectors used in the file's last granule. (0xC0 is
    NOT a valid entry: DECB will think that the file is empty even
    if the dir entry says that the last sector contains some bytes.)
*/

#ifndef _decbfile_h_
#define _decbfile_h_

#include <coco.h>


// DSKCON operation codes.
//
enum
{
    DECB_DSKCON_READ            = 2,
    DECB_DSKCON_WRITE           = 3,
};


// Error codes (unsigned char).
//
enum
{
    DECB_OK,
    DECB_ERR_INVALID_ARGUMENT,
    DECB_ERR_IO,
    DECB_ERR_NOT_FOUND,
    DECB_ERR_OUT_OF_SPACE,
    DECB_ERR_FAT_NOT_LOADED,
    DECB_ERR_CORRUPT_FAT,
    DECB_ERR_CORRUPT_DIR,
    DECB_ERR_ALREADY_EXISTS,
    DECB_ERR_INTERRUPTED,
    DECB_ERR_END_OF_DIR,
    DECB_ERR_DRIVE_NOT_REGISTERED,
};


// File types.
//
enum
{
    DECB_TYPE_BASIC_PROGRAM     = 0,
    DECB_TYPE_BASIC_DATA        = 1,
    DECB_TYPE_MACHINE_CODE      = 2,
    DECB_TYPE_ASCII_TEXT        = 3,
};


// File formats.
//
enum
{
    DECB_FORMAT_BINARY          = 0x00,
    DECB_FORMAT_ASCII           = 0xFF,
};


// Other constants.
//
enum
{
    DECB_MAX_NUM_TRACKS         = 35,
    DECB_LAST_DIR_SECTOR        = 18,
    DECB_MAX_NUM_GRANULES       = 68,
    DECB_SEQ_WRITE_BUFFER_SIZE  = 512,
};


// Object representing an open file.
//
typedef struct DECBFile
{
    byte driveNo;
    byte dirSectorNum;                  // 3..DECB_LAST_DIR_SECTOR (1 means closed)
    byte byteOffsetInDirSector;         // 0, 32, ..., 224
    byte firstGranule;                  // 0..DECB_MAX_NUM_GRANULES-1
    byte fileType;                      // see DECB_TYPE_* enum
    byte fileFormat;                    // see DECB_FORMAT_* enum
    word numBytesUsedInLastSector;      // 0..256
    byte modified;                      // boolean
} DECBFile;


typedef struct DECBRecordFile
{
    DECBFile file;
    word headerSize;                    // size of file's header, in bytes (may be zero)
    word recordSize;                    // size of a record, in bytes (must not be zero)
    word numRecords;                    // current number of records in the file (may be zero)
} DECBRecordFile;


// 32-byte directory entry.
//
typedef struct DECBDirEntry
{
    char name[8];                       // normalized name (uppercase, space-padded)
    char ext[3];                        // normalized extension (uppercase, space-padded)
    byte fileType;                      // see DECB_TYPE_* enum
    byte fileFormat;                    // see DECB_FORMAT_* enum
    byte firstGranule;                  // 0..DECB_MAX_NUM_GRANULES-1
    word numBytesUsedInLastSector;      // 0..256
    byte padding[16];                   // zeroes, as expected by EDTASM
} DECBDirEntry;


// Structure to be used with decb_openDir(), decb_readDir() and decb_closeDir(),
//
typedef struct DECBDirIterator
{
    byte driveNo;
    byte sectorIndex;
    byte entryOffset;  // offset in sectorBuffer[]
    byte sectorBuffer[256];
} DECBDirIterator;


// State of a disk drive.
//
typedef struct DECBDrive
{
    byte driveNo;  // Disk Basic drive number
    byte fatLoaded;
    byte fatNeedsSave;
    byte fatBuffer[DECB_MAX_NUM_GRANULES];
} DECBDrive;


typedef struct DECBDskConVariables
{
    byte opCode;   // DCOPC
    byte drive;    // DCDRV
    byte track;    // DCTRK
    byte sector;   // DCSEC
    void *buffer;  // DCBPT
    byte status;   // DCSTA
} DECBDskConVariables;


// operation: DSKCON operation code
// buffer: non null pointer to a 256-byte region (not modified by this function).
// drive: 0..3.
// track: 0..DECB_MAX_NUM_TRACKS-1.
// sector: 1..18 (sic).
// Returns non-zero for success, zero for failure.
//
byte decb_dskcon(byte operation, void *buffer, byte drive, byte track, byte sector);


// Normalizes the filename in 'src' into the 12-byte buffer
// designated by 'dest'.
// Expects period as extension separator in 'src'.
// Converts letters to uppercase.
// Pads filename and extension with spaces.
// Excess filename and extension characters are not used.
// Writes 11 non-null characters to the destination buffer,
// followed by a terminating '\0' character.
//
void decb_normalizeFilename(char dest[12], const char *src);


// Convert a filename as stored in a directory entry into a non-space-padded
// filename with a period as the extension separator.
// lowerCase: If non-zero, dest[] will be in lower-case. If zero, the letters
//            will be as they appear in the directory entry.
//
void
decb_denormalizeFilename(char dest[13], char src[11], byte lowerCase); 


// Starts a traversal of the directory entries in the specified drive.
// Call decb_readDir() to read each entry, then call decb_closeDir().
//
// dirIter: Address of an iterator that gets initialized by this function.
//
// CAUTION: decb_init() MUST have been called before this.
//
byte decb_openDir(byte driveNo, DECBDirIterator *dirIter);


// Reads the next entry, if any, in the directory targeted by the given iterator.
//
// dirIter: Must have been initialized by decb_openDir().
// dirEntry: Address of a pointer to a directory entry.
//           Receives a pointer only if this function returns DECB_OK.
// Returns DECB_OK (and fills *dirEntry) if a directory entry was found;
//         DECB_ERR_END_OF_DIR DECB_ERR_IOif the end of the directory is reached;
//         DECB_ERR_IO if the disk could not be accessed to read a directory sector;
//
// This function must NOT be called on an iterator after the function has returned
// a code other than DECB_OK.
//
byte decb_readDir(DECBDirIterator *dirIter, DECBDirEntry **dirEntry);


// Does nothing in the current implementation, but should be called anyway
// in case a future implementation needs to do something.
//
byte decb_closeDir(DECBDirIterator *dirIter);


// Searches the directory for an entry that matches the given name (if opening
// an existing file) or for an entry in which to create a new file.
//
// forNewFile: If TRUE, searches for an empty entry and checks that no existing
//             entry matches normalizedFilename[]. Returns DECB_OK if an entry
//             is found, DECB_ERR_NOT_FOUND if none is found, or DECB_ERR_ALREADY_EXISTS
//             if normalizedFilename[] is found in the directory.
//             If FALSE, looks for an entry that matches normalizedFilename.
//             Returns DECB_OK or DECB_ERR_NOT_FOUND.
//
// normalizedFilename: See decb_normalizeFilename().
//
// dirSectorBuffer: If an entry is found, this array will receive the directory sector
//                  that contains that entry.
//
// dirSectorNum: Will receive the number (3..DECB_LAST_DIR_SECTOR) of that sector.
//
// byteOffsetInDirSector: Will receive the offset (a multiple of 32) in that sector
//                        where the found entry appears.
//
// NOTE: Returns DECB_ERR_IO if a sector read operation fails.
//
byte decb_findDirEntry(byte forNewFile,
                       byte driveNo,
                       char normalizedFilename[12],
                       byte dirSectorBuffer[256],
                       byte *dirSectorNum,
                       byte *byteOffsetInDirSector);


// Does not access the drive if the FAT is known to already be loaded.
// Returns:
// - DECB_OK upon success;
// - DECB_ERR_IO upon a hardware failure;
// - DECB_ERR_NOT_FOUND if driveNo has not been registered with
//   decb_registerDrive().
//
byte decb_readFAT(byte driveNo);


// FAT must already be loaded.
//
// Any FAT modification MUST be done through this function only.
// After calling this function, decb_writeFAT() MUST be called
// to flush the FAT to the actual drive.
//
// Returns:
// - DECB_OK upon success;
// - DECB_ERR_NOT_FOUND if the drive number is not currently registered;
// - DECB_ERR_INVALID_ARGUMENT if entryIndex is not lower than DECB_MAX_NUM_GRANULES.
//
byte decb_setFATEntry(byte driveNo, byte entryIndex, byte newValue);


// Does not access the drive if the FAT has not been changed
// since it was loaded.
// The FAT must have been loaded.
// Only decb_setFATEntry() must be used to modify the FAT.
//
byte decb_writeFAT(byte driveNo);


// Scans the FAT image for the given drive number to find a free entry
// and returns its index, or 0xFF if none is found.
// A failure may be due to 'driveNo' not having been registered with
// decb_registerDrive().
//
byte decb_findFreeGranule(byte driveNo);


// Only useful if not running under Disk Basic.
// dskconRoutine: Must be an equivalent to Disk Basic's DSKCON routine.
// vars: Address of variables equivalent to Disk Basic's DCOPC, etc.
//
byte decb_setDskConAddresses(void (*dskconRoutine)(), DECBDskConVariables *vars);


// Must be called before using the rest of this library.
//
// THERE IS NO WARRANTY AS TO THE RELIABILITY OF THIS LIBRARY.
// Users as advised to make BACKUPS of any file that might come into
// contact with this library.
//
// N.B.: The high-speed POKE should typically NOT be in effect
//       while accessing the disk.
//
// driveArray, numDrives:
//     Array of structures to be used to remember the state of the
//     drives to be used by this library.
//
// decb_registerDrive() must be called for each drive number to be used.
//
// Returns DECB_OK or an error code.
//
// See also decb_registerDrive(), decb_unregisterDrive() and
// decb_unregisterAllDrives().
// See decb_setDskConAddresses() if not running under Disk Basic.
//
byte decb_init(DECBDrive *driveArray, word numDrives);


// Must be called when finished using this API.
// Returns DECB_OK or an error code.
//
// decb_writeFAT() must have been called on each drive whose FAT
// may have been modified.
//
// Automatically unregisters drive numbers that have been registered
// with decb_registerDrive().
//
byte decb_shutdown();


// Tell this library that the given drive number will be used.
// This allows a program to access up to 256 drives, while only
// allocating a DECBDrive array large enough for the maximum number
// of drives to will be used at a time.
//
// For example, if a file must be copied from drive 3 to 147, then
// call decb_registerDrive(3) and decb_registerDrive(147), then do
// the copy. If a file on drive 62 must then be read, unregister
// either 3 or 147 with decb_unregisterDrive(), then register 62
// read the file.
// 
// Drive numbers do not have to be registered in numerical order.
// It is not necessary to unregister drive numbers before calling
// decb_shutdown().
//
// Returns:
// - DECB_OK upon success;
// - DECB_ERR_OUT_OF_SPACE if there is no room to register a new drive
//   (resolve this by passing a larger array to decb_init());
// - DECB_ERR_ALREADY_EXISTS if the drive number is already registered.
//
// See also decb_unregisterDrive() and decb_unregisterAllDrives().
//
byte decb_registerDrive(byte decbDriveNo);


// Unregisters a drive number that has been registered with
// decb_registerDrive().
//
// Returns:
// - DECB_OK upon success;
// - DECB_ERR_NOT_FOUND if the drive number is not currently registered;
//
// See also decb_unregisterAllDrives().
//
byte decb_unregisterDrive(byte decbDriveNo);


// Returns DECB_OK.
//
byte decb_unregisterAllDrives();


// Create a new file for sector-based I/O.
// Write the modified FAT immediately to the actual drive.
//
// file: Must point to the structure to initialize.
// filename: Must contain the non-normalized filename to give the new file.
// fileType: Must be one of the DECB_TYPE_* constants.
// fileFormat: Must be one of the DECB_FORMAT_* constants.
//
// Returns DECB_OK or an error code (e.g., DECB_ERR_ALREADY_EXISTS).
// DECB_ERR_DRIVE_NOT_REGISTERED means that 'driveNo' has not been registered;
// see decb_registerDrive().
//
// See also decb_readSector(), decb_writeSector(), decb_closeSectorFile().
//
// CAUTION: decb_init() MUST have been called before this.
//
byte decb_createSectorFile(DECBFile *file, byte driveNo, const char *filename,
                           byte fileType, byte fileFormat);


// Opens the designated file in the given drive and fills the DECBFile
// structure upon success.
//
// Returns DECB_OK, DECB_ERR_NOT_FOUND or DECB_ERR_IO.
// DECB_ERR_DRIVE_NOT_REGISTERED means that 'driveNo' has not been registered;
// see decb_registerDrive().
//
// See also decb_readSector(), decb_writeSector(), decb_closeSectorFile().
//
// CAUTION: decb_init() MUST have been called before this.
//
byte decb_openSectorFile(DECBFile *file, byte driveNo, const char *filename);


// Like decb_openSectorFile(), but the filename is specified by
// the given directory entry.
//
// CAUTION: decb_init() MUST have been called before this.
//
// DECB_ERR_DRIVE_NOT_REGISTERED means that 'driveNo' has not been registered;
// see decb_registerDrive().
//
byte decb_openSectorFileFromDirEntry(DECBFile *file, byte driveNo, DECBDirEntry *entry);


// DECB_ERR_DRIVE_NOT_REGISTERED means that 'driveNo' has not been registered;
// see decb_registerDrive().
//
byte decb_getNumFreeGranules(byte driveNo, byte *numFreeGranules);


// Indicates if the given number is a value that can be expected
// to appear in a FAT. Returns TRUE or FALSE.
//
byte decb_isValidFATEntry(byte entry);


// Returns the length of the given file, in granules (rounded up),
// or 0xFF if an error is detected in 'file' or the given FAT image.
//
// Reads the FAT if not already done.
//
// lastFileGranule: Must point to a byte that will receive the FAT entry index
//                  (0..DECB_MAX_NUM_GRANULES-1) of the last granule of the file,
//                  upon success.
// numSectors: Must point to a word that will receive the number of sectors
//             contained in the file, upon success.
//
byte decb_getNumGranulesInOpenFile(DECBFile *file,
                                   byte *lastFileGranule, word *numSectors);


// Returns the number of granules used by the file described by the given
// directory entry, or 0xFF upon error.
// Stores the number of sectors used in *numSectors.
// Stores the number of bytes used in lengthInBytes[0] (high word) and
// lengthInBytes[1] low word. (Function dwtoa(), declared by <cmoc.h>
// can be used to get an ASCII decimal representation of lengthInBytes[].)
//
byte decb_getFileSizeFromDirEntry(byte driveNo, DECBDirEntry *entry,
                                  word *numSectors, dword *lengthInBytes);


// Returns the number of granules used by 'file', which must be a currently opened file.
// Upon error, returns 255 (0xFF).
// numSectors: Must not be null. Receives the number of sectors in the file.
//             The last sector may not be used entirely.
// lengthInBytes: Must not be null. Receives the 32-bit length in bytes of the file.
//
byte decb_getOpenFileSize(DECBFile *file, word *numSectors, dword *lengthInBytes);


// Similar to decb_getFileSizeFromDirEntry() but accepts an unnormalized filename
// (e.g., "foobar.txt") instead of a directory entry.
//
byte decb_getFileSizeFromFilename(byte driveNo, const char *filename,
                                  word *numSectors, dword *lengthInBytes);


// Determine the FAT entry index from a file granule index.
//
// Reads the FAT if not already done.
//
// fileGranIndex: Index into the granules of the contents of 'file'.
// fatEntryIndex: Pointer to a byte that receives 0..DECB_MAX_NUM_GRANULES-1,
//                upon success.
//
// Returns DECB_OK or an error code.
//
// Example: If 'file' is allocated at granules 54, 27, 33, then
//          those granules are at indices 0, 1, 2 from the perspective
//          of the contents of 'file'. If this function is given 2,
//          it will return 33.
//
byte decb_getFileGranuleFromIndex(DECBFile *file,
                             byte fileGranIndex,
                             byte *fatEntryIndex);


// Puts 0xFF in each FAT entry of the given FAT image that belongs to the
// granule chain starting at FAT entry index 'firstGranule'.
//
// Reads the FAT if not already done.
//
// Calls decb_setFATEntry().
// The caller must call decb_writeFAT() to flush the FAT to the actual drive.
//
// Returns DECB_OK or an error code.
//
byte decb_freeGranuleChain(byte driveNo, byte firstGranule);


// Frees the granules occupied by the designated non-normalized filename,
// if found, and frees the directory entry.
//
// Returns DECB_OK or an error code (namely DECB_ERR_NOT_FOUND).
//
byte decb_kill(byte driveNo, const char *filename);


// Changes the name and extension of the specified existing file on
// the specified drive.
// Returns DECB_OK or an error code. Fails if no file exists with
// the specified filename.
//
byte decb_rename(byte driveNo, const char *existingFilename, const char *newFilename);


// Sets the number of bytes used by the file at the start of the file's last sector.
//
// numBytesUsedInLastSector: 0..256.
//
// Returns DECB_OK upon success, or DECB_ERR_INVALID_ARGUMENT.
//
byte decb_setNumBytesUsedInLastSector(DECBFile *file, word numBytesUsedInLastSector);


// Changes the length of a currently open file.
// The new length must not require the allocation of new granules to the file.
//
// newNumSectors: The new number of used sectors in the file.
//                The last sector does not have to be used entirely.
// numBytesUsedInLastSector: The new number of bytes used by the file's
//                           last sector (0..256).
//
// Returns DECB_ERR_INVALID_ARGUMENT, or an error code if the FAT could
// not be read, or DECB_ERR_CORRUPT_FAT, or DECB_OK upon success.
// DECB_OK is returned when newNumSectors is longer than the current file.
//
// This function can be used to length the file, but not to the point of
// requiring the allocation of new granules.
//
// Upon success, decb_closeSectorFile() must be called for the truncation
// to take effect on the physical disk.
// There is no need to call decb_setNumBytesUsedInLastSector().
//
byte decb_truncateOpenFile(DECBFile *file,
                           word newNumSectors,
                           word numBytesUsedInLastSector);


// Determines the physical track and sector numbers that correspond to the
// given file granule index and to the sector number in that granule.
// The resulting track and sector numbers are suitable for decb_dskcon().
//
// file: The open file to which fileGranIndex is relative.
// fileGranIndex: Zero-based index of a granule index into the contents
//                of the file.
// sectorIndexInGranule: 0..8.
// track: (output) 0..16, 18..DECB_MAX_NUM_TRACKS-1.
// sector: (output) 1..9
//
// Returns DECB_OK or an error code.
//
byte decb_computeTrackAndSector(DECBFile *file,
                                byte fileGranIndex, byte sectorIndexInGranule,
                                byte *track, byte *sector);


// Writes a sector-sized buffer to the specified sector of the given open file.
// Appends granules and sectors to the file if the specified sector is beyond
// the current end of the file.
//
// NOTE: The caller must call decb_writeFAT() after it is done writing
//       sectors to the file, or it must call decb_closeSectorFile(), which
//       calls decb_writeFAT().
//
// file: The open file to write to.
// sectorBuffer: The 256 bytes of data to be written (not modified by this function).
// fileSectorIndex: A file-relative sector index. Indices 0..8 are in the file's
//                  first granule, 9..17 are in the second, etc., no matter where
//                  the file's granules are allocated physically on the disk.
//
// Returns DECB_OK or an error code.
//
byte decb_writeSector(DECBFile *file,
                      byte sectorBuffer[256],
                      word fileSectorIndex);


// Reads the sector at the specified index from the designated file.
// fileSectorIndex: Zero-based index into the sectors that form the
//                  contents of the file. This index is file-relative,
//                  not track-relative.
// Returns DECB_OK if the sector exists and was successfully read;
//         DECB_ERR_NOT_FOUND if the given sector index is too large;
//         another error code otherwise.
//
byte decb_readSector(DECBFile *file,
                     byte sectorBuffer[256],
                     word fileSectorIndex);


// Terminates the use of the given file object. In the case where the file
// has been modified, updates the directory entry and the FAT.
//
// CAUTION: In the case of a modified file, the caller must have called
//          decb_setNumBytesUsedInLastSector() or decb_truncateOpenFile()
//          before calling this function.
//
// Returns DECB_OK or an error code.
//
byte decb_closeSectorFile(DECBFile *file);


// Copy the contents of the specified source file to a new file that
// will be created under the given destination filename (where a period
// introduces the extension, e.g., "foo.txt").
// decb_denormalizeFilename() can be used to form the destination
// filename from a directory entry's 11-byte "normalized" filename.
// decb_kill() can be used to remove a file that may already exist
// under the given destination filename.
//
// After each sector is copied successfully, if 'progressFunctor' is not
// null, it is invoked with the given 'userData'. If that functor
// returns zero, the copy is interrupted, the files are closed and
// DECB_ERR_INTERRUPTED is returned. The destination file will exist
// but will be incomplete (see decb_kill() to erase it).
//
// Returns DECB_OK upon success, or an error code otherwise.
//
// CAUTION: decb_init() MUST have been called before this.
//
byte decb_copyFile(byte srcDriveNo, DECBDirEntry *srcDirEntry,
                   byte destDriveNo, const char *destFilename,
                   byte (*progressFunctor)(word currentSectorIndex,
                                           word totalNumSectors,
                                           void *userData),
                   void *userData);


// Useful to write sequentially to a newly created file.
// First call decb_initSeqWriteBuffer(), then call decb_getFreeSpaceAddress()
// and decb_getFreeSpaceSize() to determine where to fill the buffer.
// Call decb_registerWrittenBytes() to keep track of the written data.
// Use decb_hasFullSector() and decb_flush() to write full sectors to
// an actual file.
//
typedef struct DECBSeqWriteBuffer
{
    word numUsedBytes;  // in buffer[]
    word numSectorsWritten;
    byte buffer[DECB_SEQ_WRITE_BUFFER_SIZE];  // enough for 2 sectors
} DECBSeqWriteBuffer;


// Must be called before any other use this DECBSeqWriteBuffer.
//
void decb_initSeqWriteBuffer(DECBSeqWriteBuffer *writeBuffer);


// Returns the first free byte in the buffer. New data should be
// written at that address. Call decb_getFreeSpaceSize() to determine
// how much room there is. Flush with decb_hasFullSector() and decb_flush().
//
byte *decb_getFreeSpaceAddress(DECBSeqWriteBuffer *writeBuffer);


word decb_getFreeSpaceSize(DECBSeqWriteBuffer *writeBuffer);


// Tells the buffer that some number of bytes has been written to it
// (at the free space pointer).
// numBytes: Must not bring the total number of bytes in the buffer over 512
//           (see decb_getFreeSpaceSize()).
//
void decb_registerWrittenBytes(DECBSeqWriteBuffer *writeBuffer, word numBytes);


// Useful to determine when to call decb_flush(). Returns a boolean.
//
byte decb_hasFullSector(DECBSeqWriteBuffer *writeBuffer);


// Typically called when decb_hasFullSector() returns TRUE.
// Should only be called for a partial sector when it is the last
// sector of the file.
// The file must eventually be closed with a call to decb_closeSectorFile().
// Returns DECB_OK upon success, or any error code received from decb_writeSector().
//
byte decb_flush(DECBFile *file, DECBSeqWriteBuffer *writeBuffer);


// Creates a new file intended to store an optional header followed by
// zero or more fixed-length records.
// headerSize: Size in bytes (may be zero) of the header at the head of the file.
// recordSize: Size in bytes (must NOT be zero) of each record that follows the header.
//
// Returns DECB_OK upon success, or an error code otherwise.
// DECB_ERR_DRIVE_NOT_REGISTERED means that 'driveNo' has not been registered;
// see decb_registerDrive().
//
// The theoretical limit on the length a record file is 2**24 bytes, i.e., 16 MB.
//
byte decb_createRecordFile(DECBRecordFile *recFile, byte driveNo, const char *filename,
                           word headerSize, word recordSize);


// Opens an existing record-based file.
// See decb_createRecordFile().
// Returns DECB_ERR_DRIVE_NOT_REGISTERED if the file is not found or if 'driveNo'
// has not been registered; see decb_registerDrive().
//
// CAUTION: decb_init() MUST have been called before this.
//
byte decb_openRecordFile(DECBRecordFile *recFile, byte driveNo, const char *filename,
                         word headerSize, word recordSize);


// Returns the number of records currently written in the file.
//
word decb_getNumRecords(DECBRecordFile *recFile);


// Write the bytes stored at 'header' to the designated file.
// The size of the header is the one used when the file was created or opened.
// Does nothing and returns DECB_OK is the header size is zero.
//
byte decb_writeHeader(DECBRecordFile *recFile, byte *header);


// Writes the given record at the given zero-based record index.
// The file is lengthened as necessary. The contents of any records added to reach
// the given record index will be undefined. It is preferrable for the caller to
// write those records explicitly, to avoid writing sensitive data to disk.
// The size of the record is the one used when the file was created or opened.
// Returns DECB_OK or an error code.
//
// Updates the length of the file's last sector.
//
byte decb_writeRecord(DECBRecordFile *recFile, byte *record, word recordIndex);


// The size of the header is the one used when the file was created or opened.
// Returns DECB_OK or an error code.
//
byte decb_readHeader(DECBRecordFile *recFile, byte *header);


// See decb_writeRecord().
// Returns DECB_ERR_NOT_FOUND if recordIndex is too high.
//
byte decb_readRecord(DECBRecordFile *recFile, byte *record, word recordIndex);


// Sets the end of the file so that 'recordIndex' becomes the first
// inexistent record in that file.
//
byte decb_truncateOpenRecordFile(DECBRecordFile *recFile, word recordIndex);


// Must be called to ensure that the disk is properly updated.
//
byte decb_closeRecordFile(DECBRecordFile *recFile);


#endif  /* _decbfile_h_ */
