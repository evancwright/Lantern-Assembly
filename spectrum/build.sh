#!/bin/sh

rm data 
../bin/Z80asm.exe -com main.asm

if [ ! -e "main.com" ]
then
	echo "build errors occurred"
	exit 1
fi
	
	echo "main.cmd has been built"

mv main.com data 

if [ -e "loading.scr" ]
then
	echo "attaching load screen"
	cp sloader.tap game.tap
	cp loading.scr loading
	../bin/mctrd add loading game.tap
else
	cp loader.tap game.tap
fi


./mctrd add data game.tap 

echo "game.tap is ready."
echo "load this into an emulator and enter LOAD \"\"."  
echo "When the file has loaded, enter RUN"
