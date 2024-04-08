@echo off
set math_block="C:/school/Fall 2023/Capstone/repo/mat_mult_fpga/rtl/hdl/math_block/math_block.vhd"
set core="C:/school/Fall 2023/Capstone/repo/mat_mult_fpga/rtl/hdl/core/core.vhd"
set krf="C:/school/Fall 2023/Capstone/repo/mat_mult_fpga/rtl/hdl/kernel_register_file/krf.vhd"
set cluster_feeder="C:/school/Fall 2023/Capstone/repo/mat_mult_fpga/rtl/hdl/cluster_feeder/cluster_feeder.vhd"
set saturator="C:/school/Fall 2023/Capstone/repo/mat_mult_fpga/rtl/hdl/saturator/saturator.vhd"
set cmc="C:/school/Fall 2023/Capstone/repo/mat_mult_fpga/rtl/hdl/cmc/cmc.vhd"
set lsram="C:\school\Fall 2023\Capstone\repo\mat_mult_fpga\rtl\hdl\mem_wrapper\lsram_1024x18_AlteraMF.vhd"
set uram="C:\school\Fall 2023\Capstone\repo\mat_mult_fpga\rtl\hdl\mem_wrapper\usram_64x18_AlteraMF.vhd"

set file="C:/school/Fall 2023/Capstone/repo/mat_mult_fpga/rtl/hdl/cluster/cluster.vhd"
set tb="C:/school/Fall 2023/Capstone/repo/mat_mult_fpga/rtl/sim/GHDL/tb_cluster/tb_cluster.vhd"

ghdl -a %math_block%
ghdl -a %core%
ghdl -a %krf%
ghdl -a %cluster_feeder%
ghdl -a %saturator%
ghdl -a %lsram%
ghdl -a %uram%

ghdl -a %cmc%

ghdl -a %file%
::ghdl -a %tb%

::ghdl -e testbench_cluster

::ghdl -r testbench_cluster --vcd=cluster.vcd --stop-time=750ns

::gtkwave cluster.vcd

::pause