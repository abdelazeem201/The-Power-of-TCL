##############################################################################
#Script: tool_constraints.tcl
# List of procs used by this tcl
# 1. P_lminus
# 2. P_msg_info
# 3. get_completed_steps

########################################

suppress_message {NDMUI-461}

# Host options
set_host_options -max_cores $INTEL_NUM_CPUS
report_host_options -nosplit

### ICC settings that must be done after a design is read in 
# Enable  the timing analysis of recovery and removal checks in the design
set_app_options -name time.disable_recovery_removal_checks -value false
# Enables clock reconvergence pessimism removal.
set_app_options -name time.remove_clock_reconvergence_pessimism -value true
# Enable freq based max_cap table
set_app_options -name time.frequency_based_max_cap -value true

# Cells inserted during each flow will have a prefix of the flow name. For ex. placement will have "place" prefix
# If Intel flow variables are not defined, then the default prefix will be used
if { $INTEL_STEP_CURR eq {cts} } {
  set_app_options -name opt.common.user_instance_name_prefix -value clock_
  set_app_options -name cts.common.user_instance_name_prefix -value cts_
} else {
  set_app_options -name opt.common.user_instance_name_prefix -value ${INTEL_STEP_CURR}_

}

# Enable higher effort timing optimization in preroute flows (default is low)
set_app_options -name opt.timing.effort -value high
# Enable higher effort area recovery in preroute flows (default is low)
set_app_options -name opt.area.effort -value medium
# Preroute flows will run mW leakage optimization
#set_app_options -name opt.leakage.effort -value medium

# Effort level for buffer area usage in data path optimization.
# Setting to medium/high, default is low
set_app_options -name opt.common.buffer_area_effort -value medium

# Bufferring for place_opt/cts_opt to reduce pre and post route timing miss-correlation
set_app_options -name opt.common.buffering_for_advanced_technology -value true 

set_app_options -name opt.common.max_fanout -value 30

# Defines maximum fanout a tie-cell can drive
#set_app_options -name opt.tie_cell.max_fanout -value 1

# Default is 1000
set_app_options -name time.high_fanout_net_threshold -value 100

# Disables checking of cell placement against pre-routed nets, including Power and Ground nets,  
# during  legaliza-tion  and  legality checking.
#set_app_options -name place.legalize.enable_prerouted_net_check -value false

# Ensure cells are placed close together for low-utilization blocks
# Recommended setings are somewhere between 0.5 and 0.65
set_app_options -name place.coarse.max_density -value 0.6

set_app_options -name place.coarse.congestion_driven_max_util -value 0.9

# Controls the target routing density for  congestion  driven  placement
set_app_options -name place.coarse.target_routing_density -value 0.7

# When set placer tries to control the maximum local pin density
set_app_options -name place.coarse.pin_density_aware -value true

set_app_options -name place.coarse.detect_detours -value true

#set_app_options -name place.coarse.icg_auto_bound -value true

# Run global route based buffering during HFSDRC
set_app_options -name place_opt.initial_drc.global_route_based -value 1

set_app_options -name place_opt.flow.optimize_icgs -value true

# Effort level for the congestion alleviation in place_opt
set_app_options -name place_opt.congestion.effort -value high
# Enable two-pass flow  to  generate  better initial  placement
set_app_options -name place_opt.initial_place.two_pass -value true
# Default is medium
set_app_options -name place_opt.initial_place.effort -value high
# Default is medium
set_app_options -name place_opt.final_place.effort -value high

set_app_options -name place_opt.flow.optimize_layers -value auto
set_app_options -name place_opt.flow.optimize_ndr -value true

# Enable layer & NDR optimizations for long timing critical nets.
# Requires all NDRs applied before place_opt for better congestion estimation.
if { [lsearch -exact [get_completed_steps] place] >= 0 || [lsearch -exact [get_completed_steps] upf_place] >= 0 } {
# Enable layer optimizations for long timing critical nets.
  set_app_options -name refine_opt.flow.optimize_layers -value true
  set_app_options -name refine_opt.flow.optimize_ndr -value true
}

set_app_options -name refine_opt.place.effort -value high
#set_app_options -name refine_opt.congestion.effort -value high

# To turn on cts verbose
set_app_options -name cts.common.verbose -value 1

# Set fanout constraint for cts
set_app_options -name cts.common.max_fanout -value $INTEL_CTS_MAX_FANOUT

#Enable NDR
set_app_options -name clock_opt.flow.optimize_ndr -value true

# Enable global router during initial stages of synthesize_clock_trees 
set_app_options -name cts.compile.enable_global_route -value true

#set_app_options -name clock_opt.flow.enable_ccd -value true

