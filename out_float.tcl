# To find floating output pins in a design
proc dangling_out_pins {} {
## To find the output pins which are not connected to any net and are DANGLING ##
set fp [open dangling_out_pins.rpt "w"]
set dangling_out_pins [get_db [get_db pins -if {.net.name == "" && .direction == out}] .name]
puts $fp "###################################################################"
puts $fp "Number of Dangling Output Pins : [llength $dangling_out_pins]"
puts $fp "###################################################################\n"
foreach pin $dangling_out_pins {
      puts $fp $pin
}
close $fp
 
