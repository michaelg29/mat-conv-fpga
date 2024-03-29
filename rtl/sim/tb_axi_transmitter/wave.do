onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/DUT/i_macclk
add wave -noupdate /tb_top/DUT/i_aclk
add wave -noupdate /tb_top/DUT/i_arst_n
add wave -noupdate /tb_top/DUT/i_accept_w
add wave -noupdate -radix hexadecimal /tb_top/DUT/i_base_addr
add wave -noupdate /tb_top/DUT/i_new_addr
add wave -noupdate -radix hexadecimal /tb_top/DUT/i_w0_wdata
add wave -noupdate /tb_top/DUT/i_w0_wen
add wave -noupdate -radix hexadecimal /tb_top/DUT/i_w1_wdata
add wave -noupdate /tb_top/DUT/i_w1_wen
add wave -noupdate /tb_top/DUT/o_tx_fifo_af
add wave -noupdate /tb_top/DUT/o_tx_fifo_db
add wave -noupdate /tb_top/DUT/o_tx_fifo_sb
add wave -noupdate /tb_top/DUT/o_tx_fifo_oflow
add wave -noupdate /tb_top/DUT/o_tx_fifo_uflow
add wave -noupdate /tb_top/DUT/o_tx_axi_awid
add wave -noupdate -radix hexadecimal /tb_top/DUT/o_tx_axi_awaddr
add wave -noupdate /tb_top/DUT/o_tx_axi_awlen
add wave -noupdate /tb_top/DUT/o_tx_axi_awsize
add wave -noupdate /tb_top/DUT/o_tx_axi_awburst
add wave -noupdate /tb_top/DUT/o_tx_axi_awlock
add wave -noupdate /tb_top/DUT/o_tx_axi_awcache
add wave -noupdate /tb_top/DUT/o_tx_axi_awprot
add wave -noupdate /tb_top/DUT/o_tx_axi_awvalid
add wave -noupdate /tb_top/DUT/i_tx_axi_awready
add wave -noupdate -radix hexadecimal /tb_top/DUT/o_tx_axi_wdata
add wave -noupdate /tb_top/DUT/o_tx_axi_wlast
add wave -noupdate /tb_top/DUT/o_tx_axi_wvalid
add wave -noupdate /tb_top/DUT/i_tx_axi_wready
add wave -noupdate /tb_top/DUT/i_tx_axi_bid
add wave -noupdate /tb_top/DUT/i_tx_axi_bresp
add wave -noupdate /tb_top/DUT/i_tx_axi_bvalid
add wave -noupdate /tb_top/DUT/o_tx_axi_bready
add wave -noupdate -radix hexadecimal /tb_top/DUT/tx_fifo_data
add wave -noupdate /tb_top/DUT/tx_fifo_wen
add wave -noupdate /tb_top/DUT/tx_fifo_slot
add wave -noupdate -radix unsigned /tb_top/DUT/payload_fifo_count
add wave -noupdate /tb_top/DUT/payload_read
add wave -noupdate /tb_top/DUT/payload_data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {17754 ps} 0}
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
