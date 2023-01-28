##############################################################################
# List of procs used by the script
# 1. P_msg_info

#Better results seen with smaller iterations

route_eco -utilize_dangling_wires true -open_net_driven true -reuse_existing_global_route true

P_msg_info "Running detail route and final DRC clean up"
eval $INTEL_INCR_DETAIL_ROUTE_OPT_CMD

if {[info exists INTEL_INC_DETAIL_ROUTE_ITERATIONS]} {
  P_msg_info "Running more iterations for better router DRV convergence"
  set_app_options -name route.detail.force_max_number_iterations -value true
  route_detail -init true -max_number_iterations $INTEL_INC_DETAIL_ROUTE_ITERATIONS
}