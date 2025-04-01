#! /bin/bash

for i in `ls ./$1*/F*/*.elf`; do
    name=${i%.elf}
    BaseName=$(basename $name)
    trace=$name.trace
    echo $i
    if [ ! -f $trace ]; then
	echo $trace
        module=' -m /home/autotest/ARM/FastModelsPortfolio_8.1/examples/FVP_VE/Build_Cortex-A57x1/Linux64-Release-GCC-4.1/cadi_system_Linux64-Release-GCC-4.1.so'
        undefined_handler=' -a ./instruction/undefined_instr_exception_handler/undefined_handler_0x20000.elf'
        attribute=' --start 0x00000000 --parameter TRACE.TarmacTraceV8.trace_instructions=true --parameter TRACE.TarmacTraceV8.trace_core_registers=true --parameter TRACE.TarmacTraceV8.trace_cp15=true --parameter TRACE.TarmacTraceV8.trace_vfp=true --parameter TRACE.TarmacTraceV8.trace_events=true --parameter TRACE.TarmacTraceV8.trace_loads_stores=true'
        output_name=' --parameter TRACE.TarmacTraceV8.trace-file='$trace
        exe_command=model_shell$undefined_handler' -a '$i$module$output_name$attribute
        echo $exe_command
	$exe_command
        #echo $trace
    fi 
done


