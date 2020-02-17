#!/bin/sh


echo "This script use z80Asm.exe by permission of Matthew Reed"
echo "Please visit trs-80emulators.com for more information"

if [ ! -e "../bin/z80asm.exe" ]
then
	echo "unable to find Z80asm.exe"
	echo "please download this and put it in the 'bin' folder"
	exit
fi

rm -f main.cmd
../bin/z80asm.exe -nh -com main.asm

mv main.com __DISK_NAME__.com

if [ -e "__DISK_NAME__.com" ]
then
echo "__DISK_NAME__.com has been built"
echo ""
echo "You can copy this into the B\0 folder under RunCPM"
echo ""
echo "To deploy to a real machine, use PCGET  and a serial client such as Terraterm"
else
echo "An error occured. Output file not found."
fi

