echo off
del /q data
del /q main.com 

echo Assembling code...
..\bin\Z80asm.exe -com main.asm 

if NOT EXIST main.com (
	echo Build errors occurred
	echo See errs.txt for details
	exit /b 1
)
	
echo main.cmd has been built

ren main.com data 

if exist loading.scr (
	echo Attaching load screen...
	copy sloader.tap game.tap
	copy loading.scr loading
	..\bin\mctrd add loading game.tap
) else (
	echo No load screen found...
	copy loader.tap game.tap
)


..\bin\mctrd add data game.tap 

echo game.tap is ready.
echo Load this into an emulator and enter LOAD ""
echo When the file has loaded, enter RUN.
