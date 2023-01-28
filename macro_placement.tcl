##############################################################################
# This script will auto-place macros in the design
# Can be used during early exploration stage
# List of procs used by the script
# 1. P_msg_info

# Check: Are there any macro cells?
set all_macro_cells [get_cells -quiet -physical_context -filter {is_hard_macro == true || is_soft_macro == true}]
if { [sizeof_collection $all_macro_cells] == 0 } {
  P_msg_info "There are no macro cells in this design"
  return
}

# Fix the locations of already placed macro cells.
set placed_macro_cells [filter_collection $all_macro_cells {is_placed == true}]
if { [sizeof_collection $placed_macro_cells] > 0 } {
  P_msg_info "There are [sizeof_collection $placed_macro_cells] macros already placed, they are marked fixed"
  set_placement_status fixed $placed_macro_cells
}

# Check: Are there any macro cells not placed?
set unplaced_macro_cells [remove_from_collection $all_macro_cells $placed_macro_cells]
if { [sizeof_collection $unplaced_macro_cells] == 0 } {
  P_msg_info "All [sizeof_collection $placed_macro_cells] macro cells are already placed"
  return
}

set unplaced_soft_macro_cells [filter_collection $unplaced_macro_cells {is_soft_macro == true}]
set switch_view 0
if { [sizeof_collection $unplaced_soft_macro_cells] > 0 } {
  #P_msg_error "Detect [sizeof_collection $unplaced_soft_macro_cells] unplaced soft macro cells!  They can't be auto placed and must be manually placed!"
  #return
  P_msg_warn "Detect [sizeof_collection $unplaced_soft_macro_cells] unplaced soft macro cells!"
  # Need to temporarily switch soft macros from abstract/design view to frame view to allow auto placement of unplaced soft macros and to avoid create_placement from opening soft macros and running placements in them.  Incidentally, that will also cause any existing collection to become invalid.
  array unset orig_view_2_cells
  foreach view {abstract design} {
    foreach_in_collection cell [set orig_view_2_cells($view) [filter_collection $unplaced_soft_macro_cells "ref_view_name == $view"]] {
      if { [sizeof_collection [get_blocks -quiet -all [set blk_frame_name [regsub $view [get_attribute -objects $cell -name ref_full_name] frame]]]] == 0 } {
        P_msg_error "Missing frame view '$blk_frame_name' for block '[get_attribute -objects $cell -name ref_name]' in lib '[get_attribute -objects $cell -name ref_lib_name]' to switch from '[get_attribute -objects $cell -name ref_view_name]' view of soft macro cell '[get_object_name $cell]'!"
      } else {
        P_msg_info "Temporarily switch from '[get_attribute -objects $cell -name ref_view_name]' view of soft macro cell '[get_object_name $cell]' of reference '[get_attribute -objects $cell -name ref_name]' to 'frame' view."
      }
    }
  }  
  write_sdc -output tmp_constraints_before_change_to_frame.sdc
  change_view -view frame $unplaced_soft_macro_cells
  set switch_view 1
  set unplaced_soft_macro_cells [filter_collection $unplaced_macro_cells {is_soft_macro == true}]
}

set unplaced_hard_macro_cells [remove_from_collection $unplaced_macro_cells $unplaced_soft_macro_cells]

P_msg_info "Placing [sizeof_collection $unplaced_hard_macro_cells] unplaced hard macro cells ..."

# Restrict macro placement orientation.  We do not allow 90 degree rotation
# Restrict macro placement to modular grid.  So that macro/APR boundaries are DRC clean.
P_msg_info "Restricting macros placement to be on modular grid ( $INTEL_MD_GRID_X , $INTEL_MD_GRID_Y ) & on orientation to N S FN FS"
if { [sizeof_collection [get_grids -quiet macro_grid]] > 0 } {
  set_grid -reset macro_grid
  set_grid -x_offset $INTEL_MD_GRID_X -y_offset [expr $INTEL_MD_GRID_Y*2] -x_step $INTEL_MD_GRID_X -y_step $INTEL_MD_GRID_Y macro_grid
} else {
  create_grid -x_offset $INTEL_MD_GRID_X -y_offset [expr $INTEL_MD_GRID_Y*2] -x_step $INTEL_MD_GRID_X -y_step $INTEL_MD_GRID_Y macro_grid -type user
}

# create keepout margin to avoid macro boundary to be too close to the block boundary
create_keepout_margin -type hard_macro -inner "[expr $INTEL_MD_GRID_X*14+$INTEL_WS_X] [expr $INTEL_MD_GRID_Y*4] [expr $INTEL_MD_GRID_X*14+$INTEL_WS_X] [expr $INTEL_MD_GRID_Y*4]" [get_block]
set_snap_setting -class macro_cell -snap user
set_macro_constraints $unplaced_hard_macro_cells -allowed_orientations {R0 R180 MX MY} -alignment_grid macro_grid

# Run "create_fp_placement" to place macros
P_msg_info "Auto placing [sizeof_collection $unplaced_hard_macro_cells] hard macro cells"
P_msg_info "Running: create_placement -effort low -floorplan"
create_placement -effort low -floorplan
if { $switch_view eq 1 } {
  foreach view {abstract design} {
    if { [sizeof_collection $orig_view_2_cells($view)] > 0 } {
      foreach_in_collection cell $orig_view_2_cells($view) {
        P_msg_info "Revert from 'frame' view back to '$view' view for soft macro cell '[get_object_name $cell]' of reference '[get_attribute -objects $cell -name ref_name]'."
      }
      change_view -view $view $orig_view_2_cells($view)
    }
  }
  if { [file exists tmp_constraints_before_change_to_frame.sdc ]} {
    read_sdc tmp_constraints_before_change_to_frame.sdc
  }
}

P_msg_info "Setting [sizeof_collection $unplaced_hard_macro_cells] hard macro cells placement to fixed"
set_placement_status fixed $unplaced_hard_macro_cells

P_msg_info "Making sure all standard cells are still unplaced"
reset_placement

#
# Once macro placements are determined, create a design specific file ./scripts/macro_placement.tcl
# to override this auto macro placement in the default flow.
# You can write out macro placement with
# write_floorplan -include {macros} -output scripts/macro_placement.tcl

#
# A typical format for this file would look like this
#
#set cell [get_cells $macro_name]
#rotate_objects -orient R0 -force $cell
#set_attribute -quiet $cell origin {71.28 120.960}
#set_placement_status fixed $cell
#



