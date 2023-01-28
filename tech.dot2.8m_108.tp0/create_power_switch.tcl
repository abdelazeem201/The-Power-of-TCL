##############################################################
# NAME :          create_power_switch.tcl
#
# SUMMARY :       create power switch cells in design
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists create_power_switch.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_POWER_SWITCH(array) INTEL_PS_X_PITCH(array) INTEL_PS_Y_PITCH(array) INTEL_UPF_POWER_NETS INTEL_PS_ALIGN_PG_GRID(array) INTEL_PG_GRID_CONFIG 
#
# PROCS USED :    None
#                         
# DESCRIPTION :   create_power_switch.tcl is to create power switch cells in staggered array configurations aligned to always-on P/G grids in all voltage areas based on the default values of INTEL_* variables
#
# EXAMPLES :      
#
###############################################################

##############################################################################
# Description: This script creates power switch cells in staggered array configurations aligned to always-on P/G grids in all voltage areas based on the default values of INTEL_* variables described below.
#
#  set INTEL_POWER_SWITCH(default) b15psbf20bl1qfkx5
#  set INTEL_PS_X_PITCH(default) 8.64
#  set INTEL_PS_Y_PITCH(default) 5.04
#
#  set INTEL_UPF_POWER_NETS {vss vcc}
#  set INTEL_POWER_PLAN mesh_upf_1aosv
#
#  set INTEL_PS_ALIGN_PG_GRID(mesh_upf_1aosv) {{m5 power_va_aon} {m6 power_all_aon}}
#  set INTEL_PS_ALIGN_PG_GRID(mesh_upf_2aosv) {{m6 power_va_aon,1 power_va_aon,2} {m7 power_all_aon,1 power_all_aon,2}}
#
#  set INTEL_TAP_CELL b15ztpn00an1d00x5
#
# Users may overwrite the default values for voltage areas of specific power domains and different power plans.
#
#   INTEL_POWER_SWITCH($power_domain) = Power switch lib cell to implement power switch cells in staggered array configuration.  Supports both single control & dual control power switch lib cell, but must match control of UPF power switch strategy.
#   INTEL_PS_X_PITCH($power_domain) = Horizontal pitch between power switch cells of adjacent staggered columns in staggered array.  Must be multiple of $INTEL_MD_GRID_X.
#   INTEL_PS_Y_PITCH($power_domain) = Vertical pitch between power switch cells of adjacent staggered rows in staggered array.  Must be multiple of $INTEL_MD_GRID_Y.
#
#   INTEL_UPF_POWER_NETS = UPF P/G nets as defined in UPF loaded to design.
#   INTEL_POWER_PLAN = UPF P/G grids which always-on grid layers to align power switch cells.
#
#   INTEL_PS_ALIGN_PG_GRID($INTEL_POWER_PLAN) = A pair of adjacent metal layers with always-on P/G grid templates in INTEL_PG_GRID_CONFIG to align power switch cells.
#   NOTE: If there are more than 1 offsets for P/G template, use the 1st offset.
#
# NOTE:
#   Support multiple disjoint voltage area shapes per power domain.
#   Currently, support only 1 UPF power switch strategy per power domain, i.e. 1 power switch lib cell mapping per power domain.
#   Hence, currently, doesn't support different UPF power switch strategies for each voltage area shape, i.e. all voltage area shapes per power domain share same UPF power switch strategy.
#   Currently, doesn't support UPF map_power_switch, i.e. power switch lib cell mappings must be specified through INTEL_POWER_SWITCH() var.
#   Currently, doesn't support child level power domains that are more always-on than parent level power domain.
#
# Required procs:
#   P_msg_info
#   P_msg_warn
#   P_msg_error
#   P_get_power_domain_info
#

# TODO:
#   To support separate UPF power switch strategies for separate voltage area shapes per power domain.
#   To support UPF map_power_switch to overwrite INTEL_POWER_SWITCH(default) if defined, but will be overwritten by INTEL_POWER_SWITCH($power_domain).

# NOTE: Cell instance prefix for power switch cells = u_ps_${power_switch_name}_.

set scr_name [file rootname [file tail [info script]]]

