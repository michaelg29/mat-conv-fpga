restart
log /tb_top/*
log /tb_top/u_fifo_sync_if/*
log /tb_top/DUT/*
log /tb_top/DUT2/*
log /tb_top/DUT2/FIFO/*

set StdArithNoWarnings 1
set NumericStdNoWarnings 1
run 0ps -all
set StdArithNoWarnings 0
set NumericStdNoWarnings 0
run -all

exit
