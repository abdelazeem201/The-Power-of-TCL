#############################################################
# NAME :          create_boundary_ws.tcl
#
# SUMMARY :       create boundary white space
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists create_boundary_ws.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_WS_X INTEL_WS_Y
#
# PROCS USED :    None 
#                         
# DESCRIPTION :   connect_boundary_ws.tcl is to create boundary white space
#
# EXAMPLES :      
#
###############################################################
set _w $INTEL_WS_X
set _ht $INTEL_WS_Y
set _bnd [create_geo_mask -objects [get_attribute [current_block] boundary]]
set _bnd_resized [resize_polygons -objects $_bnd -size "-$_w -$_ht"]
set _slivers [split_polygons -objects [compute_polygons -objects1 $_bnd -operation NOT -objects2 $_bnd_resized]]
set cnt 0
foreach_in_col each [get_attr $_slivers poly_rects] {
  incr cnt
  create_placement_blockage -boundary [get_attr $each point_list] -type hard -name boundary_ws_$cnt
}

