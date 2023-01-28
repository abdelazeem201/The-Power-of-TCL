##############################################################
# NAME :          ##############################################################
# NAME :          create_rectilinear_routing_blockage.tcl
#
# SUMMARY :       create routing blockages around macro in design
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists create_rectilinear_routing_blockage.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_MIN_ROUTING_LAYER INTEL_MAX_ROUTING_LAYER
#
# PROCS USED :    None
#                         
# DESCRIPTION :   create_rectilinear_routing_blockage.tcl is to create route blockage over the macro to make sure signal routes not too close to the macro boundary. It excludes pin shapes while creating the route blockage so that the router can access the pins.
#
# EXAMPLES :      
#
###############################################################
redirect /dev/null {remove_routing_blockage macro_rb*}

foreach var {INTEL_MAX_ROUTING_LAYER INTEL_MIN_ROUTING_LAYER} {
  global $var
  if { ![info exists $var] } {
    P_msg_error "$proc_name: Missing required var '$var'!  Check 'project_setup.tcl' file!"
    return
  } 
}

set tech [get_techs -quiet -of_objects [current_lib]]
set all_metal_layer_order_list [get_object_name [sort_collection [get_layers -filter {layer_type == interconnect && mask_order >= 0} -of_objects $tech] mask_order]]
set signal_routing_layers [lrange $all_metal_layer_order_list [lsearch -exact $all_metal_layer_order_list $INTEL_MIN_ROUTING_LAYER] [lsearch -exact $all_metal_layer_order_list $INTEL_MAX_ROUTING_LAYER]]

foreach_in_collection i [get_cells -hier -quiet -filter "is_hard_macro==true || is_soft_macro== true"] {
  set macro_name [get_attribute $i full_name]
  #   set poly [get_attribute $i boundary]
  set pin_layers [lsort -unique [get_attr [get_pins -all -of $i -filter "port_type != power && port_type != ground"] layer_name]]
  set top_pin_layer [lindex $pin_layers [expr [llength $pin_layers]-1]]
  set cnt 1

  foreach layer $signal_routing_layers {
    set poly [get_attribute $i boundary]
    if {[sizeof_collection  [get_pins -quiet -all -of $i -filter "layer_name == $layer && port_type != power && port_type != ground"]] > 0 } {
      foreach_in_collection pin [get_pins -all -of $i -filter "layer_name == $layer"] {
        set p [create_poly_rect -boundary  [get_attr [get_shape -of $pin] bbox]]
        set p [resize_polygon -objects $p -size {0.08 0.08}]
        set poly [compute_polygons -operation not -objects1 $poly -objects2 $p]
      }
      if {[get_attr [get_layer $layer] routing_direction] == {vertical}} {
        set poly2 [resize_polygon -objects $poly -size {0.00 0.08}]
      } elseif {[get_attr [get_layer $layer] routing_direction] == {horizontal}} {
        set poly2 [resize_polygon -objects $poly -size {0.08 0.00}]
      }
      foreach_in_collection each [get_attribute $poly2 poly_rects] {
        create_routing_blockage  -net_type "signal clock scan reset tie_high tie_low" -boundary [get_attribute $each point_list] -layers $layer -name macro_rb1_${macro_name}_${layer}_${cnt} -zero_spacing
        incr cnt
      }
    } elseif {[sizeof_collection  [get_pins -quiet -all -of $i -filter "layer_name == $layer"]] == 0 } {
      if {[get_attr [get_layer $layer] routing_direction] == {vertical}} {
        set p [resize_polygon -objects $poly -size {0.00 0.08 }]
      } elseif {[get_attr [get_layer $layer] routing_direction] == {horizontal}} {
        set p [resize_polygon -objects $poly -size {0.08 0.00 }]
      }
      foreach_in_collection each [get_attribute $p poly_rects] {
        create_routing_blockage  -net_type "signal clock scan reset tie_high tie_low" -boundary [get_attribute $each point_list] -layers $layer -name macro_rb2_${macro_name}_${layer}_${cnt} -zero_spacing
        incr cnt
      }
    }
    if {$layer eq $top_pin_layer} break
  }
}


