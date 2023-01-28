###############################################################################
##############################################################################
# List of procs used by this scripts
# 1. P_msg_info
##############################################################################

###################################################
# Clock tree synthesis - Only CTS
###################################################

# Doing initial clock tree using clock_opt
report_app_options clock_opt.*
P_msg_info "Running CTS for all clocks"
eval $INTEL_CLK_OPT_CMD

compute_clock_latency
