############################################################
# NAME :          create_boundary_blockage.tcl
#
# SUMMARY :       create boundary blockage 
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists create_boundary_blockage.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_MAX_PG_LAYER
#
# PROCS USED :    None 
#                         
# DESCRIPTION :   create_boundary_blockage.tcl is to create boundary blockage to avoid signal routes to be too close to the boundary
#
# EXAMPLES :      
#
##############################################################
set _w 0.080
set _ht 0.080
set _bnd [create_geo_mask -objects [get_attribute [current_block] boundary]]
set _bnd_resized [resize_polygons -objects $_bnd -size "-$_w -$_ht"]
set _slivers [split_polygons -objects [compute_polygons -objects1 $_bnd -operation NOT -objects2 $_bnd_resized]]
foreach_in_col each [get_attr $_slivers poly_rects] {
  create_routing_blockage -boundary [get_attr $each point_list] -layers [get_layers -filter "name=~m*"] -name_prefix rtblkg_bdr_ -zero_spacing
}

