restart
log /tb_top/*
log /tb_top/DUT/*
log /tb_top/DUT/kernel_rf/*
log /tb_top/DUT/c_mem_c/*
log /tb_top/DUT/core0/*
log /tb_top/DUT/core1/*
log /tb_top/DUT/core2/*
log /tb_top/DUT/core3/*
log /tb_top/DUT/core4/*
log /tb_top/DUT/sat/*
log /tb_top/DUT/cluster_feed/*
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
run 0ps -all
set StdArithNoWarnings 0
set NumericStdNoWarnings 0
run -all

exit
