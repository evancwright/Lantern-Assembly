echo off


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
