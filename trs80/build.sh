#!/bin/sh



if [ ! -e "../bin/z80asm.exe" ]
then
	echo "unable to find Z80asm.exe"
	echo "please download this and put it in the 'bin' folder"
	exit
fi

rm -f main.cmd
../bin/z80asm.exe -nh main.asm

if [ -e "main.cmd" ]
then
echo "main.cmd has been built"
echo ""
echo "You can run this directly in mame using the Quickload option"
echo "Note: to launch MAME run mame64 -debug trs80l2"
echo ""
echo "To deploy to the machine, attach the cmd file to a disk image using TRS Tools"
echo "If you are using a FreHD, copy the cmd file to your SDC card"
echo "boot your TRS-80 into DOS and use the import2 command. Example \"main.cmd game/cmd\""
else
echo "An error occured. Output file not found."
fi

