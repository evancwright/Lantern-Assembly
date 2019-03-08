copy ..\CCommon\*.* . 
copy ..\8086Skel\defs.h .
wcc -0 -l=main.list -bt=dos main.c
wcl -bt=dos main
copy main.exe ..
wdis main -s -ld

