##############################################################
# NAME :          create_site_rows.tcl
#
# SUMMARY :       create other site rows in design
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists create_site_rows.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_STDCELL_BONUS_GATEARRAY_TILE INTEL_STDCELL_CORE2H_TILE
#
# PROCS USED :    None
#                         
# DESCRIPTION :   create_site_rows.tcl is to create other site rows in design.
#
# EXAMPLES :      
#
###############################################################

###########################################
# Add extra placement sites for all tiles
###########################################
if { [info exists INTEL_STDCELL_BONUS_GATEARRAY_TILE] } {
  create_site_array -name $INTEL_STDCELL_BONUS_GATEARRAY_TILE -site $INTEL_STDCELL_BONUS_GATEARRAY_TILE -transparent true -flip_first_row false -boundary [get_attribute -objects [current_block] -name boundary]
} else {
 P_msg_error "Missing 'INTEL_STDCELL_BONUS_GATEARRAY_TILE' var for stdcell tile 'bonuscore' site def!"
}
if { [info exists INTEL_STDCELL_CORE2H_TILE] } {
  set _bnd [create_geo_mask -objects [get_attribute [current_design] boundary]]
  set _w 0
  set _ht -0.63
  ##set _ht 0.63
  #set _bnd_resized [resize_polygons -objects  $_bnd -size "$_w $_ht"]
  set _bnd_resized [resize_polygons -objects  $_bnd -size "$_w $_ht"]
 ## create_site_array -name $INTEL_STDCELL_TILE -site $INTEL_STDCELL_TILE -transparent true -flip_first_row false -flip_alternate_row false -boundary [get_attribute [get_attr $_bnd_resized poly_rects] point_list]

create_site_array -name $INTEL_STDCELL_CORE2H_TILE -site $INTEL_STDCELL_CORE2H_TILE -transparent true -flip_first_row false -flip_alternate_row true -boundary [get_attribute [get_attr $_bnd_resized poly_rects] point_list]
} 

##else {
##  P_msg_error "Missing 'INTEL_STDCELL_TILE' var for stdcell tile 'core' site def!"
##}

