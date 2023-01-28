##############################################################################
# List of procs used by this script
# 1. P_msg_info
###

#If needed, reads scan def and re-orders before running placement.
if { [info exists INTEL_INSERT_SCAN] && $INTEL_INSERT_SCAN } {
  if { [info exists INTEL_INPUT_SCANDEF] && $INTEL_INPUT_SCANDEF != "" } {
    read_def $INTEL_INPUT_SCANDEF
  } else {
    read_def ./inputs/$INTEL_DESIGN_NAME.syn.scandef
  }
  check_scan_chain
}

#SPG Support
if { [info exists INTEL_SPG] && $INTEL_SPG } {
  if { [info exists INTEL_SPG_DEF] && $INTEL_SPG_DEF } {
    read_def ./inputs/$INTEL_DESIGN_NAME.syn.def
  }
  set_app_options -name place_opt.flow.do_spg -value true
}

# Doing place_opt with default options
report_app_options place_opt.*
#P_msg_info "Running: $INTEL_PLACE_CMD"
#eval $INTEL_PLACE_CMD

### quick report for intermediate step

### congestion removal flow
# BKM #1 if design is congested


##change made

source -echo $env(INTEL_ASIC)/asicflows/synopsys/apr/dont_use_nn.tcl
create_placement -effort high
source -echo $env(INTEL_ASIC)/asicflows/synopsys/apr/dont_use_nn.tcl

set_app_options -list {place_opt.flow.enable_ccd true}
place_opt -from initial_drc -to initial_opto 
source -echo  $env(INTEL_ASIC)/asicflows/synopsys/apr/dont_use_nn.tcl
place_opt -from final_place 
#place_opt -from initial_drc -to initial_drc
source -echo $env(INTEL_ASIC)/asicflows/synopsys/apr/dont_use_nn.tcl



set_app_options -list {place_opt.flow.enable_ccd false}
place_opt -from final_opto
#create_placement -effort high -congestion -congestion_effort high -use_seed_locs

#place_opt -from initial_drc -to final_opto

# BKM #2 if design is congested
#create_placement -congestion_driven_restructuring
#place_opt -from initial_drc -to initial_drc
#update_timing -full

#create_placement -timing -congestion -congestion_effort high -effort high -use_seed_locs
#place_opt -from initial_drc
