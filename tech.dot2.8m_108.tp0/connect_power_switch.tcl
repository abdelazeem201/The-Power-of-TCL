############################################################
# NAME :          connect_power_switch.tcl
#
# SUMMARY :       connect power switch pins
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists connect_power_switch.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_PS_CONNECT_CONFIG(array) INTEL_PS_CONNECT_CORNER(array) INTEL_DESIGN_NAME
#
# PROCS USED :    None
#                         
# DESCRIPTION :   connect_power_switch.tcl is to connect enable/control pins of power switch cells to control ports of power switch strategies based on the default values of INTEL_* variables.
#
# EXAMPLES :      
#
#############################################################

##############################################################################
#
#  set INTEL_PS_CONNECT_CONFIG(default) daisy
#  set INTEL_PS_CONNECT_CORNER(default) lower_left
#
# Users may overwrite the default values for specific power domains.
#
#  INTEL_PS_CONNECT_CONFIG($power_domain) = Connection mode among power switch cells supported by -mode option of connect_power_switch command, i.e. hfn, daisy or fishbone.
#  INTEL_PS_CONNECT_CORNER($pwer_domain) = Start corner/point of power switch cell for daisy or fishbone mode as supported by -start_point option of connect_power_switch command, i.e. lower_left, upper_left, lower_right or upper_right.
#
# NOTE:
#   Direction for daisy or fishbone mode as supported by -direction option of connect_power_switch command is hardcoded as vertical.
#
# Supported UPF power switch strategies.
# 1) Single-control UPF power switch strategy, with optional single-ack.
# 2) Dual-control UPF power switch strategy, with optional single-ack or dual-ack.
#
# Supported power switch lib cell mappings.
# 3) Map single-control UPF power switch strategy to single-switch power switch lib cell.
# 4) Map dual-control UPF power switch strategy to dual-switch power switch lib cell.
#
# Unsupported UPF power switch strategies.
# 5) More than 1 UPF power switch strategy per power domain.
# 6) More than 1 power switch lib cell mapping per UPF power switch strategy.
# 7) UPF power switch strategy with more than 2 controls.
#
# Unsupported power switch lib cell mappings.
# 8) Map single-control UPF power switch strategy to dual-switch power switch lib cell by daisy-chaining end of chain A to start of chain B.
# 9) Map dual-control UPF power switch strategy to single-switch power switch lib cell by interleaving cells of switch A with cells of switch B.
#
# Required procs:
#   P_msg_info
#   P_msg_warn
#   P_msg_error
#   P_get_power_domain_info
#

# TODO:
#   To support separate UPF power switch strategies for separate voltage area shapes per power domain.

set scr_name [file rootname [file tail [info script]]]

# Library-specific power switch lib cell pin names.
array unset ps_2sw_lib_pin_type_2_name
# Pin names of 73.* dual-switch power switch lib cells.
set ps_2sw_lib_pin_type_2_name(control,a) a
set ps_2sw_lib_pin_type_2_name(ack,a) aout
set ps_2sw_lib_pin_type_2_name(control,b) b
set ps_2sw_lib_pin_type_2_name(ack,b) bout

# Hierarchical punch-through port infixes.
# NOTE: Hierarchical punch-through port names for power switch single-control & single-ack ports = ${power_switch_name}_$ps_port_type_2_hier_infix({control|ack})_*.
array unset ps_1sw_port_type_2_hier_infix
set ps_1sw_port_type_2_hier_infix(control) sleep
set ps_1sw_port_type_2_hier_infix(ack) ack
# NOTE: Hierarchical punch-through port names for power switch dual-control & dual-ack ports = ${power_switch_name}_$ps_port_type_2_hier_infix({control|ack},{a|b})_*.
array unset ps_2sw_port_type_2_hier_infix
set ps_2sw_port_type_2_hier_infix(control,a) sleep0
set ps_2sw_port_type_2_hier_infix(ack,a) ack0
set ps_2sw_port_type_2_hier_infix(control,b) sleep1
set ps_2sw_port_type_2_hier_infix(ack,b) ack1

