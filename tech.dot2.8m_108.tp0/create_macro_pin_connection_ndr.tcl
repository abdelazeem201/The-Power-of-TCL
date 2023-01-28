##############################################################
# NAME :          create_macro_pin_connection_ndr.tcl
#
# SUMMARY :       create macro pin connection NDR
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists create_macro_pin_connection_ndr.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     None
#
# PROCS USED :    None
#                         
# DESCRIPTION :   create_macro_pin_connection_ndr.tcl is to macro pin connection NDR based on macro pin width
#
# EXAMPLES :      
#
###############################################################
# This script create macro pin connection NDR
set all_macro_cells [get_cells -quiet -physical_context -filter "is_hard_macro==true || is_soft_macro==true"]

foreach_in_collection macro $all_macro_cells {
# find all the macro pins
  set all_pins [get_pins -of_objects $macro]
  foreach_in_collection pin $all_pins {
    foreach_in_collection terminal [get_terminals -of $pin -quiet -filter "layer.name==m4 && (direction==in || direction==out)"] {
      set layer [get_attribute $terminal layer.name]
      set bbox [get_attribute $terminal bbox]
      scan $bbox {{%f %f} {%f %f}} llx lly urx ury
      echo $layer [get_attribute $terminal name]	 
      regexp {m(\d)} $layer match layer_num
      if {[expr $layer_num % 2 ] ==0 } {
        set width [format %.3f [expr $ury-$lly]]
      } else {
        set width [format %.3f [expr $urx-$llx]]
      }


      if {![info exists mwidth($layer)]} {
        lappend mwidth($layer) $width

        create_routing_rule macro_pin_connection_rule_${layer}_${width}  -default_reference_rule -snap_to_track -taper_distance 0 \
          -widths "$layer $width" 
      } else {
        if {[lsearch $mwidth($layer) $width] == -1} {
          create_routing_rule macro_pin_connection_rule_${layer}_${width}  -default_reference_rule -snap_to_track -taper_distance 0 \
            -widths "$layer $width" 

        }
      }
      set connected_net [get_net -of_object $pin]
      set_routing_rule $connected_net -rule macro_pin_connection_rule_${layer}_${width}  -min_routing_layer m3 -max_routing_layer m5
    }
  }

}

