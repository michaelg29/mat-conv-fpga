restart
log /tb_top/*
log /tb_top/DUT/*
log /tb_top/DUT/fifo_a/*
log /tb_top/DUT/fifo_b/*
log /tb_top/DUT/core_mac/*

set StdArithNoWarnings 1
set NumericStdNoWarnings 1
run 0ps -all
set StdArithNoWarnings 0
set NumericStdNoWarnings 0
run -all

exit