set_app_options -name clock_opt.place.effort -value high
#set_app_options -name clock_opt.congestion.effort -value high

set_app_options -name route.global.timing_driven -value true
# Can only enable crosstalk after floorplan due to unsupported by place_pins.
#  Error: place_pins cannot be used with crosstalk driven mode in global route (DPPA-269)
if { [lsearch -exact [get_completed_steps] place] >= 0 } {
  set_app_options -name route.global.crosstalk_driven -value true
}
set_app_options -name route.global.macro_corner_track_utilization -value 95

#set_app_options -name route_opt.flow.enable_ccd -value true
#set_app_options -name route_opt.flow.enable_cto -value true
set_app_options -name route_opt.flow.enable_power -value true
set_app_options -name route_opt.flow.xtalk_reduction -value true

# To optimize wire length and via counts for tie-off nets
set_app_options -name route.detail.optimize_tie_off_effort_level -value high

set_app_options -name time.si_enable_analysis -value true
set_app_options -name extract.enable_coupling_cap -value true

report_app_options -non_default > ./reports/$INTEL_DESIGN_NAME.$INTEL_STEP_CURR.app_options-non_default.rpt

# Set routing layers
remove_ignored_layers -all
if {[info exists INTEL_STEP_CURR] && $INTEL_STEP_CURR != "" && [info exists INTEL_MIN_ROUTING_LAYER_OVERRIDE(${INTEL_STEP_CURR})] && $INTEL_MIN_ROUTING_LAYER_OVERRIDE(${INTEL_STEP_CURR}) != ""} {
  set min_routing_layer $INTEL_MIN_ROUTING_LAYER_OVERRIDE(${INTEL_STEP_CURR})
} else {
  set min_routing_layer $INTEL_MIN_ROUTING_LAYER
}
if {[info exists INTEL_STEP_CURR] && $INTEL_STEP_CURR != "" && [info exists INTEL_MAX_ROUTING_LAYER_OVERRIDE(${INTEL_STEP_CURR})] && $INTEL_MAX_ROUTING_LAYER_OVERRIDE(${INTEL_STEP_CURR}) != ""} {
  set max_routing_layer $INTEL_MAX_ROUTING_LAYER_OVERRIDE(${INTEL_STEP_CURR})
} else {
  set max_routing_layer $INTEL_MAX_ROUTING_LAYER
}
if {[info exists INTEL_STEP_CURR] && $INTEL_STEP_CURR != "" && [info exists INTEL_RC_IGNORE_LAYERS_OVERRIDE(${INTEL_STEP_CURR})] && $INTEL_RC_IGNORE_LAYERS_OVERRIDE(${INTEL_STEP_CURR}) != ""} {
  set rc_ignore_layer $INTEL_RC_IGNORE_LAYERS_OVERRIDE(${INTEL_STEP_CURR})
} else {
  set rc_ignore_layer $INTEL_RC_IGNORE_LAYERS
}
if {$INTEL_STEP_CURR eq "place"} {
# Intel Custom Foundry Collateral recommended
# Ignore m0/m1 during placement only results in better optimization. Reset after placement.
  set_ignored_layers -min_routing_layer m2
  report_ignored_layers
} else {
  P_msg_info "Setting min_routing_layer: $min_routing_layer"
  P_msg_info "Setting max_routing_layer: $max_routing_layer"
  P_msg_info "Setting rc_ignore_layer:   $rc_ignore_layer"
  set_ignored_layers  \
    -min_routing_layer $min_routing_layer \
    -max_routing_layer $max_routing_layer \
    -rc_congestion_ignored_layers $rc_ignore_layer
}

# NOTE: Setting routing_direction attribute for layer in design will cause ATTR-11 info message whenever routing_direction attribute of the layer is later queried.
set_attribute -objects [get_layers $INTEL_HORIZONTAL_LAYERS] -name routing_direction -value horizontal
set_attribute -objects [get_layers $INTEL_VERTICAL_LAYERS] -name routing_direction -value vertical

set_routing_rule [get_nets $INTEL_POWER_NET] -min_routing_layer m2 -min_layer_mode hard
set_routing_rule [get_nets $INTEL_GROUND_NET] -min_routing_layer m2 -min_layer_mode hard

set_app_options -name plan.macro.spacing_rule_heights -value "0.00um ${INTEL_MACRO_Y_SPACING}um" ;#macros can either abut or spaced 1.890um away in Y direction
set_app_options -name plan.macro.spacing_rule_widths -value "0.00um ${INTEL_MACRO_X_SPACING}um" ; #macros can either abut or spaced 2.160um away in X direction
