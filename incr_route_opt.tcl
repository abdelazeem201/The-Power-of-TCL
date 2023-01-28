##############################################################################
# List of procs used by this scripts
# 1. P_msg_info
##############################################################################

##############################################################################
# Run detail route
##############################################################################
# Running second loop of route_opt
set_app_options -name route_opt.eco_route.mode -value detail
report_app_options route_opt.*
P_msg_info "Running post route incremental optimization"
eval $INTEL_INCR_ROUTE_OPT_CMD

