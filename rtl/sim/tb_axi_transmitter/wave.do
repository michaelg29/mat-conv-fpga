onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/DUT/i_macclk
add wave -noupdate /tb_top/DUT/i_arst_n
add wave -noupdate /tb_top/DUT/i_accept_w
add wave -noupdate -radix hexadecimal /tb_top/DUT/i_base_addr
add wave -noupdate /tb_top/DUT/i_new_addr
add wave -noupdate -radix hexadecimal /tb_top/DUT/i_w0_wdata
add wave -noupdate /tb_top/DUT/i_w0_wen
add wave -noupdate -radix hexadecimal /tb_top/DUT/i_w1_wdata
add wave -noupdate /tb_top/DUT/i_w1_wen
add wave -noupdate /tb_top/DUT/o_tx_fifo_af
add wave -noupdate -radix hexadecimal /tb_top/DUT/tx_fifo_data
add wave -noupdate /tb_top/DUT/tx_fifo_wen
add wave -noupdate /tb_top/DUT/tx_fifo_slot
add wave -noupdate /tb_top/DUT/u_tx_fifo/WE
add wave -noupdate -radix hexadecimal /tb_top/DUT/u_tx_fifo/DATA
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {40000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 222
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {95652 ps}
