#!/bin/sh

rm errs.txt
rm game.bin
echo "Assembling..."
../bin/lwasm main.asm --6809 --list=game.list --output=game.bin 2> errs.txt

echo "files assembled"
if [ -s errs.txt ]
then
   echo "Errors occured."
else
   echo "Attaching file to disk image"
   ../bin/writecocofile advent.dsk game.bin 2>> errs.txt
   if [ -s errs.txt ]
   then
        echo "Unable to attach .bin file to disk image.  Is it open?"
   fi
fi
echo "done"
