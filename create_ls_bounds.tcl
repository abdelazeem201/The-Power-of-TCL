##############################################################################
# Description: This script creates movebounds along voltage area boundaries for level-shifter & isolation cells, as well as to extend always-on P/G grids across voltage areas, based on the default values of INTEL_* variables described below.
#
#   set INTEL_LS_BOUND($voltage_area,$voltage_area_shape,outer) {}
#   set INTEL_LS_BOUND_CELLS($voltage_area,$voltage_area_shape,outer) {}
#
#   set INTEL_LS_BOUND($voltage_area,$voltage_area_shape,inner) {}
#   set INTEL_LS_BOUND_CELLS($voltage_area,$voltage_area_shape,inner) {}
#
# Users are expected to provide proper values for each voltage area & shape if applicable.
#
#   INTEL_LS_BOUND($voltage_area,outer) = List of margins of outer movebound from sides of single-shape voltage area starting from lower left-most edge in clockwise order.
#   INTEL_LS_BOUND_CELLS($voltage_area,outer) = List of cell patterns of level-shifter & isolation cells with parent location in UPF for outer movebound of single-shape voltage area.
#
#   INTEL_LS_BOUND($voltage_area,$voltage_area_shape,outer) = List of margins of outer movebound from sides of 1 of the multiple disjoint shapes of voltage area starting from lower left-most edge in clockwise order.
#   INTEL_LS_BOUND_CELLS($voltage_area,$voltage_area_shape,outer) = List of cell patterns of level-shifter & isolation cells with parent location in UPF for outer movebound of 1 of the multiple disjoint shapes of voltage area.
#
#   INTEL_LS_BOUND($voltage_area,inner) = List of margins of inner movebound from sides of single-shape voltage area starting from lower left-most edge in clockwise order.
#   INTEL_LS_BOUND_CELLS($voltage_area,inner) = List of cell patterns of level-shifter & isolation cells with self location in UPF for inner movebound of single-shape voltage area.
#
#   INTEL_LS_BOUND($voltage_area,$voltage_area_shape,inner) = List of margins of inner movebound from sides of 1 of the multiple disjoint shapes of voltage area starting from lower left-most edge in clockwise order.
#   INTEL_LS_BOUND_CELLS($voltage_area,$voltage_area_shape,inner) = List of cell patterns of level-shifter & isolation cells with self location in UPF for inner movebound of 1 of the multiple disjoint shapes of voltage area.
#
# NOTE:
#   Movebound margins & cells for single-shape voltage area can also be specified using the format with explicit voltage area shape, but not vice-versa.
#   Number of margins for a voltage area shape must be either match the number of sides or empty.
#   Margins must be either positive number or 0 for no movebound at the given side.
#   Margins of vertical edges must be multiple of placement site width and >= width of vertical halo cell + widest level-shifter/isolation cell.
#   Margins of horizontal edges must be multiple of row height and >= 2 rows (level-shifter cells are double-height).
#
# Required procs:
#   P_msg_info
#   P_msg_warn
#   P_msg_error
#

set scr_name [file rootname [file tail [info script]]]

set bnd_prefix BOUND_VA

########################################
# Sort vertices of rectilinear polygons to start from lower left-most edges in clockwise order.

