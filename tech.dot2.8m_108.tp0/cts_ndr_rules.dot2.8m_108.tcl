##############################################################
# NAME :          cts_ndr_rules.dot2.8m_108.tcl
#
# SUMMARY :       create NDR rules
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists cts_ndr_rules.dot2.8m_108.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_ENABLE_CLOCK_NDR
#
# PROCS USED :    P_msg_info
#                         
# DESCRIPTION :   cts_ndr_rules.dot2.8m_108.tcl is to creat NDR rules for clock routes
#
# EXAMPLES :      
#
###############################################################

#############################################
# NDR RULE : ndr_defaultW_3T_noSh
#############################################
if {[get_routing_rules -quiet ndr_defaultW_3T_noSh] != ""} {
  remove_routing_rules ndr_defaultW_3T_noSh
}

P_msg_info "Defining NDR rule : ndr_defaultW_3T_noSh"

create_routing_rule ndr_defaultW_3T_noSh -default_reference_rule -snap_to_track \
    -spacings {m5 0.090 m6 0.090}

report_routing_rules

#############################################
# NDR RULE : ndr_defaultW_3T_Sh
#############################################
if {[get_routing_rules -quiet ndr_defaultW_3T_Sh] != ""} {
  remove_routing_rules ndr_defaultW_3T_Sh
}

P_msg_info "Defining NDR rule : ndr_defaultW_3T_Sh"

create_routing_rule ndr_defaultW_3T_Sh -default_reference_rule -snap_to_track \
    -shield_widths {m1 0.00 m2 0.00 m3 0.00 m4 0.00}

report_routing_rules

#############################################
# NDR RULE : ndr_defaultW_3T_noSh_Lth
#############################################
if {[sizeof_collection [get_routing_rules ndr_defaultW_3T_noSh_Lth -quiet]] > 0} {
  remove_routing_rules ndr_defaultW_3T_noSh_Lth
}

P_msg_info "Defining NDR rule : ndr_defaultW_3T_noSh_Lth"

create_routing_rule ndr_defaultW_3T_noSh_Lth -default_reference_rule -snap_to_track \
   -spacings {m5 0.090 m6 0.090} \
   -spacing_length_thresholds {m5 1.0 m6 1.0}

if { [info exists INTEL_ENABLE_CLOCK_NDR] && $INTEL_ENABLE_CLOCK_NDR==1} {
  set wide_wire 0
  foreach clk [array names INTEL_CTS_NDR_RULE] {
    if {[string first "ndr_wide" $INTEL_CTS_NDR_RULE($clk)] ne -1} {
      set wide_wire 1
    }
  }

  if {$wide_wire eq 1} {  
  #############################################
  # NDR RULE : ndr_wideW_m3_m6_noSh
  #############################################
    if {[sizeof_collection [get_routing_rules ndr_wideW_m3_m6_noSh -quiet]] > 0} {
      remove_routing_rules ndr_wideW_m3_m6_noSh
    }

    P_msg_info "Defining NDR rule : ndr_wideW_m3_m6_noSh"

    create_routing_rule ndr_wideW_m3_m6_noSh -default_reference_rule \
      -taper_distance 0 \
      -widths {m3 0.108 m4 0.108 m5 0.108 m6 0.108}

      #############################################
      # NDR RULE : ndr_wideW_m3_m6_Sh
      #############################################
    if {[sizeof_collection [get_routing_rules ndr_wideW_m3_m6_Sh -quiet]] > 0} {
      remove_routing_rules ndr_wideW_m3_m6_Sh
    }

    P_msg_info "Defining NDR rule : ndr_wideW_m3_m6_Sh"

    create_routing_rule ndr_wideW_m3_m6_Sh -default_reference_rule \
      -taper_distance 0 \
      -widths {m3 0.108 m4 0.108 m5 0.108 m6 0.108} \
      -shield_widths {m1 0.00 m2 0.00 m3 0.044 m4 0.044 m5 0.044 m6 0.044}
  }
}


