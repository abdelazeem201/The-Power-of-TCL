###############################################################################

###################################################
# Create clock shield
###################################################

if {[info exists INTEL_ENABLE_CLOCK_NDR] && $INTEL_ENABLE_CLOCK_NDR} {
  # Creating shields if Clock need shielding
  if {[sizeof_collection [get_vias -quiet -filter undefined(owner)]] > 0} {
    remove_vias [get_vias -filter undefined(owner)]
  }

  if {[sizeof_collection [get_shape -quiet -filter "undefined(owner) && shape_use==global_route"]] > 0} {
    remove_shape [get_shape -filter "undefined(owner) && shape_use==global_route"]
  }

  create_shields -preferred_direction_only true -align_to_shape_end true
  set_extraction_options -virtual_shield_extraction false
  report_shields
}