proc get_polygon_ordered_vertices { poly } {
  if { [llength $poly] == 0 } {
    P_msg_warn "$scr_name: Empty polygon '$poly'!"
    return {}
  } elseif { [llength $poly] < 4 } {
    P_msg_error "$scr_name: Invalid fewer than 4 vertices in rectilinear polygon '$poly'!  Expect 4 or more vertices!"
    return
  } elseif { [llength $poly] % 2 != 0 } {
    P_msg_error "$scr_name: Invalid odd number of vertices in rectilinear polygon '$poly'!  Expect even number of vertices!"
    return
  }
  lassign [lindex $poly end] prev_x prev_y
  set prev_dir {}
  foreach vertex $poly {
    lassign $vertex x y
    if { ![string is double -strict $x] || ![string is double -strict $y] } {
      P_msg_error "$scr_nam: Detect invalid coordinate for vertex '$vertex' in polygon '$poly'!  Expect pair of numbers for coordinate!"
      return
    } elseif { $x == $prev_x && $y == $prev_y } {
      P_msg_error "$scr_num: Detect invalid zero-length edge between consecutive vertices '$prev_x $prev_y' and '$vertex' in polygon '$poly'!  Expect non-zero-length edge!"
      return
    } elseif { $x == $prev_x } {
      set dir horizontal
    } elseif { $y == $prev_y } {
      set dir vertical
    } else {
      P_msg_error "$scr_name: Detect invalid non-rectilinear edge between consecutive vertices '$prev_x $prev_y' and '$vertex' in polygon '$poly'!  Expect horizontal nor vertical edge!"
      return
    }
    if { $dir == $prev_dir } {
      P_msg_error "$scr_name: Detect invalid non-turning $dir edge between consecutive vertices '$prev_x $prev_y' and '$vertex' in polygon '$poly'!  Expect edge turns at veritves!"
      return
    }
    set prev_x $x
    set prev_y $y
    set prev_dir $dir
  }
  if { [lindex $poly 0 0] != [lindex $poly end 0] && [lindex $poly 0 1] != [lindex $poly end 1] } {
    P_msg_error "$scr_name: Detect non-rectilinear closing edge between end vertex '[lindex $poly end]' and begin vertex '[lindex $poly 0]' in polygon '$poly'!  Expect horizontal nor vertical edge!"
    return
  }
  set ll_vertex [lindex [lsort -index 0 -real -increasing [lsort -index 1 -real -increasing $poly]] 0]
  set ll_idx [lsearch -exact $poly $ll_vertex]
  set ll_poly "[lrange $poly $ll_idx end] [lrange $poly 0 [expr $ll_idx - 1]]"
  lassign $ll_vertex ll_x ll_y
  lassign [lindex $ll_poly 1] ll2_x ll2_y
  if { $ll2_x == $ll_x } {
    if { $ll2_y <= $ll_y } {
      P_msg_error "$scr_name: Unable to re-order coordinates to start from lower left-most vertex in polygon '$poly' with invalid new start vertex '$ll_vertex' & next vertex '$ll2_x $ll2_y'!"
      return
    } else {
    # ASSERT: Vertices in clockwise order.
      set sort_poly $ll_poly
    }
  } elseif { $ll2_y == $ll_y } {
    if { $ll2_x <= $ll_x } {
      P_msg_error "$scr_name:: Unable to re-order coordinates to start from lower left-most vertex in polygon '$poly' with invalid new start vertex '$ll_vertex' & next vertex '$ll2_x $ll2_y'!"
      return
    } else {
    # ASSERT: Vertices in counter-clockwise order.
      set sort_poly "[lrange $ll_poly 0 0] [lreverse [lrange $ll_poly 1 end]]"
    }
  }
  return $sort_poly
}

########################################

