restart
log /tb_top/*
log /tb_top/DUT/*
log /tb_top/intf/*
log /tb_top/fifo_DUT/dcfifo64x512_0/*
log /tb_top/fifo_DUT/dcfifo64x512_0/DCFIFO_MW/*

set StdArithNoWarnings 1
set NumericStdNoWarnings 1
run 0ps -all
set StdArithNoWarnings 0
set NumericStdNoWarnings 0
run -all

exit
