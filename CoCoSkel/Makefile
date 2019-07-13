#makefile for adventure game

CC=cmoc
CFLAGS= -c -i 
LIBS = -L ../CoCoLib -ldecbfile

.PHONY :
all : game.dat adventur.bin
	cp blank.dsk adventur.dsk
	writecocofile adventur.dsk adventur.bin
	writecocofile adventur.dsk game.dat
	$(info To run program mount adventur.dsk, loadm \"adventur\", exec)

adventur.bin : loader.o
	cmoc -o adventur.bin loader.o -L ../CoCoLib -ldecbfile

game.dat : main.o checks.o common.o Dictionary.o ObjectTable.o
	$(CC) -o game.dat main.o checks.o common.o \
		Dictionary.o ObjectTable.o  \
		$(LIBS)


%.o : %.c
	$(CC) $(CFLAGS) -o $@ $<

.PHONY : clean
clean :
	rm -f *.o *.dat *.bin


