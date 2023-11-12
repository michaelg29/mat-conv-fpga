onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/DUT/i_rst_n
add wave -noupdate /tb_top/DUT/i_rclk
add wave -noupdate /tb_top/DUT/i_ren
add wave -noupdate /tb_top/DUT/o_rdata
add wave -noupdate /tb_top/DUT/o_empty
add wave -noupdate /tb_top/DUT/o_rvalid
add wave -noupdate /tb_top/DUT/o_rerr
add wave -noupdate /tb_top/DUT/i_wclk
add wave -noupdate /tb_top/DUT/i_wdata
add wave -noupdate /tb_top/DUT/i_wen
add wave -noupdate /tb_top/DUT/o_full
add wave -noupdate /tb_top/DUT/o_wvalid
add wave -noupdate /tb_top/DUT/o_werr
add wave -noupdate /tb_top/DUT/mem
add wave -noupdate /tb_top/DUT/head
add wave -noupdate /tb_top/DUT/tail
add wave -noupdate /tb_top/DUT/count
add wave -noupdate /tb_top/DUT/wcount
add wave -noupdate /tb_top/DUT/rcount
add wave -noupdate /tb_top/DUT/empty
add wave -noupdate /tb_top/DUT/full
add wave -noupdate /tb_top/DUT/wgrant
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {52468 ps} 0}
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
WaveRestoreZoom {5 ns} {105 ns}
