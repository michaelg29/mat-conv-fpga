restart
log /tb_top/*
log /tb_top/DUT/*
log /tb_top/DUT/u_tx_fifo/*

set StdArithNoWarnings 1
set NumericStdNoWarnings 1
run 0ps -all
set StdArithNoWarnings 0
set NumericStdNoWarnings 0
run -all

exit
