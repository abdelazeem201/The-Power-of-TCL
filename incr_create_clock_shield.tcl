##############################################################################

###################################################
# Create clock shield
###################################################

if {[info exists INTEL_ENABLE_CLOCK_NDR] && $INTEL_ENABLE_CLOCK_NDR} {
  create_shield -shielding_mode reshield -preferred_direction_only true -align_to_shape_end true
  set_extraction_options -virtual_shield_extraction false
  report_shields
}
