#build the loader

cmoc -c -i loader.c
cmoc -o loader.bin loader.o -L . -ldecbfile




writecocofile heinlein.dsk loader.bin


#build main program

cmoc -c -i  main.c
cmoc -o main.bin --org=4400  main.o -L . -ldecbfile



mv main.bin game.dat
writecocofile heinlein.dsk game.dat

echo "To run program mount heinlein.dsk, loadm \"loader\", exec"
