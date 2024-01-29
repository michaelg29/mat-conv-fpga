onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/DUT/i_macclk
add wave -noupdate /tb_top/DUT/i_rst_n
add wave -noupdate -radix hexadecimal /tb_top/DUT/i_wdata
add wave -noupdate /tb_top/DUT/i_waddr
add wave -noupdate /tb_top/DUT/i_new_pkt
add wave -noupdate /tb_top/DUT/i_write_blank_ack
add wave -noupdate /tb_top/DUT/o_write_blank_en
add wave -noupdate /tb_top/DUT/o_ignore
add wave -noupdate /tb_top/DUT/i_read_status
add wave -noupdate /tb_top/DUT/o_cmd_data
add wave -noupdate /tb_top/DUT/o_cmd_data_id
add wave -noupdate /tb_top/DUT/o_cmd_data_valid
add wave -noupdate /tb_top/DUT/o_eor
add wave -noupdate /tb_top/DUT/o_cmd_kern
add wave -noupdate /tb_top/DUT/o_cmd_subj
add wave -noupdate /tb_top/DUT/o_cmd_valid
add wave -noupdate /tb_top/DUT/o_cmd_err
add wave -noupdate /tb_top/DUT/input_fsm_state
add wave -noupdate -radix hexadecimal /tb_top/DUT/cur_cmd_chksum
add wave -noupdate -radix hexadecimal /tb_top/DUT/cur_cmd_status
add wave -noupdate -radix hexadecimal /tb_top/DUT/new_cmd_chksum
add wave -noupdate -radix hexadecimal /tb_top/DUT/new_cmd_status
add wave -noupdate /tb_top/DUT/cur_cmd_kern
add wave -noupdate /tb_top/DUT/cur_cmd_subj
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {11855 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 273
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
WaveRestoreZoom {0 ps} {43401 ps}
