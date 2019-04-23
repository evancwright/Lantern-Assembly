#!/bin/sh



if [ ! -e "../bin/z80asm.exe" ]
then
	echo "unable to find Z80asm.exe"
	echo "please download this and put it in the 'bin' folder"
	exit
fi

rm -f main.cmd
../bin/z80asm.exe -nh -com main.asm

if [ -e "main.com" ]
then
echo "main.com has been built"
echo ""
echo "You can copy this into the B\0 folder under RunCPM"
echo ""
echo "To deploy to a real machine, use PCGET  and a serial client such as Terraterm"
else
echo "An error occured. Output file not found."
fi

