############################################################
# NAME :          add_filler_cells.tcl
#
# SUMMARY :       fill base layer
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists add_filler_cells.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_BONUS_GATEARRAY_CELLS INTEL_STDCELL_FILLER_CELLS
#
# PROCS USED :    None
#                         
# DESCRIPTION :   add bonus gate array cells and filler cells to the design
#
# EXAMPLES :      
#
#############################################################
set filler_list {}
if {[info exists INTEL_DECAP_CELLS] && $INTEL_DECAP_CELLS ne ""} {
  foreach filler $INTEL_DECAP_CELLS {
      lappend filler_list [file dir [get_object_name [index_collection [get_lib_cells -quiet */$filler/frame] 0]]]
  }
  create_stdcell_fillers -lib_cells $filler_list -continue_on_error
  connect_pg_net -automatic
  remove_stdcell_fillers_with_violation
}

set filler_list {}
if {[info exists INTEL_BONUS_GATEARRAY_CELLS] && $INTEL_BONUS_GATEARRAY_CELLS ne ""} {
  foreach filler $INTEL_BONUS_GATEARRAY_CELLS {
    if {[sizeof_collection [get_lib_cells  -quiet */$filler]] > 0} {
      lappend filler_list [file dir [get_object_name [index_collection [get_lib_cells -quiet */$filler/frame] 0]]]
  
    }
  }
  if {[llength $filler_list] > 0} {
    create_stdcell_fillers -lib_cells $filler_list
  }
}

##############################################################################
# Insert spc*03 & spc*02 & spc*01 filler cells
##############################################################################
# Insert spc*03 & spc*02 placement site spacer fill cells. 

set filler_list {}
foreach filler $INTEL_STDCELL_FILLER_CELLS {
  lappend filler_list [file dir [get_object_name [index_collection [get_lib_cells -quiet */$filler/frame] 0]]]

}
create_stdcell_fillers -lib_cells $filler_list










