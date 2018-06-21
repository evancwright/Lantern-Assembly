#!/bin/sh

echo "building C64 version"

if  [ -e advent.d64 ]
then
   rm -f advent.64
fi

echo "assembling..."
./tasm -65 -b -c -s main.asm advent.prg

cp blank.d64 advent.d64
 
echo "attaching program to disk image..."
./c1541 -attach advent.d64 -write advent.prg advent

echo "Reminder:"
echo "LOAD \"*\",8 loads the directory" 
echo "THE * key is the  ] key"
