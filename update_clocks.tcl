##############################################################################
##############################################################################
# List of procs used by this scripts
# 1. P_source_if_exists
#    (i) P_rdtConvertSeconds
# 2. P_msg_info
##############################################################################

if { [sizeof_collection [set clks [get_clocks -quiet -filter {is_virtual == false}]]] == 0 } {
  P_msg_warn "No clock found to update clock!  Skip!"
  return
}

set_propagated_clock $clks
P_msg_info "Running compute_clock_latency - Adjusting I/O timing and set to propagated clock timing"
compute_clock_latency

###################################################
# Update clock uncertainty
###################################################
set design_current_scenario [current_scenario]
foreach_in_collection scenario [all_scenarios] {
  current_scenario $scenario
  if {[file exists scripts/update_clock_uncertainty.tcl]} {
    P_msg_info "Applying uncertainty values from scripts/update_clock_uncertainty.tcl for scenario $scenario";
    P_source_if_exists update_clock_uncertainty.tcl
  }
}

current_scenario $design_current_scenario

