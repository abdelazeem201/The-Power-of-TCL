 
# To find floating input pins in a design
proc dangling_input_pins {} {
## To find the input pins which are not connected to any net and are DANGLING ##
set fp [open dangling_input_pins.rpt "w"]
set dangling_input_pins [get_db [get_db pins -if {.net.name == "" && .direction == in}] .name]
puts $fp "###################################################################"
puts $fp "Number of Dangling Input Pins : [llength $dangling_input_pins]"
puts $fp "###################################################################\n"
foreach pin $dangling_input_pins {
      puts $fp $pin
}
close $fp
 
