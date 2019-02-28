#build the loader

cmoc -c -i loader.c
cmoc -o game.bin loader.o -L ../CoCoLib -ldecbfile




writecocofile blank.dsk game.bin


#build main program

cmoc -c -i  main.c
cmoc -o main.bin --org=0x0C00  main.o -L ../CoCoLib -ldecbfile



mv main.bin game.dat
writecocofile blank.dsk game.dat


cp blank.dsk advent.dsk

echo "To run program mount advent.dsk, loadm \"game\", exec"
