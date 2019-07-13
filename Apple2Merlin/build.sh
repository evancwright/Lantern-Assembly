#!/bin/sh
echo "This script requires java and AppleCommander-1.3.5.13-ac"
rm -f main.bin

../bin/Merlin32.exe  -V ../Merlin32_v1.0/Library/ main.s
mv main main.bin

if [[ -s errs.txt ]]
then
	echo  "errors occured."
	exit 1
fi


rm -f test.dsk

echo "creating a disk image"

cp PRODOS.dsk advent.dsk

echo "attaching file to disk image"

java -jar ../apple2/AppleCommander-1.3.5.13-ac.jar -p advent.dsk game.bin bin 0x800 < main.bin

cp advent.dsk "/cygdrive/c/Users/Evan/Documents/Apple2/ADTPro-2.0.2/disks"

../apple2/Applewin.exe -d1 advent.dsk -d2 PRODOS.dsk
