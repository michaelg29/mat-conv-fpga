onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/i_clk
add wave -noupdate /tb_top/core_dut0/*
add wave -noupdate /tb_top/core_dut0/MAC2/*
add wave -noupdate /tb_top/i_pixels
add wave -noupdate /tb_top/pixels_delay
add wave -noupdate /tb_top/i_pixel_cores
add wave -noupdate /tb_top/o_res
add wave -noupdate /tb_top/oreg
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
