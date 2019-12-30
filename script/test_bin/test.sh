#! /bin/bash


rm result
for i in `ls *.xml`; do
    name=${i%.xml}
    trace=$name.trace
    csim_v8 --file=$i --trace=$trace &> $name.log
    if ! grep -q "Test Case Pass" $name.log
    then
	echo "$name Test Failed!" >> result
    else
	echo "$name Test Pass!" >> result
    fi
done

