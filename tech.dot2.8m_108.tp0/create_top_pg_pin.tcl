##############################################################
# NAME :          create_top_pg_pin.tcl
#
# SUMMARY :       create terminals for top pg pins in frame view
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists create_top_pg_pin.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_MAX_PG_LAYER
#
# PROCS USED :    None
#                         
# DESCRIPTION :   create_top_pg_pin.tcl is to create terminals for top pg pins in frame view for next level PG connections
#
# EXAMPLES :      
#
###############################################################

# NOTE: Only P/G shapes of stripe shape use are considered for adding terminals, i.e. P/G shapes created using compile_pg or create_pg_* commands, not user_route, macro_pin_connect, lib_cell_pin_connect or other shape uses.
# ASSERT: $INTEL_MAX_PG_LAYER is top-most layer used in design. i.e. no shape of higher layer exist.

proc create_top_pg_pin args {
  parse_proc_arguments -args $args opts
  set proc_name [namespace tail [lindex [info level 0] 0]]
  set force_opt [info exists opts(-force)]
  set verb_opt [info exists opts(-verbose)]

  foreach proc {P_msg_info P_msg_warn P_msg_error} {
    if { [info procs $proc] == {} } {
      echo "#ERROR-MSG: $proc_name: Missing required proc '$proc'!  Check 'procs.tcl' file!"
      return
    }
  }
  # ASSERT: $INTEL_MAX_PG_LAYER is valid route layer.
  foreach var {INTEL_MAX_PG_LAYER} {
    global $var
    if { ![info exists $var] } {
      P_msg_error "$proc_name: Missing required var '$var'!  Check 'project_setup.tcl' file!"
      return
    } elseif { $verb_opt } {
      P_msg_info "$proc_name: $var = [set $var] ;"
    }
  }
  if { [get_app_var synopsys_program_name] != {icc2_shell} } {
    P_msg_error "$proc_name: Detect incorrect tool '[get_app_var synopsys_program_name]'!  Expect ICC2 'icc2_shell'!"
    return
  } elseif { [get_app_option_value -name shell.common.product_version] < {K-2015.06-SP1} } {
    P_msg_error "$proc_name: Detect unsupported ICC2 version '[get_app_option_value -name shell.common.product_version]'!  Expect 'K-2015.06-SP1' or newer!"
    return
  }

  set err_num 0
  if { [sizeof_collection [current_lib -quiet]] == 0 } {
    incr err_num
    P_msg_error "$proc_name: Failed to find any currently opened lib!  Expect lib opened!"
  } elseif { [sizeof_collection [set tech [get_techs -quiet -of_objects [current_lib]]]] == 0 } {
    incr err_num
    P_msg_error "$proc_name: Failed to find any tech in current lib '[get_object_name [current_lib]]'!  Expect technology set in lib!"
  } elseif { [sizeof_collection [current_block -quiet]] == 0 } {
    incr err_num
    P_msg_error "$proc_name: Failed to find any currently opened block from current lib '[get_object_name [current_lib]]'!  Expect block opened!"
  } elseif { [llength [set die_bndry [get_attribute -quiet -objects [current_block] -name boundary]]] == 0 } {
    incr err_num
    P_msg_error "$proc_name: Failed to find any boundary for current block '[get_object_name [current_block]]' from lib '[get_object_name [current_lib]]'!  Expect boundary set for block!"
  }
  if { $err_num > 0 } {
    P_msg_error "$proc_name: Abort due to $err_num errors above!"
    return
  }

  set tl_pg_term_prefix TTM_
  # Use format to workaround floating imprecision for comparison & avoid scientific notation for near-zero number.
  set fmt "%.[expr entier( log10 ( [get_attribute -objects $tech -name length_precision] ) ) + 1]f"

  set all_rt_lyr_sort_list [get_object_name [sort_collection [get_layers -filter {layer_type == interconnect && mask_order >= 0 && mask_name =~ metal*} -of_objects $tech] mask_order]]
  # Sanity check to ensure $INTEL_MAX_PG_LAYER is valid route layer.
  if { [lsearch -exact $all_rt_lyr_sort_list $INTEL_MAX_PG_LAYER] < 0 } {
    incr err_num
    P_msg_error "$proc_name: Invalid INTEL_MAX_PG_LAYER '$INTEL_MAX_PG_LAYER'!  Expect 1 from '$all_rt_lyr_sort_list'!"
  }
  if { $err_num > 0 } {
    P_msg_error "$proc_name: Abort due to $err_num errors above!"
    return
  }
  set top_pg_lyr_name $INTEL_MAX_PG_LAYER

  set tl_pg_shps [get_shapes -quiet -filter "layer_name == $top_pg_lyr_name && ( net_type == ground || net_type == power ) && shape_use == stripe" *]
  if { [sizeof_collection $tl_pg_shps] == 0 } {
    incr err_num
    P_msg_error "$proc_name: Failed to find any P/G shape on layer '$top_pg_lyr_name' to create terminal  Expect terminals exist!"
  }
  if { $err_num > 0 } {
    P_msg_error "$proc_name: Abort due to $err_num errors above!"
    return
  }

  set tl_pg_nets [sort_collection [get_nets -of_objects $tl_pg_shps] {net_type full_name}]
  foreach_in_collection net $tl_pg_nets {
    # Somehow, get_ports needs -physical_context option for -of_objects of P/G nets, yet unnecessary for signal nets.
    set port [get_ports -quiet -physical_context -of_objects $net]
    if { [sizeof_collection $port] == 0 } {
      incr err_num
      P_msg_error "$proc_name: Missing connecting port for P/G net '[get_object_name $net]' of type '[get_attribute -objects $net -name net_type]' for P/G shapes on layer '$top_pg_lyr_name'!  Expect connecting port exists!"
    } elseif { [sizeof_collection $port] > 1 } {
      #incr err_num
      #P_msg_error "$proc_name: Found multiple ([sizeof_collection $port]) connecting ports '[get_object_name $port]' for P/G net '[get_object_name $net]' of type '[get_attribute -objects $net -name net_type]' for P/G shapes on layer '$top_pg_lyr_name'!  Expect single connecting port only!"
    }
  }
  if { $err_num > 0 } {
    P_msg_error "$proc_name: Abort due to $err_num errors above!"
    return
  }

  if { [sizeof_collection [set beyond_lyr_pg_shps [get_shapes -quiet -filter "layer.mask_order > [get_attribute -objects [get_layers $top_pg_lyr_name] -name mask_order] && ( net_type == ground || net_type == power ) && shape_use == stripe" *]]] > 0 } {
    # TODO: If should treat as error instead?
    P_msg_warn "$proc_name: Detect [sizeof_collection $beyond_lyr_pg_shps] P/G shapes above INTEL_MAX_PG_LAYER '$top_pg_lyr_name' on layers '[get_object_name [sort_collection [get_layers [lsort -unique [get_attribute -objects $beyond_lyr_pg_shps -name layer_name]]] mask_order]]' of nets '[get_object_name [sort_collection [get_nets -of_objects $beyond_lyr_pg_shps] {net_type full_name}]]'!"
  }

  if { [sizeof_collection [set old_tl_pg_terms [get_terminals -quiet -filter "layer.full_name == $top_pg_lyr_name && ( port.port_type == ground || port.port_type == power )" $tl_pg_term_prefix${top_pg_lyr_name}_*]]] > 0 } {
    foreach_in_collection port [sort_collection [get_ports -of_objects $old_tl_pg_terms] {port_type full_name}] {
      if { [sizeof_collection [set old_tl_port_terms [filter_collection $old_tl_pg_terms "port.full_name == [get_object_name $port]"]]] > 0 } {
        if { $force_opt } {
          # Delete shapes of terminals also delete the associated terminals.  However, delete terminals won't delete the associated shapes.
          #[remove_terminals $old_tl_port_terms]
          P_msg_warn "$proc_name: Deleted pre-existing [remove_shapes [get_shapes -of_objects $old_tl_port_terms]] P/G terminals on layer '$top_pg_lyr_name' of port '[get_object_name $port]' of type '[get_attribute -objects $port -name port_type]'!"
        } else {
          incr err_num
          P_msg_error "$proc_name: Detect pre-existing [sizeof_collection $old_tl_port_terms] P/G terminals on layer '$top_pg_lyr_name' of port '[get_object_name $port]' of type '[get_attribute -objects $port -name port_type]'!  Must delete them before creating new ones again or use '-force' option!"
        }
      }
    }
  }
  if { $err_num > 0 } {
    P_msg_error "$proc_name: Abort due to $err_num errors above!"
    return
  }

  unset err_num
  unset tech
  unset all_rt_lyr_sort_list
  unset beyond_lyr_pg_shps
  unset old_tl_pg_terms
  unset -nocomplain old_tl_port_terms

  # ASSERT: Only $proc_name, $verb_opt, $tl_pg_term_prefix, $fmt, $top_pg_lyr_name & tl_pg_shps vars are required hereafter.

  set orig_val(snap_setting-enabled) [get_snap_setting -enabled]
  set_snap_setting -enabled 0

  set tl_pg_ns_shps [filter_collection $tl_pg_shps {owner.object_class == net}]
  set tl_pg_ns_nets [sort_collection [get_nets -of_objects $tl_pg_ns_shps] {net_type full_name}]
  P_msg_info "$proc_name: Creating P/G terminals for [sizeof_collection $tl_pg_ns_shps] net shapes of [sizeof_collection $tl_pg_shps] P/G shapes on layer '$top_pg_lyr_name' of [sizeof_collection $tl_pg_ns_nets] nets '[get_object_name $tl_pg_ns_nets]' of [sizeof_collection $tl_pg_nets] P/G nets ..."
  set tl_pg_terms {}
  foreach_in_collection net $tl_pg_ns_nets {
    # Somehow, get_ports needs -physical_context option for -of_objects of P/G nets, yet unnecessary for signal nets.
    #set port [get_ports -quiet -physical_context -of_objects $net]
    set port [get_ports [get_object_name $net]]
    set port_name [get_object_name $port]
    # Soft quote requires extra escape for meta regexp in addition to extra escape for hard quote.
    # Unfortunately, unlike ICC, ICC2 get_* -regexp doesn't yet support for -filter with -of_objects option.
    ##[get_terminals -regexp -filter "full_name =~ ${port_name}_\\\\d+" -of_objects $port]
    if { [sizeof_collection [set old_port_terms [get_terminals -quiet -regexp -filter "port.full_name == $port_name" "${port_name}_\\\\d+"]]] > 0 } {
      set term_suffix_idx [expr [lindex [lsort -integer [regsub -all -line "^${port_name}_" [join [get_object_name $old_port_terms] "\n"] {}]] end] + 1]
    } else {
      set term_suffix_idx 0
    }
    set tl_net_shps [sort_collection [filter_collection $tl_pg_ns_shps "net.full_name == [get_object_name $net]"] {bbox_llx bbox_lly}]
    if { $verb_opt } {
      P_msg_info "$proc_name: Use starting numerical suffix '$term_suffix_idx' to create P/G terminals on layer '$top_pg_lyr_name' of port '$port_name' of type '[get_attribute -objects $port -name port_type]' for [sizeof_collection $tl_net_shps] P/G net shapes of net '[get_object_name $net]'."
    }
    set tl_port_terms {}
    foreach_in_collection shp $tl_net_shps {
      # Unfortunately, shape object can't be owned by both net & connected port.
      #set term [create_terminal -port $port -object $shp]
      # Hence, need to create separate shape for terminal.
      if { [set shp_type [get_attribute -objects $shp -name shape_type]] == {path} } {
        # Unfortunately, must force rect type shape for terminal because create_abstract complains error if P/G terminal is of path type shape.
        #  Error: Shape 'PATH_???' of port '???' is of unexpected type 'path'.
        # On the other hand, create_frame is fine with path type shape.
        #set shp_opt "-path [list [get_attribute -objects $shp -name points]] -width [get_attribute -objects $shp -name width] -start_endcap [get_attribute -objects $shp -name start_endcap] -end_endcap [get_attribute -objects $shp -name end_endcap]"
        #if { [get_attribute -objects $shp -name start_endcap] == {variable} } {
        #  append shp_opt " -start_extension [get_attribute -objects $shp -name start_extension]"
        #}
        #if { [get_attribute -objects $shp -name end_endcap] == {variable} } {
        #  append shp_opt " -end_extension [get_attribute -objects $shp -name end_extension]"
        #}
        if { [get_attribute -objects $shp -name number_of_points] > 2 } {
          set shp_type polygon
          set shp_opt "-boundary $shp"
        } else {
          set shp_type rect
          set shp_opt "-boundary $shp"
        }
      } elseif { $shp_type == {polygon} } {
        #set shp_opt "-boundary [list [get_attribute -objects $shp -name points]]"
        set shp_opt "-boundary $shp"
       } else {
        # ASSERT: $shp_type == {rect}
        #set shp_opt "-boundary [list [get_attribute -objects $shp -name bbox]]"
        set shp_opt "-boundary $shp"
      }
      # Using -port creates terminal with TM_ prefix automatically, and needs to be changed later.
      #set new_shp [create_shape -layer $top_pg_lyr_name -shape_type rect -port $port {*}$shp_opt -shape_use [get_attribute -objects $shp -name shape_use]]
      # Unfortunately, can't get terminal from its shape object.
      ##set_attribute -objects [get_terminals -of_objects $new_shp] -name name -value $tl_pg_term_prefix${top_pg_lyr_name}_${port_name}_$term_suffix_idx
      #set_attribute -objects [get_terminals -filter "shape.full_name == [get_object_name $new_shp]" TM_*] -name name -value $tl_pg_term_prefix${top_pg_lyr_name}_${port_name}_$term_suffix_idx
      # Hence, create netless shape 1st, and later use create_terminal to assign prefix.
      append_to_collection tl_port_terms [set term [create_terminal -port $port -name $tl_pg_term_prefix${top_pg_lyr_name}_${port_name}_$term_suffix_idx -object [create_shape -layer $top_pg_lyr_name -shape_type rect {*}$shp_opt -shape_use [get_attribute -objects $shp -name shape_use]]]]
      if { $verb_opt } {
        if { [set term_shp_type [get_attribute -objects [set term_shp [get_attribute -objects $term -name shape]] -name shape_type]] == {path} } {
          set term_shp_desc "width '[get_attribute -objects $term_shp -name width]' & [expr [llength [get_attribute -objects $term_shp -name points]] - 1]-segmented center line '[get_attribute -objects $term_shp -name points]'"
        } elseif { $term_shp_type == {polygon} } {
          set term_shp_desc "[llength [get_attribute -objects $term_shp -name points]]-sided boundary '[get_attribute -objects $term_shp -name points]'"
        } else {
          set term_shp_desc "bbox '[get_attribute -objects $term_shp -name bbox]'"
        }
        P_msg_info "$proc_name:   Created P/G terminal '[get_object_name $term]' on layer '[get_attribute -objects $term -name layer.full_name]' of port '[get_object_name [get_ports -of_objects $term]]' of type '[get_attribute -objects $term -name port.port_type]' with '$term_shp_type' type shape of $term_shp_desc."
      }
      incr term_suffix_idx
    }
    P_msg_info "$proc_name: Created [sizeof_collection $tl_port_terms] P/G terminals on layer '$top_pg_lyr_name' of port '$port_name' of type '[get_attribute -objects $port -name port_type]' with shapes of '[lsort -unique [get_attribute -objects $tl_port_terms -name shape.shape_type]]' types for [sizeof_collection $tl_net_shps] P/G net shapes of net '[get_object_name $net]'."
    append_to_collection tl_pg_terms $tl_port_terms
  }
  P_msg_info "$proc_name: Created total [sizeof_collection $tl_pg_terms] P/G terminals on layer '$top_pg_lyr_name' of ports '[get_object_name [get_ports -of_objects $tl_pg_terms]]' of type '[lsort -unique [get_attribute -objects $tl_pg_terms -name port.port_type]]' with shapes of '[lsort -unique [get_attribute -objects $tl_pg_terms -name shape.shape_type]]' types for [sizeof_collection $tl_pg_ns_shps] net shapes of [sizeof_collection $tl_pg_shps] P/G shapes on layer '$top_pg_lyr_name' of [sizeof_collection $tl_pg_ns_nets] nets '[get_object_name $tl_pg_ns_nets]' of [sizeof_collection $tl_pg_nets] P/G nets ..."

  set_snap_setting -enabled $orig_val(snap_setting-enabled)

  return 1
}

define_proc_attributes create_top_pg_pin \
  -info "Create terminals for P/G straps on top layer specified by INTEL_MAX_PG_LAYER." \
  -define_args {
    {-force "Delete pre-existing P/G terminals on top layer, instead of display error messages" {} boolean optional}
    {-verbose "Display verbose informational messages" {} boolean optional}
  }

create_top_pg_pin

# EOF