if { ![info exists INTEL_UPF_POWER_NETS] } {
  P_msg_error "$scr_name: Missing required var 'INTEL_UPF_POWER_NETS' for UPF power nets!  Check 'project_setup.tcl' file!"
  return
} else {
  foreach net_name $INTEL_UPF_POWER_NETS {
    if { [sizeof_collection [set net [get_nets -quiet $net_name]]] == 0 } {
      P_msg_error "$scr_name: Failed to find any net of name '$net_name' defined in 'INTEL_UPF_POWER_NETS' var!  Check 'project_setup.tcl' file!"
      return
    } elseif { [lsearch -exact {ground power} [set net_type [get_attribute -objects $net -name net_type]]] < 0 } {
      P_msg_error "$scr_name: Detect non-P/G net type of '$net_type' for net '[get_object_name $net]' defined in 'INTEL_UPF_POWER_NETS' var!  Expect groud or power net type only!"
      return
    }
  }
}
set aon_net_order_list [get_object_name [get_nets -quiet -filter {net_type == power} $INTEL_UPF_POWER_NETS]]

if { ![info exists INTEL_PG_GRID_CONFIG] } {
  P_msg_error "$scr_name: Missing required var 'INTEL_PG_GRID_CONFIG' for UPF power plan!  Check 'project_setup.tcl' file!"
  return
}
set pg_grid_dict [dict create {*}$INTEL_PG_GRID_CONFIG]
set ps_x_layer_name {}
set ps_y_layer_name {}
set ps_x_layer_aon_pitch {}
set ps_y_layer_aon_pitch {}
set ps_x_layer_aon_offset_list {}
set ps_y_layer_aon_offset_list {}
if { ![info exists INTEL_POWER_PLAN] } {
  P_msg_error "$scr_name: Missing required var 'INTEL_POWER_PLAN' for UPF power plan!  Check 'project_setup.tcl' file!"
  return
} elseif { ![info exists INTEL_PS_ALIGN_PG_GRID($INTEL_POWER_PLAN)] } {
  P_msg_error "$scr_name: Missing required var 'INTEL_PS_ALIGN_PG_GRID($INTEL_POWER_PLAN)' for metal layers on always-on P/G grids to align power switch cells!  Check 'project_setup.tcl' file!"
  return
} else {
  set align_lyr_list {}
  foreach align_cfg $INTEL_PS_ALIGN_PG_GRID($INTEL_POWER_PLAN) {
echo align_cfg is $align_cfg
    lassign $align_cfg lyr_name aon_tpl_1 aon_tpl_2
    if { [sizeof_collection [set lyr [get_layers -quiet $lyr_name]]] == 0 } {
      P_msg_error "$scr_name: Failed to find any layer of name '$lyr_name' defined in 'INTEL_PS_ALIGN_PG_GRID($INTEL_POWER_PLAN)' var!  Check 'project_setup.tcl' file!"
      return
    } elseif { [set lyr_type [get_attribute -objects $lyr -name layer_type]] != {interconnect} } {
      P_msg_error "$scr_name: Detect non-routing layer type of '$lyr_type' for layer '[get_object_name $lyr]' defined in 'INTEL_PS_ALIGN_PG_GRID($INTEL_POWER_PLAN)' var!  Expect interconnect layer type only!"
      return
    }
    lappend align_lyr_list $lyr_name
    if { ![string match power_all_aon* $aon_tpl_1] && ![string match power_va_aon* $aon_tpl_1] } {
      P_msg_error "$scr_name: Detect invalid P/G grid template '$aon_tpl_1' for layer '[get_object_name $lyr]' defined in 'INTEL_PS_ALIGN_PG_GRID($INTEL_POWER_PLAN)' var!  Expect 'power_all_aon' or 'power_va_aon' only!"
      return
    }
    if { [llength $aon_tpl_2] > 0 && ![string match power_all_aon,2 $aon_tpl_2] && ![string match power_va_aon,2 $aon_tpl_2] } {
      P_msg_error "$scr_name: Detect invalid P/G grid template '$aon_tpl_2' for layer '[get_object_name $lyr]' defined in 'INTEL_PS_ALIGN_PG_GRID($INTEL_POWER_PLAN)' var!  Expect 'power_all_aon,2' or 'power_va_aon,2' only!"
      return
    }
  }
  if { [llength $align_lyr_list] != 2 } {
    P_msg_error "$scr_name: Detect incorrect number-pair of layers '$align_lyr_list' defined by 'INTEL_PS_ALIGN_PG_GRID($INTEL_POWER_PLAN)' var!  Expect a pair of layers only!"
    return
  } elseif { [lsort [set lyr_dir_list [get_attribute -objects [get_layers $align_lyr_list] -name routing_direction]]] != {horizontal vertical} } {
    P_msg_error "$scr_name: Detect incorrect directions '$lyr_dir_list' of layers '$align_lyr_list' defined by 'INTEL_PS_ALIGN_PG_GRID($INTEL_POWER_PLAN)' var!  Expect horizontal and vertical for the pair of layers!"
    return
  }
  # TODO: Check for adjacent layers.
  # TODO: Check for always-on P/G layers.
  set ps_x_layer_name [get_object_name [filter_collection [get_layers $align_lyr_list] {routing_direction == vertical}]]
  set ps_y_layer_name [get_object_name [filter_collection [get_layers $align_lyr_list] {routing_direction == horizontal}]]

  # TODO: Add sanity check for INTEL_PG_GRID_CONFIG.
  foreach align_cfg $INTEL_PS_ALIGN_PG_GRID($INTEL_POWER_PLAN) {
echo align_cfg is $align_cfg
    lassign $align_cfg lyr_name aon_tpl_1 aon_tpl_2
    if { [get_attribute -objects [get_layers $lyr_name] -name routing_direction] == {horizontal} } {
      if { ![dict exists $pg_grid_dict $ps_y_layer_name $aon_tpl_1 pitch] } {
        if { [dict exists $pg_grid_dict ${ps_y_layer_name}_1 $aon_tpl_1 pitch] } {
          set ps_y_layer_name ${ps_y_layer_name}_1
echo "b1"
          set ps_y_layer_aon_pitch [dict get $pg_grid_dict $ps_y_layer_name $aon_tpl_1 pitch]
        } else {
          P_msg_error "$scr_name: Missing pitch for template '$aon_tpl_1' of layer '$ps_y_layer_name' in 'INTEL_PG_GRID_CONFIG' var!"
        }
      } else {
echo "b2"
        set ps_y_layer_aon_pitch [dict get $pg_grid_dict $ps_y_layer_name $aon_tpl_1 pitch]
      }
      if { ![dict exists $pg_grid_dict $ps_y_layer_name $aon_tpl_1 offset,width] } {
        P_msg_error "$scr_name: Missing offset,width for template '$aon_tpl_1' of layer '$ps_y_layer_name' in 'INTEL_PG_GRID_CONFIG' var!"
      } else {
echo "b3"
        set ps_y_layer_aon_offset_list [lindex [dict get $pg_grid_dict $ps_y_layer_name $aon_tpl_1 offset,width] 0 0]
      }
      if { [llength $aon_tpl_2] > 0 } {
        if { ![dict exists $pg_grid_dict $ps_y_layer_name $aon_tpl_2 offset,width] } {
          P_msg_error "$scr_name: Missing offset,width for template '$aon_tpl_2' of layer '$ps_y_layer_name' in 'INTEL_PG_GRID_CONFIG' var!"
        } else {
echo "b4"
          lappend ps_y_layer_aon_offset_list [lindex [dict get $pg_grid_dict $ps_y_layer_name $aon_tpl_2 offset,width] 0 0]
        }
      }
    } else {
echo "checking $pg_grid_dict $ps_x_layer_name $aon_tpl_1 pitch"
      if { ![dict exists $pg_grid_dict $ps_x_layer_name $aon_tpl_1 pitch] } {
        if { [dict exists $pg_grid_dict ${ps_x_layer_name}_1 $aon_tpl_1 pitch] } {
          set ps_x_layer_name ${ps_x_layer_name}_1
echo "b51"
          set ps_x_layer_aon_pitch [dict get $pg_grid_dict $ps_x_layer_name $aon_tpl_1 pitch]
        } else {
          P_msg_error "$scr_name: Missing pitch for template '$aon_tpl_1' of layer '$ps_x_layer_name' in 'INTEL_PG_GRID_CONFIG' var!"
        }
      } else {
echo "b5"
        set ps_x_layer_aon_pitch [dict get $pg_grid_dict $ps_x_layer_name $aon_tpl_1 pitch]
      }
      if { ![dict exists $pg_grid_dict $ps_x_layer_name $aon_tpl_1 offset,width] } {
        P_msg_error "$scr_name: Missing offset,width for template '$aon_tpl_1' of layer '$ps_x_layer_name' in 'INTEL_PG_GRID_CONFIG' var!"
      } else {
echo "b6"
        set ps_x_layer_aon_offset_list [lindex [dict get $pg_grid_dict $ps_x_layer_name $aon_tpl_1 offset,width] 0 0]
      }
      if { [llength $aon_tpl_2] > 0 } {
        if { ![dict exists $pg_grid_dict $ps_x_layer_name $aon_tpl_2 offset,width] } {
          P_msg_error "$scr_name: Missing offset,width for template '$aon_tpl_2' of layer '$ps_x_layer_name' in 'INTEL_PG_GRID_CONFIG' var!"
        } else {
echo "b7"
          lappend ps_x_layer_aon_offset_list [lindex [dict get $pg_grid_dict $ps_x_layer_name $aon_tpl_2 offset,width] 0 0]
        }
      }
    }
  }
}