array unset va_bounds
set total_va_bnd_num 0
set total_va_bnd_cell_num 0
foreach_in_collection va [set vas [get_voltage_areas]] {
  set va_name [get_object_name $va]
  set va_shapes [get_voltage_area_shapes -of_objects $va]
  #set va_shape_count [get_attribute -objects $va -name shape_count]
  set va_shape_count [sizeof_collection $va_shapes]
  if { $va_shape_count > 1 } {
    set err_num 0
    foreach va_band {outer inner} {
      if { [info exists INTEL_LS_BOUND($va_name,$va_band)] } {
        P_msg_error "$scr_name: Detect invalid non-VA-shape-specific 'INTEL_LS_BOUND($va_name,$va_band)' var defined for voltage area '$va_name' with multiple ($va_shape_count) shapes '[get_object_name $va_shapes]'!  Expect VA-shape-specific 'INTEL_LS_BOUND($va_name,\$va_shape,$va_band)' var defined for each of $va_shape_count VA shapes instead!"
        incr err_num
      }
      if { [info exists INTEL_LS_BOUND_CELLS($va_name,$va_band)] } {
        P_msg_error "$scr_name: Detect invalid non-VA-shape-specific 'INTEL_LS_BOUND_CELLS($va_name,$va_band)' var defined for voltage area '$va_name' with multiple ($va_shape_count) shapes '[get_object_name $va_shapes]'!  Expect VA-shape-specific 'INTEL_LS_BOUND_CELLS($va_name,\$va_shape,$va_band)' var defined for each of $va_shape_count VA shapes instead!"
        incr err_num
      }
    }
    if { $err_num > 0 } {
      P_msg_error "$scr_name: Skip creating movebounds for $va_shape_count voltage area shapes '[get_object_name $va_shapes]' of voltage area '$va_name' due to $err_num errors above!"
      continue
    }
  }
  set va_bounds(outer) {}
  set va_bounds(inner) {}
  foreach_in_collection va_shp $va_shapes {
    set va_shp_name [get_object_name $va_shp]
    # Need create_poly_rect to expand rectangular va_shape to list of vertices because rectangular va_shape boundary attribute is in bbox instead of polygon.
    set va_shp_vertices_list [get_polygon_ordered_vertices [get_attribute -objects [create_poly_rect -boundary [get_attribute -objects $va_shp -name boundary]] -name point_list]]
    set err_num 0
    array unset bound_list
    array unset bound_cell_list
    array unset bound_gm
    foreach va_band {outer inner} {
      set bound_list($va_band) {}
      set bound_list_var {}
      set bound_cell_list($va_band) {}
      set bound_cell_list_var {}
      set bound_gm($va_band) [create_geo_mask]
      if { [info exists INTEL_LS_BOUND($va_name,$va_shp_name,$va_band)] } {
        set bound_list($va_band) $INTEL_LS_BOUND($va_name,$va_shp_name,$va_band)
        set bound_list_var INTEL_LS_BOUND($va_name,$va_shp_name,$va_band)
      } elseif { $va_shape_count > 1 } {
      } elseif { [info exists INTEL_LS_BOUND($va_name,$va_band)] } {
        set bound_list($va_band) $INTEL_LS_BOUND($va_name,$va_band)
        set bound_list_var INTEL_LS_BOUND($va_name,$va_band)
      }
      if { [info exists INTEL_LS_BOUND_CELLS($va_name,$va_shp_name,$va_band)] } {
        set bound_cell_list($va_band) $INTEL_LS_BOUND_CELLS($va_name,$va_shp_name,$va_band)
        set bound_cell_list_var INTEL_LS_BOUND_CELLS($va_name,$va_shp_name,$va_band)
      } elseif { $va_shape_count > 1 } {
      } elseif { [info exists INTEL_LS_BOUND_CELLS($va_name,$va_band)] } {
        set bound_cell_list($va_band) $INTEL_LS_BOUND_CELLS($va_name,$va_band)
        set bound_cell_list_var INTEL_LS_BOUND_CELLS($va_name,$va_band)
      }
      if { [llength $bound_list($va_band)] > 0 } {
        if { [llength [lsearch -all -exact -real $bound_list($va_band) 0]] == [llength $bound_list($va_band)] } {
          P_msg_warn "$scr_name: Ignore all-zero margins VA $va_band band '$bound_list($va_band)' defined by '$bound_list_var' var for [llength $va_shp_vertices_list]-sided VA shape '$va_shp_name' of voltage area '$va_name'!"
          set bound_list($va_band) {}
        }
        set side_idx 0
        foreach margin $bound_list($va_band) {
          if { ![string is double -strict $margin] || $margin < 0 } {
            P_msg_error "$scr_name: Detect invalid $side_idx-th margin '$margin' in VA $va_band band '$bound_list($va_band)' defined by '$bound_list_var' var for [llength $va_shp_vertices_list]-sided VA shape '$va_shp_name' of voltage area '$va_name'!  Expect non-negative number!"
            incr err_num
          }
          # TODO: Check if margins of vertical edges are multiple of site widths & margins of horizontal edges are multiple of row heights.
          incr side_idx
        }
        if { [llength $bound_list($va_band)] != [llength $va_shp_vertices_list] } {
          P_msg_error "$scr_name: Detect mismatched number ([llength $bound_list($va_band)] of margins in VA $va_band band '$bound_list($va_band)' defined by '$bound_list_var' var for [llength $va_shp_vertices_list]-sided VA shape '$va_shp_name' of voltage area '$va_name'!  Expect [llength $va_shp_vertices_list] margins specified!"
          incr err_num
        }
      } elseif { [llength $bound_cell_list($va_band)] > 0 } {
        P_msg_error "$scr_name: Detect empty VA $va_band band margins due to missing 'INTEL_LS_BOUND($va_name,$va_shp_name,$va_band)' var for non-empty VA $va_band band cells '$bound_cell_list($va_band)' defined by '$bound_cell_list_var' var for [llength $va_shp_vertices_list]-sided VA shape '$va_shp_name' of voltage area '$va_name'!  Expect [llength $va_shp_vertices_list] margins defined by 'INTEL_LS_BOUND($va_name,$va_shp_name,$va_band)' var!"
        incr err_num
      }
      set bound_cells($va_band) {}
      if { [llength $bound_cell_list($va_band)] > 0 } {
        set bound_cells($va_band) [get_cells -quiet $bound_cell_list($va_band)]
        if { [sizeof_collection $bound_cells($va_band)] == 0 } {
          P_msg_error "$scr_name: Unable to find any cell matching VA $va_band band cell names '$bound_cell_list($va_band)' defined by '$bound_cell_list_var' var for [llength $va_shp_vertices_list]-sided VA shape '$va_shp_name' of voltage area '$va_name'!  Expect 1 or more cells!"
          incr err_num
        } elseif { [sizeof_collection [set bad_cells [filter_collection $bound_cells($va_band) {is_level_shifter != true && is_isolation != true}]]] > 0 } {
          P_msg_error "$scr_name: Detect [sizeof_collection $bad_cells] non-level-shifter non-isolation cells '[get_object_name $bad_cells]' of references '[lsort -unique [get_attribute -objects $bad_cells -name ref_name]]' among [sizeof_collection $bound_cells($va_band)] cells matching VA $va_band band cell names '$bound_cell_list($va_band)' defined by '$bound_cell_list_var' var for [llength $va_shp_vertices_list]-sided VA shape '$va_shp_name' of voltage area '$va_name'!  Expect only level-shifter or isolation cells!"
          incr err_num
        }
      } elseif { [llength $bound_list($va_band)] > 0 } {
        P_msg_error "$scr_name: Detect empty VA $va_band band cells due to missing 'INTEL_LS_BOUND_CELLS($va_name,$va_shp_name,$va_band)' var for non-empty VA $va_band band margins '$bound_list($va_band)' defined by '$bound_list_var' var for [llength $va_shp_vertices_list]-sided VA shape '$va_shp_name' of voltage area '$va_name'!  Expect 1 or more cell patterns defined by 'INTEL_LS_BOUND_CELLS($va_name,$va_shp_name,$va_band)' var!"
        incr err_num
      }
    }
    if { $err_num > 0 } {
      P_msg_error "$scr_name: Skip creating movebounds for [llength $va_shp_vertices_list]-sided VA shape '$va_shp_name' of voltage area '$va_name' due to $err_num errors above!"
      continue
    } elseif { [llength $bound_list(outer)] == 0 && [llength $bound_list(inner)] == 0 } {
      P_msg_info "$scr_name: Skip creating empty movebound for [llength $va_shp_vertices_list]-sided VA shape '$va_shp_name' of voltage area '$va_name' given both empty VA outer & inner band margins."
      continue
    } elseif { [llength $bound_list(outer)] == 0 } {
      set bound_list(outer) [lrepeat [llength $va_shp_vertices_list] 0]
    } elseif { [llength $bound_list(inner)] == 0 } {
      set bound_list(inner) [lrepeat [llength $va_shp_vertices_list] 0]
    }

    lassign [lindex $va_shp_vertices_list end] prev_x prev_y
    lassign [lindex $va_shp_vertices_list 0] begin_x begin_y
    set prev_outer_margin [lindex $bound_list(outer) end]
    set prev_inner_margin [lindex $bound_list(inner) end]
    foreach vertex "[lrange $va_shp_vertices_list 1 end] [lrange $va_shp_vertices_list 0 0]" outer_margin $bound_list(outer) inner_margin $bound_list(inner) {
      lassign $vertex end_x end_y
      set outer_pr {}
      set inner_pr {}
      if { $end_x == $begin_x } {
      # Vertical edge
      if { $end_y < $begin_y } {
      # Down direction => left = inner & right = outer
      if { $begin_x < $prev_x } {
      # Left direction => concave vertex
      if { $outer_margin > 0 } {
      set outer_pr [create_poly_rect -boundary "{$end_x $end_y} {[expr $begin_x + $outer_margin] $begin_y}"]
      }
        if { $inner_margin > 0 } {
          set inner_pr [create_poly_rect -boundary "{[expr $end_x - $inner_margin] $end_y} {$begin_x [expr $begin_y + $prev_inner_margin]}"]
        }
      } elseif { $begin_x > $prev_x } {
      # Right direction => convex vertex
      if { $outer_margin > 0 } {
      set outer_pr [create_poly_rect -boundary "{$end_x $end_y} {[expr $begin_x + $outer_margin] [expr $begin_y + $prev_outer_margin]}"]
      }
        if { $inner_margin > 0 } {
          set inner_pr [create_poly_rect -boundary "{[expr $end_x - $inner_margin] $end_y} {$begin_x $begin_y}"]
        }
      }
    } elseif { $end_y > $begin_y } {
    # Up direction => left = outer & right = inner
    if { $begin_x < $prev_x } {
    # Left direction => convex vertex
    if { $outer_margin > 0 } {
    set outer_pr [create_poly_rect -boundary "{[expr $begin_x - $outer_margin] [expr $begin_y - $prev_outer_margin]} {$end_x $end_y}"]
    }
        if { $inner_margin > 0 } {
          set inner_pr [create_poly_rect -boundary "{$begin_x $begin_y} {[expr $end_x + $inner_margin] $end_y}"]
        }
      } elseif { $begin_x > $prev_x } {
      # Right direction => concave vertex
      if { $outer_margin > 0 } {
      set outer_pr [create_poly_rect -boundary "{[expr $begin_x - $outer_margin] $begin_y} {$end_x $end_y}"]
      }
        if { $inner_margin > 0 } {
          set inner_pr [create_poly_rect -boundary "{$begin_x [expr $begin_y - $prev_inner_margin]} {[expr $end_x + $inner_margin] $end_y}"]
        }
      }
      }
    } elseif { $end_y == $begin_y } {
    # Horizontal edge
    if { $end_x < $begin_x } {
    # Left direction => top = inner & bottom = outer
    if { $begin_y < $prev_y } {
    # Down direction => convex vertex
    if { $outer_margin > 0 } {
    set outer_pr [create_poly_rect -boundary "{$end_x [expr $end_y - $outer_margin]} {[expr $begin_x + $prev_outer_margin] $begin_y}"]
    }
      if { $inner_margin > 0 } {
        set inner_pr [create_poly_rect -boundary "{$end_x $end_y} {$begin_x [expr $begin_y + $inner_margin]}"]
      }
    } elseif { $begin_y > $prev_y } {
    # Up direction => concave vertex
    if { $outer_margin > 0 } {
    set outer_pr [create_poly_rect -boundary "{$end_x [expr $end_y - $outer_margin]} {$begin_x $begin_y}"]
    }
      if { $inner_margin > 0 } {
        set inner_pr [create_poly_rect -boundary "{$end_x $end_y} {[expr $begin_x + $prev_inner_margin] [expr $begin_y + $inner_margin]}"]
      }
    }
  } elseif { $end_x > $begin_x } {
  # Right direction => top = outer & bottom = inner
  if { $begin_y < $prev_y } {
  # Down direction => concave vertex
  if { $outer_margin > 0 } {
  set outer_pr [create_poly_rect -boundary "{$begin_x $begin_y} {$end_x [expr $end_y + $outer_margin]}"]
  }
      if { $inner_margin > 0 } {
        set inner_pr [create_poly_rect -boundary "{[expr $begin_x - $prev_inner_margin] [expr $begin_y - $inner_margin]} {$end_x $end_y}"]
      }
    } elseif { $begin_y > $prev_y } {
    # Up direction => convex vertex
    if { $outer_margin > 0 } {
    set outer_pr [create_poly_rect -boundary "{[expr $begin_x - $prev_outer_margin] $begin_y} {$end_x [expr $end_y + $outer_margin]}"]
    }
      if { $inner_margin > 0 } {
        set inner_pr [create_poly_rect -boundary "{$begin_x [expr $begin_y - $inner_margin]} {$end_x $end_y}"]
      }
    }
    }
  }
  if { [sizeof_collection $outer_pr] > 0 } {
    set bound_gm(outer) [compute_polygons -operation or -objects1 $bound_gm(outer) -objects2 $outer_pr]
  }
  if { [sizeof_collection $inner_pr] > 0 } {
    set bound_gm(inner) [compute_polygons -operation or -objects1 $bound_gm(inner) -objects2 $inner_pr]
  }
  set prev_x $begin_x
  set prev_y $begin_y
  set begin_x $end_x
  set begin_y $end_y
  set prev_outer_margin $outer_margin
  set prev_inner_margin $inner_margin
}

foreach va_band {outer inner} {
  if { [get_attribute -objects $bound_gm($va_band) -name shape_count] > 0 } {
    append_to_collection va_bounds($va_band) [set va_bnd [create_bound -name ${bnd_prefix}_${va_band}_${va_name}_${va_shp_name} -type hard -boundary $bound_gm($va_band) $bound_cells($va_band)]]
    if { [compare_collection [get_cells -quiet -of_objects $va_bnd] $bound_cells($va_band)] != 0 } {
      P_msg_error "$scr_name: Detect mismatched cells between [sizeof_collection [get_cells -quiet -of_objects $va_bnd]] cells bound by hard movebound '[get_object_name $va_bnd]' and [sizeof_collection $bound_cells($va_band)] cells defined by 'INTEL_LS_BOUND_CELLS($va_name,$va_shp_name,$va_band)' var for [llength $va_shp_vertices_list]-sided VA shape '$va_shp_name' of voltage area '$va_name'!  Please report this issue to ICF."
    }
  }
}
   }
   foreach va_band {outer inner} {
     if { [sizeof_collection $va_bounds($va_band)] > 0 } {
       P_msg_info "$scr_name: Created [sizeof_collection $va_bounds($va_band)] hard movebounds '[get_object_name $va_bounds($va_band)]' for [sizeof_collection [get_cells -quiet -of_objects $va_bounds($va_band)]] level-shifter and/or isolation cells at VA $va_band bands for $va_shape_count voltage area shapes '[get_object_name $va_shapes]' of voltage area '$va_name'."
       incr total_va_bnd_num [sizeof_collection $va_bounds($va_band)]
       incr total_va_bnd_cell_num [sizeof_collection [get_cells -quiet -of_objects $va_bounds($va_band)]]
     } else {
       P_msg_info "$scr_name: Created 0 hard movebound for 0 level-shifter or isolation cell at VA $va_band bands for $va_shape_count voltage area shapes '[get_object_name $va_shapes]' of voltage area '$va_name'."
     }
   }
}
P_msg_info "$scr_name: Total $total_va_bnd_num hard movebounds created for $total_va_bnd_cell_num level-shifter and/or isolation cells at VA outer & innner bands for [sizeof_collection [get_voltage_area_shapes -of_objects $vas]] voltage area shapes of [sizeof_collection $vas] voltage areas."

unset scr_name

