restart
log /tb_top/*
log /tb_top/cmc_dut/*
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
run 0ps -all
set StdArithNoWarnings 0
set NumericStdNoWarnings 0
run -all

exit
