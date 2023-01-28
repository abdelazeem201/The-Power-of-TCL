##############################################################################
##############################################################################
# List of procs used by this scripts
# 1. P_msg_info
##############################################################################

###################################################
# Post CTS hold fixing
###################################################

# Setting up post-CTS refine_opt
set_app_options -name opt.timing.effort -value high

# Allow layer optimization
set_app_options -name refine_opt.flow.optimize_layers -value true

set_app_options -name refine_opt.flow.optimize_ndr -value true
set_app_options -name opt.area.effort -value ultra
set_app_options -name opt.common.buffer_area_effort -value ultra

# Extraction
#set_app_options -name extract.extract_min_cross_diagonal -value true
set_app_options -name extract.long_net_pessimism_removal -value true

# Hold
set_app_options -as_user_default -name refine_opt.hold.effort -value medium

# Post-CTS optimization
report_app_options refine_opt.*
P_msg_info "Running post CTS hold fix optimization"
eval $INTEL_POST_CTS_OPT_CMD

#Fix routing
route_group -nets [get_nets -hier * -filter "net_type==clock"]
