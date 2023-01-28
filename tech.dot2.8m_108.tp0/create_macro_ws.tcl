###############################################################
# NAME :          create_macro_ws.tcl
#
# SUMMARY :       create white space around macro boundaries
#
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists create_macro_ws.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     None
#
# PROCS USED :    INTEL_WS_X INTEL_WS_Y
#                         
# DESCRIPTION :   create_macro_ws.tcl is to create white space around macro boundaries
#
# EXAMPLES :      
#
###############################################################
#Create WS around macro boundaries
#
set _w $INTEL_WS_X
set _ht $INTEL_WS_Y
set all_macro_cells [get_cells -quiet -physical_context -filter "is_hard_macro==true || is_soft_macro==true"]
set cnt 0
foreach_in_collection macro_cell $all_macro_cells {
  set _bnd [create_geo_mask -objects [get_attribute $macro_cell boundary]]
  set _bnd_resized [resize_polygons -objects  $_bnd -size "$_w $_ht"]
  #set _slivers [split_polygons -objects [compute_polygons -objects1 $_bnd -operation NOT -objects2 $_bnd_resized]]
  foreach_in_col each [get_attr $_bnd_resized poly_rects]  {
    incr cnt
    create_placement_blockage -boundary [get_attr $each point_list] -type hard -name macro_ws_$cnt
  }
}

