onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/aclk_dut
add wave -noupdate /tb_top/macclk_dut
add wave -noupdate /tb_top/arst_n
add wave -noupdate /tb_top/wdata
add wave -noupdate /tb_top/wen
add wave -noupdate /tb_top/DUT/dcfifo64x512_0/rdempty
add wave -noupdate /tb_top/DUT/dcfifo64x512_0/wrempty
add wave -noupdate /tb_top/aempty
add wave -noupdate /tb_top/empty
add wave -noupdate /tb_top/ren
add wave -noupdate /tb_top/q
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {322222 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 432
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
WaveRestoreZoom {273792 ps} {356763 ps}
