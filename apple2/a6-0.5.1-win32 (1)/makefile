# makefile for a6
#
# $Id: makefile 10 2012-09-03 23:48:22Z simon.collis@gmail.com $
#
# This is a very simple makefile, and presumes you have GCC.
#
# It's never been tested, by the way, feedback appreciated :)
#
all: a6

a6: AsmFile.o Charset.o Conditional.o Config.o Cpu.o Directive.o Error.o Expression.o Global.o Label.o Main.o OutputCbm.o OutputFactory.o OutputHex.o String.o Text.o
	gcc -o $@ $^

AsmFile.o: AsmFile.cpp AsmFile.h Conditional.h Config.h Cpu.h Directive.h Error.h Expression.h Global.h Label.h Main.h OutputFactory.h String.h
Charset.o: Charset.cpp Charset.h
Conditional.o: Conditional.cpp Conditional.h Error.h
Cpu.o: Cpu.cpp Cpu.h Directive.h Error.h Expression.h Global.h OutputFactory.h String.h
Directive.o: Directive.cpp Directive.h AsmFile.h Conditional.h Config.h Cpu.h Error.h Expression.h Global.h Label.h Main.h OutputFactory.h String.h Text.h
Error.o: Error.cpp Error.h Asmfile.h Global.h
Expression.o: Expression.cpp Expression.h Error.h Global.h OutputFactory.h Text.h
Global.o: Global.cpp Global.h Error.h
Label.o: Label.cpp Label.h AsmFile.h Config.h Error.h Global.h Main.h OutputFactory.h String.h
Main.o: Main.cpp Main.h AsmFile.h Conditional.h Config.h Cpu.h Error.h Global.h Label.h OutputFactory.h String.h Text.h
OutputCbm.o: OutputCbm.cpp OutputCbm.h
OutputFactory.o: OutputFactory.cpp OutputFactory.h Error.h Global.h String.h
OutputHex.o: OutputHex.cpp OutputHex.h
String.o: String.cpp String.h Main.h
Text.o: Text.cpp Text.h Error.h OutputFactory.h

.PHONY : clean uninstall

clean :
	-rm *.o a6

.cpp.o:
	g++ -Wall -pedantic -O6 -c $*.cpp -o $*.o
