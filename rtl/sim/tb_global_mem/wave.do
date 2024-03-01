onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/w_aclk_dut
add wave -noupdate /tb_top/w_macclk_dut
add wave -noupdate /tb_top/rst_n
add wave -noupdate /tb_top/A_ADDR
add wave -noupdate /tb_top/A_DIN
add wave -noupdate /tb_top/A_WEN
add wave -noupdate /tb_top/A_REN
add wave -noupdate /tb_top/A_DOUT_REN
add wave -noupdate /tb_top/A_DOUT
add wave -noupdate /tb_top/A_SB_CORRECT
add wave -noupdate /tb_top/A_DB_DETECT
add wave -noupdate /tb_top/B_ADDR
add wave -noupdate /tb_top/B_DIN
add wave -noupdate /tb_top/B_WEN
add wave -noupdate /tb_top/B_REN
add wave -noupdate /tb_top/B_DOUT_REN
add wave -noupdate /tb_top/B_DOUT
add wave -noupdate /tb_top/B_SB_CORRECT
add wave -noupdate /tb_top/B_DB_DETECT
add wave -noupdate /tb_top/C_ADDR
add wave -noupdate /tb_top/C_DIN
add wave -noupdate /tb_top/C_WEN
add wave -noupdate /tb_top/DUT_usram/DUT/rden_a
add wave -noupdate /tb_top/DUT_usram/DUT/address_a
add wave -noupdate /tb_top/DUT_usram/DUT/q_a
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {132000 ps} 0}
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
WaveRestoreZoom {64625 ps} {164625 ps}
