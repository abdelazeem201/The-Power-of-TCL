##############################################################################
# Script: io_placement.tcl
# Description : Places ports in the design
# List of procs used by this script
# 1. P_msg_info
# 2. P_msg_warn

#############################################
# This is a template/example constraint
#############################################

set_block_pin_constraints -self -allowed_layers $INTEL_PORT_LAYERS -corner_keepout_num_tracks 9 -pin_spacing 1 -hard_constraints {layer spacing}

####################################################################
# Make the terminal with min length
# This is to avoid DRC violation if the terminal ends up floating
####################################################################

foreach {metal stub} $INTEL_TERM_LENGTH {
  set term_length($metal) $stub
}

############################################
# Find ports to be placed
############################################

set all_sig_ports [get_ports -quiet -filter {port_type == signal}]
set new_ports {}

# If DEF/TCL was read-in -> Checking if all the ports were placed correctly, if not add them to list of ports to be placed
if {[info exists INTEL_FP_INPUT] && ($INTEL_FP_INPUT == "DEF" || $INTEL_FP_INPUT == "FP_TCL")} {
  foreach_in_collection port $all_sig_ports {
    set layer [get_attribute $port layer]
    set physical_status [get_attribute $port physical_status]

    if {$physical_status == "unplaced"} {
      P_msg_warn "Port [get_object_name $port] is not placed. Placing it"
      append_to_collection new_ports $port
    } else {
      set bbox [get_attribute [get_terminals -of_objects $port] bbox]
      scan $bbox {{%f %f} {%f %f}} t_llx t_lly t_urx t_ury
	echo "Attributes of port [get_object_name $port]: [get_object_name $layer] $bbox $physical_status"
	if { [regexp {(^m)(.*)} [get_object_name $layer]] && $physical_status == "placed"  } {
        set_placement_status fixed $port
        P_msg_warn "Port [get_object_name $port] is placed but doesn't have fixed attribute. Fixing it"
      }
    }
  }
  P_msg_info "Placing [sizeof_collection $new_ports] unplaced I/O Ports ..."
} else {
  set new_ports $all_sig_ports
  P_msg_info "Placing all [sizeof_collection $new_ports] I/O Ports ..."
}

###############################################
# Place ports based on list of ports created
###############################################

if { [sizeof_collection $new_ports] > 0 } {
  #place_opt -to initial_place
  place_pins -ports $new_ports -self

  foreach_in_collection port $new_ports {
    set acc_dir [get_attribute [get_terminals -of_objects $port] access_direction]
    set lyr_name [get_object_name [get_attribute [get_terminals -of_objects $port] layer]]
    scan [get_attribute [get_terminals -of_objects $port] bbox] {{%f %f} {%f %f}} t_llx t_lly t_urx t_ury
    #puts "term: [get_object_name $port] t_llx: $t_llx t_lly: $t_lly t_urx: $t_urx t_ury: $t_ury layer: $lyr_name direction: $acc_dir \n"

    set term_shp [get_shapes -of_objects [get_terminals -of_objects $port]]
    switch -- $acc_dir {
      left {
        set newx [expr $t_llx + $term_length($lyr_name)]
        set_attribute $term_shp bbox "{$t_llx $t_lly} {$newx $t_ury}"
      }
      right {
        set newx [expr $t_urx - $term_length($lyr_name)]
        set_attribute $term_shp bbox "{$newx $t_lly} {$t_urx $t_ury}"
      }
      top {
        set newy [expr $t_ury - $term_length($lyr_name)]
        set_attribute $term_shp bbox "{$t_llx $newy} {$t_urx $t_ury}"
      }
      bottom {
        set newy [expr $t_lly + $term_length($lyr_name)]
        set_attribute $term_shp bbox "{$t_llx $t_lly} {$t_urx $newy}"
      }
    }
  }
  snap_objects [get_terminals -of_objects $new_ports]
  set_placement_status fixed $new_ports
  # Removing temporary standard cell placement created above
  reset_placement
}


