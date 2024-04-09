onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/DUT/i_macclk
add wave -noupdate /tb_top/DUT/i_rst_n
add wave -noupdate /tb_top/DUT/i_por_n
add wave -noupdate /tb_top/DUT/i_rx_pkt
add wave -noupdate -radix hexadecimal /tb_top/DUT/i_rx_addr
add wave -noupdate -radix hexadecimal /tb_top/DUT/i_rx_data
add wave -noupdate /tb_top/DUT/i_write_blank_ack
add wave -noupdate /tb_top/DUT/o_write_blank_en
add wave -noupdate /tb_top/DUT/o_drop_pkts
add wave -noupdate -radix hexadecimal /tb_top/DUT/i_rdata
add wave -noupdate /tb_top/DUT/i_rvalid
add wave -noupdate /tb_top/DUT/i_state_reg_pls
add wave -noupdate -radix hexadecimal /tb_top/DUT/o_addr
add wave -noupdate /tb_top/DUT/o_ren
add wave -noupdate /tb_top/DUT/o_wen
add wave -noupdate -radix hexadecimal /tb_top/DUT/o_wdata
add wave -noupdate /tb_top/DUT/i_proc_error
add wave -noupdate /tb_top/DUT/i_res_written
add wave -noupdate /tb_top/DUT/o_cmd_valid
add wave -noupdate /tb_top/DUT/o_cmd_err
add wave -noupdate /tb_top/DUT/o_cmd_kern
add wave -noupdate /tb_top/DUT/o_cmd_subj
add wave -noupdate /tb_top/DUT/o_cmd_kern_signed
add wave -noupdate /tb_top/DUT/o_eor
add wave -noupdate /tb_top/DUT/o_prepad_done
add wave -noupdate /tb_top/DUT/o_payload_done
add wave -noupdate /tb_top/DUT/input_fsm_state
add wave -noupdate -radix hexadecimal /tb_top/DUT/cur_cmd_chksum
add wave -noupdate /tb_top/DUT/cur_cmd_status
add wave -noupdate /tb_top/DUT/new_cmd_status
add wave -noupdate /tb_top/DUT/cur_cmd_err
add wave -noupdate /tb_top/DUT/cur_cmd_kern
add wave -noupdate /tb_top/DUT/cur_cmd_subj
add wave -noupdate /tb_top/DUT/cur_cmd_kern_signed
add wave -noupdate /tb_top/DUT/cur_cmd_cmplt
add wave -noupdate /tb_top/DUT/write_blank_ack
add wave -noupdate -radix unsigned /tb_top/DUT/exp_cols
add wave -noupdate -radix unsigned /tb_top/DUT/cur_cols
add wave -noupdate -radix unsigned /tb_top/DUT/cur_pkts
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10164 ps} 0}
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
