##############################################################
# NAME :          create_port_layer.tcl
#
# SUMMARY :       create port layers over all terminals for LVS
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists create_port_layer.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     None
#
# PROCS USED :    None
#                         
# DESCRIPTION :   create_port_layer.tcl is to create port layers over all terminals for LVS
#
# EXAMPLES :      
#
###############################################################
# Add net shapes & texts on corresponding port layers over all terminals for LVS.

# ASSERT: Port layers are always of datatype 2 of corresponding drawn layers.

proc create_port_layer args {
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
  foreach var {} {
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

  # Datatype number of port layers, assuming same for all mask layers.
  set pl_dt_num 2

  # Height of port layer texts.
  set pl_txt_height 0.1

  # Unfortunately, can't use mapping approach which requires consistent layer naming and properly defined in techfiles across all dot processes.
  #array unset layer_2_port_layer
  #array set layer_2_port_layer {
  #  ndiff         ndiffport
  #  pdiff         pdiffport
  #  tcn           diffconport
  #  poly          poly1port
  #  #gcn           polyconport ;# Not defined in Redbook
  #  m1            m1_text
  #  m2            m2_text
  #  m3            m3_text
  #  m4            m4_text
  #  m5            m5_text
  #  m6            m6_text
  #  m7            m7_text
  #  m8            m8_text
  #  ce1           ce1port
  #  ce2           ce2port
  #}

  # Use format to workaround floating imprecision for comparison & avoid scientific notation for near-zero number.
  set fmt "%.[expr entier( log10 ( [get_attribute -objects $tech -name length_precision] ) ) + 1]f"

  set all_terms [get_terminals -quiet *]
  if { [sizeof_collection $all_terms] == 0 } {
    incr err_num
    P_msg_error "$proc_name: Failed to find any terminal to create net shape & text on port layer of datatype '$pl_dt_num'!  Expect terminals exist!"
  } elseif { [sizeof_collection [filter_collection $all_terms {port.port_type == signal}]] == 0 } {
    incr err_num
    P_msg_error "$proc_name: Failed to find any signal terminal among [sizeof_collection $all_terms] terminals to create net shape & text on port layer of datatype '$pl_dt_num'!  Expect signal terminals also exist!"
  } else {
    foreach_in_collection term $all_terms {
      if { [sizeof_collection [set port [get_attribute -objects $term -name port]]] == 0 } {
        incr err_num
        P_msg_error "$proc_name: Failed to find any port for terminal '[get_object_name $term]' of layer '[get_attribute -objects $term -name layer.full_name]' to create net shape & text on port layer of datatype '$pl_dt_num'!  Expect terminal associated to port!"
      } elseif { [sizeof_collection [set net [get_nets -quiet -of_objects $port]]] == 0 } {
        incr err_num
        P_msg_error "$proc_name: Failed to find any net connected to port '[get_object_name $port]' of terminal '[get_object_name $term]' on layer '[get_attribute -objects $term -name layer.full_name]' to create net shape & text on port layer of datatype '$pl_dt_num'!  Expect port connected to net!"
      }
    }
  }
  if { $err_num > 0 } {
    P_msg_error "$proc_name: Abort due to $err_num errors above!"
    return
  }

  if { [sizeof_collection [set old_pl_shps [get_shapes -quiet -filter "purpose_number == $pl_dt_num" *]]] > 0 } {
    foreach_in_collection lyr [sort_collection [get_layers [lsort -unique [get_attribute -objects $old_pl_shps -name layer_name]]] {mask_order layer_number}] {
    # Somehow name attribute of layer object always appends purpose_number/datatype_number if non-zero, despite layer_name already indicates the purpose/datatype.
      set lyr_name [lindex [split [get_object_name $lyr] :] 0]
      set old_pl_lyr_pr_shps [filter_collection $old_pl_shps "layer_name == $lyr_name && shape_type != text"]
      set old_pl_lyr_txt_shps [filter_collection $old_pl_shps "layer_name == $lyr_name && shape_type == text"]
      if { [sizeof_collection $old_pl_lyr_pr_shps] > 0 || [sizeof_collection $old_pl_lyr_txt_shps] > 0 } {
        if { $force_opt } {
          set del_shp_desc_list {}
          if { [sizeof_collection $old_pl_lyr_pr_shps] > 0 } {
            lappend del_shp_desc_list "[remove_shapes $old_pl_lyr_pr_shps] shapes"
          }
          if { [sizeof_collection $old_pl_lyr_txt_shps] > 0 } {
            lappend del_shp_desc_list "[remove_shapes $old_pl_lyr_txt_shps] texts"
          }
          P_msg_warn "$proc_name: Deleted pre-existing [join $del_shp_desc_list { & }] on port layer '$lyr_name' of number '[get_attribute -objects $lyr -name layer_number]:[get_attribute -objects $lyr -name purpose_number]'!"
        } else {
          incr err_num
          P_msg_error "$proc_name: Detect pre-existing [sizeof_collection $old_pl_lyr_pr_shps] shapes & [sizeof_collection $old_pl_lyr_txt_shps] texts on port layer '$lyr_name' of number '[get_attribute -objects $lyr -name layer_number]:[get_attribute -objects $lyr -name purpose_number]'!  Must delete them before creating new ones again or use '-force' option!"
        }
      }
    }
  }
  if { $err_num > 0 } {
    P_msg_error "$proc_name: Abort due to $err_num errors above!"
    return
  }

  unset err_num
  unset old_pl_shps
  unset -nocomplain old_pl_lyr_pr_shps old_pl_lyr_txt_shps

  # ASSERT: Only $proc_name, $verb_opt, $pl_dt_num, $pl_txt_height, $fmt & $all_terms vars are required hereafter.

  set orig_val(snap_setting-enabled) [get_snap_setting -enabled]
  set_snap_setting -enabled 0

  set all_term_lyrs [sort_collection [get_layers [lsort -unique [get_attribute -objects $all_terms -name shape.layer_name]]] {mask_order layer_number}]
  P_msg_info "$proc_name: Creating net shapes & texts on port layers of datatype '$pl_dt_num' for [sizeof_collection $all_terms] terminals of [sizeof_collection $all_term_lyrs] layers '[get_object_name $all_term_lyrs]' ..."
  set pl_pr_shps {}
  set pl_txt_shps {}
  foreach_in_collection lyr $all_term_lyrs {
    set lyr_name [get_object_name $lyr]
    set lyr_terms [sort_collection -dictionary [filter_collection $all_terms "shape.layer_name == $lyr_name"] {shape.bbox_llx shape.bbox_lly}]
    # Safer to use $lyr_num:$pl_dt_num instead of $lyr_name:$pl_dt_num which may crash ICC2.
    set pl_lyr_dt_num_pair [get_attribute -objects $lyr -name layer_number]:$pl_dt_num
    set pl_lyr_pr_shps {}
    set pl_lyr_txt_shps {}
    foreach_in_collection term $lyr_terms {
      set net [get_nets -of_objects [get_attribute -objects $term -name port]]
      set term_shp [get_attribute -objects $term -name shape]
      if { [set shp_type [get_attribute -objects $term_shp -name shape_type]] == {path} } {
        set shp_opt "-path [list [get_attribute -objects $term_shp -name points]] -width [get_attribute -objects $term_shp -name width] -start_endcap [get_attribute -objects $term_shp -name start_endcap] -end_endcap [get_attribute -objects $term_shp -name end_endcap]"
        if { [get_attribute -objects $term_shp -name start_endcap] == {variable} } {
          append shp_opt " -start_extension [get_attribute -objects $term_shp -name start_extension]"
        }
        if { [get_attribute -objects $term_shp -name end_endcap] == {variable} } {
          append shp_opt " -end_extension [get_attribute -objects $term_shp -name end_extension]"
        }
        # Use arbitrary 1st sub-rectangle of path because path may be hollow at bbox center.
        set txt_bbox [get_attribute -objects [index_collection [split_polygons -objects $term -output poly_rect] 0] -name bbox]
      } elseif { $shp_type == {polygon} } {
        set shp_opt "-boundary [list [get_attribute -objects $term_shp -name points]]"
        # Use arbitrary 1st sub-rectangle of polygon because polygon may be hollow at bbox center.
        set txt_bbox [get_attribute -objects [index_collection [split_polygons -objects $term -output poly_rect] 0] -name bbox]
      } else {
      # ASSERT: $shp_type == {rect}
        set txt_bbox [get_attribute -objects $term_shp -name bbox]
        set shp_opt "-boundary [list $txt_bbox]"
      }
      append_to_collection pl_lyr_pr_shps [set pr_shp [create_shape -layer $pl_lyr_dt_num_pair -shape_type $shp_type -net $net {*}$shp_opt -shape_use user_route]]
      set txt_ctr "[format $fmt [expr ( [lindex $txt_bbox 0 0] + [lindex $txt_bbox 1 0] ) * 0.5]] [format $fmt [expr ( [lindex $txt_bbox 0 1] + [lindex $txt_bbox 1 1] ) * 0.5]]"
      append_to_collection pl_lyr_txt_shps [set txt_shp [create_shape -layer $pl_lyr_dt_num_pair -shape_type text -text [get_object_name $net] -origin $txt_ctr -justification C -height $pl_txt_height -shape_use user_route]]
      if { $verb_opt } {
        if { [set pr_shp_type [get_attribute -objects $pr_shp -name shape_type]] == {path} } {
          set pr_shp_desc "width '[get_attribute -objects $pr_shp -name width]' & [expr [llength [get_attribute -objects $pr_shp -name points]] - 1]-segmented center line '[get_attribute -objects $pr_shp -name points]'"
        } elseif { $pr_shp_type == {polygon} } {
          set pr_shp_desc "[llength [get_attribute -objects $pr_shp -name points]]-sided boundary '[get_attribute -objects $pr_shp -name points]'"
        } else {
          set pr_shp_desc "bbox '[get_attribute -objects $pr_shp -name bbox]'"
        }
        P_msg_info "$proc_name:   Created on port layer '[lsort -unique [get_attribute -objects [add_to_collection $pr_shp $txt_shp] -name layer_name]]' of number '[lsort -unique [list [get_attribute -objects $pr_shp -name layer_number]:[get_attribute -objects $pr_shp -name purpose_number] [get_attribute -objects $txt_shp -name layer_number]:[get_attribute -objects $txt_shp -name purpose_number]]]' with type '$pr_shp_type' net '[get_object_name [get_nets -of_objects $pr_shp]]' shape of $pr_shp_desc & text '[get_attribute -objects $txt_shp -name text]' at '[get_attribute -objects $txt_shp -name origin]' for terminal '[get_object_name $term]' of layer '$lyr_name' of number '[get_attribute -objects $lyr -name layer_number]:[get_attribute -objects $lyr -name purpose_number]'."
      }
    }
    set pl_lyr [get_layers [lsort -unique [get_attribute -objects [add_to_collection $pl_lyr_pr_shps $pl_lyr_txt_shps] -name layer_name]]]
    set pl_lyr_name [lindex [split [get_object_name $pl_lyr] :] 0]
    P_msg_info "$proc_name: Created [sizeof_collection $pl_lyr_pr_shps] net shapes & [sizeof_collection $pl_lyr_txt_shps] texts on port layer '$pl_lyr_name' of number '[get_attribute -objects $pl_lyr -name layer_number]:[get_attribute -objects $pl_lyr -name purpose_number]' for [sizeof_collection $lyr_terms] terminals of layer '$lyr_name'."
    append_to_collection pl_pr_shps $pl_lyr_pr_shps
    append_to_collection pl_txt_shps $pl_lyr_txt_shps
  }
  set pl_shp_lyrs [sort_collection [get_layers [lsort -unique [get_attribute -objects [add_to_collection $pl_pr_shps $pl_txt_shps] -name layer_name]]] {mask_order layer_number}]
  set pl_shp_lyr_list [join [regsub -all -line {:\d+$} [join [get_object_name $pl_shp_lyrs] "\n"] {}]]
  P_msg_info "$proc_name: Created total [sizeof_collection $pl_pr_shps] net shapes & [sizeof_collection $pl_txt_shps] texts on [sizeof_collection $pl_shp_lyrs] port layers '$pl_shp_lyr_list' for [sizeof_collection $all_terms] terminals of [sizeof_collection $all_term_lyrs] layers '[get_object_name $all_term_lyrs]'."

  set_snap_setting -enabled $orig_val(snap_setting-enabled)

  return 1
}

define_proc_attributes create_port_layer \
  -info "Create net shapes & texts on corresponding port layers over all terminals." \
  -define_args {
    {-force "Delete pre-existing net shapes & texts on port layers, instead of display error messages" {} boolean optional}
    {-verbose "Display verbose informational messages" {} boolean optional}
}

create_port_layer

# EOF

