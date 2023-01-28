############################################################
# NAME :          add_va_iso_cells.tcl
#
# SUMMARY :       add VA isolation cells to the design
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists add_va_iso_cells.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_VA_ISO_CELL
#
# PROCS USED :    None
#                         
# DESCRIPTION :   add_va_iso_cells.tcl is to place boundary cells on the outside and inside of vertical edges of voltage areas.
#
# EXAMPLES :      
#
#############################################################
suppress_message CHF-115

# Place boundary cells around core boundary and macros

set macro_cells ""
set macro_cells [get_cells -quiet -physical_context -filter "is_hard_macro==true || is_soft_macro==true"]  

if { [sizeof_collection $macro_cells] == 0 } {

  set halo_target_objects [get_core_area]

} else {

  set halo_target_objects [list [get_core_area] $macro_cells]
}

# add halo cells around voltage areas
set va [remove_from_collection [get_voltage_areas] [get_voltage_areas DEFAULT_VA]]  

if {[sizeof_collection $va] > 0} {

  set die [get_attribute [get_core_area] boundary]
  set core [get_attribute [compute_polygons -oper not -objects1 $die -objects2 $va] poly_rects.point_list]

  # define vertical polygon along outside of vertical edges of voltage areas
  set bar_poly [get_attribute [compute_polygons -oper xor -objects1 [resize_polygon -size {-0.270 0} $core] -objects2 $core] poly_rects]

  # shrink top of vertical bar to only allow placement of top halo cell
  set uy [get_attribute [resize_polygon -size {0 0 0 -0.816} $bar_poly] poly_rects]

  set cnt 1

  # create temporary placement blockage to only allow placement of top halo cell
  foreach_in_collection what $uy {

    set box [get_attribute $what bbox]
    create_placement_blockage -type hard -bbox $box -name halo_tmpblkg_${cnt}
    incr cnt
  }

  set die_bound [get_attr [get_core_area] boundary]
  set die_bound_lr [resize_polygon -objects  $die_bound -size {0.5 0 0.5 0}]
  set new_polygon [compute_polygon -objects1 $die_bound_lr -operation NOT -objects2 $die_bound]
  set new_polygon [resize_polygon -objects $new_polygon -size {0.5 0 0.5 0}]
  set uy  [get_attribute $new_polygon poly_rects]
  set cnt 1
  foreach_in_collection what $uy {
    set box [get_attribute $what bbox]
    create_placement_blockage -type hard -bbox $box -name halo_boundary_tmpblkg_${cnt}
    incr cnt
  }

  # place outside top va halo cell
  create_boundary_cells \
    -prefix halo_va_outside_top \
    -separator "_" \
    -target_objects [get_voltage_areas DEFAULT_VA] \
    -left_boundary_cell $INTEL_VA_ISO_CELL \
    -right_boundary_cell $INTEL_VA_ISO_CELL \
    -left_boundary_cell_force_orient R0 \
    -right_boundary_cell_force_orient MY 
    # remove temporary halo placement blockages
  remove_placement_blockage [get_placement_blockage *halo_tmpblkg*]

  # shrink bottom of vertical bar to only allow placement of outside bottom halo cell
  set ly [get_attribute [resize_polygon -size {0 -0.816 0 0} $bar_poly] poly_rects]

  set cnt 1

  # create temporary placement blockage to only allow placement of bottom halo cell
  foreach_in_collection what $ly {

    set box [get_attribute $what bbox]
    create_placement_blockage -type hard -bbox $box -name halo_tmpblkg_${cnt}
    incr cnt
  }

  # place outside bottom va halo cell
  create_boundary_cells \
    -prefix halo_va_outside_bottom \
    -separator "_" \
    -target_objects [get_voltage_areas DEFAULT_VA] \
    -left_boundary_cell $INTEL_VA_ISO_CELL \
    -right_boundary_cell $INTEL_VA_ISO_CELL \
    -left_boundary_cell_force_orient R0 \
    -right_boundary_cell_force_orient MY 
    # remove temporary halo placement blockages
  remove_placement_blockage [get_placement_blockage *halo_tmpblkg*]

  create_boundary_cells \
    -prefix halo_va_outside \
    -separator "_" \
    -target_objects [get_voltage_areas DEFAULT_VA] \
    -left_boundary_cell $INTEL_VA_ISO_CELL \
    -right_boundary_cell $INTEL_VA_ISO_CELL \
    -left_boundary_cell_force_orient R0 \
    -right_boundary_cell_force_orient MY 

    # define vertical polygon along inside of vertical edges of voltage areas
    set bar_poly [get_attribute [compute_polygons -oper xor -objects1 [resize_polygon -size {0.270 0} $core] -objects2 $core] poly_rects]

    # shrink top of vertical bar to only allow placement of top halo cell
    set uy [get_attribute [resize_polygon -size {0 0 0 -0.816} $bar_poly] poly_rects]

  set cnt 1

  # create temporary placement blockage to only allow placement of top halo cell
  foreach_in_collection what $uy {

    set box [get_attribute $what bbox]
    create_placement_blockage -type hard -bbox $box -name halo_tmpblkg_${cnt}
    incr cnt
  }

  # place inside top va halo cell
  create_boundary_cells \
    -prefix halo_va_inside_top \
    -separator "_" \
    -target_objects $va \
    -left_boundary_cell $INTEL_VA_ISO_CELL \
    -right_boundary_cell $INTEL_VA_ISO_CELL \
    -left_boundary_cell_force_orient R0 \
    -right_boundary_cell_force_orient MY 

    # remove temporary halo placement blockages
  remove_placement_blockage [get_placement_blockage *halo_tmpblkg*]

  # shrink bottom of vertical bar to only allow placement of bottom halo cell
  set ly [get_attribute [resize_polygon -size {0 -0.816 0 0} $bar_poly] poly_rects]

  set cnt 1

  # create temporary placement blockage to only allow placement of bottom halo cell
  foreach_in_collection what $ly {

    set box [get_attribute $what bbox]
    create_placement_blockage -type hard -bbox $box -name halo_tmpblkg_${cnt}
    incr cnt
  }

   # place inside bottom va halo cell
   create_boundary_cells \
     -prefix halo_va_inside_bottom \
     -separator "_" \
     -target_objects $va \
     -left_boundary_cell $INTEL_VA_ISO_CELL \
     -right_boundary_cell $INTEL_VA_ISO_CELL \
     -left_boundary_cell_force_orient R0 \
     -right_boundary_cell_force_orient MY 

     # remove temporary halo placement blockages
   remove_placement_blockage [get_placement_blockage *halo_tmpblkg*]

   # place remaining inside va halo cells along inside vertical edges of vas
   create_boundary_cells \
     -prefix halo_va_inside \
     -separator "_" \
     -target_objects $va \
     -left_boundary_cell $INTEL_VA_ISO_CELL \
     -right_boundary_cell $INTEL_VA_ISO_CELL \
     -left_boundary_cell_force_orient R0 \
     -right_boundary_cell_force_orient MY 

}
remove_placement_blockage [get_placement_blockage *halo_boundary_tmpblkg*]

unsuppress_message CHF-115


