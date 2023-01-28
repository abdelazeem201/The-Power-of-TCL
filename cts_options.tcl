##############################################################################
# Script: cts_options.tcl
##############################################################################

##############################################################################
# List of procs used by this scripts
# 1. P_msg_info
##############################################################################

# List out all the clocks.  Override with INTEL_CTS_NETS if exist
if {[info exist INTEL_CTS_NETS] && $INTEL_CTS_NETS != ""} {
  set clock_list $INTEL_CTS_NETS
} else {
  set clock_list [get_object_name [get_clocks]]
}

# set the CTS references (this may be too much...)
P_msg_info "Setting clock tree references"
derive_clock_cell_references


######################################################
## Check for NDR track availability if NDR is enabled
######################################################
# Setting Clock routing rules
foreach clock $clock_list {

### Get max_tran constraint for clock ###
  set clock_period [get_attribute [get_clocks $clock] period]
  set ctran_val [expr {( $clock_period*.1 > 125) ? 125 : $clock_period*.1}]
  P_msg_info "Constraining CTS max transition on clock $clock to ${ctran_val}ps"

  foreach_in_collection mode [all_modes] {
    current_mode $mode
    set_max_transition $ctran_val -clock_path $clock -mode $mode
  }

  P_msg_info "Setting clock tree routing rule options for : $clock"
  set clk_options "set_clock_routing_rules -clocks $clock"

  if {[info exists INTEL_ENABLE_CLOCK_NDR] && $INTEL_ENABLE_CLOCK_NDR && [info exists INTEL_CTS_NDR_RULE($clock)] && $INTEL_CTS_NDR_RULE($clock)!=""} {
    P_msg_info "Setting routing rule for $clock : $INTEL_CTS_NDR_RULE($clock)"
    set clk_options "$clk_options -rule $INTEL_CTS_NDR_RULE($clock)"

  } elseif {[info exists INTEL_ENABLE_CLOCK_NDR] && $INTEL_ENABLE_CLOCK_NDR && [info exists INTEL_CTS_NDR_RULE(DEFAULT)] && $INTEL_CTS_NDR_RULE(DEFAULT)!=""} {
    P_msg_info "Default NDR rule $INTEL_CTS_NDR_RULE(DEFAULT) has been defined and will be applied to $clock";
    P_msg_info "Setting routing rule for $clock : $INTEL_CTS_NDR_RULE(DEFAULT)";
    set clk_options "$clk_options -rule $INTEL_CTS_NDR_RULE(DEFAULT)"

  } else {
    P_msg_info "Neither a default NDR rule nor a clock specific NDR rule is defined for $clock...";
    P_msg_info "Clock $clock will use default routing rule";
    set clk_options "$clk_options -default_rule"
  }


  if {[info exists INTEL_CTS_MIN_ROUTING_LAYER($clock)] && $INTEL_CTS_MIN_ROUTING_LAYER($clock)!="" && [info exists INTEL_CTS_MAX_ROUTING_LAYER($clock)] && $INTEL_CTS_MAX_ROUTING_LAYER($clock)!=""} {
    P_msg_info "Clock specific min-max layers are defined for $clock and will be used"
    set clk_options "$clk_options -min_routing_layer $INTEL_CTS_MIN_ROUTING_LAYER($clock) -max_routing_layer $INTEL_CTS_MAX_ROUTING_LAYER($clock)"
  } else {
    P_msg_info "Clock specific min-max layer is not defined. Default clock min-max layer setting will be used for $clock"
    set clk_options "$clk_options -min_routing_layer $INTEL_CTS_MIN_ROUTING_LAYER(DEFAULT) -max_routing_layer $INTEL_CTS_MAX_ROUTING_LAYER(DEFAULT)"
  }

  eval "$clk_options -net_type root"
  eval "$clk_options -net_type internal"
  set_clock_routing_rules -min_routing_layer $INTEL_CTS_LEAF_MIN_LAYER -max_routing_layer $INTEL_CTS_LEAF_MAX_LAYER -clocks $clock -net_type sink -default_rule
}

report_routing_rules -verbose -significant_digits 3
