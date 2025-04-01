#! /bin/bash

mkdir -p test_binary
for i in `ls $1*.pl`; do
    test_binary=${i%.pl}
    filename=$(basename $test_binary)
    swipl -f $i -g "execAll('result.s', 1)." -t halt
    ./compile.sh
    ./newdir.sh $filename ./test_binary/

done
