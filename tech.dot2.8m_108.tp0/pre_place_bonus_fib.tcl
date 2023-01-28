##############################################################
# NAME :          pre_place_bonus_fib.tcl
#
# SUMMARY :       pre place bonus fib cells
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists pre_place_bonus_fib.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_DEBUG_CELLS
#
# PROCS USED :    P_msg_warn P_msg_error P_msg_info
#                         
# DESCRIPTION :   pre_place_bonus_fib.tcl is to pre place bonus fib cells in design
#
# EXAMPLES :      
#
###############################################################
# Place groups of fib & bonus cells in staggered array pattern.

# Cells preferred in same row are specified in the same sub-list, whereas cells in different rows are specified in different sub-lists of INTEL_DEBUG_CELLS var.
# NOTE: All placement blockages are ignored, per P_placement_blockage_move_or_unmove proc.

# Configuration for staggered array placement of fib and bonus cell insertion.
# fib_bonus_start_x & fib_bonus_start_y are offsets to lower-left most cell of lower-left most cell array.
# fib_bonus_incr_x & fib_bonus_incr_y are pitches between non-staggered cell arrays, where staggered ones are at half x & y offsets between them.
set fib_bonus_cells   [dict get $INTEL_DEBUG_CELLS pre_place bonus_fib ref_cell_list]
set fib_bonus_start_x [dict get $INTEL_DEBUG_CELLS pre_place bonus_fib x_start]
set fib_bonus_start_y [dict get $INTEL_DEBUG_CELLS pre_place bonus_fib y_start]
set fib_bonus_incr_x [dict get $INTEL_DEBUG_CELLS pre_place bonus_fib x_step]
set fib_bonus_incr_y [dict get $INTEL_DEBUG_CELLS pre_place bonus_fib y_step]
set fib_bonus_prefix [dict get $INTEL_DEBUG_CELLS pre_place bonus_fib prefix]
# Scaling factors to relax array window to slightly larger than cell array specified to accommodate any overlapping tap cell.  Must be >= 1.0.
set fib_bonus_array_width_scale [dict get $INTEL_DEBUG_CELLS pre_place bonus_fib width_scale]
set fib_bonus_array_height_scale [dict get $INTEL_DEBUG_CELLS pre_place bonus_fib height_scale]

set scr_name [file rootname [file tail [info script]]]
foreach proc {P_msg_info P_msg_warn P_msg_error} {
  if { [info procs $proc] == {} } {
    echo "#ERROR-MSG: $scr_name: Missing required proc '$proc'!  Check 'procs.tcl' file!"
    return
  }
}
if { [get_app_var synopsys_program_name] != {icc2_shell} } {
  P_msg_error "$scr_name: Detect incorrect tool '[get_app_var synopsys_program_name]'!  Expect ICC2 'icc2_shell'!"
  return
} elseif { [get_app_option_value -name shell.common.product_version] < {K-2015.06-SP1} } {
  P_msg_error "$scr_name: Detect unsupported ICC2 version '[get_app_option_value -name shell.common.product_version]'!  Expect 'K-2015.06-SP1' or newer!"
  return
}
set err_num 0
foreach var {fib_bonus_cells } {
  if { ![info exists $var] } {
    incr err_num
    P_msg_error "$scr_name: Missing required var '$var'!  Check 'project_setup.tcl' file!"
  } elseif { [llength [set $var]] == 0 } {
    incr err_num
    P_msg_error "$scr_name: Detect empty list defined by var '$var'!  Check 'project_setup.tcl' file!"
  }
}
if { $err_num > 0 } {
  P_msg_error "$scr_name: Abort due to $err_num errors above!"
  return
}

if { [sizeof_collection [set garray_cells [get_cells -quiet $fib_bonus_prefix*]]] > 0 } {
  incr err_num
  P_msg_error "$scr_name: Detect pre-existing [sizeof_collection $garray_cells] fib & bonus array cells of name matching '$fib_bonus_prefix*' already inserted!  Must delete them before creating new ones again!"
}

