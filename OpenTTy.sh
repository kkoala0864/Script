#! /bin/bash

for i in {0..3}
do
	echo "screen /dev/ttyUSB"$i" 115200" 
	screen /dev/ttyUSB$i 115200
	sleep 1
done
