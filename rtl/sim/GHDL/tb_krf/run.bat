@echo off
set file="C:\school\Fall 2023\Capstone\repo\mat_mult_fpga\rtl\hdl\kernel_register_file\krf.vhd"
set tb="C:\school\Fall 2023\Capstone\repo\mat_mult_fpga\rtl\sim\GHDL\tb_krf\tb_krf.vhd"

ghdl -a %file%
ghdl -a %tb%

ghdl -e testbench_krf

ghdl -r testbench_krf --vcd=krf.vcd --stop-time=750ns

gtkwave krf.vcd

pause