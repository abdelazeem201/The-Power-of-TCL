##############################################################
# NAME :          pre_place_fiducial.tcl
#
# SUMMARY :       add local fiducial cells to design
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists pre_place_fiducial.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_DEBUG_CELLS
#
# PROCS USED :    P_msg_info P_msg_warn P_placement_blockage_move_or_unmove
#                         
# DESCRIPTION :   pre_place_fiducial.tcl is to add local fiducial cells to the design
#
# EXAMPLES :      
#
###############################################################

## Places 2x local fiducials in staggered fashion

##############################################################################
## Set default fiducial cells if not defined and check for cell existense
##############################################################################

set fidxcell [dict get $INTEL_DEBUG_CELLS pre_place local_fid ref_cell_list]
set default_xstep [dict get $INTEL_DEBUG_CELLS pre_place local_fid x_step]
set default_ystep [dict get $INTEL_DEBUG_CELLS pre_place local_fid y_step]
set x_offset [dict get $INTEL_DEBUG_CELLS pre_place local_fid x_start]
set y_offset [dict get $INTEL_DEBUG_CELLS pre_place local_fid y_start]
set prefix [dict get $INTEL_DEBUG_CELLS pre_place local_fid prefix]

redirect -variable warn { set fidcell [get_lib_cells */$fidxcell] }
if {[string match *othing* $warn]} {
  P_msg_error "$fidxcell physical_lib_cell not found"; return;
}

###################################################
## To check is fids already exists in the design
###################################################

set orig_fidcnt [sizeof_collection [get_cells -quiet -hierarchical ${prefix}*]]

#####################################################
## Get Fid cell dimensions for calculations
#####################################################

scan [get_attribute [index_collection [get_lib_cells -quiet */$fidxcell] 0] boundary_bbox] "{%f %f} {%f %f}" llx lly urx ury;

set fid1width [expr $urx - $llx]
set fid1height [expr $ury - $lly]

#####################################################
## Move existing placement blockage out of bounds
#####################################################

set blockage_bbox_pairs [P_placement_blockage_move_or_unmove move]

create_cluster_cells -lib_cells {{$fidcell 1}} -x_step $default_xstep -y_step $default_ystep -x_offset $x_offset -y_offset $y_offset \
                     -delta_x $fid1width -delta_y $fid1height -stagger -prefix $prefix

###################################################
## Restore orignal placement blockages in design
###################################################

P_placement_blockage_move_or_unmove $blockage_bbox_pairs

######################################################
## Print statistics on number of fid cells inserted
######################################################

set fidcnt [expr [sizeof_collection [get_cells -quiet -hierarchical ${prefix}*]] - $orig_fidcnt]
if {$fidcnt>0} { 
  set_placement_status legalize_only [get_cells -quiet -hierarchical ${prefix}*] 
  #set_placement_status fixed [get_cells -quiet -hierarchical ${prefix}*]
};

if {$orig_fidcnt>0} {
  P_msg_warn " Design already has $orig_fidcnt ${prefix}";
}

if {$fidcnt>0} { P_msg_info "Added $fidcnt $fidxcell cells" };
if {$fidcnt<1} { P_msg_warn "No cells were added" };


