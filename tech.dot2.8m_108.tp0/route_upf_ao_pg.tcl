#############################################################
# NAME :          route_upf_ao_pg.tcl
#
# SUMMARY :       route secondary PG pins for isolation, level shifters and always on cells.
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists route_upf_ao_pg.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     None
#
# PROCS USED :    P_add_sec_pg_hookup P_msg_info
#                         
# DESCRIPTION :   route_upf_ao_pg.tcl is to route secondary PG pins for isolation, level shifters and always on cells.
#
# EXAMPLES :      
#
###############################################################
#
##############################################################################
# Route secondary P/G pins of isolation, level-shifter & always-on cells in UPF flow.

# Secondary PG hookup for Isolation and Always-on cells
set iso_unfixed [get_cells -physical_context -f "is_isolation && !is_fixed" -quiet] 
set aon_unfixed [get_cells -physical_context -f "ref_block.always_on &&  !is_fixed" -quiet]
set ls_unfixed  [get_cells -physical_context -f "is_level_shifter && !is_fixed" -quiet]

foreach ret_flop [lsort -unique [get_attribute [get_lib_cells */* -filter "is_retention==true"] name]] {
  lappend ret_flop_stdcells [string range $ret_flop 0 7]
}

set ret_filter_pattern "(ref_name=~[join [lsort -unique $ret_flop_stdcells] {*) || (ref_name =~} ]*)"
set ret_flop_unfixed [get_cells -physical_context -filter $ret_filter_pattern -quiet]
set ret_flop_unfixed [get_cells -physical_context $ret_flop_unfixed -filter "is_fixed == false" -quiet]

set unfixed_cells [add_to_collection $iso_unfixed $aon_unfixed]
set unfixed_cells [add_to_collection $unfixed_cells $ls_unfixed]
set unfixed_cells [add_to_collection $unfixed_cells $ret_flop_unfixed]
P_add_sec_pg_hookup -cells $unfixed_cells

P_msg_info "Set dont_touch & dont_touch_placement on [sizeof_collection [get_cells -physical_context -filter "is_isolation==true" -quiet]] isolation cells, [sizeof_collection [get_cells -physical_contex -filter "is_level_shifter==true" -quiet]] level-shifter cells & [sizeof_collection [get_cells -physical_context -f {ref_block.always_on} -quiet]] always-on cells ..."

set pm_cells [get_cells -physical_context -filter "is_isolation==true" -quiet]
append_to_collection pm_cells [get_cells -physical_contex -filter "is_level_shifter==true" -quiet]
append_to_collection pm_cells [get_cells -physical_context -f {ref_block.always_on} -quiet]
append_to_collection pm_cells [get_cells -physical_context -filter $ret_filter_pattern -quiet]
set_dont_touch $pm_cells
set_placement_status fixed $pm_cells

#Freeze secondary PG routing
#set_net_routing_rule [get_nets -all -hierarchical * -filter "net_type == Power"] -reroute freeze


