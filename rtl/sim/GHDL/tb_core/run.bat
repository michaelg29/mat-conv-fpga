@echo off
set component1="C:/school/Fall 2023/Capstone/repo/mat_mult_fpga/rtl/hdl/math_block/math_block.vhd"
set file="C:/school/Fall 2023/Capstone/repo/mat_mult_fpga/rtl/hdl/core/core.vhd"
set tb="C:/school/Fall 2023/Capstone/repo/mat_mult_fpga/rtl/sim/GHDL/tb_core/tb_core.vhd"

ghdl -a %component1%
ghdl -a %file%
ghdl -a %tb%

ghdl -e testbench_core

ghdl -r testbench_core --vcd=core.vcd --stop-time=750ns

gtkwave core.vcd

::pause