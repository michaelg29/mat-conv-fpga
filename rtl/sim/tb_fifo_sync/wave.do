onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/DUT2/i_clk
add wave -noupdate /tb_top/DUT2/i_rst_n
add wave -noupdate -radix hexadecimal /tb_top/DUT2/i_wdata
add wave -noupdate /tb_top/DUT2/i_wen
add wave -noupdate /tb_top/DUT2/i_ren
add wave -noupdate -radix hexadecimal /tb_top/DUT2/o_rdata
add wave -noupdate /tb_top/DUT2/o_empty
add wave -noupdate /tb_top/DUT2/o_full
add wave -noupdate /tb_top/DUT2/o_rvalid
add wave -noupdate /tb_top/DUT2/o_rerr
add wave -noupdate /tb_top/DUT2/o_wvalid
add wave -noupdate /tb_top/DUT2/o_werr
add wave -noupdate /tb_top/DUT2/cnt
add wave -noupdate /tb_top/DUT2/max_idx
add wave -noupdate /tb_top/DUT2/ren_int
add wave -noupdate /tb_top/DUT2/empty_int
add wave -noupdate -radix hexadecimal /tb_top/DUT2/rdata_int
add wave -noupdate /tb_top/DUT2/rvalid_int
add wave -noupdate -radix hexadecimal /tb_top/DUT2/rdata_buf
add wave -noupdate /tb_top/DUT2/rdata_rdy
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {61507 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
WaveRestoreZoom {44378 ps} {94378 ps}