set lib_cell_count_pair_list {}
set garray_width 0.0
set garray_height 0.0
foreach row_cell_ref_list $fib_bonus_cells {
  set row_width 0.0
  set row_height 0.0
  foreach ref_name $row_cell_ref_list {
    set lib_cell [index_collection [get_lib_cells -quiet */$ref_name] 0]
    if { [sizeof_collection $lib_cell] == 0 } {
      incr err_num
      P_msg_error "$scr_name: Unable to find any lib cell of name '$ref_name'!"
    } elseif { [sizeof_collection $lib_cell] > 1 } {
      incr err_num
      P_msg_error "$scr_name: Found multiple ([sizeof_collection $lib_cell]) lib cells '[get_object_name $lib_cell]' matching name '$ref_name'!  Expect 1 lib cell per name."
    } else {
      lappend lib_cell_count_pair_list "[get_object_name $lib_cell] 1"
      scan [get_attribute -objects $lib_cell -name boundary_bbox] {{%f %f} {%f %f}} cell_llx cell_lly cell_urx cell_ury
      set row_width [expr $row_width + $cell_urx - $cell_llx]
      set row_height [expr max( $row_height , $cell_ury - $cell_lly )]
    }
  }
  set garray_width [expr max( $garray_width , $row_width )]
  set garray_height [expr $garray_height + $row_height]
}
unset -nocomplain row_cell_ref_list
unset -nocomplain row_width row_height
unset -nocomplain ref_name lib_cell
unset -nocomplain cell_llx cell_lly cell_urx cell_ury

if { $err_num > 0 } {
  P_msg_error "$scr_name: Abort due to $err_num errors above!"
  return
}

if { [llength $lib_cell_count_pair_list] == 0 } {
  P_msg_warn "$scr_name: No fib & bonus array cell to insert from 'INTEL_DEBUG_CELLS' var!  Skip!"
  return
}

set placement_blockage_bbox_pair_list {}
if { [sizeof_collection [get_placement_blockages -quiet *]] > 0 } {
  P_msg_info "$scr_name: Temporarily moving placement blockages outside block boundary before inserting fib & bonus array cells."
  set placement_blockage_bbox_pair_list [P_placement_blockage_move_or_unmove move]
}

if { [llength $lib_cell_count_pair_list] > 0 } {
  set win_half_width [expr $garray_width * 0.5 * $fib_bonus_array_width_scale]
  set win_half_height [expr $garray_height * 0.5 * $fib_bonus_array_height_scale]
  create_cluster_cells -lib_cells $lib_cell_count_pair_list -stagger -x_step $fib_bonus_incr_x -y_step $fib_bonus_incr_y -delta_x $win_half_width -delta_y $win_half_height -x_offset [expr $fib_bonus_start_x + $win_half_width] -y_offset [expr $fib_bonus_start_y + $win_half_height] -prefix $fib_bonus_prefix
  if { [sizeof_collection [set garray_cells [get_cells -hier -quiet $fib_bonus_prefix*]]] > 0 } {
    P_msg_info "$scr_name: Total [sizeof_collection $garray_cells] fib & bonus array cells inserted with [expr [sizeof_collection $garray_cells] / [llength $lib_cell_count_pair_list]] arrays of [llength $lib_cell_count_pair_list] cells per array."
    set_placement_status legalize_only $garray_cells
    set_placement_status fixed $garray_cells
  } else {
    P_msg_error "$scr_name: Total 0 fib & bonus array cell inserted with 0 array of [llength $lib_cell_count_pair_list] cells per array!"
  }
}

if { [llength $placement_blockage_bbox_pair_list] > 0 } {
  P_msg_info "$scr_name: Restoring original placement blockages after inserting fib & bonus array cells."
  P_placement_blockage_move_or_unmove $placement_blockage_bbox_pair_list
}

unset scr_name err_num
unset garray_cells
unset lib_cell_count_pair_list
unset garray_width garray_height
unset placement_blockage_bbox_pair_list
unset -nocomplain win_half_width win_half_height

# EOF

