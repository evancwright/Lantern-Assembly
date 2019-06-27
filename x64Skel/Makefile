#makefile for adventure game


advent.out : main.o checks.o common.o Dictionary.o ObjectTable.o
	g++ -o advent.out main.o checks.o common.o Dictionary.o ObjectTable.o 

%.o : %.c
	g++ -c -g $< -o $@

.PHONY : clean
clean :
	rm *.o


