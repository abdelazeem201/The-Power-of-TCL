##############################################################################
# List of procs used by this script
# 1. P_msg_info
###

# Incremental placement optimization
report_app_options refine_opt.*
P_msg_info "Running: $INTEL_POST_PLACE_CMD"
eval $INTEL_POST_PLACE_CMD

