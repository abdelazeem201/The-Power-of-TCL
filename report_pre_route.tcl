##############################################################################
# Script: route_pre_route.tcl
##############################################################################

# Check routeablilty
check_routability

# Check for Ideal Nets
set num_ideal [sizeof_collection [get_nets * -hier -filter "is_ideal ==true" -quiet]]
if {$num_ideal >= 1} {
  P_msg_info "$num_ideal Nets are ideal prior to route_opt. Please investigate"
}
