# Specify the path to your synthesized netlist
set synthesized_netlist "path/to/your/synthesized_netlist.v"

# Specify the name of your synthesized library
set synthesized_library "your_synthesized_library"

# Specify the report file where latch information will be stored
set report_file "latch_report.txt"

# Start Design Compiler
dc_shell -no_gui -x "set link_library $synthesized_library; set link_design $synthesized_netlist;"

# Analyze the design to obtain latch information
analyze -format verilog $synthesized_netlist
elaborate $synthesized_netlist

# Report the number of latches
set num_latches [get_lib_cells -hierarchical -quiet -filter {cell_type =~ *latch*}]
set num_latches_count [llength $num_latches]

# Write the latch information to the report file
set report_handle [open $report_file "w"]
puts $report_handle "Number of Latches: $num_latches_count"
puts $report_handle "List of Latches:"
foreach latch $num_latches {
    puts $report_handle $latch
}
close $report_handle

# Exit Design Compiler
exit
