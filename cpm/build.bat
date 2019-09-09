if not exists..bin\z80asm.exe (
	echo "unable to find Z80asm.exe"
	echo "please download this and put it in the 'bin' folder"
	exit
)

if exists main.com (
	del main.com
)

..\bin\z80asm.exe -nh -com main.asm

ren main.com __DISK_IMAGE_NAME__.com
echo "__DISK_IMAGE_NAME.com has been built"
echo ""
echo "You can copy this into the B\0 folder under RunCPM"
echo ""
echo "To deploy to a real machine, use PCGET, KERMIT  and a serial client such as Terraterm"
else
echo "An error occured. Output file not found."
fi

