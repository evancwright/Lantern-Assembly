cmoc -c -i  main.c
cmoc -o main.bin --org=C00  main.o setNumBytesUsedInLastSector.o \
	writeSector.o \
	setFATEntry.o dskcon.o \
	getFileGranuleFromIndex.o init.o isValidFATEntry.o shutdown.o closeSectorFile.o \
	writeFAT.o readFAT.o findFreeGranule.o setDskConAddresses.o createSectorFile.o \
	normalizeFileName.o findDirEntry.o getNumGranulesInOpenFile.o  \
	getNumGranulesInFile.o computeTrackAndSector.o 




mv main.bin game.dat
writecocofile heinlein.dsk game.dat
