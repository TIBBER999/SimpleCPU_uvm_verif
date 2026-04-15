onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group DUT /uvm_top/DUT/clk
add wave -noupdate -expand -group DUT /uvm_top/DUT/reset
add wave -noupdate -expand -group DUT /uvm_top/DUT/s
add wave -noupdate -expand -group DUT /uvm_top/DUT/load
add wave -noupdate -expand -group DUT /uvm_top/DUT/in
add wave -noupdate -expand -group DUT /uvm_top/DUT/out
add wave -noupdate -expand -group DUT /uvm_top/DUT/N
add wave -noupdate -expand -group DUT /uvm_top/DUT/V
add wave -noupdate -expand -group DUT /uvm_top/DUT/Z
add wave -noupdate -expand -group DUT /uvm_top/DUT/w
add wave -noupdate -expand -group DUT /uvm_top/DUT/DP/REGFILE/R0
add wave -noupdate -expand -group DUT /uvm_top/DUT/DP/REGFILE/R1
add wave -noupdate -expand -group DUT /uvm_top/DUT/DP/REGFILE/R2
add wave -noupdate -expand -group DUT /uvm_top/DUT/DP/REGFILE/R3
add wave -noupdate -expand -group DUT /uvm_top/DUT/DP/REGFILE/R4
add wave -noupdate -expand -group DUT /uvm_top/DUT/DP/REGFILE/R5
add wave -noupdate -expand -group DUT /uvm_top/DUT/DP/REGFILE/R6
add wave -noupdate -expand -group DUT /uvm_top/DUT/DP/REGFILE/R7
add wave -noupdate -expand -group TB /uvm_top/bfm/clk
add wave -noupdate -expand -group TB /uvm_top/bfm/reset
add wave -noupdate -expand -group TB /uvm_top/bfm/s
add wave -noupdate -expand -group TB /uvm_top/bfm/load
add wave -noupdate -expand -group TB /uvm_top/bfm/in
add wave -noupdate -expand -group TB /uvm_top/bfm/out
add wave -noupdate -expand -group TB /uvm_top/bfm/N
add wave -noupdate -expand -group TB /uvm_top/bfm/V
add wave -noupdate -expand -group TB /uvm_top/bfm/Z
add wave -noupdate -expand -group TB /uvm_top/bfm/w
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2970 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 148
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
WaveRestoreZoom {2735 ns} {3132 ns}
