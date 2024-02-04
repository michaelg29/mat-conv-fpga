@echo off
set file="C:/school/Fall 2023/Capstone/repo/mat_mult_fpga/rtl/hdl/math_block/math_block.vhd"
set tb="C:/school/Fall 2023/Capstone/repo/mat_mult_fpga/rtl/sim/GHDL/tb_math_block/tb_math_block.vhd"

ghdl -a %file%
ghdl -a %tb%

ghdl -e testbench_math_block

ghdl -r testbench_math_block --vcd=math_block.vcd --stop-time=750ns

gtkwave math_block.vcd

pause