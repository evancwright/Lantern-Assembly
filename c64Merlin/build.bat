echo off
echo Building for C64...

if EXIST advent.d64 (
   del advent.64
)

echo Assembling...
..\bin\Merlin32.exe  -V ..\Merlin32_v1.0\Library main.s

copy blank.d64 __DISK_NAME__.d64
 
echo Attaching program to disk image...
..\bin\c1541 -attach advent.d64 -write advent.prg advent

echo Program is ready to run
echo Reminder:
echo LOAD "$",8 loads the directory
echo LOAD "advent.prg",8 loads the program

echo "attaching program to disk image..."
..\bin\c1541 -attach __DISK_NAME__.d64 -write main advent.prg