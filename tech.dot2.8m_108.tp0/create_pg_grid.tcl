##############################################################
# NAME :          create_pg_grid.tcl
#
# SUMMARY :       create PG grid
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists create_pg_grid.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_PG_GRID_CONFIG INTEL_MAX_PG_LAYER INTEL_MIN_PG_LAYER INTEL_UPF_POWER_NETS INTEL_DESIGN_NAME INTEL_POWER_PLAN
#
# PROCS USED :    None
#                         
# DESCRIPTION :   create_pg_grid.tcl is to create PG grid for a design
#
# EXAMPLES :      
#
###############################################################
# Create P/G grids in partition and voltage areas for UPF.

# P/G grid configuration, customized per track pattern per dot process.

# Syntax for INTEL_PG_GRID_CONFIG var:
#   $layer {
#     pullback $pullback
#     $template {
#       pitch $pitch
#       offset,width {
#         $offset1  $width1
#         $offset2  $width2
#       }
#       ?staple? {
#         repeat $repeat
#         start,length {
#           $start1  $length1
#           $start2  $length2
#         }
#       }
#     }
#   }
#   ?$via_layer? {
#     via_master_rule  $via_master_rule
#   }
#
# where
# a) $layer is metal layer between INTEL_MIN_PG_LAYER and INTEL_MAX_PG_LAYER, inclusively.
# b) pullback must be 0 or positive number, where 0 = extend P/G straps to design block boundary & generate pins, >0 = pullback spacing (typically half end-to-end space) from design block boundary.
# c) Same pullback is applied to macro instance boundary, except 0 = extend P/G straps to touch macro instance boundary if macro has same P/G pins.  However, actual pullback may be larger if macro has blockage that causes DR to push P/G straps further back.
# d) $template is either ground, power, power_va_primary, power_va_aon, power_va_aon,1, power_va_aon,2, power_sw_cell_aon, power_all_aon, power_all_aon,1, or power_all_aon,2, as explained below.
# e) pullback must be > 0 if there is power_va_primary template, which is also pullback spacing (typically half end-to-end space) from voltage area boundary.
# f) staple is only valid & optional for ground, power or power_va_primary template for creating non-continuous interleaving between ground & power short straps in same track.
#
# g) $via_layer is optional for via layer connecting adjacent metal layers between INTEL_MIN_PG_LAYER and INTEL_MAX_PG_LAYER, inclusively.
# h) $via_master_rule is via master rule previously defined by set_pg_via_master_rule command or list of arguments for set_pg_via_master_rule command to define new via master rule.

# 1) For non-UPF P/G grids, each layer must define pullback & templates:
#     {pullback ground power}
#
# 2) For UPF with single always-on supply voltage, each layer must define pullback & templates of either:
#    a) {pullback ground power_va_primary ?power_va_aon? ?power_sw_cell_aon?} where power_va_aon & power_sw_cell_aon are optional.
#    b) {pullback ground power_all_aon}
#
# 3) For UPF with dual always-on supply voltages, each layer must define pullback & templates of either:
#    a) {pullback ground power_va_primary ?power_va_aon,1? ?power_va_aon,2? ?power_sw_cell_aon?} where power_va_aon,1, power_va_aon,2 & power_sw_cell_aon are optional.
#    b) {pullback ground power_all_aon,1 power_all_aon,2}
#    NOTE: Order of the dual always-on power nets is based on $INTEL_UPF_POWER_NETS var, i.e. {aon,1 aon,2}.

# ASSERT: Ground net must be common across all power domains, i.e. voltage areas.
# Layers in power_all_aon must be above than & mutually exclusive with layers in power_va_aon, power_va_primary & power_sw_cell_aon.
# Layers may be shared but their offsets must be mutually exclusive between power_va_aon, power_va_primary & power_sw_cell_aon.

# ASSERT: Input always-on power pins of power switch cells must already be logically connected to the always-on power net of the power domain, i.e. using connect_pg_net command.

# NOTE: Currently, support only contiguous layers of P/G grids between INTEL_MIN_PG_LAYER and INTEL_MAX_PG_LAYER, inclusively, i.e. skip layer not supported.
# NOTE: Currently, support only 2 nested levels of voltage areas.
# NOTE: Currently, support only child level voltage areas that are equal or less always-on than parent level voltage area, i.e. gas-station not supported.

# NOTE: P/G straps for always-on power nets, i.e. power_va_aon* templates, are extended to voltage area boundaries, except DEFAULT_VA.
# TODO: Extend P/G straps of power_va_aon* templates into $INTEL_LS_BOUND($voltage_area,{outer|inner}) beyond voltage area boundaries.

set_app_options -name plan.pgroute.high_capacity_mode -value true
set_app_options -name plan.pgroute.honor_signal_route_drc -value true
set_app_options -name plan.pgroute.honor_std_cell_drc -value true
# Only allow vias within full intersection of adjacent layers.
set_app_options -name plan.pgroute.via_site_threshold -value 1.0
#set_app_options -name plan.pgroute.overlap_route_boundary -value true
#set_app_options -name plan.pgroute.verbose -value true

