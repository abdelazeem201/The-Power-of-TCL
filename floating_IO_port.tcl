# To find floating IO ports in the design 
proc floating_io_ports {} {
set fp [open floating_io_ports.rpt "w"] 
set in [get_db [get_db ports -if {.direction == in && .net.num_loads == 0}] .name]
set out [get_db [get_db ports -if {.direction == out && .net.num_drivers == 0}] .name]     
      puts $fp "## TOTAL FLOATING IO PORTS : [expr [llength $in] + [llength $out]] \n"
      puts $fp "## FLOATING INPUT PORTS : [llength $in] ##\n"
      puts $fp $in
      puts $fp "\n## FLOATING OUTPUT PORTS : [llength $out] ##\n"
      puts $fp $out 
close $fp 
puts "Please check floating_io_ports.rpt\n"
}
