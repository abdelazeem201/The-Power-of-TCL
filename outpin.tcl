# To find the output pins that are connected to nets but those nets have no load
set fp [open dangling_out_pins.rpt "a"]
set noLoad_out_pins [get_db [get_db pins -if {.net.num_loads==0 && .direction == out && !.net.is_power && !.net.is_ground}] .name]
puts $fp "\n###################################################################"
puts $fp "Number of No Load Output Pins : [llength $noLoad_out_pins]"
puts $fp "###################################################################\n"
foreach pin $noLoad_out_pins {
      puts $fp $pin
}
puts "Check the file dangling_out_pins.rpt"
close $fp
}
 
