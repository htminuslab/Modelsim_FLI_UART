@echo off
del *.bak *.o *.dll

@REM Build DLL
gcc -g -c -Wall -I. -I%MTI_HOME%/include src\comport.c
gcc -g -c -Wall -I. -I%MTI_HOME%/include src\uart_fli.c
gcc -shared -lm -o  uart_fli.dll uart_fli.o comport.o -L%MTI_HOME%/win64pe -lmtipli


@REM Compile VHDL Design
vcom -quiet -2008 rtl/redge.vhd
vcom -quiet -2008 rtl/uart_fli.vhd
vcom -quiet -2008 rtl/uart_rtl.vhd
vcom -quiet -2008 rtl/top_struct.vhd

@REM compile Testbench
vcom -quiet -2008 testbench/top_tester_rtl.vhd
vcom -quiet -2008 testbench/top_tb_struct.vhd

@REM Run Modelsim in batch mode (fastest, see user guide)
vsim -batch -stats=none -quiet top_tb -do "nolog -r *;set StdArithNoWarnings 1; set NumericStdNoWarnings 1; run -all; quit -f"
@REM vsim -c -quiet top_tb -do "nolog -r *;set StdArithNoWarnings 1; set NumericStdNoWarnings 1; run -all; quit -f"
@REM vsim -quiet top_tb -do "nolog -r *;set StdArithNoWarnings 1; set NumericStdNoWarnings 1; run -all; quit -f"