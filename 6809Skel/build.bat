ECHO OFF 
DEL /q errs.txt
DEL /q game.bin
 
ECHO Assembling...
..\bin\lwasm main.asm --6809 --list=game.list --output=game.bin 2> errs.txt

 
FOR %%A IN ("errs.txt") DO SET /A size = %%~zA
 
IF %size% GTR 0 (
   ECHO Errors occured.
   ECHO See errs.txt for details.
   EXIT /B 1
)ELSE (
   ECHO Attaching file to disk image
   ..\bin\writecocofile advent.dsk game.bin 2> errs.txt
   
   FOR %%A IN ("errs.txt") DO SET /A size  = %%~zA
   IF %size% GTR 0 (
        ECHO Unable to attach .bin file to disk image.  Is it open in an emulator?
		EXIT /B 1
   ) ELSE (
		echo done.
		echo the file game.bin has been attached to advent.dsk
	)
)