###############################################################################################################

#
# SUMMARY :       create routing blockages around macro in design
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists create_rectilinear_routing_blockage.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_MIN_ROUTING_LAYER INTEL_MAX_ROUTING_LAYER
#
# PROCS USED :    None
#                         
# DESCRIPTION :   create_rectilinear_routing_blockage.tcl is to create route blockage over the macro to make sure signal routes not too close to the macro boundary. It excludes pin shapes while creating the route blockage so that the router can access the pins.
#
# EXAMPLES :      
#
###############################################################
redirect /dev/null {remove_routing_blockage macro_rb*}

foreach var {INTEL_MAX_ROUTING_LAYER INTEL_MIN_ROUTING_LAYER} {
  global $var
  if { ![info exists $var] } {
    P_msg_error "$proc_name: Missing required var '$var'!  Check 'project_setup.tcl' file!"
    return
  } 
}

set tech [get_techs -quiet -of_objects [current_lib]]
set all_metal_layer_order_list [get_object_name [sort_collection [get_layers -filter {layer_type == interconnect && mask_order >= 0} -of_objects $tech] mask_order]]
set signal_routing_layers [lrange $all_metal_layer_order_list [lsearch -exact $all_metal_layer_order_list $INTEL_MIN_ROUTING_LAYER] [lsearch -exact $all_metal_layer_order_list $INTEL_MAX_ROUTING_LAYER]]

foreach_in_collection i [get_cells -hier -quiet -filter "is_hard_macro==true || is_soft_macro== true"] {
  set macro_name [get_attribute $i full_name]
  #   set poly [get_attribute $i boundary]
  set pin_layers [lsort -unique [get_attr [get_pins -all -of $i -filter "port_type != power && port_type != ground"] layer_name]]
  set top_pin_layer [lindex $pin_layers [expr [llength $pin_layers]-1]]
  set cnt 1

  foreach layer $signal_routing_layers {
    set poly [get_attribute $i boundary]
    if {[sizeof_collection  [get_pins -quiet -all -of $i -filter "layer_name == $layer && port_type != power && port_type != ground"]] > 0 } {
      foreach_in_collection pin [get_pins -all -of $i -filter "layer_name == $layer"] {
        set p [create_poly_rect -boundary  [get_attr [get_shape -of $pin] bbox]]
        set p [resize_polygon -objects $p -size {0.08 0.08}]
        set poly [compute_polygons -operation not -objects1 $poly -objects2 $p]
      }
      if {[get_attr [get_layer $layer] routing_direction] == {vertical}} {
        set poly2 [resize_polygon -objects $poly -size {0.00 0.08}]
      } elseif {[get_attr [get_layer $layer] routing_direction] == {horizontal}} {
        set poly2 [resize_polygon -objects $poly -size {0.08 0.00}]
      }
      foreach_in_collection each [get_attribute $poly2 poly_rects] {
        create_routing_blockage  -net_type "signal clock scan reset tie_high tie_low" -boundary [get_attribute $each point_list] -layers $layer -name macro_rb1_${macro_name}_${layer}_${cnt} -zero_spacing
        incr cnt
      }
    } elseif {[sizeof_collection  [get_pins -quiet -all -of $i -filter "layer_name == $layer"]] == 0 } {
      if {[get_attr [get_layer $layer] routing_direction] == {vertical}} {
        set p [resize_polygon -objects $poly -size {0.00 0.08 }]
      } elseif {[get_attr [get_layer $layer] routing_direction] == {horizontal}} {
        set p [resize_polygon -objects $poly -size {0.08 0.00 }]
      }
      foreach_in_collection each [get_attribute $p poly_rects] {
        create_routing_blockage  -net_type "signal clock scan reset tie_high tie_low" -boundary [get_attribute $each point_list] -layers $layer -name macro_rb2_${macro_name}_${layer}_${cnt} -zero_spacing
        incr cnt
      }
    }
    if {$layer eq $top_pin_layer} break
  }
}


###############################################################################################################

