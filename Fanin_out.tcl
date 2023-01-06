#Script to get the intermediate logic between fanout cone of one instance to fanin cone of another instance:

proc intersect_fanin_fanout {x y} {
     if {[get_ports -quiet $x] != ""} {
          set X [all_fanout -from [get_ports $x]]
     } else {
          set X [all_fanout -from [get_pins $x]]
     }
     if {[get_ports -quiet $y] != ""} {
          set Y [all_fanin -to [get_ports $y]]
     } else {
          set Y [all_fanin -to [get_pins $y]]
     }
     set result [remove_from_collection -intersect $X $Y]
     return $result
 }