proc create_pg_grid args {
  parse_proc_arguments -args $args opts
  global pg_pullback INTEL_POWER_PLAN
  set proc_name [namespace tail [lindex [info level 0] 0]]
  # TODO: Support -force option.
  set force_opt [info exists opts(-force)]
  set out_cmd_file [expr { [info exists opts(-output_command_file)] ? $opts(-output_command_file) : {} }]
  set rpt_prefix [expr { [info exists opts(-report_prefix)] ? $opts(-report_prefix) : {} }]
  set keep_spec_opt [info exists opts(-keep_spec)]
  set verb_opt [info exists opts(-verbose)]

  foreach proc {P_msg_info P_msg_warn P_msg_error} {
    if { [info procs $proc] == {} } {
      echo "#ERROR-MSG: $proc_name: Missing required proc '$proc'!  Check 'procs.tcl' file!"
      return
    }
  }
  foreach proc {P_get_power_domain_info} {
    if { [info procs $proc] == {} } {
      P_msg_error "$proc_name: Missing required proc '$proc'!  Check 'procs.tcl' file!"
      return
    }
  }

  # ASSERT: $INTEL_MAX_PG_LAYER is valid route layer.
  # ASSERT: $INTEL_MIN_PG_LAYER is valid route layer & not higher than $INTEL_MAX_PG_LAYER.
  foreach var {INTEL_PG_GRID_CONFIG INTEL_MAX_PG_LAYER INTEL_MIN_PG_LAYER INTEL_UPF_POWER_NETS} {
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
  } elseif { [get_app_option_value -name shell.common.product_version] < {K-2015.06-SP5} } {
    P_msg_error "$proc_name: Detect unsupported ICC2 version '[get_app_option_value -name shell.common.product_version]'!  Expect 'K-2015.06-SP5' or newer!"
    return
  }
  if { $verb_opt } {
    report_app_options plan.pgroute.*
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

  # TODO: Sanity check INTEL_MIN_PG_LAYER, INTEL_MAX_PG_LAYER & INTEL_UPF_POWER_NETS.
  set all_metal_via_layer_order_list [get_object_name [sort_collection [get_layers -filter {( layer_type == interconnect || layer_type == via_cut ) && mask_order >= 0} -of_objects $tech] mask_order]]
  set pg_layer_order_list [lrange $all_metal_via_layer_order_list [lsearch -exact $all_metal_via_layer_order_list $INTEL_MIN_PG_LAYER] [lsearch -exact $all_metal_via_layer_order_list $INTEL_MAX_PG_LAYER]]
  P_msg_info "$proc_name: Creating P/G grids for layers '$pg_layer_order_list' defined in 'INTEL_PG_GRID_CONFIG' ..."

  set all_metal_layer_order_list [get_object_name [sort_collection [get_layers -filter {( layer_type == interconnect ) && mask_order >= 0} -of_objects $tech] mask_order]]
  set pg_metal_layer_order_list [lrange $all_metal_layer_order_list [lsearch -exact $all_metal_layer_order_list $INTEL_MIN_PG_LAYER] [lsearch -exact $all_metal_layer_order_list $INTEL_MAX_PG_LAYER]]

  # TODO: Implement -force option.

  set valid_pg_template_list {ground power power_all_aon power_all_aon,1 power_all_aon,2 power_sw_cell_aon power_va_aon power_va_aon,1 power_va_aon,2 power_va_primary}

  # Somehow, get_nets -physical_context option will rearrange order of nets in pattern argument.
  # ASSERT: Nets in INTEL_UPF_POWER_NETS are top-level nets.
  set aon_net_order_list [get_object_name [get_nets -quiet -filter {net_type == power} $INTEL_UPF_POWER_NETS]]

  array unset dir_2_axis
  array set dir_2_axis {
    vertical    x
    horizontal  y
  }
  array unset dir_2_ortho_dir
  array set dir_2_ortho_dir {
    vertical    horizontal
    horizontal  vertical
  }

  # TODO: Sanity check INTEL_PG_GRID_CONFIG.
  set pg_grid_dict [dict create {*}$INTEL_PG_GRID_CONFIG]

  array unset pd_2_pwr_sw_list
  array unset pd_2_pg_net
  foreach_in_collection pd [get_power_domains -quiet -hierarchical] {
    set pd_name [get_object_name $pd]
    #set pd_2_pg_net(gnd,$pd_name) [get_object_name [get_nets -physical_context [get_attribute -objects [get_voltage_areas -objects $pd] -name ground_net.full_name]]]
    set pd_2_pg_net(gnd,$pd_name) [get_object_name [get_nets -physical_context [get_attribute -objects $pd -name primary_ground.full_name]]]
    #set pd_2_pg_net(pwr_pri,$pd_name) [get_object_name [get_nets -physical_context [get_attribute -objects [get_voltage_areas -objects $pd] -name power_net.full_name]]]
    set pd_2_pg_net(pwr_pri,$pd_name) [get_object_name [get_nets -physical_context [get_attribute -objects $pd -name primary_power.full_name]]]
    set pd_2_pwr_sw_list($pd_name) [P_get_power_domain_info -pwr_domain $pd_name -query ps_names]
    if { [llength $pd_2_pwr_sw_list($pd_name)] > 0 } {
    # ASSERT: Single always-on supply net to multiple power switches in same power domain.
    # ASSERT: P_get_power_domain_info -query aon_pwr returns top-level net.
      set pd_2_pg_net(pwr_aon,$pd_name) [P_get_power_domain_info -pwr_domain $pd_name -ps_name [lindex $pd_2_pwr_sw_list($pd_name) 0] -query aon_pwr]
    } else {
      set pd_2_pg_net(pwr_aon,$pd_name) $pd_2_pg_net(pwr_pri,$pd_name)
    }
  }
  set top_pd_name [get_object_name [get_power_domains -of_objects [get_voltage_areas DEFAULT_VA]]]

  #array unset va_2_outer_va_list
  array unset va_2_inner_va_list
  #array unset va_2_abut_va_list
  set vas [get_voltage_areas -quiet]
  foreach_in_collection va $vas {
  #set va_2_outer_va_list([get_object_name $va]) {}
    set va_2_inner_va_list([get_object_name $va]) {}
    #set va_2_abut_va_list([get_object_name $va]) {}
  }
  set other_vas $vas
  foreach_in_collection va $vas {
    set va_name [get_object_name $va]
    set other_vas [remove_from_collection $other_vas $va]
    foreach_in_collection other_va $other_vas {
      set other_va_name [get_object_name $other_va]
	if { [get_attribute -objects [compute_polygons -operation xor -objects1 [get_attribute $va region] -objects2 [get_attribute $other_va region]] -name shape_count] == 0 } {
      # ASSERT: $va is same as $other_va.  For disjoint VA shapes, all VA shapes of $va & $other_va are identical.
        P_msg_error "$proc_name: Detect 2 voltage areas '$va_name $other_va_name' are identical shapes with each other!  Expect different shapes!"
    } elseif { [get_attribute -objects [compute_polygons -operation not -objects1 [get_attribute $va region] -objects2 [get_attribute $other_va region]] -name shape_count] == 0 } {
      # ASSERT: $va inside $other_va.  For disjoint VA shapes, all VA shapes of $va are inside those of $other_va.
      #lappend va_2_outer_va_list($va_name) $other_va_name
        lappend va_2_inner_va_list($other_va_name) $va_name
    } elseif { [get_attribute -objects [compute_polygons -operation not -objects1 [get_attribute $other_va region] -objects2 [get_attribute $va region]] -name shape_count] == 0 } {
      # ASSERT: $other_va inside $va.  For disjoint VA shapes, all VA shapes of $other_va are inside those of $va.
        lappend va_2_inner_va_list($va_name) $other_va_name
        #lappend va_2_outer_va_list($other_va_name) $va_name
        } elseif { [get_attribute -objects [compute_polygons -operation and -objects1 [get_attribute $va region] -objects2 [get_attribute $other_va region]] -name shape_count] > 0 } {
        # ASSERT: $va & $other_va partially overlap.  For disjoint VA shapes, any 1 or more of VA shapes partially overlap.
        # ASSERT: ICC2 won't create overlapping voltage areas, but possible due to user edit later.
        P_msg_error "$proc_name: Detect 2 voltage areas '$va_name $other_va_name' partially overlap each other!  Expect no partially overlap between shapes!"
      } elseif { [get_attribute -objects [compute_polygons -operation or -objects1 [get_attribute $va region] -objects2 [get_attribute $other_va region]] -name shape_count] < [get_attribute -objects $va -name shape_count] + [get_attribute -objects $other_va -name shape_count] } {
      # ASSERT: $va & $other_va abut.  For disjoint VA shapes, any 1 or more of VA shapes abut.
      #lappend va_2_abut_va_list($va_name) $other_va_name
      #lappend va_2_abut_va_list($other_va_name) $va_name
      }
      }
    }
    # TOOO: Find children inner vas only instead of descendants inner vas.

    if { [llength $out_cmd_file] > 0 } {
    # TODO: Check dir write permission.
      file mkdir [file dirname $out_cmd_file]
      set out_cmd_list "{# [file tail $out_cmd_file]}"
      lappend out_cmd_list "# Commands run by $proc_name proc for [get_object_name [current_block]] block."
    }

    # ASSERT: m2 is top-layer of input always-on power pin for all power switch cells in lib.
    set sw_cell_aon_pin_top_layer_name m2
    foreach_in_collection va $vas {
      set va_name [get_object_name $va]
      set pd_name [get_object_name [get_power_domains -of_objects $va]]
      if { [sizeof_collection [set ps_cells [get_cells -quiet -filter {is_power_switch == true} -of_objects $va]]] > 0 } {
        foreach_in_collection cell $ps_cells {
        # Somehow, pg_type == primary, instead of backup.
        # changed pin_direction from "in" to inout 
          if { [sizeof_collection [set aon_pin [get_pins -quiet -filter {port_type == power && pin_direction == inout} -of_objects $cell]]] == 0 } {
            P_msg_error "$proc_name: Unable to find input always-on power pin for power switch cell '[get_object_name $cell]' of reference '[get_attribute -objects $cell -name ref_name]' in voltage area '$va_name'!"
            continue
          } elseif { [sizeof_collection [set aon_pin_top_lyr_shps [get_shapes -filter "layer_name == $sw_cell_aon_pin_top_layer_name" -of_objects $aon_pin]]] == 0 } {
            P_msg_error "$proc_name: Unable to find pin shape on layer '$sw_cell_aon_pin_top_layer_name' for input always-on power pin '[get_attribute -objects $aon_pin -name name]' for power switch cell '[get_object_name $cell]' of reference '[get_attribute -objects $cell -name ref_name]' in voltage area '$va_name'!"
            continue
          }
          # TODO: Check P/G net connection for aon pin.
          # TODO: Handle vertical dir of top layer for aon pin.
          set rgn_llx [lindex [lsort -real -increasing [get_attribute -objects $aon_pin_top_lyr_shps -name bbox_llx]] 0]
          set rgn_urx [lindex [lsort -real -decreasing [get_attribute -objects $aon_pin_top_lyr_shps -name bbox_urx]] 0]
          set rgn_lly [lindex [get_attribute -objects $cell -name boundary_bbox] 0 1]
          set rgn_ury [lindex [get_attribute -objects $cell -name boundary_bbox] 1 1]
          set rgn_cmd "create_pg_region rgn_va_${va_name}_ps_cell_[get_object_name $cell] -polygon {{$rgn_llx $rgn_lly} {$rgn_urx $rgn_ury}}"
          if { [llength $out_cmd_file] > 0 } {
            lappend out_cmd_list $rgn_cmd
          }
          if { $verb_opt } {
            P_msg_info "$proc_name: Running command '$rgn_cmd' ..."
          }
          eval $rgn_cmd
        }
      } elseif { [llength $pd_2_pwr_sw_list($pd_name)] > 0 } {
        P_msg_error "$proc_name: Missing power switch cell in voltage area '$va_name' of power domain '$pd_name'!  Skip creating extra always-on power mesh for power switch cell of UPF power switch '$pd_2_pwr_sw_list($pd_name)'!"
        continue
      }
    }

    # Generic parameterized P/G wire patterns for mesh & staple styles of P/G grids.
    set wptn_m_cmd {create_pg_wire_pattern wptn_mesh -parameters {layer direction width} -layer @layer -direction @direction -width @width}
    set wptn_s_cmd {create_pg_wire_pattern wptn_staple -parameters {layer direction width length} -layer @layer -direction @direction -width @width -low_end_reference_point 0 -high_end_reference_point @length}
    # Default via master rule.
    set svrl_d_cmd {set_pg_strategy_via_rule svrl_default -via_rule { {intersection: adjacent} {via_master: default} }}
    if { [llength $out_cmd_file] > 0 } {
      lappend out_cmd_list $wptn_m_cmd $wptn_s_cmd $svrl_d_cmd
    }
    if { $verb_opt } {
      P_msg_info "$proc_name: Running command '$wptn_m_cmd' ..."
      P_msg_info "$proc_name: Running command '$wptn_s_cmd' ..."
      P_msg_info "$proc_name: Running command '$svrl_d_cmd' ..."
    }
    eval $wptn_m_cmd
    eval $wptn_s_cmd
    eval $svrl_d_cmd

    set pg_metal_layer_order_list {}
    set pg_metal_layer_order_list1 {}
    array unset lyr_2_pg_stg
    set lyr_2_pg_stg(via_rule,[lindex $pg_layer_order_list 0]) svrl_default
    array unset lyr_2_pg_vmrl
    set lyr_2_pg_vmrl([lindex $pg_layer_order_list 0]) {}
    foreach lyr_name $pg_layer_order_list {
      if { [sizeof_collection [set lyr [get_layers -quiet $lyr_name]]] == 0 } {
        P_msg_error "$proc_name: Detect invalid layer name '$lyr_name'!"
        continue
      } elseif { [set lyr_type [get_attribute -objects $lyr -name layer_type]] == {via_cut} } {
        set upper_lyr_name [lindex $pg_layer_order_list [expr [lsearch -exact $pg_layer_order_list $lyr_name] + 1]]
        if { ![dict exists $pg_grid_dict $lyr_name] } {
          set lyr_2_pg_stg(via_rule,$upper_lyr_name) svrl_default
          set lyr_2_pg_vmrl($upper_lyr_name) {}
        } else {
          dict for {rule_key rule_val} [dict get $pg_grid_dict $lyr_name] {
            if { $rule_key == {via_master_rule} } {
              set svrl_cmd "set_pg_strategy_via_rule svrl_$lyr_name"
              # Unfortunately, no get_pg_via_master_rules command available.
              redirect -variable vm_rule_rpt { catch { report_pg_via_master_rules $rule_val } }
              if { [llength $rule_val] == 1 && [regexp -line "^Via definition rule: $rule_val$" $vm_rule_rpt] } {
                append svrl_cmd " -via_rule { {intersection: adjacent} {via_master: $rule_val} }"
                set lyr_2_pg_vmrl($upper_lyr_name) $rule_val
              } else {
                set vmrl_cmd "set_pg_via_master_rule vmrl_$lyr_name [list {*}$rule_val]"
                if { [llength $out_cmd_file] > 0 } {
                  lappend out_cmd_list $vmrl_cmd
                }
                if { $verb_opt } {
                  P_msg_info "$proc_name: Running command '$vmrl_cmd' ..."
                }
                eval $vmrl_cmd
                append svrl_cmd " -via_rule { {intersection: adjacent} {via_master: [lindex $vmrl_cmd 1]} }"
                set lyr_2_pg_vmrl($upper_lyr_name) [lindex $vmrl_cmd 1]
              }
              if { [llength $out_cmd_file] > 0 } {
                lappend out_cmd_list $svrl_cmd
              }
              if { $verb_opt } {
                P_msg_info "$proc_name: Running command '$svrl_cmd' ..."
              }
              eval $svrl_cmd
              set lyr_2_pg_stg(via_rule,$upper_lyr_name) [lindex $svrl_cmd 1]
            } else {
              P_msg_error "$proc_name: Detect invalid rule config '$rule_key' of value '[join $rule_val]' for via layer '$lyr_name' in 'INTEL_PG_GRID_CONFIG' var!"
              continue
            }
          }
        }
      } elseif { $lyr_type == {interconnect} } {
        if {[dict size [dict filter $pg_grid_dict key ${lyr_name}_*]] == 0} {
        lappend pg_metal_layer_order_list $lyr_name
        lappend pg_metal_layer_order_list1 $lyr_name
        set lyr_2_pg_stg(stg,$lyr_name) {}
        if { ![dict exists $pg_grid_dict $lyr_name] } {
          P_msg_error "$proc_name: Missing layer '$lyr_name' in'INTEL_PG_GRID_CONFIG'!"
          continue
        } elseif { [lsearch -exact [set tpl_key_list [dict keys [dict get $pg_grid_dict $lyr_name]]] pullback] < 0 } {
          P_msg_error "$proc_name: Missing boundary pullback 'pullback' for layer '$lyr_name' in 'INTEL_PG_GRID_CONFIG' var!"
          continue
        } elseif { [lsearch -exact $tpl_key_list ground] < 0 } {
          P_msg_error "$proc_name: Missing template 'ground' for layer '$lyr_name' in 'INTEL_PG_GRID_CONFIG' var!"
          continue
        } elseif { [lsearch -exact $tpl_key_list power] < 0 && [lsearch -exact $tpl_key_list power_va_primary] < 0 && ![regexp -line "^power_all_aon(,[12])?$" [join $tpl_key_list "\n"]] } {
          P_msg_error "$proc_name: Missing template 'power', 'power_va_primary', 'power_all_aon', 'power_all_aon,1' or 'power_all_aon,2' for layer '$lyr_name' in 'INTEL_PG_GRID_CONFIG' var!"
          continue
        }
        set lyr_dir [get_attribute -objects $lyr -name routing_direction]
        if { ![string is double -strict [set pullback [dict get $pg_grid_dict $lyr_name pullback]]] || $pullback < 0 } {
          P_msg_error "$proc_name: Invalid boundary pullback '$pullback' for layer '$lyr_name' in 'INTEL_PG_GRID_CONFIG' var!  Expect non-negative number!"
          continue
        }
        # TODO: Find macros within each VA.
        set rgn_blkg_list {}
        # Value pairs for create_pg_region -expand option refer to Y-enlargement for horizontal edges & X-enlargement for vertical edges, i.e. the opposite of resize_polygons -size option.
        if { $pullback <= 0 } {
          set rgn_expand {0 0}
        } elseif { $lyr_dir eq {horizontal} } {
        #       set rgn_expand "0 $pullback"
          set rgn_expand "0 [expr $pullback/2]"
        } else {
        #       set rgn_expand "$pullback 0 "
          set rgn_expand "[expr $pullback/2] 0"
        }
        foreach_in_collection cell [get_cells -quiet -physical_context -filter {design_type == macro || design_type == module} *] {
          set cell_name [get_object_name $cell]
          if { [sizeof_collection [add_to_collection [get_shapes -quiet -filter "layer_name == $lyr_name" -of_objects $cell] [get_routing_blockages -quiet -filter "layer_name == $lyr_name" -of_objects $cell]]] > 0 } {
            if { [get_attribute -objects $cell -name is_soft_macro] } {
              set rgn_cmd "create_pg_region rgn_layer_${lyr_name}_sm_$cell_name -block [list $cell_name]"
            } else {
            # Somehow, multiple hard macros in -group_of_macros option for blockage also block P/G routes between them.
              set rgn_cmd "create_pg_region rgn_layer_${lyr_name}_hm_$cell_name -group_of_macros [list $cell_name]"
            }

            if { [info exists pg_pullback(macro)] && $pg_pullback(macro) != "" } {

              foreach layer $pg_pullback(macro) {
                set pullback_macro([lindex $layer 0],macro) [lindex $layer 1]
              }
              set rgn_expand_macro $pullback_macro([lindex $lyr_name 0],macro)

              if { $rgn_expand_macro <= 0 } {
                set rgn_expand {0 0}
              } elseif { $lyr_dir eq {horizontal} } {
                set rgn_expand "0 $rgn_expand_macro"
              } else {
                set rgn_expand "$rgn_expand_macro 0"
              }
            }

            append rgn_cmd " -expand [list $rgn_expand]"
            if { [llength $out_cmd_file] > 0 } {
              lappend out_cmd_list $rgn_cmd
            }
            if { $verb_opt } {
              P_msg_info "$proc_name: Running command '$rgn_cmd' ..."
            }
            eval $rgn_cmd
            lappend rgn_blkg_list [lindex $rgn_cmd 1]
          }
        }
        dict for {tpl_name tpl_dict} [dict get $pg_grid_dict $lyr_name] {
          if { $tpl_name == {pullback} } {
            continue
          } elseif { [lsearch -exact $valid_pg_template_list $tpl_name] < 0 } {
            P_msg_error "$proc_name: Invalid template '$tpl_name' for layer '$lyr_name' in 'INTEL_PG_GRID_CONFIG' var!  Expect 1 of '$valid_pg_template_list'!"
            continue
          }
          if { ![dict exists $tpl_dict pitch] } {
            P_msg_error "$proc_name: Missing group pitch 'pitch' for template '$tpl_name' of layer '$lyr_name' in 'INTEL_PG_GRID_CONFIG' var!"
            continue
          } elseif { ![string is double -strict [set pitch [dict get $tpl_dict pitch]]] || $pitch <= 0 } {
            P_msg_error "$proc_name: Invalid group pitch '$pitch' for template '$tpl_name' of layer '$lyr_name' in 'INTEL_PG_GRID_CONFIG' var!  Expect positive number!"
            continue
          }
          if { ![dict exists $tpl_dict offset,width] } {
            P_msg_error "$proc_name: Missing offset & width pairs 'offset,width' for template '$tpl_name' of layer '$lyr_name' in 'INTEL_PG_GRID_CONFIG' var!"
            continue
          }
          foreach {offset width} [dict get $tpl_dict offset,width] {
            if { ![string is double -strict $offset] || $offset < 0 || $offset >= $pitch } {
              P_msg_error "$proc_name: Invalid offset '$offset' for template '$tpl_name' of layer '$lyr_name' in 'INTEL_PG_GRID_CONFIG' var!  Expect non-negative number smaller than pitch '$pitch'!"
              continue
            }
            if { ![string is double -strict $width] || $width <= 0 || $width >= $pitch } {
              P_msg_error "$proc_name: Invalid width '$width' for template '$tpl_name' of layer '$lyr_name' in 'INTEL_PG_GRID_CONFIG' var!  Expect positive number smaller than pitch '$pitch'!"
              continue
            }
          }
          if { [dict exists $tpl_dict staple] } {
            if { ![dict exists $tpl_dict staple repeat] } {
              P_msg_error "$proc_name: Missing segment repeat 'repeat' for staple of template '$tpl_name' of layer '$lyr_name' in 'INTEL_PG_GRID_CONFIG' var!"
              continue
            } elseif { ![string is double -strict [set repeat [dict get $tpl_dict staple repeat]]] || $repeat <= 0 } {
              P_msg_error "$proc_name: Invalid segment repeat '$repeat' for staple of template '$tpl_name' of layer '$lyr_name' in 'INTEL_PG_GRID_CONFIG' var!  Expect positive number!"
              continue
            }
            if { ![dict exists $tpl_dict staple start,length] } {
              P_msg_error "$proc_name: Missing start & length pairs 'start,length' for staple of template '$tpl_name' of layer '$lyr_name' in 'INTEL_PG_GRID_CONFIG' var!"
              continue
            }
            foreach {start length} [dict get $tpl_dict staple start,length] {
              if { ![string is double -strict $start] || $start < 0 || $start >= $repeat } {
                P_msg_error "$proc_name: Invalid start '$start' for staple of template '$tpl_name' of layer '$lyr_name' in 'INTEL_PG_GRID_CONFIG' var!  Expect non-negative number smaller than repeat '$repeat'!"
                continue
              }
              if { ![string is double -strict $length] || $length <= 0 || $length >= $repeat } {
                P_msg_error "$proc_name: Invalid length '$length' for staple of template '$tpl_name' of layer '$lyr_name' in 'INTEL_PG_GRID_CONFIG' var!  Expect positive number smaller than repeat '$repeat'!"
                continue
              }
            }
          }
          array unset pitch_pair
          array unset offset_pair
          set pitch_pair($dir_2_axis($lyr_dir)) $pitch
          if { [dict exists $tpl_dict staple] } {
            set pitch_pair($dir_2_axis($dir_2_ortho_dir($lyr_dir))) $repeat
          } else {
            set pitch_pair($dir_2_axis($dir_2_ortho_dir($lyr_dir))) 0
          }
          set tpl_ptn_list {}
          foreach {offset width} [dict get $tpl_dict offset,width] {
            set offset_pair($dir_2_axis($lyr_dir)) $offset
            if { [dict exists $tpl_dict staple] } {
              foreach {start length} [dict get $tpl_dict staple start,length] {
                set offset_pair($dir_2_axis($dir_2_ortho_dir($lyr_dir))) $start
                lappend tpl_ptn_list " {name: wptn_staple} {parameters: {$lyr_name $lyr_dir $width $length}} {offset: {$offset_pair(x) $offset_pair(y)}} {pitch: {$pitch_pair(x) $pitch_pair(y)}} "
              }
            } else {
              set offset_pair($dir_2_axis($dir_2_ortho_dir($lyr_dir))) 0
              lappend tpl_ptn_list " {name: wptn_mesh} {parameters: {$lyr_name $lyr_dir $width}} {offset: {$offset_pair(x) $offset_pair(y)}} {pitch: {$pitch_pair(x) $pitch_pair(y)}} "
            }
          }
          set ptn_cmd "create_pg_composite_pattern ptn_${lyr_name}_$tpl_name -add_patterns { $tpl_ptn_list }"
          if { [llength $out_cmd_file] > 0 } {
            lappend out_cmd_list $ptn_cmd
          }
          if { $verb_opt } {
            P_msg_info "$proc_name: Running command '$ptn_cmd' ..."
          }
          eval $ptn_cmd
          set ptn_name [lindex $ptn_cmd 1]
          if { [lsearch -exact {ground power} $tpl_name] >= 0 } {
            if { $tpl_name eq {ground} } {
              set net_name $pd_2_pg_net(gnd,$top_pd_name)
            } elseif { $tpl_name eq {power} } {
              set net_name $pd_2_pg_net(pwr_pri,$top_pd_name)
            } 

            set stg_cmd "set_pg_strategy stg_$ptn_name -pattern { {name: $ptn_name} {nets: $net_name} {offset_start: {0 0}} } -design_boundary"
            if { $pullback == 0 } {
              append stg_cmd " -extension { {stop: design_boundary_and_generate_pin} }"
            } else {
              append stg_cmd " -extension { {stop: -$pullback} }"
            }
            if { [llength $rgn_blkg_list] > 0 } {
              append stg_cmd " -blockage { {pg_regions: $rgn_blkg_list} }"
            }
            if { [llength $out_cmd_file] > 0 } {
              lappend out_cmd_list $stg_cmd
            }
            if { $verb_opt } {
              P_msg_info "$proc_name: Running command '$stg_cmd' ..."
            }
            eval $stg_cmd
            lappend lyr_2_pg_stg(stg,$lyr_name) [lindex $stg_cmd 1]
          } elseif { [string match power_va_aon* $tpl_name] || [string match power_all_aon* $tpl_name]} {
	    if {[string match power_va_aon* $tpl_name] && ($INTEL_POWER_PLAN eq "mesh_upf_2aosv")} {   
		set vas_1 [filter_collection $vas {full_name != DEFAULT_VA}]
	    } else { 
		set vas_1  $vas
	    }

            foreach_in_collection va $vas_1 {
              set va_name [get_object_name $va]
              set pd_name [get_object_name [get_power_domains -of_objects $va]]
              if { $tpl_name eq {power_va_aon} || $tpl_name eq {power_va_aon,1} } {
                set net_name [lindex $aon_net_order_list 0]
              } elseif { $tpl_name eq {power_va_aon,2} } {
                set net_name [lindex $aon_net_order_list 1]
              } elseif { $tpl_name eq {power_all_aon} || $tpl_name eq {power_all_aon,1} } {
                set net_name [lindex $aon_net_order_list 0]
              } elseif { $tpl_name eq {power_all_aon,2} } {
                set net_name [lindex $aon_net_order_list 1]
              }

              if { [llength $pd_2_pwr_sw_list($pd_name)] == 0 } {
              # TODO: Check if necessary to have extra always-on straps in non-shutdown voltage area.
              #continue
                set va_net_name $pd_2_pg_net(pwr_pri,$pd_name)
              } else {
                set va_net_name $pd_2_pg_net(pwr_aon,$pd_name)
              }
              if { $va_net_name != $net_name } {
                continue
              }
              set stg_cmd "set_pg_strategy stg_${ptn_name}_$va_name -pattern { {name: $ptn_name} {nets: $net_name} {offset_start: {0 0}} }"
              if { $va_name eq {DEFAULT_VA} } {
                append stg_cmd " -design_boundary"
                if { $pullback == 0 } {
                  append stg_cmd " -extension { {stop: design_boundary_and_generate_pin} }"
                } else {
                  append stg_cmd " -extension { {stop: -$pullback} }"
                }
              } else {
              # TODO: Extend P/G straps of power_va_aon* templates into $INTEL_LS_BOUND($voltage_area,{outer|inner}) beyond voltage area boundaries.
                append stg_cmd " -voltage_areas $va_name"
              }
              set other_va_blkg_list {}
              foreach_in_collection other_va [get_voltage_areas -quiet $va_2_inner_va_list($va_name)] {
                set other_va_name [get_object_name $other_va]
                set other_pd_name [get_object_name [get_power_domains -of_objects $other_va]]
                if { [llength $pd_2_pwr_sw_list($other_pd_name)] == 0 } {
                  set other_net_name $pd_2_pg_net(pwr_pri,$other_pd_name)
                } else {
                  set other_net_name $pd_2_pg_net(pwr_aon,$other_pd_name)
                }
                if { $other_net_name != $net_name } {
                  lappend other_va_blkg_list $other_va_name
                }
              }
              if { [llength $rgn_blkg_list] > 0 || [llength $other_va_blkg_list] > 0 } {
                append stg_cmd " -blockage {"
                if { [llength $rgn_blkg_list] > 0 } {
                  append stg_cmd " {pg_regions: $rgn_blkg_list}"
                }
                if { [llength $other_va_blkg_list] > 0 } {
                  append stg_cmd " {voltage_areas: $other_va_blkg_list}"
                }
                append stg_cmd " }"
              }
              if { [llength $out_cmd_file] > 0 } {
              lappend out_cmd_list $stg_cmd
              }
              if { $verb_opt } {
              P_msg_info "$proc_name: Running command '$stg_cmd' ..."
              }
              eval $stg_cmd
              lappend lyr_2_pg_stg(stg,$lyr_name) [lindex $stg_cmd 1]
              }
              } elseif { $tpl_name eq {power_va_primary} } {
              #
              #          if { $pullback == 0 } {
              #            P_msg_error "$proc_name: Detect unsupported boundary pullback '$pullback' for template '$tpl_name' of layer '$lyr_name' in 'INTEL_PG_GRID_CONFIG' var!  Expect positive number!"
              #            continue
              #          }
              foreach_in_collection va [filter_collection $vas {full_name != DEFAULT_VA}] {
              set va_name [get_object_name $va]
              # Separate P/G regions with numerical suffix appended are created for voltage area with disjoint VA shapes.

              if { [info exists pg_pullback(va)] && $pg_pullback(va) != "" } {

              foreach layer $pg_pullback(va) {
                set pullback_va([lindex $layer 0],va) [lindex $layer 1]
              }
              set rgn_expand_va $pullback_va([lindex $lyr_name 0],va)

              if { $rgn_expand_va == 0 } {
                P_msg_error "$proc_name: Detect unsupported boundary pullback '$rgn_expand_va' for template '$tpl_name' of layer '$lyr_name' in 'pg_pullback' var!  Expect positive number!"
                continue
              }

              if { $lyr_dir eq {horizontal} } {
                set rgn_expand "0 $rgn_expand_va"
              } else {
                set rgn_expand "$rgn_expand_va 0"
              }
            }

            set rgn_cmd "create_pg_region rgn_layer_${lyr_name}_va_$va_name -voltage_area $va_name -expand [list $rgn_expand]"
            if { [llength $out_cmd_file] > 0 } {
              lappend out_cmd_list $rgn_cmd
            }
            if { $verb_opt } {
              P_msg_info "$proc_name: Running command '$rgn_cmd' ..."
            }
            eval $rgn_cmd
          }
          foreach_in_collection va $vas {
            set va_name [get_object_name $va]
            set pd_name [get_object_name [get_power_domains -of_objects $va]]
            set net_name $pd_2_pg_net(pwr_pri,$pd_name)
            set stg_cmd "set_pg_strategy stg_${ptn_name}_$va_name -pattern { {name: $ptn_name} {nets: $net_name} {offset_start: {0 0}} }"
            if { $va_name eq {DEFAULT_VA} } {
              append stg_cmd " -design_boundary"
              if { $pullback == 0 } {
                append stg_cmd " -extension { {stop: design_boundary_and_generate_pin} }"
              } else {
                append stg_cmd " -extension { {stop: -$pullback} }"
              }
            } else {
            ##modified to adjust pull back for voltage area boundary 1/2 DR 
            #             append stg_cmd " -voltage_areas $va_name -extension { {stop: -$pullback} }"
            #
              if { [info exists pg_pullback(va)] && $pg_pullback(va) != "" } {
                foreach layer $pg_pullback(va) {
                  set pullback_va([lindex $layer 0],va) [lindex $layer 1]
                }
                set rgn_expand_va $pullback_va([lindex $lyr_name 0],va)
              }

              append stg_cmd " -voltage_areas $va_name -extension { {stop: -$rgn_expand_va} }"
            }
            set other_va_blkg_pg_rgn_list {}
            foreach_in_collection other_va [get_voltage_areas -quiet $va_2_inner_va_list($va_name)] {
              set other_va_name [get_object_name $other_va]
              set other_pd_name [get_object_name [get_power_domains -of_objects $other_va]]
              set other_net_name $pd_2_pg_net(pwr_pri,$other_pd_name)
              if { $other_net_name != $net_name && [sizeof_collection [set pg_rgns [get_pg_regions -quiet rgn_layer_${lyr_name}_va_$other_va_name*]]] > 0 } {
                lappend other_va_blkg_pg_rgn_list {*}[get_object_name $pg_rgns]
              }
            }
            if { [llength $rgn_blkg_list] > 0 || [llength $other_va_blkg_pg_rgn_list] > 0 } {
              append stg_cmd " -blockage { {pg_regions: $rgn_blkg_list $other_va_blkg_pg_rgn_list} }"
            }
            if { [llength $out_cmd_file] > 0 } {
              lappend out_cmd_list $stg_cmd
            }
            if { $verb_opt } {
              P_msg_info "$proc_name: Running command '$stg_cmd' ..."
            }
            eval $stg_cmd
            lappend lyr_2_pg_stg(stg,$lyr_name) [lindex $stg_cmd 1]
          }
        } elseif { $tpl_name eq {power_sw_cell_aon} } {
          foreach_in_collection va $vas {
            set va_name [get_object_name $va]
            set pd_name [get_object_name [get_power_domains -of_objects $va]]
            if { [llength $pd_2_pwr_sw_list($pd_name)] == 0 } {
              continue
            } else {
              set net_name $pd_2_pg_net(pwr_aon,$pd_name)
            }
            if { [sizeof_collection [set pg_rgns [get_pg_regions -quiet rgn_va_${va_name}_ps_cell_*]]] == 0 } {
              P_msg_error "$proc_name: Missing P/G region for power switch cells in voltage area '$va_name' of power domain '$pd_name'!  Skip creating extra always-on power mesh on layer '$lyr_name' for power switch cell!"
            } else {
              set stg_cmd "set_pg_strategy stg_${ptn_name}_$va_name -pattern { {name: $ptn_name} {nets: $net_name} {offset_start: {0 0}} } -pg_regions { [get_object_name $pg_rgns] }"
              if { [llength $out_cmd_file] > 0 } {
                lappend out_cmd_list $stg_cmd
              }
              if { $verb_opt } {
                P_msg_info "$proc_name: Running command '$stg_cmd' ..."
              }
              eval $stg_cmd
              lappend lyr_2_pg_stg(stg,$lyr_name) [lindex $stg_cmd 1]
            }
          }
        }
      }
    } elseif {[dict size [dict filter $pg_grid_dict key ${lyr_name}_*]] > 1} {
        lappend pg_metal_layer_order_list $lyr_name
        dict for { a b} [dict filter  $pg_grid_dict key ${lyr_name}_*] { 
        set lyr_name1 $a
        lappend pg_metal_layer_order_list1 $lyr_name1
        set lyr_2_pg_stg(stg,$lyr_name1) {}
        if { ![dict exists $pg_grid_dict $lyr_name1] } {
          P_msg_error "$proc_name: Missing layer '$lyr_name1' in'INTEL_PG_GRID_CONFIG'!"
          continue
        } elseif { [lsearch -exact [set tpl_key_list [dict keys [dict get $pg_grid_dict $lyr_name1]]] pullback] < 0 } {
          P_msg_error "$proc_name: Missing boundary pullback 'pullback' for layer '$lyr_name1' in 'INTEL_PG_GRID_CONFIG' var!"
          continue
        } elseif { [lsearch -exact $tpl_key_list ground] < 0 } {
          P_msg_error "$proc_name: Missing template 'ground' for layer '$lyr_name1' in 'INTEL_PG_GRID_CONFIG' var!"
          continue
        } elseif { [lsearch -exact $tpl_key_list power] < 0 && [lsearch -exact $tpl_key_list power_va_primary] < 0 && ![regexp -line "^power_all_aon(,[12])?$" [join $tpl_key_list "\n"]] } {
          P_msg_error "$proc_name: Missing template 'power', 'power_va_primary', 'power_all_aon', 'power_all_aon,1' or 'power_all_aon,2' for layer '$lyr_name1' in 'INTEL_PG_GRID_CONFIG' var!"
          continue
        }
        set lyr_dir [get_attribute -objects $lyr -name routing_direction]
        if { ![string is double -strict [set pullback [dict get $pg_grid_dict $lyr_name1 pullback]]] || $pullback < 0 } {
          P_msg_error "$proc_name: Invalid boundary pullback '$pullback' for layer '$lyr_name1' in 'INTEL_PG_GRID_CONFIG' var!  Expect non-negative number!"
          continue
        }
        if { ![info exists lyr_2_pg_stg(via_rule,$lyr_name1)] } {
	  set lyr_2_pg_stg(via_rule,$lyr_name1) svrl_default
       #   set lyr_2_pg_vmrl($lyr_name1) {}
        }

        # TODO: Find macros within each VA.
        set rgn_blkg_list {}
        # Value pairs for create_pg_region -expand option refer to Y-enlargement for horizontal edges & X-enlargement for vertical edges, i.e. the opposite of resize_polygons -size option.
        if { $pullback <= 0 } {
          set rgn_expand {0 0}
        } elseif { $lyr_dir eq {horizontal} } {
        #       set rgn_expand "0 $pullback"
          set rgn_expand "0 [expr $pullback/2]"
        } else {
        #       set rgn_expand "$pullback 0 "
          set rgn_expand "[expr $pullback/2] 0"
        }
        foreach_in_collection cell [get_cells -quiet -physical_context -filter {design_type == macro || design_type == module} *] {
          set cell_name [get_object_name $cell]
          if { [sizeof_collection [add_to_collection [get_shapes -quiet -filter "layer_name == $lyr_name" -of_objects $cell] [get_routing_blockages -quiet -filter "layer_name == $lyr_name" -of_objects $cell]]] > 0 } {
            if { [get_attribute -objects $cell -name is_soft_macro] } {
              set rgn_cmd "create_pg_region rgn_layer_${lyr_name1}_sm_$cell_name -block [list $cell_name]"
            } else {
            # Somehow, multiple hard macros in -group_of_macros option for blockage also block P/G routes between them.
              set rgn_cmd "create_pg_region rgn_layer_${lyr_name1}_hm_$cell_name -group_of_macros [list $cell_name]"
            }

            if { [info exists pg_pullback(macro)] && $pg_pullback(macro) != "" } {

              foreach layer $pg_pullback(macro) {
                set pullback_macro([lindex $layer 0],macro) [lindex $layer 1]
              }
              set rgn_expand_macro $pullback_macro([lindex $lyr_name 0],macro)

              if { $rgn_expand_macro <= 0 } {
                set rgn_expand {0 0}
              } elseif { $lyr_dir eq {horizontal} } {
                set rgn_expand "0 $rgn_expand_macro"
              } else {
                set rgn_expand "$rgn_expand_macro 0"
              }
            }

            append rgn_cmd " -expand [list $rgn_expand]"
            if { [llength $out_cmd_file] > 0 } {
              lappend out_cmd_list $rgn_cmd
            }
            if { $verb_opt } {
              P_msg_info "$proc_name: Running command '$rgn_cmd' ..."
            }
            eval $rgn_cmd
            lappend rgn_blkg_list [lindex $rgn_cmd 1]
          }
        }
        dict for {tpl_name tpl_dict} [dict get $pg_grid_dict $lyr_name1] {
          if { $tpl_name == {pullback} } {
            continue
          } elseif { [lsearch -exact $valid_pg_template_list $tpl_name] < 0 } {
            P_msg_error "$proc_name: Invalid template '$tpl_name' for layer '$lyr_name1' in 'INTEL_PG_GRID_CONFIG' var!  Expect 1 of '$valid_pg_template_list'!"
            continue
          }
          if { ![dict exists $tpl_dict pitch] } {
            P_msg_error "$proc_name: Missing group pitch 'pitch' for template '$tpl_name' of layer '$lyr_name1' in 'INTEL_PG_GRID_CONFIG' var!"
            continue
          } elseif { ![string is double -strict [set pitch [dict get $tpl_dict pitch]]] || $pitch <= 0 } {
            P_msg_error "$proc_name: Invalid group pitch '$pitch' for template '$tpl_name' of layer '$lyr_name1' in 'INTEL_PG_GRID_CONFIG' var!  Expect positive number!"
            continue
          }
          if { ![dict exists $tpl_dict offset,width] } {
            P_msg_error "$proc_name: Missing offset & width pairs 'offset,width' for template '$tpl_name' of layer '$lyr_name1' in 'INTEL_PG_GRID_CONFIG' var!"
            continue
          }
          foreach {offset width} [dict get $tpl_dict offset,width] {
            if { ![string is double -strict $offset] || $offset < 0 || $offset >= $pitch } {
              P_msg_error "$proc_name: Invalid offset '$offset' for template '$tpl_name' of layer '$lyr_name1' in 'INTEL_PG_GRID_CONFIG' var!  Expect non-negative number smaller than pitch '$pitch'!"
              continue
            }
            if { ![string is double -strict $width] || $width <= 0 || $width >= $pitch } {
              P_msg_error "$proc_name: Invalid width '$width' for template '$tpl_name' of layer '$lyr_name1' in 'INTEL_PG_GRID_CONFIG' var!  Expect positive number smaller than pitch '$pitch'!"
              continue
            }
          }
          if { [dict exists $tpl_dict staple] } {
            if { ![dict exists $tpl_dict staple repeat] } {
              P_msg_error "$proc_name: Missing segment repeat 'repeat' for staple of template '$tpl_name' of layer '$lyr_name1' in 'INTEL_PG_GRID_CONFIG' var!"
              continue
            } elseif { ![string is double -strict [set repeat [dict get $tpl_dict staple repeat]]] || $repeat <= 0 } {
              P_msg_error "$proc_name: Invalid segment repeat '$repeat' for staple of template '$tpl_name' of layer '$lyr_name1' in 'INTEL_PG_GRID_CONFIG' var!  Expect positive number!"
              continue
            }
            if { ![dict exists $tpl_dict staple start,length] } {
              P_msg_error "$proc_name: Missing start & length pairs 'start,length' for staple of template '$tpl_name' of layer '$lyr_name1' in 'INTEL_PG_GRID_CONFIG' var!"
              continue
            }
            foreach {start length} [dict get $tpl_dict staple start,length] {
              if { ![string is double -strict $start] || $start < 0 || $start >= $repeat } {
                P_msg_error "$proc_name: Invalid start '$start' for staple of template '$tpl_name' of layer '$lyr_name1' in 'INTEL_PG_GRID_CONFIG' var!  Expect non-negative number smaller than repeat '$repeat'!"
                continue
              }
              if { ![string is double -strict $length] || $length <= 0 || $length >= $repeat } {
                P_msg_error "$proc_name: Invalid length '$length' for staple of template '$tpl_name' of layer '$lyr_name1' in 'INTEL_PG_GRID_CONFIG' var!  Expect positive number smaller than repeat '$repeat'!"
                continue
              }
            }
          }
          array unset pitch_pair
          array unset offset_pair
          set pitch_pair($dir_2_axis($lyr_dir)) $pitch
          if { [dict exists $tpl_dict staple] } {
            set pitch_pair($dir_2_axis($dir_2_ortho_dir($lyr_dir))) $repeat
          } else {
            set pitch_pair($dir_2_axis($dir_2_ortho_dir($lyr_dir))) 0
          }
          set tpl_ptn_list {}
          foreach {offset width} [dict get $tpl_dict offset,width] {
            set offset_pair($dir_2_axis($lyr_dir)) $offset
            if { [dict exists $tpl_dict staple] } {
              foreach {start length} [dict get $tpl_dict staple start,length] {
                set offset_pair($dir_2_axis($dir_2_ortho_dir($lyr_dir))) $start
                lappend tpl_ptn_list " {name: wptn_staple} {parameters: {$lyr_name $lyr_dir $width $length}} {offset: {$offset_pair(x) $offset_pair(y)}} {pitch: {$pitch_pair(x) $pitch_pair(y)}} "
              }
            } else {
              set offset_pair($dir_2_axis($dir_2_ortho_dir($lyr_dir))) 0
              lappend tpl_ptn_list " {name: wptn_mesh} {parameters: {$lyr_name $lyr_dir $width}} {offset: {$offset_pair(x) $offset_pair(y)}} {pitch: {$pitch_pair(x) $pitch_pair(y)}} "
            }
          }
          set ptn_cmd "create_pg_composite_pattern ptn_${lyr_name1}_$tpl_name -add_patterns { $tpl_ptn_list }"
          if { [llength $out_cmd_file] > 0 } {
            lappend out_cmd_list $ptn_cmd
          }
          if { $verb_opt } {
            P_msg_info "$proc_name: Running command '$ptn_cmd' ..."
          }
          eval $ptn_cmd
          set ptn_name [lindex $ptn_cmd 1]
          if { [lsearch -exact {ground power} $tpl_name] >= 0} {
            if { $tpl_name eq {ground} } {
              set net_name $pd_2_pg_net(gnd,$top_pd_name)
            } elseif { $tpl_name eq {power} } {
              set net_name $pd_2_pg_net(pwr_pri,$top_pd_name)
            } 

            set stg_cmd "set_pg_strategy stg_$ptn_name -pattern { {name: $ptn_name} {nets: $net_name} {offset_start: {0 0}} } -design_boundary"
            if { $pullback == 0 } {
              append stg_cmd " -extension { {stop: design_boundary_and_generate_pin} }"
            } else {
              append stg_cmd " -extension { {stop: -$pullback} }"
            }
            if { [llength $rgn_blkg_list] > 0 } {
              append stg_cmd " -blockage { {pg_regions: $rgn_blkg_list} }"
            }
            if { [llength $out_cmd_file] > 0 } {
              lappend out_cmd_list $stg_cmd
            }
            if { $verb_opt } {
              P_msg_info "$proc_name: Running command '$stg_cmd' ..."
            }
            eval $stg_cmd
            lappend lyr_2_pg_stg(stg,$lyr_name1) [lindex $stg_cmd 1]
          } elseif { [string match power_va_aon* $tpl_name] || [string match power_all_aon* $tpl_name]} {
	    if {[string match power_va_aon* $tpl_name] && ($INTEL_POWER_PLAN eq "mesh_upf_2aosv")} {   
		set vas_2 [filter_collection $vas {full_name != DEFAULT_VA}]
	    } else { 
		set vas_2  $vas
	    }

            foreach_in_collection va $vas_2 {
              set va_name [get_object_name $va]
              set pd_name [get_object_name [get_power_domains -of_objects $va]]
              if { $tpl_name eq {power_va_aon} || $tpl_name eq {power_va_aon,1} } {
                set net_name [lindex $aon_net_order_list 0]
              } elseif { $tpl_name eq {power_va_aon,2} } {
                set net_name [lindex $aon_net_order_list 1]
              } elseif { $tpl_name eq {power_all_aon} || $tpl_name eq {power_all_aon,1} } {
                set net_name [lindex $aon_net_order_list 0]
              } elseif { $tpl_name eq {power_all_aon,2} } {
                set net_name [lindex $aon_net_order_list 1]
              }
              if { [llength $pd_2_pwr_sw_list($pd_name)] == 0 } {
              # TODO: Check if necessary to have extra always-on straps in non-shutdown voltage area.
              #continue
                set va_net_name $pd_2_pg_net(pwr_pri,$pd_name)
              } else {
                set va_net_name $pd_2_pg_net(pwr_aon,$pd_name)
              }
              if { $va_net_name != $net_name } {
                continue
              }
              set stg_cmd "set_pg_strategy stg_${ptn_name}_$va_name -pattern { {name: $ptn_name} {nets: $net_name} {offset_start: {0 0}} }"
              if { $va_name eq {DEFAULT_VA} } {
                append stg_cmd " -design_boundary"
                if { $pullback == 0 } {
                  append stg_cmd " -extension { {stop: design_boundary_and_generate_pin} }"
                } else {
                  append stg_cmd " -extension { {stop: -$pullback} }"
                }
              } else {
              # TODO: Extend P/G straps of power_va_aon* templates into $INTEL_LS_BOUND($voltage_area,{outer|inner}) beyond voltage area boundaries.
                append stg_cmd " -voltage_areas $va_name"
              }
              set other_va_blkg_list {}
              foreach_in_collection other_va [get_voltage_areas -quiet $va_2_inner_va_list($va_name)] {
                set other_va_name [get_object_name $other_va]
                set other_pd_name [get_object_name [get_power_domains -of_objects $other_va]]
                if { [llength $pd_2_pwr_sw_list($other_pd_name)] == 0 } {
                  set other_net_name $pd_2_pg_net(pwr_pri,$other_pd_name)
                } else {
                  set other_net_name $pd_2_pg_net(pwr_aon,$other_pd_name)
                }
                if { $other_net_name != $net_name } {
                  lappend other_va_blkg_list $other_va_name
                }
              }
              if { [llength $rgn_blkg_list] > 0 || [llength $other_va_blkg_list] > 0 } {
                append stg_cmd " -blockage {"
                if { [llength $rgn_blkg_list] > 0 } {
                  append stg_cmd " {pg_regions: $rgn_blkg_list}"
                }
                if { [llength $other_va_blkg_list] > 0 } {
                  append stg_cmd " {voltage_areas: $other_va_blkg_list}"
                }
                append stg_cmd " }"
              }
              if { [llength $out_cmd_file] > 0 } {
              lappend out_cmd_list $stg_cmd
              }
              if { $verb_opt } {
              P_msg_info "$proc_name: Running command '$stg_cmd' ..."
              }
              eval $stg_cmd
              lappend lyr_2_pg_stg(stg,$lyr_name1) [lindex $stg_cmd 1]
              }
              } elseif { $tpl_name eq {power_va_primary} } {
              #
              #          if { $pullback == 0 } {
              #            P_msg_error "$proc_name: Detect unsupported boundary pullback '$pullback' for template '$tpl_name' of layer '$lyr_name1' in 'INTEL_PG_GRID_CONFIG' var!  Expect positive number!"
              #            continue
              #          }
              foreach_in_collection va [filter_collection $vas {full_name != DEFAULT_VA}] {
              set va_name [get_object_name $va]
              # Separate P/G regions with numerical suffix appended are created for voltage area with disjoint VA shapes.

              if { [info exists pg_pullback(va)] && $pg_pullback(va) != "" } {

              foreach layer $pg_pullback(va) {
                set pullback_va([lindex $layer 0],va) [lindex $layer 1]
              }
              set rgn_expand_va $pullback_va([lindex $lyr_name 0],va)

              if { $rgn_expand_va == 0 } {
                P_msg_error "$proc_name: Detect unsupported boundary pullback '$rgn_expand_va' for template '$tpl_name' of layer '$lyr_name1' in 'pg_pullback' var!  Expect positive number!"
                continue
              }

              if { $lyr_dir eq {horizontal} } {
                set rgn_expand "0 $rgn_expand_va"
              } else {
                set rgn_expand "$rgn_expand_va 0"
              }
            }

            set rgn_cmd "create_pg_region rgn_layer_${lyr_name1}_va_$va_name -voltage_area $va_name -expand [list $rgn_expand]"
            if { [llength $out_cmd_file] > 0 } {
              lappend out_cmd_list $rgn_cmd
            }
            if { $verb_opt } {
              P_msg_info "$proc_name: Running command '$rgn_cmd' ..."
            }
            eval $rgn_cmd
          }
          foreach_in_collection va $vas {
            set va_name [get_object_name $va]
            set pd_name [get_object_name [get_power_domains -of_objects $va]]
            set net_name $pd_2_pg_net(pwr_pri,$pd_name)
            set stg_cmd "set_pg_strategy stg_${ptn_name}_$va_name -pattern { {name: $ptn_name} {nets: $net_name} {offset_start: {0 0}} }"
            if { $va_name eq {DEFAULT_VA} } {
              append stg_cmd " -design_boundary"
              if { $pullback == 0 } {
                append stg_cmd " -extension { {stop: design_boundary_and_generate_pin} }"
              } else {
                append stg_cmd " -extension { {stop: -$pullback} }"
              }
            } else {
            ##modified to adjust pull back for voltage area boundary 1/2 DR 
            #             append stg_cmd " -voltage_areas $va_name -extension { {stop: -$pullback} }"
            #
              if { [info exists pg_pullback(va)] && $pg_pullback(va) != "" } {
                foreach layer $pg_pullback(va) {
                  set pullback_va([lindex $layer 0],va) [lindex $layer 1]
                }
                set rgn_expand_va $pullback_va([lindex $lyr_name 0],va)
              }

              append stg_cmd " -voltage_areas $va_name -extension { {stop: -$rgn_expand_va} }"
            }
            set other_va_blkg_pg_rgn_list {}
            foreach_in_collection other_va [get_voltage_areas -quiet $va_2_inner_va_list($va_name)] {
              set other_va_name [get_object_name $other_va]
              set other_pd_name [get_object_name [get_power_domains -of_objects $other_va]]
              set other_net_name $pd_2_pg_net(pwr_pri,$other_pd_name)
              if { $other_net_name != $net_name && [sizeof_collection [set pg_rgns [get_pg_regions -quiet rgn_layer_${lyr_name1}_va_$other_va_name*]]] > 0 } {
                lappend other_va_blkg_pg_rgn_list {*}[get_object_name $pg_rgns]
              }
            }
            if { [llength $rgn_blkg_list] > 0 || [llength $other_va_blkg_pg_rgn_list] > 0 } {
              append stg_cmd " -blockage { {pg_regions: $rgn_blkg_list $other_va_blkg_pg_rgn_list} }"
            }
            if { [llength $out_cmd_file] > 0 } {
              lappend out_cmd_list $stg_cmd
            }
            if { $verb_opt } {
              P_msg_info "$proc_name: Running command '$stg_cmd' ..."
            }
            eval $stg_cmd
            lappend lyr_2_pg_stg(stg,$lyr_name1) [lindex $stg_cmd 1]
          }
        } elseif { $tpl_name eq {power_sw_cell_aon} } {
          foreach_in_collection va $vas {
            set va_name [get_object_name $va]
            set pd_name [get_object_name [get_power_domains -of_objects $va]]
            if { [llength $pd_2_pwr_sw_list($pd_name)] == 0 } {
              continue
            } else {
              set net_name $pd_2_pg_net(pwr_aon,$pd_name)
            }
            if { [sizeof_collection [set pg_rgns [get_pg_regions -quiet rgn_va_${va_name}_ps_cell_*]]] == 0 } {
              P_msg_error "$proc_name: Missing P/G region for power switch cells in voltage area '$va_name' of power domain '$pd_name'!  Skip creating extra always-on power mesh on layer '$lyr_name' for power switch cell!"
            } else {
              set stg_cmd "set_pg_strategy stg_${ptn_name}_$va_name -pattern { {name: $ptn_name} {nets: $net_name} {offset_start: {0 0}} } -pg_regions { [get_object_name $pg_rgns] }"
              if { [llength $out_cmd_file] > 0 } {
                lappend out_cmd_list $stg_cmd
              }
              if { $verb_opt } {
                P_msg_info "$proc_name: Running command '$stg_cmd' ..."
              }
              eval $stg_cmd
              lappend lyr_2_pg_stg(stg,$lyr_name1) [lindex $stg_cmd 1]
            }
          }
        }
      }
    }
    #set lyr_2_pg_stg(stg,$lyr_name1) [lsort -decreasing $lyr_2_pg_stg(stg,$lyr_name1)]
   }
 } else {
      P_msg_error "$proc_name: Invalid layer type '$lyr_type' for layer '$lyr_name'!  Expect 'interconnect' or 'via_cut'!"
  }
}

if { [llength $rpt_prefix] > 0 } {
# TODO: Check dir write permission.
  file mkdir [file dirname $rpt_prefix]
  report_app_options plan.pgroute.* > $rpt_prefix.app_options.plan.pg_route.rpt
  report_pg_via_master_rules > $rpt_prefix.pg_via_master_rules.rpt
  report_pg_strategy_via_rules > $rpt_prefix.pg_strategy_via_rules.rpt
  report_pg_patterns > $rpt_prefix.pg_patterns.rpt
  report_pg_regions > $rpt_prefix.pg_regions.rpt
  report_pg_strategies > $rpt_prefix.pg_strategies.rpt
}

# Not sure why compile_pg won't automatically add vias from P/G straps to soft macro P/G pins.  Yet, OK with hard macro P/G pins.
array unset macro_2_top_lyr
foreach_in_collection cell [get_cells -quiet -physical_context -filter {design_type == module}] {
  set macro_2_top_lyr([get_object_name $cell]) [lindex [get_object_name [sort_collection [get_layers -quiet -filter {layer_type == interconnect && mask_order >= 0 && mask_name =~ metal*} [lsort -unique [get_attribute -objects [add_to_collection [get_shapes -quiet -of_objects $cell] [get_routing_blockages -quiet -of_objects $cell]] -name layer_name]]] mask_order]] end]
}

set lower_lyr_name {}
foreach lyr_name $pg_metal_layer_order_list1 {
  if { $verb_opt } {
    set pg_lyr_start_time [clock seconds]
    P_msg_info "$proc_name: Start '$lyr_name' layer P/G grid at [clock format $pg_lyr_start_time] ..."
  }
  if { ![info exists lyr_2_pg_stg(stg,$lyr_name)] } {
    P_msg_error "$proc_name: Missing P/G strategy for for layer '$lyr_name'!"
    continue
  }
  if { ![info exists lyr_2_pg_stg(via_rule,$lyr_name)] } {
    P_msg_error "$proc_name: Missing P/G strategy via rule for layer '$lyr_name'!"
    continue
  }
  set cmp_cmd "compile_pg -strategies [list $lyr_2_pg_stg(stg,$lyr_name)] -via_rule $lyr_2_pg_stg(via_rule,$lyr_name)"
  if { [llength $out_cmd_file] > 0 } {
    lappend out_cmd_list $cmp_cmd
  }
  if { $verb_opt } {
    P_msg_info "$proc_name: Running command '$cmp_cmd' ..."
  }
  eval $cmp_cmd
  if { $verb_opt } {
    P_msg_info "$proc_name: Done '$lyr_name' layer P/G grid at [clock format [clock seconds]]."
    set elapsed_secs [expr [clock seconds] - $pg_lyr_start_time]
    P_msg_info "$proc_name: Run-time for '$lyr_name' layer P/G grid = [format {%dh:%02dm:%02ds} [expr $elapsed_secs / 3600] [expr $elapsed_secs % 3600 / 60] [expr $elapsed_secs % 60]]"
  }
  if { [llength $lower_lyr_name] == 0 } {
    set lower_lyr_name $lyr_name
    continue
  }
  if { $verb_opt } {
    set pg_via_start_time [clock seconds]
    P_msg_info "$proc_name: Start macro P/G vias between '$lyr_name' & '$lower_lyr_name' layers at [clock format $pg_via_start_time] ..."
  }
  foreach_in_collection va $vas {
    set pd_name [get_object_name [get_power_domains -of_objects $va]]
    set va_cells {}
    foreach_in_collection cell [get_cells -quiet -filter {design_type == module} -of_objects $va] {
      if { $macro_2_top_lyr([get_object_name $cell]) == $lower_lyr_name } {
        append_to_collection va_cells $cell
      }
    }
    if { [sizeof_collection $va_cells] > 0 } {
    # Somehow, create_pg_vias -nets & -{from,to}_layers options only allow net & layer names respectively, but not net or layer object.
      set pg_via_cmd "create_pg_vias -nets {$pd_2_pg_net(gnd,$pd_name) $pd_2_pg_net(pwr_pri,$pd_name)} -within_bbox [list [get_attribute -objects $va_cells -name boundary]] -from_types strap -from_layers $lyr_name -to_types macro_pin -to_layers $lower_lyr_name"
      if { [llength $lyr_2_pg_vmrl($lyr_name)] > 0 } {
        append pg_via_cmd " -via_masters [list $lyr_2_pg_vmrl($lyr_name)]"
      }
      if { [llength $out_cmd_file] > 0 } {
        lappend out_cmd_list $pg_via_cmd
      }
      if { $verb_opt } {
        P_msg_info "$proc_name: Running command '$pg_via_cmd' ..."
      }
      eval $pg_via_cmd
    }
  }
  if { $verb_opt } {
    P_msg_info "$proc_name: Done macro P/G vias between '$lyr_name' & '$lower_lyr_name' layers at [clock format [clock seconds]]."
    set elapsed_secs [expr [clock seconds] - $pg_via_start_time]
    P_msg_info "$proc_name: Run-time for macro P/G vias between '$lyr_name' & '$lower_lyr_name' layers = [format {%dh:%02dm:%02ds} [expr $elapsed_secs / 3600] [expr $elapsed_secs % 3600 / 60] [expr $elapsed_secs % 60]]"
  }
  set lower_lyr_name $lyr_name
}

if { !$keep_spec_opt } {
# Somehow, only remove_pg_regions supports wildcard.
# TODO: Delete only P/G specs created.
  remove_pg_regions -all
  remove_pg_strategies -all
  remove_pg_patterns -all
  remove_pg_strategy_via_rules -all
  remove_pg_via_master_rules -all
}

# Not sure why compile_pg won't automatically add v2 vias from P/G straps to power switch input always-on power pins.
set sw_cell_aon_pin_above_layer_name [lindex $pg_metal_layer_order_list [expr [lsearch -exact $pg_metal_layer_order_list $sw_cell_aon_pin_top_layer_name] + 1]]
foreach_in_collection va $vas {
  set va_name [get_object_name $va]
  set pd_name [get_object_name [get_power_domains -of_objects $va]]
  if { [llength $pd_2_pwr_sw_list($pd_name)] == 0 } {
    continue
  }
  if { $verb_opt } {
    set pg_via_va_start_time [clock seconds]
    P_msg_info "$proc_name: Start '$va_name' voltage area power switch P/G vias at [clock format $pg_via_va_start_time] ..."
  }
  set net_name $pd_2_pg_net(pwr_aon,$pd_name)
  # Somehow, create_pg_vias -nets & -{from,to}_layers options only allow net & layer names respectively, but not net or layer object.
  ## remove via insertion to power switch pin because of via ladder implementation
  #    set pg_via_cmd "create_pg_vias -nets $net_name -within_bbox [list [get_attribute -objects $va -name region]] -from_types strap -from_layers $sw_cell_aon_pin_above_layer_name -to_types pwrswitch_pin -to_layers $sw_cell_aon_pin_top_layer_name"
  set pg_via_cmd ""
  if { [llength $out_cmd_file] > 0 } {
    lappend out_cmd_list $pg_via_cmd
  }
  if { $verb_opt } {
    P_msg_info "$proc_name: Running command '$pg_via_cmd' ..."
  }
  eval $pg_via_cmd
  if { $verb_opt } {
    P_msg_info "$proc_name: Done '$va_name' voltage area power switch P/G vias at [clock format [clock seconds]]."
    set elapsed_secs [expr [clock seconds] - $pg_via_va_start_time]
    P_msg_info "$proc_name: Run-time for '$va_name' voltage area power switch P/G vias = [format {%dh:%02dm:%02ds} [expr $elapsed_secs / 3600] [expr $elapsed_secs % 3600 / 60] [expr $elapsed_secs % 60]]"
  }
}
if { [llength $out_cmd_file] > 0 } {
  lappend out_cmd_list "# Total [expr [llength $out_cmd_list] - 2] commands run by $proc_name proc." {# EOF}
    redirect $out_cmd_file {
      echo [join $out_cmd_list "\n"]
    }
  }
  return 1
}

define_proc_attributes create_pg_grid \
  -info "Create P/G grids, in partition and voltage areas for UPF, with layers in INTEL_PG_GRID_CONFIG from INTEL_MIN_PG_LAYER up to INTEL_MAX_PG_LAYER.  For dual always-on supply UPF, mapping of aon,1 & aon,2 to always-on power nets is based on their orders in INTEL_UPF_POWER_NETS." \
  -define_args {
    {-force "Delete pre-existing P/G objects (straps & vias), instead of display error messages" {} boolean optional}
    {-output_command_file "Output file to capture ICC2 commands run to create P/G grids. Default: No output" {} string optional}
    {-report_prefix "Prefix of report output files for intermediate P/G specs created. Default: No report" {} string optional}
    {-keep_spec "Keep without deleting intermediate P/G specs (regions, patterns, strategies & via rules) from design block" {} boolean optional}
    {-verbose "Display verbose informational messages" {} boolean optional}
}

set scr_name [file rootname [file tail [info script]]]

set pg_start_time [clock seconds]
P_msg_info "$scr_name: Start P/G grids at [clock format $pg_start_time] ..."

set _w 0
set _ht 0.050
set _bnd [create_geo_mask -objects [get_attribute [current_block] boundary]]
set _bnd_resized [resize_polygons -objects $_bnd -size "-$_w -$_ht"]
set _slivers [split_polygons -objects [compute_polygons -objects1 $_bnd -operation NOT -objects2 $_bnd_resized]]
foreach_in_col each [get_attr $_slivers poly_rects] {
  create_routing_blockage -boundary [get_attr $each point_list] -layers [get_layers m* -filter "routing_direction==horizontal"] -name_prefix rtblkg_bdr_forpg_
}

set _w 0.05
set _ht 0
set _bnd [create_geo_mask -objects [get_attribute [current_block] boundary]]
set _bnd_resized [resize_polygons -objects $_bnd -size "-$_w -$_ht"]
set _slivers [split_polygons -objects [compute_polygons -objects1 $_bnd -operation NOT -objects2 $_bnd_resized]]
foreach_in_col each [get_attr $_slivers poly_rects] {
  create_routing_blockage -boundary [get_attr $each point_list] -layers [get_layers m* -filter "routing_direction==vertical"] -name_prefix rtblkg_bdr_forpg_
}

#create_pg_grid -output_command_file ./reports/$INTEL_DESIGN_NAME.floorplan.create_pg_grid.txt -report_prefix ./reports/$INTEL_DESIGN_NAME.floorplan
create_pg_grid -output_command_file ./reports/$INTEL_DESIGN_NAME.floorplan.create_pg_grid.txt -report_prefix ./reports/$INTEL_DESIGN_NAME.floorplan -verbose -keep_spec
## added to create m1 PG which is parallel to m2
set m1_pg_straps [get_shapes -quiet -filter "layer_name==m1 && (net_type==power||net_type==ground)"]
if {[sizeof_collection $m1_pg_straps] > 0} {
  remove_objects $m1_pg_straps
}
set m2_pg_straps [get_shapes -quiet -filter "layer_name==m2 && (net_type==power||net_type==ground)"]
if {[sizeof_collection $m2_pg_straps] > 0} {
  foreach_in_collection pg_strap $m2_pg_straps {
    create_shape -boundary [get_attribute $pg_strap bbox] -layer m1 -shape_use stripe -shape_type rect -net [get_attribute $pg_strap net]
  }
}

if {[sizeof_collection [get_routing_blockages -quiet rtblkg_bdr_forpg_*]] != 0} {
  remove_routing_blockages rtblkg_bdr_forpg_*
}
P_msg_info "$scr_name: Done P/G grids at [clock format [clock seconds]]."
set elapsed_secs [expr [clock seconds] - $pg_start_time]
P_msg_info "$scr_name: Run-time for overall P/G grids = [format {%dh:%02dm:%02ds} [expr $elapsed_secs / 3600] [expr $elapsed_secs % 3600 / 60] [expr $elapsed_secs % 60]]"

unset scr_name

# EOF