foreach_in_collection pd [get_power_domains -hierarchical *] {
  set pd_name [get_object_name $pd]
  set va_name [get_object_name [get_voltage_areas -of_objects $pd]]
  set ps_name [P_get_power_domain_info -pwr_domain $pd_name -query ps_names]
  if { [llength $va_name] == 0 } {
    P_msg_error "$scr_name: Detect missing voltage area for power domain '$pd_name'!  Skip connecting power switch cells for power switch '$ps_name'!"
    continue
  } elseif { [llength $ps_name] == 0 } {
    P_msg_info "$scr_name: No power switch defined for power domain '$pd_name' to connect any power switch cell."
    continue
  } elseif { [llength $ps_name] > 1 } {
    P_msg_error "$scr_name: Detect unsupported multiple ([llength $ps_name]) UPF power switches '$ps_name' defined for power domain '$pd_name'!  Currently only support 1 UPF power switch per power domain!"
    continue
  }
  # Use voltage area specific connect mode, start corner if defined, if not use the default connect mode, start corner values.
  if { [info exists INTEL_PS_CONNECT_CONFIG($pd_name)] } {
    set ps_conn_config $INTEL_PS_CONNECT_CONFIG($pd_name)
    if { [lsearch -exact {hfn daisy fishbone} $ps_conn_config] < 0 } {
      P_msg_error "$scr_name: Invalid value '$ps_conn_config' defined in 'INTEL_PS_CONNECT_CONFIG($pd_name)' var for power domain '$pd_name'!  Ignore and use '$INTEL_PS_CONNECT_CONFIG(default)' from 'INTEL_PS_CONNECT_CONFIG(default)' var instead!"
      set ps_conn_config $INTEL_PS_CONNECT_CONFIG(default)
    }
  } else {
    set ps_conn_config $INTEL_PS_CONNECT_CONFIG(default)
  }
  if { [lsearch -exact {hfn daisy fishbone} $ps_conn_config] < 0 } {
    P_msg_error "$scr_name: Invalid value '$ps_conn_config' defined in 'INTEL_PS_CONNECT_CONFIG(default)' var for power domain '$pd_name'!  Check 'project_setup.tcl' file!  Skip connecting power switch cells for power switch '$ps_name'!"
    break
  }
  if { [info exists INTEL_PS_CONNECT_CORNER($pd_name)] } {
    set ps_conn_corner $INTEL_PS_CONNECT_CORNER($pd_name)
    if { [lsearch -exact {lower_left upper_left lower_right upper_right} $ps_conn_corner] < 0 } {
      P_msg_error "$scr_name: Invalid value '$ps_conn_corner' defined in 'INTEL_PS_CONNECT_CORNER($pd_name)' var for power domain '$pd_name'!  Ignore and use '$INTEL_PS_CONNECT_CORNER(default)' from 'INTEL_PS_CONNECT_CORNER(default)' var instead!"
      set ps_conn_corner $INTEL_PS_CONNECT_CORNER(default)
    } elseif { $ps_conn_config == {hfn} } {
      P_msg_error "$scr_name: Ignore value '$ps_conn_corner' defined in 'INTEL_PS_CONNECT_CORNER($pd_name)' var for power domain '$pd_name' for connection mode '$INTEL_PS_CONNECT_CONFIG($pd_name)' defined in 'INTEL_PS_CONNECT_CONFIG($pd_name)' var!"
    }
  } else {
    set ps_conn_corner $INTEL_PS_CONNECT_CORNER(default)
  }
  if { [lsearch -exact {lower_left upper_left lower_right upper_right} $ps_conn_corner] < 0 } {
    P_msg_error "$scr_name: Invalid value '$ps_conn_corner' defined in 'INTEL_PS_CONNECT_CORNER(default)' var for power domain '$pd_name'!  Check 'project_setup.tcl' file!  Skip connecting power switch cells for power switch '$ps_name'!"
    break
  }
  if { [sizeof_collection [set va_ps_cells [get_cells -quiet -filter {is_power_switch == true} -of_objects [get_voltage_areas $va_name]]]] == 0 } {
    P_msg_error "$scr_name: Missing power switch cell to connect in voltage area '$va_name' of power domain '$pd_name'!  Skip connecting power switch cells for power switch '$ps_name'!"
    continue
  }
  set mode_dir_corner_opt {}
  set mode_dir_corner_msg {}
  if { $ps_conn_config != {hfn} } {
    append mode_dir_corner_opt " -direction vertical -start_point $ps_conn_corner"
    append mode_dir_corner_msg " in direction 'vertical' starting at corner '$ps_conn_corner'"
  }

  set ps_enable_control_a [P_get_power_domain_info -pwr_domain $pd_name -ps_name $ps_name -query ps_enable_control_a]
  set ps_enable_control_b [P_get_power_domain_info -pwr_domain $pd_name -ps_name $ps_name -query ps_enable_control_b]
  #set ps_enable_control_a_refpin [P_get_power_domain_info -pwr_domain $pd_name -ps_name $ps_name -query ps_enable_control_a_refpin]
  #set ps_enable_control_b_refpin [P_get_power_domain_info -pwr_domain $pd_name -ps_name $ps_name -query ps_enable_control_b_refpin]
  set ps_ack_port_a [P_get_power_domain_info -pwr_domain $pd_name -ps_name $ps_name -query ps_ack_port_a]
  set ps_ack_port_b [P_get_power_domain_info -pwr_domain $pd_name -ps_name $ps_name -query ps_ack_port_b]
  #set ps_ack_port_a_refpin [P_get_power_domain_info -pwr_domain $pd_name -ps_name $ps_name -query ps_ack_port_a_refpin]
  #set ps_ack_port_b_refpin [P_get_power_domain_info -pwr_domain $pd_name -ps_name $ps_name -query ps_ack_port_b_refpin]
  if { $ps_conn_config == {hfn} && [llength $ps_ack_port_a] > 0 } {
    P_msg_warn "$scr_name: Detect unsupported '$INTEL_PS_CONNECT_CONFIG($pd_name)' defined in 'INTEL_PS_CONNECT_CONFIG($pd_name)' var to connect ack port '$ps_ack_port_a' of power switch '$ps_name' of power domain '$pd_name'!  Ignore ack ports '[join "$ps_ack_port_a $ps_ack_port_b"]' of power switch '$ps_name'!"
    set ps_ack_port_a {}
    set ps_ack_port_b {}
  }

  set ps_prefix u_ps_${ps_name}_
  if { [sizeof_collection [set ps_cells [filter_collection $va_ps_cells "name =~ $ps_prefix*"]]] == 0 } {
    P_msg_error "$scr_name: Found no power switch cell of name matching '$ps_prefix*' to connect in voltage area '$va_name' for power switch '$ps_name' of power domain '$pd_name'!  Skip connecting power switch cells for power switch '$ps_name'!"
    continue
  } elseif { [sizeof_collection [set ps_lib_cells [get_lib_cells -of_objects $ps_cells]]] > 1 } {
    P_msg_error "$scr_name: Detect multiple ([sizeof_collection $ps_lib_cells]) power switch lib cells '[get_object_name $ps_lib_cells]' among [sizeof_collection $ps_cells] power switch cells of name matching '$ps_prefix*' in voltage area '$va_name' to connect for power switch '$ps_name' of power domain '$pd_name'!  Skip connecting power switch cells for power switch '$ps_name'!"
    continue
  }
  set ps_ctrl_lib_pins [get_lib_pins -quiet -filter {port_type == signal && port_direction == in && is_switch_pin == true} -of_objects $ps_lib_cells]
  if { [sizeof_collection $ps_ctrl_lib_pins] == 0 } {
    P_msg_error "$scr_name: Missing control lib pin in power switch lib cell '[get_object_name $ps_lib_cells]' of [sizeof_collection $ps_cells] power switch cells of name matching '$ps_prefix*' in voltage area '$va_name' to connect for power switch '$ps_name' of power domain '$pd_name'!  Skip connecting power switch cells for power switch '$ps_name'!"
    continue
  }
  set ps_ack_lib_pins [get_lib_pins -quiet -filter {port_type == signal && port_direction == out && is_acknowledge_pin == true} -of_objects $ps_lib_cells]
  if { $ps_conn_config != {hfn} && [sizeof_collection $ps_ack_lib_pins] == 0 } {
    P_msg_error "$scr_name: Missing ack lib pin in power switch lib cell '[get_object_name $ps_lib_cells]' of [sizeof_collection $ps_cells] power switch cells of name matching '$ps_prefix*' in voltage area '$va_name' to connect in mode '$ps_conn_config' for power switch '$ps_name' of power domain '$pd_name'!  Skip connecting power switch cells for power switch '$ps_name'!"
    continue
  }

  set port_a_msg {}
  set port_b_msg {}
  if { [llength $ps_enable_control_a] == 0 } {
    P_msg_error "$scr_name: Missing control port for power switch '$ps_name' of power domain '$pd_name'!  Skip connecting power switch cells for power switch '$ps_name'!"
    continue
  } elseif { [llength $ps_enable_control_b] == 0 && [sizeof_collection $ps_ctrl_lib_pins] == 1  } {
  # Single-control UPF power switch strategy.
  set ack_a_opt {}
  set port_a_msg " from control net '$ps_enable_control_a' through hierarchical port '${ps_name}_$ps_1sw_port_type_2_hier_infix(control)_*'"
  if { [llength $ps_ack_port_a] > 0 } {
  append ack_a_opt " -ack_out $ps_ack_port_a -ack_port_name ${ps_name}_$ps_1sw_port_type_2_hier_infix(ack)_"
  append port_a_msg " to ack net '$ps_ack_port_a' through hierarchical port '${ps_name}_$ps_1sw_port_type_2_hier_infix(ack)_*'"
  }
    if { [sizeof_collection $ps_ctrl_lib_pins] == 0 } {
    # NOTE: Already check above, but check again to be sure.
      P_msg_error "$scr_name: Missing control lib pin in power switch lib cell '[get_object_name $ps_lib_cells]' of [sizeof_collection $ps_cells] power switch cells of name matching '$ps_prefix*' in voltage area '$va_name' to connect for single-control power switch '$ps_name' of power domain '$pd_name'!  Report this error to ICF!"
      return
    } elseif { [sizeof_collection $ps_ctrl_lib_pins] == 1 } {
    # Single-switch power switch lib cell.
    connect_power_switch -voltage_area $va_name -object_list $ps_cells -mode $ps_conn_config {*}$mode_dir_corner_opt -source $ps_enable_control_a -port_name ${ps_name}_$ps_1sw_port_type_2_hier_infix(control)_ {*}$ack_a_opt
    } else {
    # Dual-switch power switch lib cell.
    #      P_msg_error "$scr_name: Detect unsupported multiple ([sizeof_collection $ps_ctrl_lib_pins]) control lib pins '[get_object_name $ps_ctrl_lib_pins]' in power switch lib cell '[get_object_name $ps_lib_cells]' of [sizeof_collection $ps_cells] power switch cells of name matching '$ps_prefix*' in voltage area '$va_name' to connect for single-control power switch '$ps_name' of power domain '$pd_name'!  Skip connecting power switch cells for power switch '$ps_name'!"
    #      set ps_enable_control_b $ps_enable_control_a
    #      continue
    }
  } elseif { [llength $ps_enable_control_b] == 0 && [sizeof_collection $ps_ctrl_lib_pins] == 2  } {
  # Dual-control UPF power switch strategy with single enable control signal.
  set ack_a_opt {} 
    set ps_enable_control_b $ps_enable_control_a
    set ps_ack_port_b $ps_ack_port_a

    set port_a_msg " from control net '$ps_enable_control_a' through hierarchical port '${ps_name}_$ps_2sw_port_type_2_hier_infix(control,a)_*'"
    if { [llength $ps_ack_port_a] > 0 } {
      append ack_a_opt " -ack_out $ps_ack_port_a -ack_port_name ${ps_name}_$ps_2sw_port_type_2_hier_infix(ack,a)_"
      append port_a_msg " to ack net '$ps_ack_port_a' through hierarchical port '${ps_name}_$ps_2sw_port_type_2_hier_infix(ack,a)_*'"
    }
    set ack_b_opt {}
    set port_b_msg " from control net '$ps_enable_control_b' through hierarchical port '${ps_name}_$ps_2sw_port_type_2_hier_infix(control,b)_*'"
    if { [llength $ps_ack_port_b] > 0 } {
      append ack_b_opt " -ack_out $ps_ack_port_b -ack_port_name ${ps_name}_$ps_2sw_port_type_2_hier_infix(ack,b)_"
      append port_b_msg " to ack net '$ps_ack_port_b' through hierarchical port '${ps_name}_$ps_2sw_port_type_2_hier_infix(ack,b)_*'"
    }
    if { [sizeof_collection $ps_ctrl_lib_pins] == 0 } {
    # NOTE: Already check above, but check again to be sure.
      P_msg_error "$scr_name: Missing control lib pin in power switch lib cell '[get_object_name $ps_lib_cells]' of [sizeof_collection $ps_cells] power switch cells of name matching '$ps_prefix*' in voltage area '$va_name' to connect for dual-control power switch '$ps_name' of power domain '$pd_name'!  Report this error to ICF!"
      return
    } elseif { [sizeof_collection $ps_ctrl_lib_pins] == 1 } {
    # Single-switch power switch lib cell.
      P_msg_error "$scr_name: Detect unsupported single control lib pin '[get_object_name $ps_ctrl_lib_pins]' in power switch lib cell '[get_object_name $ps_lib_cells]' of [sizeof_collection $ps_cells] power switch cells of name matching '$ps_prefix*' in voltage area '$va_name' to connect for dual-control power switch '$ps_name' of power domain '$pd_name'!  Skip connecting power switch cells for power switch '$ps_name'!"
      continue
    } else {
    # Dual-switch power switch lib cell.
      set port_a_lib_pins [filter_collection $ps_ctrl_lib_pins "name == $ps_2sw_lib_pin_type_2_name(control,a)"]
      if { [sizeof_collection $port_a_lib_pins] == 0 } {
        P_msg_error "$scr_name: Failed to find control lib pin '$ps_2sw_lib_pin_type_2_name(control,a)' among [sizeof_collection $ps_ctrl_lib_pins] control lib pins '[get_object_name $ps_ctrl_lib_pins]' of power switch lib cell '[get_object_name $ps_lib_cells]' among [sizeof_collection $ps_cells] power switch cells of name matching '$ps_prefix*' in voltage area '$va_name' to connect for dual-control power switch '$ps_name' of power domain '$pd_name'!  Skip connecting power switch cells for control port '$ps_enable_control_a' of power switch '$ps_name'!"
        continue
      } elseif { $ps_conn_config != {hfn} && [sizeof_collection [set ack_a_lib_pins [filter_collection $ps_ack_lib_pins "name == $ps_2sw_lib_pin_type_2_name(ack,a)"]]] == 0 } {
        P_msg_error "$scr_name: Failed to find ack lib pin '$ps_2sw_lib_pin_type_2_name(ack,a)' among [sizeof_collection $ps_ack_lib_pins] ack lib pins '[get_object_name $ps_ack_lib_pins]' of power switch lib cell '[get_object_name $ps_lib_cells]' among [sizeof_collection $ps_cells] power switch cells of name matching '$ps_prefix*' in voltage area '$va_name' to connect in mode '$ps_conn_config' for dual-control power switch '$ps_name' of power domain '$pd_name'!  Skip connecting power switch cells for control port '$ps_enable_control_a' of power switch '$ps_name'!"
        continue
      }
      append_to_collection port_a_lib_pins $ack_a_lib_pins
      set port_b_lib_pins [filter_collection $ps_ctrl_lib_pins "name == $ps_2sw_lib_pin_type_2_name(control,b)"]
      if { [sizeof_collection $port_b_lib_pins] == 0 } {
        P_msg_error "$scr_name: Failed to find control lib pin '$ps_2sw_lib_pin_type_2_name(control,b)' among [sizeof_collection $ps_ctrl_lib_pins] control lib pins '[get_object_name $ps_ctrl_lib_pins]' of power switch lib cell '[get_object_name $ps_lib_cells]' among [sizeof_collection $ps_cells] power switch cells of name matching '$ps_prefix*' in voltage area '$va_name' to connect for dual-control power switch '$ps_name' of power domain '$pd_name'!  Skip connecting power switch cells for control port '$ps_enable_control_b' of power switch '$ps_name'!"
        continue
      } elseif { $ps_conn_config != {hfn} && [sizeof_collection [set ack_b_lib_pins [filter_collection $ps_ack_lib_pins "name == $ps_2sw_lib_pin_type_2_name(ack,b)"]]] == 0 } {
        P_msg_error "$scr_name: Failed to find ack lib pin '$ps_2sw_lib_pin_type_2_name(ack,b)' among [sizeof_collection $ps_ack_lib_pins] ack lib pins '[get_object_name $ps_ack_lib_pins]' of power switch lib cell '[get_object_name $ps_lib_cells]' among [sizeof_collection $ps_cells] power switch cells of name matching '$ps_prefix*' in voltage area '$va_name' to connect in mode '$ps_conn_config' for for power switch '$ps_name' of power domain '$pd_name'!  Skip connecting power switch cells for control port '$ps_enable_control_b' of power switch '$ps_name'!"
        continue
      }
      append_to_collection port_b_lib_pins $ack_b_lib_pins
      connect_power_switch -voltage_area $va_name -object_list $ps_cells -lib_pin $port_a_lib_pins -mode $ps_conn_config {*}$mode_dir_corner_opt -source $ps_enable_control_a -port_name ${ps_name}_$ps_2sw_port_type_2_hier_infix(control,a)_ {*}$ack_a_opt

      # added for connection aout to b connection
      #take the last output of the small enable chain (a->aout) and feed it back into the big enable chain (b->bout) of the power switch in reverse order
      set small_en_st_pt [get_net $ps_enable_control_a]
      set power_switch_libcell [get_attr [get_lib_cell  $ps_lib_cells] name]
      set sw_daisychain_cells [filter_collection [all_fanout -from $small_en_st_pt -only_cells -flat] "ref_name == $power_switch_libcell"]
      set pg_sw_cell_count [sizeof $sw_daisychain_cells]
      set first_switch_cell [get_cell -of [get_pin -physical -of [get_net $ps_enable_control_a]] -filter "ref_name == $power_switch_libcell"]
      #    set cur_sig   [get_flat_pins -of $small_en_st_pt]
      set cur_sig   [get_flat_pins -of $first_switch_cell -filter "name == $ps_2sw_lib_pin_type_2_name(control,a)" ]
      set ps_sw_ordered_list [list]
      #    lappend ps_sw_ordered_list [get_attr [get_flat_cells -of_objects [get_flat_pins -of $small_en_st_pt]] full_name]	
      lappend ps_sw_ordered_list [get_attr [get_cell -of [get_pin -physical -of [get_net $ps_enable_control_a]] -filter "ref_name == $power_switch_libcell"] full_name]	

      for {set count 1} {$count < $pg_sw_cell_count} {incr count} {
#        set next_ps_cell_out_pin [filter_collection [index_collection [get_flat_pins -filter "direction==out" [all_fanout -from $cur_sig -flat]] 1] "name == $ps_2sw_lib_pin_type_2_name(ack,a)"]
        set next_ps_cell_out_pin [filter_collection [index_collection [filter_collection [all_fanout -from $cur_sig -flat] "direction==out && is_hierarchical== false && object_class == pin"] 1]  "name == $ps_2sw_lib_pin_type_2_name(ack,a)"]
        if {[sizeof $next_ps_cell_out_pin] == 0} {
          P_msg_info "CHECKPOINT: Processed $count cells, actual count of ps cells is $pg_sw_cell_count"
          break
        } 
        set next_ps_cell_name [get_object_name [get_cells -of $next_ps_cell_out_pin]]
        if {[get_attr [get_cells $next_ps_cell_name] ref_name] != $power_switch_libcell} {
          P_msg_error "Unexpected cell found on power switch daisy chain: $next_ps_cell_name, ref_name: [get_attr [get_cells $next_ps_cell_name] ref_name]"
          return
        }
        lappend ps_sw_ordered_list $next_ps_cell_name
        set cur_sig $next_ps_cell_out_pin

        if {$count > [expr $pg_sw_cell_count + 2]} {
        # infinite loop, break now
          P_msg_error "Unexpected number of loop iterations (=$count, expecting $pg_sw_cell_count) while trying to find cells in power switch daisy chain"
          return
          break
        }
      }

      set reversed_ps_sw_ordered_list [list]
      foreach cur_ps_sw $ps_sw_ordered_list {
        set reversed_ps_sw_ordered_list [linsert $reversed_ps_sw_ordered_list 0 $cur_ps_sw]
      }
      set last_sw_cell [lindex $reversed_ps_sw_ordered_list 0]
      set last_sw_cell_ackouta "${last_sw_cell}/$ps_2sw_lib_pin_type_2_name(ack,a)"

      set mode_dir_corner_opt_b " -direction vertical"
      connect_power_switch -voltage_area $va_name -object_list $reversed_ps_sw_ordered_list -source $last_sw_cell_ackouta  -port_name ${ps_name}_$ps_2sw_port_type_2_hier_infix(control,b)_  -mode $ps_conn_config -lib_pin $port_b_lib_pins {*}$mode_dir_corner_opt_b {*}$ack_b_opt -keep_order

    }
  } else {
  # Dual-control UPF power switch strategy.
  set ack_a_opt {}
  set port_a_msg " from control net '$ps_enable_control_a' through hierarchical port '${ps_name}_$ps_2sw_port_type_2_hier_infix(control,a)_*'"
  if { [llength $ps_ack_port_a] > 0 } {
  append ack_a_opt " -ack_out $ps_ack_port_a -ack_port_name ${ps_name}_$ps_2sw_port_type_2_hier_infix(ack,a)_"
  append port_a_msg " to ack net '$ps_ack_port_a' through hierarchical port '${ps_name}_$ps_2sw_port_type_2_hier_infix(ack,a)_*'"
  }
    set ack_b_opt {}
    set port_b_msg " from control net '$ps_enable_control_b' through hierarchical port '${ps_name}_$ps_2sw_port_type_2_hier_infix(control,b)_*'"
    if { [llength $ps_ack_port_b] > 0 } {
      append ack_b_opt " -ack_out $ps_ack_port_b -ack_port_name ${ps_name}_$ps_2sw_port_type_2_hier_infix(ack,b)_"
      append port_b_msg " to ack net '$ps_ack_port_b' through hierarchical port '${ps_name}_$ps_2sw_port_type_2_hier_infix(ack,b)_*'"
    }
    if { [sizeof_collection $ps_ctrl_lib_pins] == 0 } {
    # NOTE: Already check above, but check again to be sure.
      P_msg_error "$scr_name: Missing control lib pin in power switch lib cell '[get_object_name $ps_lib_cells]' of [sizeof_collection $ps_cells] power switch cells of name matching '$ps_prefix*' in voltage area '$va_name' to connect for dual-control power switch '$ps_name' of power domain '$pd_name'!  Report this error to ICF!"
      return
    } elseif { [sizeof_collection $ps_ctrl_lib_pins] == 1 } {
    # Single-switch power switch lib cell.
      P_msg_error "$scr_name: Detect unsupported single control lib pin '[get_object_name $ps_ctrl_lib_pins]' in power switch lib cell '[get_object_name $ps_lib_cells]' of [sizeof_collection $ps_cells] power switch cells of name matching '$ps_prefix*' in voltage area '$va_name' to connect for dual-control power switch '$ps_name' of power domain '$pd_name'!  Skip connecting power switch cells for power switch '$ps_name'!"
      continue
    } else {
    # Dual-switch power switch lib cell.
      set port_a_lib_pins [filter_collection $ps_ctrl_lib_pins "name == $ps_2sw_lib_pin_type_2_name(control,a)"]
      if { [sizeof_collection $port_a_lib_pins] == 0 } {
        P_msg_error "$scr_name: Failed to find control lib pin '$ps_2sw_lib_pin_type_2_name(control,a)' among [sizeof_collection $ps_ctrl_lib_pins] control lib pins '[get_object_name $ps_ctrl_lib_pins]' of power switch lib cell '[get_object_name $ps_lib_cells]' among [sizeof_collection $ps_cells] power switch cells of name matching '$ps_prefix*' in voltage area '$va_name' to connect for dual-control power switch '$ps_name' of power domain '$pd_name'!  Skip connecting power switch cells for control port '$ps_enable_control_a' of power switch '$ps_name'!"
        continue
      } elseif { $ps_conn_config != {hfn} && [sizeof_collection [set ack_a_lib_pins [filter_collection $ps_ack_lib_pins "name == $ps_2sw_lib_pin_type_2_name(ack,a)"]]] == 0 } {
        P_msg_error "$scr_name: Failed to find ack lib pin '$ps_2sw_lib_pin_type_2_name(ack,a)' among [sizeof_collection $ps_ack_lib_pins] ack lib pins '[get_object_name $ps_ack_lib_pins]' of power switch lib cell '[get_object_name $ps_lib_cells]' among [sizeof_collection $ps_cells] power switch cells of name matching '$ps_prefix*' in voltage area '$va_name' to connect in mode '$ps_conn_config' for dual-control power switch '$ps_name' of power domain '$pd_name'!  Skip connecting power switch cells for control port '$ps_enable_control_a' of power switch '$ps_name'!"
        continue
      }
      append_to_collection port_a_lib_pins $ack_a_lib_pins
      set port_b_lib_pins [filter_collection $ps_ctrl_lib_pins "name == $ps_2sw_lib_pin_type_2_name(control,b)"]
      if { [sizeof_collection $port_b_lib_pins] == 0 } {
        P_msg_error "$scr_name: Failed to find control lib pin '$ps_2sw_lib_pin_type_2_name(control,b)' among [sizeof_collection $ps_ctrl_lib_pins] control lib pins '[get_object_name $ps_ctrl_lib_pins]' of power switch lib cell '[get_object_name $ps_lib_cells]' among [sizeof_collection $ps_cells] power switch cells of name matching '$ps_prefix*' in voltage area '$va_name' to connect for dual-control power switch '$ps_name' of power domain '$pd_name'!  Skip connecting power switch cells for control port '$ps_enable_control_b' of power switch '$ps_name'!"
        continue
      } elseif { $ps_conn_config != {hfn} && [sizeof_collection [set ack_b_lib_pins [filter_collection $ps_ack_lib_pins "name == $ps_2sw_lib_pin_type_2_name(ack,b)"]]] == 0 } {
        P_msg_error "$scr_name: Failed to find ack lib pin '$ps_2sw_lib_pin_type_2_name(ack,b)' among [sizeof_collection $ps_ack_lib_pins] ack lib pins '[get_object_name $ps_ack_lib_pins]' of power switch lib cell '[get_object_name $ps_lib_cells]' among [sizeof_collection $ps_cells] power switch cells of name matching '$ps_prefix*' in voltage area '$va_name' to connect in mode '$ps_conn_config' for for power switch '$ps_name' of power domain '$pd_name'!  Skip connecting power switch cells for control port '$ps_enable_control_b' of power switch '$ps_name'!"
        continue
      }
      append_to_collection port_b_lib_pins $ack_b_lib_pins
      connect_power_switch -voltage_area $va_name -object_list $ps_cells -lib_pin $port_a_lib_pins -mode $ps_conn_config {*}$mode_dir_corner_opt -source $ps_enable_control_a -port_name ${ps_name}_$ps_2sw_port_type_2_hier_infix(control,a)_ {*}$ack_a_opt
      connect_power_switch -voltage_area $va_name -object_list $ps_cells -lib_pin $port_b_lib_pins -mode $ps_conn_config {*}$mode_dir_corner_opt -source $ps_enable_control_b -port_name ${ps_name}_$ps_2sw_port_type_2_hier_infix(control,b)_ {*}$ack_b_opt
    }
  }


  #set conn_cells [filter_collection [all_fanout -flat -only_cells -from $ps_enable_control_a] {is_hierarchical == false}]
  set conn_cells [filter_collection [all_transitive_fanout -flat -only_cells -from $ps_enable_control_a] {is_hierarchical == false}]
  if { [compare_collection $conn_cells $ps_cells] != 0 } {
    if { [sizeof_collection [set extra_cells [remove_from_collection $conn_cells $ps_cells]]] > 0 } {
      P_msg_warn "$scr_name: Detect [sizeof_collection $extra_cells] non-power-switch cells among [sizeof_collection $conn_cells] cells connected for [sizeof_collection $ps_cells] power switch cells '[join $ps_cell_path_list /]' of reference '[lsort -unique [get_attribute -objects $conn_cells -name ref_name]]' in voltage area '[get_object_name [get_voltage_areas -of_objects $conn_cells]]'$port_a_msg with mode '$ps_conn_config'$mode_dir_corner_msg for power switch '$ps_name' of power domain '$pd_name'."
    }
    if { [sizeof_collection [set skip_cells [remove_from_collection $ps_cells $conn_cells]]] > 0 } {
      P_msg_warn "$scr_name: Detect [sizeof_collection $skip_cells] power-switch cells skipped from [sizeof_collection $conn_cells] cells connected for [sizeof_collection $ps_cells] power switch cells '[join $ps_cell_path_list /]' of reference '[lsort -unique [get_attribute -objects $conn_cells -name ref_name]]' in voltage area '[get_object_name [get_voltage_areas -of_objects $conn_cells]]'$port_a_msg with mode '$ps_conn_config'$mode_dir_corner_msg for power switch '$ps_name' of power domain '$pd_name'."
    }
  } else {
    P_msg_info "$scr_name: Connected [sizeof_collection $conn_cells] of [sizeof_collection $ps_cells] power switch cells '[join $ps_cell_path_list /]' of reference '[lsort -unique [get_attribute -objects $conn_cells -name ref_name]]' in voltage area '[get_object_name [get_voltage_areas -of_objects $conn_cells]]'$port_a_msg with mode '$ps_conn_config'$mode_dir_corner_msg for power switch '$ps_name' of power domain '$pd_name'."
  }
  file mkdir ./reports
  report_transitive_fanout -nosplit -from $ps_enable_control_a > ./reports/$INTEL_DESIGN_NAME.floorplan.[string map {/ _} $pd_name].transitive_fanout.$ps_name.[string map {/ _ [ _ ] _} $ps_enable_control_a].rpt
  if { [llength $ps_enable_control_b] > 0 } {
  #set conn_b_cells [filter_collection [all_fanout -flat -only_cells -from $ps_enable_control_b] {is_hierarchical == false}]
  set conn_b_cells [filter_collection [all_transitive_fanout -flat -only_cells -from $ps_enable_control_b] {is_hierarchical == false}]
  if { [compare_collection $conn_b_cells $ps_cells] != 0 } {
  if { [sizeof_collection [set extra_cells [remove_from_collection $conn_b_cells $ps_cells]]] > 0 } {
    P_msg_warn "$scr_name: Detect [sizeof_collection $extra_cells] non-power-switch cells among [sizeof_collection $conn_b_cells] cells connected for [sizeof_collection $ps_cells] power switch cells '[join $ps_cell_path_list /]' of reference '[lsort -unique [get_attribute -objects $conn_b_cells -name ref_name]]' in voltage area '[get_object_name [get_voltage_areas -of_objects $conn_b_cells]]'$port_b_msg with mode '$ps_conn_config'$mode_dir_corner_msg for power switch '$ps_name' of power domain '$pd_name'."
  }
  if { [sizeof_collection [set skip_cells [remove_from_collection $ps_cells $conn_b_cells]]] > 0 } {
    P_msg_warn "$scr_name: Detect [sizeof_collection $skip_cells] power-switch cells skipped from [sizeof_collection $conn_b_cells] cells connected for [sizeof_collection $ps_cells] power switch cells '[join $ps_cell_path_list /]' of reference '[lsort -unique [get_attribute -objects $conn_b_cells -name ref_name]]' in voltage area '[get_object_name [get_voltage_areas -of_objects $conn_b_cells]]'$port_b_msg with mode '$ps_conn_config'$mode_dir_corner_msg for power switch '$ps_name' of power domain '$pd_name'."
  }
} else {
    P_msg_info "$scr_name: Connected [sizeof_collection $conn_b_cells] of [sizeof_collection $ps_cells] power switch cells '[join $ps_cell_path_list /]' of reference '[lsort -unique [get_attribute -objects $conn_b_cells -name ref_name]]' in voltage area '[get_object_name [get_voltage_areas -of_objects $conn_b_cells]]'$port_b_msg with mode '$ps_conn_config'$mode_dir_corner_msg for power switch '$ps_name' of power domain '$pd_name'."
  }
  report_transitive_fanout -nosplit -from $ps_enable_control_b > ./reports/$INTEL_DESIGN_NAME.floorplan.[string map {/ _} $pd_name].transitive_fanout.$ps_name.[string map {/ _ [ _ ] _} $ps_enable_control_b].rpt
}
}

unset scr_name


