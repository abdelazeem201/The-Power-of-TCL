##############################################################################
##############################################################################
# List of procs used by this scripts
# 1. P_msg_info
##############################################################################

#Route clock nets

if { [sizeof_collection [set clks [get_clocks -quiet -filter {is_virtual == false}]]] == 0 } {
  P_msg_warn "No clock found to route clock net!  Skip!"
  return
}

# Routing clocks
report_app_options route.*
P_msg_info "Routing clock nets"
route_group -all_clock_nets -reuse_existing_global_route true
#synthesize_clock_trees -postroute -routed_clock_stage detail
set_app_options -name clock_opt.flow.enable_ccd -value true
clock_opt
# :D
# Post route clock optimization
#clock_opt -from route_clock -to route_clock
#compute_clock_latency
#clock_opt -from final_opto -to final_opto


