restart
log /tb_top/*
log /tb_top/cluster_feeder_dut/*
log /tb_top/krf_dut/*
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
run 0ps -all
set StdArithNoWarnings 0
set NumericStdNoWarnings 0
run -all

exit
