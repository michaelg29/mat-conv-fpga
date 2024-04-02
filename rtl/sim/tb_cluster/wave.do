onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/i_clk
add wave -noupdate /tb_top/*
add wave -noupdate /tb_top/DUT/i_new_pkt
add wave -noupdate /tb_top/DUT/i_newrow
add wave -noupdate /tb_top/DUT/i_is_subj
add wave -noupdate /tb_top/DUT/i_is_kern
add wave -noupdate /tb_top/DUT/i_discont
add wave -noupdate /tb_top/DUT/i_cmd_kern_signed
add wave -noupdate /tb_top/DUT/i_pkt
add wave -noupdate /tb_top/DUT/o_pixel
add wave -noupdate /tb_top/DUT/cluster_feed/i_sel
add wave -noupdate /tb_top/DUT/cluster_feed/i_new
add wave -noupdate /tb_top/DUT/cluster_feed/i_pixel*
add wave -noupdate /tb_top/DUT/cluster_feed/o_pixel*
add wave -noupdate /tb_top/DUT/core0/i_s*
add wave -noupdate /tb_top/DUT/core0/o_res
add wave -noupdate /tb_top/DUT/c_mem_c/i_addr
add wave -noupdate /tb_top/DUT/c_mem_c/i_core*
add wave -noupdate /tb_top/DUT/c_mem_c/o_core*

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
