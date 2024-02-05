onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/w_bclk_dut
add wave -noupdate /tb_top/w_macclk_dut
add wave -noupdate /tb_top/rst_n
add wave -noupdate /tb_top/DUT/aempty
add wave -noupdate /tb_top/DUT/bempty
add wave -noupdate /tb_top/i_clk
add wave -noupdate /tb_top/i_pixels
add wave -noupdate /tb_top/i_kernels
add wave -noupdate /tb_top/i_sub
add wave -noupdate /tb_top/oreg
add wave -noupdate /tb_top/kreg1
add wave -noupdate /tb_top/kreg2
add wave -noupdate /tb_top/DUT/i_sub
add wave -noupdate /tb_top/DUT/o_res
add wave -noupdate /tb_top/DUT/MAC*
add wave -noupdate /tb_top/DUT/o_res
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {55726 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 224
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
WaveRestoreZoom {0 ps} {92434 ps}
