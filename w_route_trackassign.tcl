##############################################################################
# List of procs used by this scripts
# 1. P_msg_info
##############################################################################

##############################################################################
# Run route_opt with track assignment
##############################################################################

set_app_options -name route.detail.eco_max_number_of_iterations -value 10
eval $INTEL_ROUTE_TRACK_ASSIGN_CMD

# Run route_opt
set_app_options -name route_opt.eco_route.mode -value track
set_app_options -name route_opt.flow.enable_ccd -value true
route_opt
