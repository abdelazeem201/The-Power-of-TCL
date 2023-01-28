##################################################################################################
## Check for narrow channel between macros or between macro and boundary narrow_channel_width < 1um in floorplan stage ##
## Run the script on floorplan stage because of derive_placement_blockage limitation
##################################################################################################

proc P_check_narrow_channel { narrow_channel_width } {
  set proc_name [namespace tail [lindex [info level 0] 0]]

  if { [sizeof_collection [set core_area [get_core_area]]] == 0 } {
    error "$proc_name: Unable to find core area in design!  Expect design floorplan has been created/initialized!"
    return
  }

  set core_bndry [get_attribute $core_area boundary]

  if { [sizeof_collection [set macro_cells [filter_collection [get_cells -hier] "is_hard_macro==true || is_soft_macro==true"]]] > 0 } {
    if { [sizeof_collection [set unplaced_macro_cells [filter_collection $macro_cells {is_placed == false}]]] > 0 } {
      error "$proc_name: Detect [sizeof_collection $unplaced_macro_cells] unplaced macro cells '[get_object_name $unplaced_macro_cells]'!  Expect all macro cells are placed!"
      return
    }
  }

  suppress_message SEL-004
  redirect /dev/null { [remove_placement_blockages [get_placement_blockages -quiet -filter is_derived==true]]}
  set_app_options -name place.floorplan.sliver_size -value ${narrow_channel_width}um
  derive_placement_blockage

  if { [set is_in_gui [get_app_var in_gui_session]] } {
    gui_remove_all_annotations -group narrow_channel_width
  }

  if {[sizeof_collection [get_placement_blockage -quiet -filter is_derived==true]] > 0 } {
    foreach_in_collection one_derived_blockage [get_placement_blockage -quiet -filter is_derived==true] {
      set blockage_bbox [get_attr [get_placement_blockage $one_derived_blockage] bbox]
      P_msg_error "$proc_name: Detect violating narrow channel, width below '$narrow_channel_width'um at bbox '$blockage_bbox'"
      if { $is_in_gui } {
        set hili_txt "Detect violating narrow channel width  < $narrow_channel_width at bbox $blockage_bbox"
        P_msg_info "$proc_name:add red-colored annotation on violating narrow channel, width below '$narrow_channel_width'um at bbox '$blockage_bbox'"
        gui_add_annotation -group narrow_channel_width -type rect -color red -width 1 -line_style DashLine -pattern DiagCrossPattern -info_tip $hili_txt -query_text $hili_txt $blockage_bbox

      }
    }
  } else {
    P_msg_info "$proc_name: No narrow channel width < $narrow_channel_width found."
  }

  ## remove derived placement blockage
  redirect /dev/null { [remove_placement_blockages [get_placement_blockages -filter is_derived==true]]}
}

##################################################################################################
## Check for narrow macro width 1.8 for x for macro , 1.63 for y for narrow macro  length       ##
##################################################################################################

