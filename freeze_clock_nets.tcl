##############################################################################
##############################################################################
# List of procs used by this scripts
# 1. P_msg_info
##############################################################################

###################################################
#Freeze clock nets
###################################################

if { [sizeof_collection [set clks [get_clocks -quiet -filter {is_virtual == false}]]] == 0 } {
  P_msg_warn "No clock found to freeze clock net!  Skip!"
  return
}
# Marking clock tree as done
P_msg_info "Marking clock buf/inv and flops to fixed and clock routes to minor change"
mark_clock_trees -synthesized
set_app_options -name cts.compile.fix_clock_tree_sinks -value true

set_attribute -objects [get_nets -physical_context -filter {net_type == clock}] -name physical_status -value minor_change
