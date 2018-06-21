echo off
echo Just FYI: This script requires java runtime and AppleCommander-1.3.5.13-ac
del /q errs.txt
del /q main.bin

tasm.exe main.asm -b -65 2> errs.txt

REN main.obj main.bin

FOR %%A IN ("errs.txt") DO set size=%%~zA
IF %size%  GTR 0 (
	ECHO  Errors occured.
	ECHO  See errs.txt for details.
	EXIT /B 1
)


ECHO Creating a disk image
:: java -jar AppleCommander-1.3.5.13-ac.jar -pro140 advent.dsk txtadv
COPY PRODOS.dsk advent.dsk

ECHO Attaching file to disk image.

java -jar AppleCommander-1.3.5.13-ac.jar -p advent.dsk game.bin bin 0x800 < main.bin

:: copy advent.dsk "/cygdrive/c/Users/Evan/Documents/Apple2/ADTPro-2.0.2/disks"

.\Applewin.exe -d1 advent.dsk -d2 PRODOS.dsk

echo Done.  File is attached to advent.dsk
 