if { ![info exists INTEL_TAP_CELL] } {
  P_msg_error "$scr_name: Missing required var 'INTEL_TAP_CELL' for tap cell!  Check 'project_setup.tcl' file!"
  return
} elseif { [sizeof_collection [set tap_libcell [index_collection [get_lib_cells -quiet */$INTEL_TAP_CELL] 0 ]]] == 0 } {
  P_msg_error "$scr_name: Unable to find any lib cell of name '$INTEL_TAP_CELL' defined in 'INTEL_TAP_CELL' var!  Check 'project_setup.tcl' file!"
  return
}
scan [get_attribute -objects $tap_libcell -name boundary_bbox] {{%f %f} {%f %f}} tap_llx tap_lly tap_urx tap_ury
#set min_x_offset [format %.3f [expr $halo_urx - $halo_llx + $tap_urx - $tap_llx]]
set min_x_offset [format %.3f [expr $tap_urx - $tap_llx]]

foreach_in_collection pd [get_power_domains -hierarchical *] {
  set pd_name [get_object_name $pd]
  set va_name [get_object_name [get_voltage_areas -of_objects $pd]]
  set ps_name [P_get_power_domain_info -pwr_domain $pd_name -query ps_names]
  if { [llength $va_name] == 0 } {
    P_msg_error "$scr_name: Detect missing voltage area for power domain '$pd_name'!  Skip creating power switch cells for power switch '$ps_name'!"
    continue
  } elseif { [llength $ps_name] == 0 } {
    P_msg_info "$scr_name: No UPF power switch defined for power domain '$pd_name' to create any power switch cell."
    continue
  } elseif { [llength $ps_name] > 1 } {
    P_msg_error "$scr_name: Detect unsupported multiple ([llength $ps_name]) UPF power switches '$ps_name' defined for power domain '$pd_name'!  Currently only support 1 UPF power switch per power domain!"
    continue
  }
  if { [info exists INTEL_POWER_SWITCH($pd_name)] } {
    set ps_libcell [index_collection [get_lib_cells -quiet */$INTEL_POWER_SWITCH($pd_name)] 0]
    set ps_libcell_pd $pd_name
  } else {
    set ps_libcell [index_collection [get_lib_cells -quiet */$INTEL_POWER_SWITCH(default)] 0]
    set ps_libcell_pd default
  }
  if { [sizeof_collection $ps_libcell] == 0 } {
    P_msg_error "$scr_name: Unable to find any lib cell of name '$INTEL_POWER_SWITCH($ps_libcell_pd)' defined in 'INTEL_POWER_SWITCH($ps_libcell_pd)' var!  Check 'project_setup.tcl' file!"
    return
  } elseif { [get_attribute -objects $ps_libcell -name is_power_switch] != true } {
    P_msg_error "$scr_name: Detect non-power-switch lib cell '[get_object_name $ps_libcell]' defined in 'INTEL_POWER_SWITCH($ps_libcell_pd)' var!  Expect power switch lib cell!"
    return
  }
  if { [info exists INTEL_PS_X_PITCH($pd_name)] } {
    set ps_x_spacing $INTEL_PS_X_PITCH($pd_name)
    set ps_x_spacing_pd $pd_name
  } else {
    set ps_x_spacing $INTEL_PS_X_PITCH(default)
    set ps_x_spacing_pd default
  }

  if { ![string is double -strict $ps_x_spacing] || $ps_x_spacing <= 0.0 } {
    P_msg_error "$scr_name: Invalid value '$ps_x_spacing' defined by 'INTEL_PS_X_PITCH($ps_x_spacing_pd)' var!  Check 'project_setup.tcl' file!"
    return
  } elseif { [set rem [format %.3f [expr fmod( $ps_x_spacing, $ps_x_layer_aon_pitch )]]] != 0.0 && $rem != $ps_x_layer_aon_pitch } {
  # To workaround floating imprecision of fmod().
  #P_msg_error "$scr_name: Detect non-multiple value '$ps_x_spacing' defined by 'INTEL_PS_X_PITCH($ps_x_spacing_pd)' var for horizontal pitch between power switch cells in staggered array of P/G grid pitch '$ps_x_layer_aon_pitch' of layer '$ps_x_layer_name' defined by 'INTEL_PS_ALIGN_PG_GRID($INTEL_POWER_PLAN)'!  Expect power switch cell pitch as multiple of P/G grid pitch!"
  #return
  }
    if { [info exists INTEL_PS_Y_PITCH($pd_name)] } {
      set ps_y_spacing $INTEL_PS_Y_PITCH($pd_name)
      set ps_y_spacing_pd $pd_name
    } else {
      set ps_y_spacing $INTEL_PS_Y_PITCH(default)
      set ps_y_spacing_pd default
    }
    if { ![string is double -strict $ps_y_spacing] || $ps_y_spacing <= 0.0 } {
      P_msg_error "$scr_name: Invalid value '$ps_y_spacing' defined by 'INTEL_PS_Y_PITCH($ps_y_spacing_pd)' var!  Check 'project_setup.tcl' file!"
      return
    } elseif { [set rem [format %.3f [expr fmod( $ps_y_spacing, $ps_y_layer_aon_pitch )]]] != 0.0 && $rem != $ps_y_layer_aon_pitch } {
    # To workaround floating imprecision of fmod().
    #P_msg_error "$scr_name: Detect non-multiple value '$ps_y_spacing' defined by 'INTEL_PS_Y_PITCH($ps_y_spacing_pd)' var for horizontal pitch between power switch cells in staggered array of P/G grid pitch '$ps_y_layer_aon_pitch' of layer '$ps_y_layer_name' defined by 'INTEL_PS_ALIGN_PG_GRID($INTEL_POWER_PLAN)'!  Expect power switch cell pitch as multiple of P/G grid pitch!"
    #return
    }

    scan [get_attribute -objects $ps_libcell -name boundary_bbox] {{%f %f} {%f %f}} ps_llx ps_lly ps_urx ps_ury
    set aon_pwr_net_name [get_object_name [get_nets -physical_context [P_get_power_domain_info -pwr_domain $pd_name -query aon_pwr -ps_name $ps_name]]]
    set aon_pwr_x_pitch $ps_x_layer_aon_pitch
    set aon_pwr_x_offset [lindex $ps_x_layer_aon_offset_list [lsearch -exact $aon_net_order_list $aon_pwr_net_name]]
    set aon_pwr_y_pitch $ps_y_layer_aon_pitch
    set aon_pwr_y_offset [lindex $ps_y_layer_aon_offset_list [lsearch -exact $aon_net_order_list $aon_pwr_net_name]]

    set ps_prefix u_ps_${ps_name}_
    foreach_in_collection va_shp [get_voltage_area_shapes -of_objects [get_voltage_areas $va_name]] {
      scan [get_attribute -objects $va_shp -name bbox] {{%f %f} {%f %f}} va_llx va_lly va_urx va_ury

      set ps_x_offset [format %.3f [expr ceil( 1.0 * ( $va_llx - $aon_pwr_x_offset ) / $aon_pwr_x_pitch ) * $aon_pwr_x_pitch + $aon_pwr_x_offset - $va_llx - ( $ps_urx - $ps_llx ) * 0.5]]
      # Equivalent alternate, but need to handle if fmod() == $aon_pwr_x_pitch due to imprecision.
      #set ps_x_offset [format %.3f [expr $aon_pwr_x_pitch - fmod( $va_llx - $aon_pwr_x_offset , $aon_pwr_x_pitch ) - ( $ps_urx - $ps_llx ) * 0.5]]
      # Need to adjust X offset to ensure sufficient sites to accommodate $INTEL_halo_power & $INTEL_TAP_CELL along left VA boundary before PS cell.
      # TODO: Also check to ensure sufficient sites along right VA boundary.
      set ps_x_offset [expr $ps_x_offset >= 0 && $ps_x_offset < $min_x_offset ? $min_x_offset : $ps_x_offset]

      set ps_y_offset [format %.3f [expr ceil( 1.0 * ( $va_lly - $aon_pwr_y_offset ) / $aon_pwr_y_pitch ) * $aon_pwr_y_pitch + $aon_pwr_y_offset - $va_lly - ( $ps_ury - $ps_lly ) * 0.5]]
      # Equivalent alternate, but need to handle if fmod() == $aon_pwr_x_pitch due to imprecision.
      #set ps_y_offset [format %.3f [expr $aon_pwr_y_pitch - fmod( $va_lly - $aon_pwr_y_offset , $aon_pwr_y_pitch ) - ( $ps_ury - $ps_lly ) * 0.5]]
      # Unfortunately, need to adjust Y offset to non-flip rows only because despite -snap_to_site true & -orient R0, create_power_switch_array simply snaps to any row even with mismatched double-height orientations for the rows.
      # ASSERT: $va_lly is on ( $INTEL_MD_GRID_Y * 2 ) grid.
      set ps_y_offset [format %.3f [expr round( $ps_y_offset / $INTEL_MD_GRID_Y / 2.0 ) * $INTEL_MD_GRID_Y * 2]]

      # TODO: Align using -pg_strategy option.
      # Somehow, create_power_switch_array -lib_cell option only allows lib_cell name, but not lib_cell object.
      create_power_switch_array -power_switch $ps_name -prefix $ps_prefix -lib_cell [get_object_name $ps_libcell] -voltage_area_shape $va_shp -x_pitch $ps_x_spacing -y_pitch $ps_y_spacing -x_offset $ps_x_offset -y_offset $ps_y_offset -orient R0 -checkerboard even

      set ps_cells [get_cells -quiet -filter "is_power_switch == true && name =~ $ps_prefix*" -of_objects $va_shp]
      if { [sizeof_collection $ps_cells] == 0 } {
        P_msg_error "$scr_name: Failed to create any power switch cell of reference '[get_attribute -objects $ps_libcell -name name]' at orientation 'R0' at offsets '$ps_x_offset $ps_y_offset' with pitches '$ps_x_spacing $ps_y_spacing' in voltage area shape '[get_object_name $va_shp]' of voltage area '$va_name' for power switch '$ps_name' of power domain '$pd_name'."
      } else {
      # ASSERT: Either single common parent or no parent.
        set ps_cell_path_list [lsort -unique [get_attribute -quiet -objects $ps_cells -name parent_cell.full_name]]
        lappend ps_cell_path_list $ps_prefix*
        P_msg_info "$scr_name: Created [sizeof_collection $ps_cells] power switch cells '[join $ps_cell_path_list /]' of reference '[lsort -unique [get_attribute -objects $ps_cells -name ref_name]]' at orientation '[lsort -unique [get_attribute -objects $ps_cells -name orientation]]' at offsets '$ps_x_offset $ps_y_offset' with pitches '$ps_x_spacing $ps_y_spacing' in voltage area shape '[get_object_name [get_voltage_area_shapes -of_objects $ps_cells]]' of voltage area '[get_object_name [get_voltage_areas -of_objects $ps_cells]]' for power switch '$ps_name' of power domain '$pd_name'."
      }

    }
  }

  unset scr_name


