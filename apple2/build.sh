#!/bin/sh
echo "This script requires java and AppleCommander-1.3.5.13-ac"
rm -f errs.txt
rm -f main.bin

./tasm.exe main.asm -b -65 2> errs.txt
mv main.obj main.bin

if [[ -s errs.txt ]]
then
	echo  "errors occured."
	exit 1
fi


rm -f test.dsk
echo "creating a disk image"
#java -jar AppleCommander-1.3.5.13-ac.jar -pro140 advent.dsk txtadv
cp PRODOS.dsk advent.dsk

echo "attaching file to disk image"

java -jar AppleCommander-1.3.5.13-ac.jar -p advent.dsk game.bin bin 0x800 < main.bin

cp advent.dsk "/cygdrive/c/Users/Evan/Documents/Apple2/ADTPro-2.0.2/disks"

./Applewin.exe -d1 advent.dsk -d2 PRODOS.dsk
