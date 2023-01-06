# To find and delete nets with no fanout (Dangling Nets)
proc dangling_nets {} {
set fp [open dangling_nets.rpt "w"]
set dangling_nets [get_db [get_db hnets -if {.num_loads  == 0}] .name]
puts "Dangling Nets being deleted will be reported in dangling_nets.rpt​\n"
puts $fp "###################################################################"
puts $fp "Number of Dangling Nets : [llength $dangling_nets]"
puts $fp "###################################################################\n"
      foreach net $dangling_nets {
            puts $fp "Dangling Net getting deleted  :\t$net"
            delete_nets $net
      }
close $fp
}
