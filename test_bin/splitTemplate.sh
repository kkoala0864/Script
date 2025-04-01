#! /bin/bash

path=./test_template/
IncludePATH=../IsaModelArch64
rm -rf $path
mkdir -p $path
for i in `grep -Ehro 'ty[^[:space:]]*,' $1`; do 
    keyword=${i%,}
    keyword=${keyword:2}
    filename=$keyword.pl
    echo $filename

    echo ":-['$IncludePATH']." > $path$filename
    awk -v pat="$keyword," '$0 ~ pat { print }' $1 >> $path$filename
    sed -i "s/%test/test/g" $path$filename
    sed -i "s///g" $path$filename
done
