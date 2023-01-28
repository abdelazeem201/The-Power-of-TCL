##############################################################
# NAME :          opportunistic_local_fiducial_place.tcl
#
# SUMMARY :       define ICC2 lib cell purpose based on the defined list
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists opportunistic_local_fiducial_place.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_LOCAL_FIDUCIAL_POSTROUTE_CELLS INTEL_LOCAL_FIDUCIAL_PREPLACE_CELL INTEL_LOCAL_FIDUCIAL_POSTROUTE_SPACING
#
# PROCS USED :    P_placement_blockage_move_or_unmove P_msg_info
#                         
# DESCRIPTION :   opportunistic_local_fiducial_place.tcl is to opportunistically add 1x2 and 2x1 local fiducial cells post route
#
# EXAMPLES :      
#
###############################################################

##############################################################################
# Opportunistically 1x2 and 2x1 local fiducial cells post route
# List of procs used by this script
# 1. P_msg_info
# 2. P_placement_blockage_move_or_unmove

if {[info exists INTEL_LOCAL_FIDUCIAL_POSTROUTE_CELLS] || $INTEL_LOCAL_FIDUCIAL_POSTROUTE_CELLS eq ""} {
  return
}

# Temporarily move Placement blockages before insertion
set blockage_bbox_pairs ""
if {[sizeof_collection [get_placement_blockages -quiet]] > 0 } {
  P_msg_info "Temporarily removing placement blockages before post-route fiducial cell insertion."
  set blockage_bbox_pairs [P_placement_blockage_move_or_unmove move];  ## move placement blockage out of bounds ##
}

set ref2_list ""
foreach cel $INTEL_LOCAL_FIDUCIAL_POSTROUTE_CELLS {
  if { [get_lib_cells -quiet */$cel/frame] ne "" } {
    lappend ref2_list [file dir [get_object_name [get_lib_cells -quiet */$cel/frame]]]
  } else {
    puts "Error: Missing Local Fiducial cells $cel in the ref libs"
  }
}

set ref1_list ""
foreach cel $INTEL_LOCAL_FIDUCIAL_PREPLACE_CELL {
  if { [get_lib_cells -quiet */$cel/frame] ne "" } {
    lappend ref1_list [file dir [get_object_name [get_lib_cells -quiet */$cel/frame]]]
  } else {
    puts "Error: Missing preplaced Local Fiducial cells $cel in the ref libs"
  }
}

if {[info exists INTEL_LOCAL_FIDUCIAL_POSTROUTE_SPACING] && ($INTEL_LOCAL_FIDUCIAL_POSTROUTE_SPACING ne "")} {
  set wsize $INTEL_LOCAL_FIDUCIAL_POSTROUTE_SPACING
} else {
  set wsize 8
}

foreach cel $ref2_list {
  set cmd "create_opportunistic_physical_cells -prefix post_routed_fiducial_"
  if { $ref1_list ne "" } {
    append cmd " -ref_list_1 {$ref1_list} -list_2_to_list_1_distance $wsize"  
  }
  append cmd " -new_cell_of_list_2 $cel -ref_list_2 {$ref2_list} -list_2_to_list_2_distance $wsize"
  P_msg_info "Run opportunistic insert lfid cells:  $cmd"
  eval $cmd
}

### Restore hard placement blockage that were moved
P_placement_blockage_move_or_unmove $blockage_bbox_pairs;            ## restore original placement blockage   ##


