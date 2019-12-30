#! /bin/bash

if [ -e $1 ]
then
	./llvm_ninja_cross/bin/clang -o $2 $1 -target arm-linux-gnueabihf -mhard-float -march=armv7a -mcpu=cortex-a9
else
	echo $1 "doesn't exist"
fi
