# To find the input pins that are connected to nets but those nets have no drivers 
set fp [open dangling_input_pins.rpt "a"]
set noDriver_input_pins [get_db [get_db pins -if {.net.num_drivers==0 && .direction == in && !.net.is_power && !.net.is_ground}] .name]
puts $fp "\n###################################################################"
puts $fp "Number of No Driver Input Pins : [llength $noDriver_input_pins]"
puts $fp "###################################################################\n"
foreach pin $noDriver_input_pins {
      puts $fp $pin
}
puts "Check the file dangling_input_pins.rpt"
close $fp
}
 
