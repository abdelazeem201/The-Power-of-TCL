# To report floating Instances in a design
proc floating_instances {} {
    set fp [open floating_instances.rpt "w"]
    foreach inst [get_db insts .name] {  
      foreach pin [get_db inst:$inst .pins.name] { 
            if {[get_db pin:$pin -if {.direction=="in" && .net.name != "" && .net.num_drivers==0 && !.net.is_power && !.net.is_ground}] != ""} {
            puts $fp "Instance $inst : $pin is floating"}             
              if {[get_db pin:$pin -if {.direction=="out" && .net.name != "" && .net.num_loads==0 && !.net.is_power && !.net.is_ground}] != ""} {
            puts  $fp "Instance $inst : $pin is floating"}
                }
         }
close $fp
puts "Please check floating_instances.rpt"
}
 
