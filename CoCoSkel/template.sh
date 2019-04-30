#build the loader

cmoc -c -i loader.c
cmoc -o game.bin loader.o -L ../CoCoLib -ldecbfile
mv game.bin OUTPUT.bin

#build main program

cmoc -c -i  main.c
cmoc -o game.dat --org=0x0C00  main.o -L ../CoCoLib -ldecbfile


cp blank.dsk OUTPUT.dsk

writecocofile OUTPUT.dsk OUTPUT.bin
writecocofile OUTPUT.dsk game.dat


echo "To run program mount OUTPUT.dsk, loadm \"OUTPUT\", exec"
