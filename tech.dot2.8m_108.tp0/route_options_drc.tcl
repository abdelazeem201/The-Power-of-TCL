############################################################
# NAME :          route_options_drc.tcl
#
# SUMMARY :       specifies route options to achieve DRV convergence
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists route_options_drc.tcl
#
# ARGUMENTS :     none
#
# VARIABLES :     INTEL_LAYER_PROMOTION INTEL_ENABLE_CLOCK_NDR INTEL_ZROUTE_VIA_DBL
#
#                         
# DESCRIPTION :   specifies route options to achieve DRV convergence
#
# EXAMPLES :      
#
#############################################################

##############################################################################
# Script: route_options_drc.tcl
# Description: Sets Z-Route options to achieve DRV convergence
##############################################################################

# Reset all the route options 
reset_app_options route.* 

###################################################
#ZRT: Common Route Options
###################################################

# specifies the routing clock topology - normal routing of clock nets(default : normal)
set_app_options -name route.common.clock_topology -value normal

# prevent auto track fill
#set_app_options -name route.common.track_auto_fill -value false
#set_app_options -name route.common.track_use_area  -value true

# mustjoin pins on stdcells will get single pin connections
# other pins can have multiple pin connect (i.e. connection "through" the pin)
#set_app_options -name route.common.single_connection_to_pins -value standard_cell_must_join_pins

# control strength of min layer constraint
set_app_options -name route.common.global_min_layer_mode -value allow_pin_connection
set_app_options -name route.common.net_min_layer_mode -value soft

#set_app_options -name route.common.global_min_layer_mode -value hard
#set_app_options -name route.common.net_min_layer_mode -value allow_pin_connection
set_routing_rule [get_flat_nets * -filter "net_type!~clock"] -min_routing_layer m2 -min_layer_mode hard

# control strength of max layer constraint
set_app_options -name route.common.global_max_layer_mode -value hard
set_app_options -name route.common.net_max_layer_mode -value hard

#control number of vias under min routing layer
set_app_options -name route.common.number_of_vias_under_global_min_layer -value 1
#control vias under min routing layer for nets with routing rule
#set_app_options -name route.common.number_of_vias_under_net_min_layer -value 4

# control not to extend m1 pins
#set_app_options -name route.common.connect_within_pins_by_layer_name -value {{m1 via_wire_all_pins}}

# Must-Join connection option 
set_app_options -name route.common.single_connection_to_pins -value standard_cell_must_join_pins
#Caused false DRC issues, and had increased convergence time
#set_app_options -name route.common.only_conn_to_must_joint_pins -value true

# amount of information in logfile - range 0 1 2 (default : 0)
set_app_options -name route.common.verbose_level -value 1

# no documentation on this switch
#set_app_options -name route.common.connect_tie_off -value true

# control whether or not to rotate the default vias
set_app_options -name route.common.rotate_default_vias -value false

# set route_m1ExtraCost 20
#set_app_options -name route.common.extra_preferred_direction_wire_cost_multiplier_by_layer_name -value {{m1 20}}

# mark clock tree nets as minor-name route.common.change only (default : true)
set_app_options -name route.common.mark_clock_nets_minor_change -value true

# reroute clock net shapes  (default : false)
set_app_options -name route.common.reroute_clock_shapes -value false

# reroute user created shapes (default : false)
set_app_options -name route.common.reroute_user_shapes -value false

# Redundant via insertion
if {[info exists INTEL_ZROUTE_VIA_DBL] && $INTEL_ZROUTE_VIA_DBL ==1} {
## Setting this option prior to routing, starts the via doubling,
## without the need for the standalone command
  set_app_options -name route.common.post_detail_route_redundant_via_insertion -value medium
} else {
  set_app_options -name route.common.post_detail_route_redundant_via_insertion -value off
}

# Enable RC driven layer assignment
if {[info exists INTEL_LAYER_PROMOTION] && $INTEL_LAYER_PROMOTION == 1} {
  set_app_options -name route.common.rc_driven_setup_effort_level -value high
}

# Enable reshielding of modified nets
if {[info exists INTEL_ENABLE_CLOCK_NDR] && $INTEL_ENABLE_CLOCK_NDR} {
  set_app_options -name route.common.reshield_modified_nets -value reshield
}

# specifies whether variable routing rule spacing is ignored against blockages
set_app_options -name route.common.ignore_var_spacing_to_blockage -value false

# specifies whether variable routing rule spacing is ignored against p/g nets
set_app_options -name route.common.ignore_var_spacing_to_pg -value true

# Remove once tf has the soft end-to-end rules removed
set_app_options -name route.common.disable_soft_end_to_end_spacing_rules -value true

###################################################
#ZRT: Global Route Options
###################################################

# enables (true) or disables (false) timing-driven global routing (default : false)
set_app_options -name route.global.timing_driven -value true
set_app_options -name route.track.crosstalk_driven -value true

# option -macro_corner_track_utilization limits the utilization of tracks
# available in the gcells near a macro corner to a specified  percentage.
# This  variable is used to control the accessibility of pins and conges-
# tion at the macro corners. By default, the router uses 100  percent  of
# available tracks in the macro boundary width.
set_app_options -name route.global.macro_corner_track_utilization -value 95

### performs global routing using effort level (low,medium,high) - tool defualt medium
set_app_options -name route.global.effort_level -value medium

# this adds extra GR cost for pin access - should help improved high pin density access
# set_app_options -name route.global.pin_access_factor -value 9


###################################################
#ZRT: Track Assignment Options
###################################################

# Enables  (true)  or disables (false) timing-driven track assign (default : false)
set_app_options -name route.track.timing_driven -value true

# Makes track assign keep same layer assignment as global route during congestion removal
# such that congestion removal doesn't change layers and impact QOR if the layer change is "down"
set_app_options -name route.track.allow_layer_change -value false


###################################################
#ZRT: Detail Route Options
###################################################

# Initially turn off antenna (if INTEL_ZROUTE_FIX_ANTENNA is set, fix antenna later)
set_app_options -name route.detail.antenna -value false

# DRC convergence effort level (default : medium)
set_app_options -name route.detail.drc_convergence_effort_level -value medium

# controls whether the router ignores specific design rule
# The setting says "DO NOT" ignore same_net_metal_space DRV's
set_app_options -name route.detail.ignore_drc -value {{same_net_metal_space false}}

# specifies whether timing-driven routing is enabled (default : false)
set_app_options -name route.detail.timing_driven -value true

# Ensure that there is no illegal tapering from NDR width to default width
#set_app_options -name route.detail.use_wide_wire_to_input_pin -value true
#set_app_options -name route.detail.use_wide_wire_to_output_pin -value true

## Set this to reduce the initial amount of vias.  The default tool setting is low.
set_app_options -name route.detail.optimize_wire_via_effort_level -value medium

# this removes REON MSR pessimism when there is no middle wire
set_app_options -name route.detail.enable_nmsr_middle_track_filter -value true


