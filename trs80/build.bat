echo off

echo Building for TRS-80...
..\bin\Z80asm.exe -nh main.asm

if EXIST main.cmd (
	echo main.cmd has been built
	echo.
	echo You can run this directly in mame using the Quickload option
	echo Note: to launch MAME run mame64 -debug trs80l2
	echo.
	echo To deploy to the machine, attach the cmd file to a disk image using TRS Tools
) else (
	echo An error occured. Output file not found.
)