proc P_check_narrow_macro_width_length { min_x_width min_y_length} {
  set proc_name [namespace tail [lindex [info level 0] 0]]

  if { [sizeof_collection [set core_area [get_core_area]]] == 0 } {
    error "$proc_name: Unable to find core area in design!  Expect design floorplan has been created/initialized!"
    return
  }

  foreach proc {P_msg_info P_msg_warn P_msg_error} {
    if { [info procs $proc] == {} } {
      echo "#ERROR-MSG: $proc_name: Missing required proc '$proc'!  Check 'procs.tcl' file!"
      return
    }
  }

  if { [sizeof_collection [set macro_cells [filter_collection [get_cells -hier] "is_hard_macro==true || is_soft_macro==true"]]] > 0 } {
    if { [sizeof_collection [set unplaced_macro_cells [filter_collection $macro_cells {is_placed == false}]]] > 0 } {
      error "$proc_name: Detect [sizeof_collection $unplaced_macro_cells] unplaced macro cells '[get_object_name $unplaced_macro_cells]'!  Expect all macro cells are placed!"
      return
    }
  }


  suppress_message SEL-004

  #check GUI mode for adding anotation on layout
  if { [set is_in_gui [get_app_var in_gui_session]] } {
    gui_remove_all_annotations -group macro_min_width
  }

  #check min_x_width on bottom and top side
  foreach_in_collection  onemacro_cell $macro_cells {
    set macro_bound [get_attr $onemacro_cell boundary]
    set macro_name [get_attr $onemacro_cell name]
    set macro_bound_bt [resize_polygon -objects  $macro_bound -size {0 0.5 0 0.5}]
    set macro_bound_lr [resize_polygon -objects  $macro_bound -size {0.5 0 0.5 0}]
    set new_polygon [compute_polygon -objects1 $macro_bound_bt -operation NOT -objects2 $macro_bound]
    set new_polygon_list [list [get_attribute [get_attribute $new_polygon poly_rects] point_list]]
    set min_x_width_exist 0

    set onelist [lindex $new_polygon_list  0 ]

    set len [llength $onelist]

    for { set i 0 } { $i < $len } {incr i } {
      set x1 [lindex [lindex $onelist $i] {0 0}]
      set y1 [lindex [lindex $onelist $i] { 0 1 }]
      set x2 [lindex [lindex $onelist $i] {2 0}]
      set y2 [lindex [lindex $onelist $i] { 2 1 }]
      set lista [list [list $x1 $y1] [list $x2 $y2]]
      set onepolyrec [create_poly_rect -boundary $lista]
      set overlap_polyrec [compute_polygons -objects1  $macro_bound_lr -objects2 $onepolyrec -operation AND]
      set width [expr abs($x1 - $x2)]
      set isempty [get_attr $overlap_polyrec is_empty]
      if { $width < $min_x_width && $isempty eq true } {
        P_msg_error "$proc_name: Detected violating narrow min x width,  x width $width < $min_x_width  at bbox '$lista' in Macro $macro_name"
        if { $is_in_gui } {
          set hili_txt "Violating narrow min x width , x width $width < $min_x_width min width in Macro $macro_name"
          P_msg_info "$proc_name: add annotation on narrow min x width, x width $width < $min_x_width at bbox '$lista' in Macro $macro_name"
          gui_add_annotation -group macro_min_width -type rect -color orangered -width 1 -line_style DashLine -pattern DiagCrossPattern -info_tip $hili_txt -query_text $hili_txt $lista
          set min_x_width_exist 1
        }
      } else {
        set min_x_width_exist 0
      }

    }
    if { $min_x_width_exist == 0 } {
      P_msg_info "$proc_name: No narrow min x width < $min_x_width found in Macro $macro_name."
    } else {
      P_msg_info "$proc_name: narrow min x width < $min_x_width found in Macro $macro_name."
    }

  }


  #check min_y_length on left and right side
  foreach_in_collection  onemacro_cell $macro_cells {
    set macro_bound [get_attr $onemacro_cell boundary]
    set macro_name [get_attr $onemacro_cell name]
    set macro_bound_lr [resize_polygon -objects  $macro_bound -size {0.5 0 0.5 0}]
    set macro_bound_bt [resize_polygon -objects  $macro_bound -size {0 0.5 0 0.5}]
    set new_polygon [compute_polygon -objects1 $macro_bound_lr -operation NOT -objects2 $macro_bound]
    set new_polygon_list [list [get_attribute [get_attribute $new_polygon poly_rects] point_list]]
    set min_y_length_exist 0

    set onelist [lindex $new_polygon_list  0 ]

    set len [llength $onelist]

    for { set i 0 } { $i < $len } {incr i } {
      set x1 [lindex [lindex $onelist $i] { 0 0 }]
      set y1 [lindex [lindex $onelist $i] { 0 1 }]
      set x2 [lindex [lindex $onelist $i] { 2 0 }]
      set y2 [lindex [lindex $onelist $i] { 2 1 }]
      set lista [list [list $x1 $y1] [list $x2 $y2]]
      set onepolyrec [create_poly_rect -boundary $lista]
      set overlap_polyrec [compute_polygons -objects1  $macro_bound_bt -objects2 $onepolyrec -operation AND]
      set length [expr abs($y1 - $y2)]
      set isempty [get_attr $overlap_polyrec is_empty]
      if { $length < $min_y_length && $isempty eq true } {
        P_msg_error "$proc_name: Detected violating narrow min y length,  y length $length < $min_y_length  at bbox '$lista' in Macro $macro_name"
        if { $is_in_gui } {
          set hili_txt "Violating narrow min y length , y width $length < $min_y_length min width in Macro $macro_name"
          P_msg_info "$proc_name: add annotation on narrow min y length, y length $length < $min_y_length at bbox '$lista' in Macro $macro_name"
          gui_add_annotation -group macro_min_width -type rect -color orangered -width 1 -line_style DashLine -pattern DiagCrossPattern -info_tip $hili_txt -query_text $hili_txt $lista
          set min_y_length_exist 1
        } 
      } else {
        set min_y_length_exist 0
      }

    }	
    if { $min_y_length_exist == 0 } {
      P_msg_info "$proc_name: No narrow min y length < $min_y_length found in Macro $macro_name."
    } else {
      P_msg_info "$proc_name: narrow min y length < $min_y_length found in Macro $macro_name."
    }
  }

}

#  check the narrow channel below 1um
P_check_narrow_channel 1

#  check the narrow macro width x:1.8um, y:1.63um 
P_check_narrow_macro_width_length 1.8 1.63
