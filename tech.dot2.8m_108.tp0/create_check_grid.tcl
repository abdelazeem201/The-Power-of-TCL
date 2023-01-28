#############################################################
# NAME :          create_check_grid.tcl
#
# SUMMARY :       create diffcheck grid
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists create_check_grid.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_CHECK_GRID_CONFIG
#
# PROCS USED :    P_msg_info P_msg_warn P_msg_error
#                         
# DESCRIPTION :   create_check_grid.tcl is to create diffcheck grid
#
# EXAMPLES :      
#
###############################################################

# Create parallel stripes for diffusion check grids across design for DRC, except over macro cells should have their own check grids internally.

# Check grid configuration, customized per dot process.
#  layer = Layer name or LayerDataType name defined in techfile for layer of stripes for check grid, as specified by DIFFCHECK or POLYCHECKDRAWN layer for P1222.* dot processes.
#  dir = Direction of layer stripes for check grid.
#  width = Width of layer stripes for check grid, as specified by DG_01 or PG_01 rule for P1222.* dot processes.  Measured in orthogonal of stripe direction.
#  pitch = Pitch between same side of edges of adjacent layer stripes for check grid, as specified by (DG_01 + DG_02) or PG_02 rule for P1222.* dot processes, must be > width.  Measured in orthogonal of stripe direction.
#  offset = Offset from partition boundary to side edge of 1st layer stripe for check grid, as specified by DG_04 or PG_04 rule for P1222.* dot processes, must be > -width && <= pitch - width.  Measured in orthogonal of stripe direction.
#  pullback = Space between partition/macro boundaries to ends of layer stripes for check grid.  Measured in stripe direction.
# NOTE: Sanity check included for pitch values to ensure INTEL_MD_GRID_X & INTEL_MD_GRID_Y are exact multiples of pitches of vertical & horizontal stripes respectively.
# NOTE: Mininum length of diffusion check grid stripes of DG_03 rule is NOT checked here, as it is somewhat indirectly & loosely ensured by mininum of 2 * INTEL_MD_GRID_X for notches between macros and between partition & macros.

# E.g. for all P1222.* dot processes:
#set INTEL_CHECK_GRID_CONFIG {
#  diffCheck {
#    dir       horizontal
#    width     0.031
#    pitch     0.090
#    offset    0.0
#    pullback  0.000
#}

