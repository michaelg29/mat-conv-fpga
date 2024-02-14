@echo off
set file="C:/school/Fall 2023/Capstone/repo/mat_mult_fpga/rtl/hdl/saturator/saturator.vhd"
set tb="C:/school/Fall 2023/Capstone/repo/mat_mult_fpga/rtl/sim/GHDL/tb_saturator/tb_saturator.vhd"

ghdl -a %file%
ghdl -a %tb%

ghdl -e testbench_saturator

ghdl -r testbench_saturator --vcd=saturator.vcd --stop-time=750ns

gtkwave saturator.vcd

::pause