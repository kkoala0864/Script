#! /bin/bash


Target=$1/F*/*_SP_*
for i in `ls $1/F*/*_SP_*.s`; do
    name=${i%.s}
    trace=$name.trace
    elf=$name.elf
    bin=$name.bin

    echo $name
    rm $trace $elf $bin

done
sed -i "s/Handler/Hanlder/g" `grep Handler -rl $Target`

for i in `ls $1/F*/*_SP_*.s`; do
    name=${i%.s}
    elf=$name.elf
    bin=$name.bin

    aarch64-linux-gnu-as -o $elf $i
    aarch64-linux-gnu-objcopy -O binary $elf $bin
done

    