proc create_check_grid args {
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
  # ASSERT: $INTEL_MD_GRID_X is exact multiple of pitch for check grid layer in vertical direction.
  # ASSERT: $INTEL_MD_GRID_Y is exact multiple of pitch for check grid layer in horizontal direction.
  foreach var {INTEL_CHECK_GRID_CONFIG INTEL_MD_GRID_X INTEL_MD_GRID_Y} {
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

  # Use format to workaround floating imprecision for comparison & avoid scientific notation for near-zero number, but unfortunately still can't handle near-zero negative number as zero.
  set fmt "%.[expr entier( log10 ( [get_attribute -objects $tech -name length_precision] ) ) + 1]f"
  set litho_grid [format $fmt [expr 1.0 * [get_attribute -objects $tech -name grid_resolution] / [get_attribute -objects $tech -name length_precision]]]

  set cg_dict [dict create {*}$INTEL_CHECK_GRID_CONFIG]
  set cfg_cg_lyr_list [dict keys $cg_dict]
  foreach lyr_name $cfg_cg_lyr_list {
    if { [sizeof_collection [get_layers -quiet $lyr_name]] == 0 } {
      incr err_num
      P_msg_error "$proc_name: Detect invalid layer name '$lyr_name' configured in INTEL_CHECK_GRID_CONFIG!  Expect layer defined in techfile!"
    }
  }
  if { $err_num > 0 } {
    P_msg_error "$proc_name: Abort due to $err_num errors above!"
    return
  }

  set valid_dir_list {horizontal vertical}
  array unset dir_2_axis
  array set dir_2_axis {
    vertical    x
    horizontal  y
  }

  # Sanity check to ensure pitch >= edge_space + width in $INTEL_CHECK_GRID_CONFIG.
  # Sanity check to ensure INTEL_MD_GRID_X & INTEL_MD_GRID_Y are exact multiples of pitches of vertical & horizontal directions respectively.
  foreach lyr_name $cfg_cg_lyr_list {
    set lyr [get_layers $lyr_name]
    set chk_pitch 1
    set chk_offset 1
    if { ![dict exists $cg_dict $lyr_name dir] } {
      incr err_num
      P_msg_error "$proc_name: Missing check grid stripe direction (dir) for layer '$lyr_name' configured in INTEL_CHECK_GRID_CONFIG!  Expect 1 of '$valid_dir_list'!"
      set chk_pitch 0
      set chk_offset 0
    } elseif { [lsearch -exact $valid_dir_list [set dir [dict get $cg_dict $lyr_name dir]]] < 0 } {
      incr err_num
      P_msg_error "$proc_name: Invalid check grid stripe direction (dir) '$dir' for layer '$lyr_name' configured in INTEL_CHECK_GRID_CONFIG!  Expect 1 of '$valid_dir_list'!"
      set chk_pitch 0
      set chk_offset 0
    } else {
      set md_grid_var INTEL_MD_GRID_[string toupper $dir_2_axis($dir)]
    }
    if { ![dict exists $cg_dict $lyr_name width] } {
      incr err_num
      P_msg_error "$proc_name: Missing check grid stripe width (width) for layer '$lyr_name' configured in INTEL_CHECK_GRID_CONFIG!  Expect positive number > $litho_grid!"
      set chk_pitch 0
      set chk_offset 0
    } elseif { ![string is double -strict [set width [dict get $cg_dict $lyr_name width]]] || $width <= $litho_grid } {
      incr err_num
      P_msg_error "$proc_name: Invalid check grid stripe width (width) '$width' for layer '$lyr_name' configured in INTEL_CHECK_GRID_CONFIG!  Expect positive number > $litho_grid!"
      set chk_pitch 0
      set chk_offset 0
    }
    if { ![dict exists $cg_dict $lyr_name pitch] } {
      incr err_num
      P_msg_error "$proc_name: Missing check grid adjacent stripe pitch (pitch) for layer '$lyr_name' configured in INTEL_CHECK_GRID_CONFIG!  Expect positive number > stripe width (width)!"
      set chk_offset 0
    } elseif { ![string is double -strict [set pitch [dict get $cg_dict $lyr_name pitch]]] || $pitch <= $litho_grid } {
      incr err_num
      P_msg_error "$proc_name: Invalid check grid adjacent stripe pitch (pitch) '$pitch' for layer '$lyr_name' configured in INTEL_CHECK_GRID_CONFIG!  Expect positive number > stripe width (width)!"
      set chk_offset 0
    } elseif { !$chk_pitch } {
      set chk_offset 0
    } elseif { $pitch <= $width } {
      incr err_num
      P_msg_error "$proc_name: Invalid check grid adjacent stripe pitch (pitch) '$pitch' for layer '$lyr_name' configured in INTEL_CHECK_GRID_CONFIG!  Expect positive number > $width (width)!"
      set chk_offset 0
    } elseif { [set rem [format $fmt [expr fmod( [set md_grid [set $md_grid_var]] , $pitch )]]] != 0.0 && $rem != $pitch } {
    # To workaround floating imprecision of fmod().
      incr err_num
      P_msg_error "$proc_name: Invalid check grid adjacent stripe pitch (pitch) '$pitch' for layer '$lyr_name' configured in INTEL_CHECK_GRID_CONFIG!  Expect positive number being divisible factor of $md_grid_var '$md_grid', i.e. $md_grid_var is multiple of pitch!"
      set chk_offset 0
    }
    if { ![dict exists $cg_dict $lyr_name offset] } {
      incr err_num
      P_msg_error "$proc_name: Missing check grid stripe side offset (offset) for layer '$lyr_name' configured in INTEL_CHECK_GRID_CONFIG!  Expect number > - stripe width (width) && <= stripe pitch (pitch) - stripe width (width)!"
    } elseif { ![string is double -strict [set offset [dict get $cg_dict $lyr_name offset]]] } {
      incr err_num
      P_msg_error "$proc_name: Invalid check grid stripe side offset (offset) '$offset' for layer '$lyr_name' configured in INTEL_CHECK_GRID_CONFIG!  Expect number > - stripe width (width) && <= stripe pitch (pitch) - stripe width (width)!"
    } elseif { !$chk_offset } {
    } elseif { $offset <= -$width || $offset > [format $fmt [expr $pitch - $width]] } {
      incr err_num
      P_msg_error "$proc_name: Invalid check grid stripe side offset (offset) '$offset' for layer '$lyr_name' configured in INTEL_CHECK_GRID_CONFIG!  Expect number > -$width (-width) && <= [format $fmt [expr $pitch - $width]] (pitch - width)!"
    }
    if { [dict exists $cg_dict $lyr_name edge_space] } {
      incr err_num
      P_msg_error "$proc_name: Detect obsolete field 'edge_space' for check grid layer '$lyr_name' configured in INTEL_CHECK_GRID_CONFIG!  Use new equivalent field 'offset'!"
    }
    if { ![dict exists $cg_dict $lyr_name pullback] } {
      incr err_num
      P_msg_error "$proc_name: Missing check grid stripe end pullback (pullback) for layer '$lyr_name' configured in INTEL_CHECK_GRID_CONFIG!  Expect number >= 0.0!"
    } elseif { ![string is double -strict [set pullback [dict get $cg_dict $lyr_name pullback]]] || $pullback < 0.0 } {
      incr err_num
      P_msg_error "$proc_name: Invalid check grid stripe end pullback (pullback) '$pullback' for layer '$lyr_name' configured in INTEL_CHECK_GRID_CONFIG!  Expect number >= 0.0!"
    }
  }
  if { $err_num > 0 } {
    P_msg_error "$proc_name: Abort due to $err_num errors above!"
    return
  }

  # Get & check macro cells.
  set all_macro_cells [get_cells -quiet -physical_context -filter {design_type == macro || design_type == module} *]
  if { [info exists opts(-macros)] } {
    if { [string match _sel* $opts(-macros)] } {
      if { [set obj_class [lsort -unique [get_attribute -objects $opts(-macros) -name object_class]]] != {cell} } {
        incr err_num
        P_msg_error "$proc_name: Invalid object class '$obj_class' of collection '[get_object_name $opts(-macros)]' for -macros option!  Expect 'cell' object class only!"
      } else {
        set macro_cells $opts(-macros)
      }
    } else {
      set macro_cells {}
      foreach cell_name $opts(-macros) {
        set cells [get_cells -quiet $cell_name]
        if { [sizeof_collection $cells] == 0 } {
          incr err_num
          P_msg_error "$proc_name: Failed to find any cell matching name '$cell_name' by -macros option in design!"
        } else {
          append_to_collection -unique macro_cells $cells
        }
      }
    }
    if { $err_num > 0 } {
      P_msg_error "$proc_name: Abort due to $err_num errors above!"
      return
    }
    if { [sizeof_collection $macro_cells] > 0 } {
      set ref_list [lsort -unique -dictionary [get_attribute -objects $macro_cells -name ref_name]]
      set macro_info_txt "[sizeof_collection $macro_cells] macro cells of [llength $ref_list] references '$ref_list'"
      P_msg_info "$proc_name: Found [sizeof_collection $macro_cells] macro cells '[get_object_name $macro_cells]' of [llength $ref_list] references '$ref_list' selected by -macros option for check grid insertion."
      if { [sizeof_collection [set other_cells [filter_collection $macro_cells {design_type != macro && design_type != module}]]] > 0 } {
        set other_ref_list [lsort -unique -dictionary [get_attribute -objects $other_cells -name ref_name]]
        P_msg_warn "$proc_name: Detect [sizeof_collection $other_cells] non-macro cells '[get_object_name $other_cells]' of [llength $other_ref_list] references '$other_ref_list' included by -macros option!"
      }
      if { [sizeof_collection [set skip_cells [remove_from_collection $all_macro_cells $macro_cells]]] > 0 } {
        set skip_ref_list [lsort -unique -dictionary [get_attribute -objects $skip_cells -name ref_name]]
        P_msg_warn "$proc_name: Detect [sizeof_collection $skip_cells] macro cells '[get_object_name $skip_cells]' of [llength $skip_ref_list] references '$skip_ref_list' skipped due to not included by -macros option!"
        foreach ref_name $skip_ref_list {
          set sel_ref_cells [filter_collection $macro_cells "ref_name == $ref_name"]
          set skip_ref_cells [filter_collection $skip_cells "ref_name == $ref_name"]
          if { [sizeof_collection $sel_ref_cells] > 0 && [sizeof_collection $skip_ref_cells] > 0 } {
            P_msg_warn "$proc_name: Detect [sizeof_collection $sel_ref_cells] of total [expr [sizeof_collection $sel_ref_cells] + [sizeof_collection $skip_ref_cells]] macro cells '[get_object_name $sel_ref_cells]' of reference '$ref_name' included by -macros option but the other [sizeof_collection $skip_ref_cells] macro cells '[get_object_name $skip_ref_cells]' of same reference excluded by -macros option!"
          }
        }
      }
    } else {
      set macro_info_txt {}
      P_msg_info "$proc_name: No macro cell selected by -macros option for check grid insertion."
    }
  } else {
    set macro_cells [sort_collection -dictionary $all_macro_cells full_name]
    if { [sizeof_collection $macro_cells] > 0 } {
      set ref_list [lsort -unique -dictionary [get_attribute -objects $macro_cells -name ref_name]]
      set macro_info_txt "[sizeof_collection $macro_cells] macro cells of [llength $ref_list] references '$ref_list'"
      P_msg_info "$proc_name: All [sizeof_collection $macro_cells] macro cells '[get_object_name $macro_cells]' of [llength $ref_list] references '$ref_list' selected by default for check grid insertion."
    } else {
      set macro_info_txt {}
      P_msg_info "$proc_name: No macro cell found in design for check grid insertion."
    }
  }
  if { $err_num > 0 } {
    P_msg_error "$proc_name: Abort due to $err_num errors above!"
    return
  }

  if { [get_defined_attributes -user -class shape is_check_grid] == {} } {
    define_user_attribute -persistent -classes shape -type boolean -name is_check_grid
  }

  if { [sizeof_collection [set old_cg_shps [get_shapes -quiet -filter {is_check_grid == true} *]]] > 0 } {
    foreach_in_collection lyr [sort_collection [get_layers [lsort -unique [get_attribute -objects $old_cg_shps -name layer_name]]] mask_order] {
    # Somehow name attribute of layer object always appends purpose_number/datatype_number if non-zero, despite layer_name already indicates the purpose/datatype.
      set lyr_name [lindex [split [get_object_name $lyr] :] 0]
      set old_cg_lyr_shps [filter_collection $old_cg_shps "layer_name == $lyr_name"]
      if { [lsearch -exact $cfg_cg_lyr_list $lyr_name] < 0 } {
        P_msg_warn "$proc_name: Keeping pre-existing [sizeof_collection $old_cg_lyr_shps] segments of check grid stripes of layer '$lyr_name'!"
      } elseif { $force_opt } {
        P_msg_warn "$proc_name: Deleted pre-existing [remove_shapes $old_cg_lyr_shps] segments of check grid stripes of layer '$lyr_name'!"
      } else {
        incr err_num
        P_msg_error "$proc_name: Detect pre-existing [sizeof_collection $old_cg_lyr_shps] segments of check grid stripes of layer '$lyr_name'!  Must delete them before creating new ones again or use '-force' option!"
      }
    }
  }
  if { $err_num > 0 } {
    P_msg_error "$proc_name: Abort due to $err_num errors above!"
    return
  }

  unset err_num
  unset -nocomplain lyr
  unset -nocomplain chk_pitch
  unset -nocomplain chk_offset
  unset -nocomplain md_grid_var
  unset -nocomplain md_grid
  unset -nocomplain rem
  unset all_macro_cells
  unset -nocomplain cells
  unset -nocomplain ref_list
  unset -nocomplain other_cells
  unset -nocomplain other_ref_list
  unset -nocomplain skip_cells
  unset -nocomplain skip_ref_list
  unset -nocomplain skip_ref_cells
  unset -nocomplain sel_ref_cells
  unset old_cg_shps
  unset -nocomplain old_cg_lyr_shps

  # ASSERT: Only $proc_name, $verb_opt, $die_bndry, $fmt, $litho_grid, $cfg_cg_lyr_list, $cg_dict, $macro_cells & $macro_info_txt vars are required hereafter.

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

  # Unfortunately, compute_polygons -objects? & resize_polygons -objects options don't yet support block object.  Hence, use boundary coord_list instead.
  if { [sizeof_collection $macro_cells] > 0 } {
    set no_macro_gm [compute_polygons -operation not -objects1 $die_bndry -objects2 $macro_cells]
    set macro_msg " but excluding crossing $macro_info_txt"
  } else {
    set no_macro_gm [create_geo_mask -objects $die_bndry]
    set macro_msg {}
  }
  array unset die_bbox
  scan [get_attribute -objects [current_block] -name boundary_bbox] {{%f %f} {%f %f}} die_bbox(llx) die_bbox(lly) die_bbox(urx) die_bbox(ury)

  set orig_val(snap_setting-enabled) [get_snap_setting -enabled]
  set_snap_setting -enabled 0

  foreach lyr_name $cfg_cg_lyr_list {
    set dir {}
    set width {}
    set pitch {}
    set offset {}
    set pullback {}
    dict with cg_dict $lyr_name {
      set axis $dir_2_axis($dir)
      set ortho_dir $dir_2_ortho_dir($dir)
      set ortho_axis $dir_2_axis($ortho_dir)
      set pitch_num [expr round( ( $die_bbox(ur$axis) - $die_bbox(ll$axis) ) / $pitch )]
      if { $verb_opt } {
        P_msg_info "$proc_name: Creating $pitch_num parallel $dir stripes of width '$width' at $axis pitch '$pitch' from $axis offset '$offset' with end $ortho_axis pullback '$pullback' for check grid layer '$lyr_name' across partition$macro_msg ..."
      }
      array unset adj_margin
      set adj_margin(ll$ortho_axis) -$pullback
      set adj_margin(ur$ortho_axis) -$pullback
      if { $offset < 0.0 } {
        incr pitch_num
        set adj_margin(ll$axis) [format $fmt [expr - $offset]]
        set adj_margin(ur$axis) [format $fmt [expr $width + $offset]]
      } else {
        set adj_margin(ll$axis) 0.0
        set adj_margin(ur$axis) 0.0
      }
      set allow_gm [resize_polygons -size "$adj_margin(llx) $adj_margin(lly) $adj_margin(urx) $adj_margin(ury)" -objects $no_macro_gm]
      array unset strp_bbox
      set strp_bbox(ll$ortho_axis) $die_bbox(ll$ortho_axis)
      set strp_bbox(ur$ortho_axis) $die_bbox(ur$ortho_axis)
      set cg_shps {}
      for { set pitch_idx 0 } { $pitch_idx < $pitch_num } { incr pitch_idx } {
        set strp_bbox(ll$axis) [format $fmt [expr $die_bbox(ll$axis) + $offset + $pitch * $pitch_idx]]
        set strp_bbox(ur$axis) [format $fmt [expr $strp_bbox(ll$axis) + $width]]
        set strp_gm [compute_polygons -operation and -objects1 $allow_gm -objects2 [create_poly_rect -boundary "{$strp_bbox(llx) $strp_bbox(lly)} {$strp_bbox(urx) $strp_bbox(ury)}"]]
        # ASSERT: Since INTEL_MD_GRID_* is multiple of pitch, vertices of partition & macros are snapped to INTEL_MD_GRID_*, and sides of partition & macros are trimmed to negative offset, resulting polygons are always disjoint aligned rectangles.
        #foreach_in_collection strp_pr [split_polygons -output poly_rect -split $ortho_dir -objects $strp_gm]
        set strp_shps {}
        foreach_in_collection strp_pr [get_attribute -objects $strp_gm -name poly_rects] {
          if { [is_false [get_attribute -objects $strp_pr -name is_rectangle]] } {
            P_msg_error "$proc_name: Detect non-rectangular [llength [get_attribute -objects $strp_pr -name point_list]]-sided polygon '[get_attribute -objects $strp_pr -name point_list]' to create [expr $pitch_idx + 1]-th $dir stripe of width '$width' for check grid layer '$lyr_name' at ll$axis '$strp_bbox(ll$axis)' & ur$axis '$strp_bbox(ur$axis)'!  Plese report this issue to ICF."
            continue
          }
          append_to_collection strp_shps [create_shape -layer $lyr_name -shape_type rect -boundary $strp_pr -shape_use user_route]
        }
        if { $verb_opt } {
          P_msg_info "$proc_name:   Created [sizeof_collection $strp_shps] segments at [expr $pitch_idx + 1]-th $dir stripe of width '$width' for check grid layer '$lyr_name' at ll$axis '$strp_bbox(ll$axis)' & ur$axis '$strp_bbox(ur$axis)'."
        }
        set_attribute -quiet -objects $strp_shps -name is_check_grid -value true
        append_to_collection cg_shps $strp_shps
      }
      P_msg_info "$proc_name: Created [sizeof_collection $cg_shps] segments on $pitch_num parallel $dir stripes of width '$width' at $axis pitch '$pitch' from $axis offset '$offset' with end $ortho_axis pullback '$pullback' for check grid layer '$lyr_name' across partition$macro_msg."
    }
  }

  set_snap_setting -enabled $orig_val(snap_setting-enabled)

  return 1
}

define_proc_attributes create_check_grid \
  -info "Create diffusion & poly check grids of parallel stripes across partition, except over macro cells, as specified by INTEL_CHECK_GRID_CONFIG.  Sanity check for pitch vertical & horizontal values using INTEL_MD_GRID_X & INTEL_MD_GRID_Y respectively." \
  -define_args {
    {-macros "Macro cells to skip check grid stripes from crossing them. Default: All macro cells" list_or_collection list optional}
    {-force "Delete pre-existing check grid stripes, instead of display error messages" {} boolean optional}
    {-verbose "Display verbose informational messages" {} boolean optional}
}

create_check_grid

# EOF

