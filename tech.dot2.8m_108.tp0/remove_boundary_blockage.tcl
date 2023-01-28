##############################################################
# NAME :          remove_boundary_blockage.tcl
#
# SUMMARY :       remove boundary blockages
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists remove_boundary_blockage.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     None
#
# PROCS USED :    None
#                         
# DESCRIPTION :   remove_boundary_blockage.tcl is to remove boundary blockages in design
#
# EXAMPLES :      
#
###############################################################
#
#Remove boundary routing blockages
#
if {[sizeof_collection [get_routing_blockages -quiet rtblkg_bdr_*]] != 0} {
  remove_routing_blockages rtblkg_bdr_*
}
if {[sizeof_collection [get_routing_blockages -quiet macro_rb*]] != 0} {
  remove_routing_blockages macro_rb*
}

