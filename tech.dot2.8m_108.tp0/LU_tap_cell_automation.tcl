###############################################################
# Proc: P_add_lu_tap_cells
# Description:
#
# Arguments:
#
#
###############################################################
proc P_add_lu_tap_cells args {
  global INTEL_DESIGN_WIDTH INTEL_DESIGN_HEIGHT INTEL_FP_BOUNDARY
  global INTEL_FP_INPUT INTEL_TAP_CELL
  global INTEL_MD_GRID_X INTEL_MD_GRID_Y
  global INTEL_STDCELL_CORE2H_TILE INTEL_NWELL_TAP_CELL
  parse_proc_arguments -args $args opts
  set proc_name [namespace tail [lindex [info level 0] 0]]
  #set INTEL_MD_GRID_X                 0.108
  #set INTEL_MD_GRID_Y                 0.630

  # Debug print inputs to the proc
  puts "proc_name = $proc_name"
  puts "args = $args"
  parray opts

  # Check the values of the args passed in
  # 1.  Make sure that the tap_cell_name is a valid tap cell
  # 2.  Validate the width_spacing_list
  #     a. Even number of entries?
  #     b. Increasing ring width

  set i 0
  foreach {width spacing} $opts(-width_spacing_list) {
    set w($i) $width
    set s($i) $spacing
    incr i
  }
  puts "INFO-MSG==> Please make sure your design is big enough to support the 80 um and 180 um zone D and zone E ring widths "
  puts "Ring ID   Width    Spacing"
  puts "-------   -----    -------"
  for {set i 0} {$i<[array size w]} {incr i} {
    puts "  $i         $w($i)       $s($i)"
  }
  #puts "INFO-MSG==> Checking if the ring widths are integral multiple of the modular grid Y"
  # Now here, we have good data passed the proc.
  # We check if the ring widths are multiples of the Modular grid Y
  #for {set i 0} {$i<[array size w]} {incr i} {
  #  if { [expr fmod($w($i),$INTEL_MD_GRID_Y)] == 0 } {
  #    puts "INFO-MSG==> No change required in the ring width "
  #  } else {
  #    puts "INFO-MSG==> Changing the ring width to integral multiple of the modular grid Y"
  #    set w($i) [expr $w($i)*$INTEL_MD_GRID_Y]
  #  }
  #}
  #puts "INFO-MSG==> Post check ring-width and spacing"
  #puts "Ring ID   Width    Spacing"
  #puts "-------   -----    -------"
  #for {set i 0} {$i<[array size w]} {incr i} {
  #  puts "$i   $w($i)   $s($i)"
  #}
  # Start algorithm
  # 1.  find all esd_id locations
  # 2.  Process each esd_id
  ######################Algorithm######################

  ##### Following section looks for Esd layers inside the macros as well as block-level#####
  ##### It also gathers the locations of all the Esd layers under one variable#####
  puts "INFO-MSG==> Looking for Esd layers in the block level as well as macros"
  set all_macro_esd_var [list ]
  set block_esd_var [get_attribute -value_list [get_shapes -quiet -filter "layer_name==esd_id"] bbox]
  set all_macro_cells [get_cells -quiet -physical_context -filter {is_hard_macro == true || is_soft_macro ==true}]
  if { [sizeof_collection $all_macro_cells] != 0 && [llength $block_esd_var] != 0 } {
    foreach_in_collection cell $all_macro_cells {
      set macro_esd_var [get_attribute -value_list [get_shapes -quiet -of $cell -filter "layer_name==esd_id"] bbox]
      if { [llength $macro_esd_var] !=0 } {
        set all_macro_esd_var [concat $all_macro_esd_var $macro_esd_var]
      } else {
        continue
      }
    }
    if { [llength $all_macro_esd_var] !=0 } {
      set esd_var [concat $block_esd_var $all_macro_esd_var]
    } else {
      set esd_var $block_esd_var
    }
    puts "all_macro_esd_var==> $all_macro_esd_var"
    puts "esd_var==> $esd_var"
  } elseif { [sizeof_collection $all_macro_cells] == 0 && [llength $block_esd_var] != 0 } {
    set esd_var $block_esd_var
  } elseif { [sizeof_collection $all_macro_cells] != 0 && [llength $block_esd_var] == 0} {
    foreach_in_collection cell $all_macro_cells {
      set macro_esd_var [get_attribute -value_list [get_shapes -quiet -of $cell -filter "layer_name==esd_id"] bbox]
      if { [llength $macro_esd_var] !=0 } {
        set all_macro_esd_var [concat $all_macro_esd_var $macro_esd_var]
      } else {
        continue
      }
    }
    if { [llength $all_macro_esd_var] !=0 } {
      set esd_var $all_macro_esd_var
    } else {
      puts "INFO-MSG==> No esd_id inside the macros" 
    }
  } else {
    puts "INFO-MSG==> No esd_ids" 
  }
  puts "INFO-MSG==> Gathering all the shapes under one variable "

  ##### Creating placement blockage on all the Esd layers #####
  puts "INFO-MSG==> Creating placement blockage on all the Esd layers"
  if { [info exists esd_var] } {
    set counter 1
    set counter_2 0

    ##### Actual automation where tap-cell rings are creating accoriding to the -width_cell_spacing args taken as an input to this proc #####
    puts "INFO-MSG==> Starting automation for creating tap-cell rings around the Esd layers"
    for {set i 1} {$i<[array size w]} {incr i} {
      set var_esd_ring_blockage [compute_polygons -objects1 [get_attribute [current_design] boundary] -operation NOT -objects2 $esd_var ]
      set var_esd_ring_blockage_2 [compute_polygons -objects1 $var_esd_ring_blockage -operation NOT -objects2  [resize_polygons -objects $esd_var -size "$w($i)"]]
      set var_esd_ring_blockage_3 [compute_polygons -objects1 $var_esd_ring_blockage -operation NOT -objects2 $var_esd_ring_blockage_2]
      set var_esd_ring_blockage_4 [compute_polygons -objects1 $var_esd_ring_blockage_3 -operation NOT -objects2 [resize_polygons -objects $esd_var -size "$w([expr $i-1])"]]
      if { $i==1 } {
        set polygon_splitting [split_polygons -objects $var_esd_ring_blockage_4 -split horizontal]
        foreach_in_collection test_var $polygon_splitting {
          create_shape -shape_type rect -boundary $test_var  -layer LATCHUP_ZONE_D
        }
      } elseif { $i==2 } {
        set polygon_splitting [split_polygons -objects $var_esd_ring_blockage_4 -split horizontal]
        foreach_in_collection test_var $polygon_splitting {
          create_shape -shape_type rect -boundary $test_var  -layer LATCHUP_ZONE_E
        }
      } else {
        puts "INFO-MSG==> Incorrect list specified we are supporting only Zone_D and Zone_E "
      }
    }
  } else {
    puts "INFO-MSG==> No esd_id looking for LATCHUP_ZONE_D and LATCHUP_ZONE_E"
  }
  ###################Code for LATCHUP_ZONE_D and LATCHUP_ZONE_E#################################
  set block_level_zone_D [get_attribute -value_list [get_shapes -quiet -filter "layer_name==LATCHUP_ZONE_D"] bbox]
  if { [llength $block_level_zone_D] != 0 } {
    set zone_D_blockage [compute_polygons -objects1 [get_attribute [current_design] boundary] -operation NOT -objects2 $block_level_zone_D]
    set zone_D_polygon_splitting [split_polygons -objects $zone_D_blockage -split horizontal]
    set counter_3 0
    foreach_in_collection test_var $zone_D_polygon_splitting {
      incr counter_3
      create_placement_blockage -boundary $test_var -type hard -name zone_D_blockage_${counter_3}
    }
    create_tap_cells -lib_cell [index_collection [get_lib_cells */$INTEL_TAP_CELL] 0] -distance $s(1) -skip_fixed_cells -separator "_"
    set dh_tap_cells [get_flat_cells -all -filter "ref_name==$INTEL_TAP_CELL"]
    set cnt 0
    if { [sizeof_collection $dh_tap_cells] > 0 } {
      set inc_num 1
      foreach_in_collection tap $dh_tap_cells {
        scan [get_attribute $tap boundary_bbox] "{%f %f} {%f %f}" lx ly ux uy
        create_placement_blockage -boundary [list [list [expr $lx-0.001] $ly] [list [expr $ux+0.001] $uy]] -type hard -name tap_blkg_$cnt
        incr cnt
      }
    }
    set bbox {}
    foreach_in_collection sr [get_site_rows -filter "site_def.name==$INTEL_STDCELL_CORE2H_TILE"] {
      if {$bbox eq ""} {
        set bbox [create_geo_mask -objects [get_attribute $sr bbox]]
      } else {
        set bbox [compute_polygons -objects1 [get_attribute $sr bbox] -operation OR -objects2 $bbox]
      }
    }
    set _bnd_resized_all [resize_polygons -objects  $bbox -size "0 0 0 -$INTEL_MD_GRID_Y"]

    set all_macro_cells [get_cells -quiet -physical_context -filter {is_hard_macro == true || is_soft_macro == true}]
    if {[sizeof_collection $all_macro_cells] > 0} {
      set _w 0
      set _ht $INTEL_MD_GRID_Y
      set macro_bbox ""
      foreach_in_collection macro $all_macro_cells {
        set _bnd [create_geo_mask -objects [get_attribute $macro boundary]]
        set _bnd_resized [resize_polygons -objects  $_bnd -size "$_w $_ht"]
        foreach_in_col each [get_attribute $_bnd_resized poly_rects]  {
          set all_bbox [get_attribute [split_polygons $each] poly_rects.bbox]
          if {[llength $all_bbox] == 2} {
            set all_bbox [list $all_bbox]
          }
          foreach bbox $all_bbox {
            scan $bbox "{%f %f} {%f %f}" lx ly ux uy
            set ly_mod [format "%.f" [expr fmod($ly, [expr 2*$INTEL_MD_GRID_Y])]]
            if {$ly_mod ne 0} {
              # need to add nwell tap cells
              lappend macro_bbox "{$lx [expr $ly-$INTEL_MD_GRID_Y]} {$ux $ly}"
            }
            set uy_mod [format "%.f" [expr fmod($uy, [expr 2*$INTEL_MD_GRID_Y])]]
            if {$uy_mod ne 0} {
              lappend macro_bbox "{$lx $uy} {$ux [expr $uy+$INTEL_MD_GRID_Y]}"
            }

          }
        }
      }
      set macro_polygon {}
      foreach bbox $macro_bbox {
        if {$macro_polygon eq ""} {
          set macro_polygon [create_geo_mask -objects $bbox]
        } else {
          set macro_polygon [compute_polygons -objects1 $bbox -operation OR -objects2 $macro_polygon]

        }
      }
      if {$macro_bbox != ""} {
        set poly_cells [create_poly_rect -boundary $macro_bbox]
        set nwell_tap_bbox [compute_polygons -operation XOR -objects1 $_bnd_resized_all -objects2 $poly_cells]
        #set nwell_tap_bbox [compute_polygons -objects1 $_bnd_resized_all -operation NOT -objects2 $macro_polygon]
        foreach each [get_attribute [split_polygons $nwell_tap_bbox] bbox]  {
          create_placement_blockage -boundary $each -type hard -name tap_blkg_$cnt
          incr cnt
        }
      } else {
        foreach_in_col each [get_attribute $_bnd_resized_all poly_rects]  {
          create_placement_blockage -boundary [get_attribute $each point_list] -type hard -name tap_blkg_$cnt
          incr cnt
        }
      }
    } else {
      foreach_in_col each [get_attribute $_bnd_resized_all poly_rects]  {
        create_placement_blockage -boundary [get_attribute $each point_list] -type hard -name tap_blkg_$cnt
        incr cnt
      }
    }
    set tap_cell_name [get_object_name [get_lib_cells */$INTEL_NWELL_TAP_CELL]]

    create_tap_cells -lib_cell [index_collection [get_lib_cells */$INTEL_NWELL_TAP_CELL] 0] -distance $s(1) -pattern every_row -skip_fixed_cells 
    remove_placement_blockages [get_placement_blockages tap_blkg_*]
    remove_placement_blockages zone_D_blockage_*
    foreach box [get_attribute -value_list [get_shapes -quiet -filter "layer_name==LATCHUP_ZONE_D"] bbox] {
      incr counter_3
      create_placement_blockage -bbox $box -type hard -name zone_D_core_blockage_${counter_3}
    }
  } else {
    puts "INFO-MSG==> No LATCHUP_ZONE_D looking for LATCHUP_ZONE_E"
  }

  set block_level_zone_E [get_attribute -value_list [get_shapes -quiet -filter "layer_name==LATCHUP_ZONE_E"] bbox]
  if { [llength $block_level_zone_E] != 0 } {
    set zone_E_blockage [compute_polygons -objects1 [get_attribute [current_design] boundary] -operation NOT -objects2 $block_level_zone_E]
    set zone_E_polygon_splitting [split_polygons -objects $zone_E_blockage -split horizontal]
    set counter_4 0
    foreach_in_collection test_var $zone_E_polygon_splitting {
      incr counter_4
      create_placement_blockage -boundary $test_var -type hard -name zone_E_blockage_${counter_4}
    }
    create_tap_cells -lib_cell [index_collection [get_lib_cells */$INTEL_TAP_CELL] 0] -distance $s(2) -skip_fixed_cells -separator "_"
    set dh_tap_cells [get_flat_cells -all -filter "ref_name==$INTEL_TAP_CELL"]
    set cnt 0
    if { [sizeof_collection $dh_tap_cells] > 0 } {
      set inc_num 1
      foreach_in_collection tap $dh_tap_cells {
        scan [get_attribute $tap boundary_bbox] "{%f %f} {%f %f}" lx ly ux uy
        create_placement_blockage -boundary [list [list [expr $lx-0.001] $ly] [list [expr $ux+0.001] $uy]] -type hard -name tap_blkg_$cnt
        incr cnt
      }
    }
    set bbox {}
    foreach_in_collection sr [get_site_rows -filter "site_def.name==$INTEL_STDCELL_CORE2H_TILE"] {
      if {$bbox eq ""} {
        set bbox [create_geo_mask -objects [get_attribute $sr bbox]]
      } else {
        set bbox [compute_polygons -objects1 [get_attribute $sr bbox] -operation OR -objects2 $bbox]
      }
    }
    set _bnd_resized_all [resize_polygons -objects  $bbox -size "0 0 0 -$INTEL_MD_GRID_Y"]
    set all_macro_cells [get_cells -quiet -physical_context -filter {is_hard_macro == true || is_soft_macro == true}]
    if {[sizeof_collection $all_macro_cells] > 0} {
      set _w 0
      set _ht $INTEL_MD_GRID_Y
      set macro_bbox ""
      foreach_in_collection macro $all_macro_cells {
        set _bnd [create_geo_mask -objects [get_attribute $macro boundary]]
        set _bnd_resized [resize_polygons -objects  $_bnd -size "$_w $_ht"]
        foreach_in_col each [get_attribute $_bnd_resized poly_rects]  {
          set all_bbox [get_attribute [split_polygons $each] poly_rects.bbox]
          if {[llength $all_bbox] == 2} {
            set all_bbox [list $all_bbox]
          }
          foreach bbox $all_bbox {
            scan $bbox "{%f %f} {%f %f}" lx ly ux uy
            set ly_mod [format "%.f" [expr fmod($ly, [expr 2*$INTEL_MD_GRID_Y])]]
            if {$ly_mod ne 0} {
              # need to add nwell tap cells
              lappend macro_bbox "{$lx [expr $ly-$INTEL_MD_GRID_Y]} {$ux $ly}"
            }
            set uy_mod [format "%.f" [expr fmod($uy, [expr 2*$INTEL_MD_GRID_Y])]]
            if {$uy_mod ne 0} {
              lappend macro_bbox "{$lx $uy} {$ux [expr $uy+$INTEL_MD_GRID_Y]}"
            }

          }
        }
      }
      set macro_polygon {}
      foreach bbox $macro_bbox {
        if {$macro_polygon eq ""} {
          set macro_polygon [create_geo_mask -objects $bbox]
        } else {
          set macro_polygon [compute_polygons -objects1 $bbox -operation OR -objects2 $macro_polygon]

        }
      }
      if {$macro_bbox != ""} {
        set poly_cells [create_poly_rect -boundary $macro_bbox]
        set nwell_tap_bbox [compute_polygons -operation XOR -objects1 $_bnd_resized_all -objects2 $poly_cells]
        #set nwell_tap_bbox [compute_polygons -objects1 $_bnd_resized_all -operation NOT -objects2 $macro_polygon]
        foreach each [get_attribute [split_polygons $nwell_tap_bbox] bbox]  {
          create_placement_blockage -boundary $each -type hard -name tap_blkg_$cnt
          incr cnt
        }
      } else {
        foreach_in_col each [get_attribute $_bnd_resized_all poly_rects]  {
          create_placement_blockage -boundary [get_attribute $each point_list] -type hard -name tap_blkg_$cnt
          incr cnt
        }
      }
    } else {
      foreach_in_col each [get_attribute $_bnd_resized_all poly_rects]  {
        create_placement_blockage -boundary [get_attribute $each point_list] -type hard -name tap_blkg_$cnt
        incr cnt
      }
    }
    set tap_cell_name [get_object_name [get_lib_cells */$INTEL_NWELL_TAP_CELL]]

    create_tap_cells -lib_cell [index_collection [get_lib_cells */$INTEL_NWELL_TAP_CELL] 0] -distance $s(2) -pattern every_row -skip_fixed_cells 
    remove_placement_blockages [get_placement_blockages tap_blkg_*]
    if {[sizeof_collection [get_placement_blockages -quiet tap_block*]]>0} {
      remove_placement_blockages [get_placement_blockages tap_block*]
    }

    remove_placement_blockages zone_E_blockage_*
    foreach box [get_attribute -value_list [get_shapes -quiet -filter "layer_name==LATCHUP_ZONE_E"] bbox] {
      incr counter_4
      create_placement_blockage -bbox $box -type hard -name zone_E_core_blockage_${counter_4}
    }
  } else {
    puts "INFO-MSG==> No LATCHUP_ZONE_E"
  }
}

define_proc_attributes P_add_lu_tap_cells \
  -info "Add latch up tap cells around esd_id layers." \
  -define_args {
  {-tap_cell_name "Library tap cell name" tap_cell_name string optional}
  {-width_spacing_list "list of ring_width and tap_cell_spacing values" width_spacing_list list  required}
}


