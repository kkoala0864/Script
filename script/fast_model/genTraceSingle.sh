#!/bin/sh

model_shell64 -a ./instruction/undefined_instr_exception_handler/undefined_handler.elf -a ./instruction/SIMD_and_Floating_Point/test.elf -m /home/autotest/ARM/FastModelsPortfolio_8.1/examples/FVP_VE/Build_Cortex-A57x1/Linux64-Release-GCC-4.1/cadi_system_Linux64-Release-GCC-4.1.so \
--start 0x00000000 \
--parameter TRACE.TarmacTraceV8.trace-file=./instruction/SIMD_and_Floating_Point/test.trace \
--parameter TRACE.TarmacTraceV8.trace_instructions=true \
--parameter TRACE.TarmacTraceV8.trace_core_registers=true \
--parameter TRACE.TarmacTraceV8.trace_cp15=true \
--parameter TRACE.TarmacTraceV8.trace_vfp=true \
--parameter TRACE.TarmacTraceV8.trace_events=true \
--parameter TRACE.TarmacTraceV8.trace_loads_stores=true
