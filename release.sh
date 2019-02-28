#!/bin/sh
rm -rf release
mkdir release
cp ../../../XmlToAdv/bin/Debug/XmlToAdv.dll release
cp ../../../PlayerLib/bin/Debug/PlayerLib.dll release
cp ../../../Player/bin/Debug/Player.exe release
cp CLL.dll release
cp IGame.dll release
cp GameTables.dll release
cp Lantern.exe release
cp -r bin release
cp -r docs release
cp -r 6502skel release
cp -r 6809skel release
cp -r z80skel release
cp -r RPiSkel release
cp -r trs80 release
cp -r apple2 release
cp -r spectrum release
cp -r cpc464 release
cp LondonAdventure.xml release
cp RichardMines5.xml release
cp LockedDoor.xml release
cp PrisonEscape.xml release
cp InstantDeath.xml release
cp FLashlight.xml release
cp SecretPassage.xml release 
cp ColdAndHungry.xml release
cp MonsterDrop.xml release
cp CompoundObject.xml release
cp BlockingMonster.xml release
cp "Heinlein Station2.xml" release
