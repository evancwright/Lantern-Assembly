#!/bin/sh

echo "building C64 version"

if  [ ! -e ../bin/Merlin32 ]
then
	echo "You need Merlin32.exe in the Lantern's bin folder."
   exit
fi

if  [ ! -e ../bin/c1541.exe ]
then
	echo "You need c1541.exe in the Lantern's bin folder to attach your game to a disk image."
   exit
fi

if  [ -e advent.d64 ]
then
   rm -f advent.64
fi


echo "assembling..."
../bin/Merlin32.exe  -V ../Merlin32_v1.0/Library/ main.s


cp blank.d64 __DISK_NAME__.d64
 
echo "attaching program to disk image..."
../bin/c1541 -attach __DISK_NAME__.d64 -write main advent.prg

echo "Reminder:"
echo "LOAD \"*\",8 loads the directory" 
echo "THE * key is the  ] key"
