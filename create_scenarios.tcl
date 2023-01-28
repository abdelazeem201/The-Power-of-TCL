# create_scenarios.tcl

if { [file exists ./inputs/$INTEL_DESIGN_NAME.mcmm.tcl] } {
  P_msg_info "Reading MCMM config from './inputs/$INTEL_DESIGN_NAME.mcmm.tcl' ..."
  source ./inputs/$INTEL_DESIGN_NAME.mcmm.tcl
} elseif {[info exists INTEL_PROCESS(WORST)] && 
          [info exists INTEL_VOLTAGE(WORST)] && 
          [info exists INTEL_TEMPERATURE(WORST)] &&
          [info exists INTEL_PROCESS(BEST)] && 
          [info exists INTEL_VOLTAGE(BEST)] && 
[info exists INTEL_TEMPERATURE(BEST)] } { 
  create_mode func

  create_corner BEST
  create_scenario -mode func -corner BEST -name func@BEST
  set_process_number $INTEL_PROCESS(BEST)
  set_voltage $INTEL_VOLTAGE(BEST)
  set_temperature $INTEL_TEMPERATURE(BEST)
  set_scenario_status -setup false -hold true -active true -max_transition true -max_capacitance true func@BEST

  create_corner WORST
  set_process_number $INTEL_PROCESS(WORST)
  set_voltage $INTEL_VOLTAGE(WORST)
  set_temperature $INTEL_TEMPERATURE(WORST)
  if { $INTEL_UPF } {
    P_msg_info "Reading UPF supply voltages from './inputs/upf/$INTEL_DESIGN_NAME.set_voltage.tcl' ..."
    source ./inputs/upf/$INTEL_DESIGN_NAME.set_voltage.tcl
  }

  create_scenario -mode func -corner WORST -name func@WORST
  set_scenario_status -setup true -hold false -active true -max_transition true -max_capacitance true func@WORST
} else {
  P_msg_fatal "Missing PVT 'INTEL_PROCESS()', 'INTEL_VOLTAGE()' and/or 'INTEL_TEMPERATURE()' var for corner 'BEST' and/or 'WORST'!  Exiting..."
}

report_modes -nosplit
report_scenarios -nosplit
report_corners -verbose > ./reports/$INTEL_DESIGN_NAME.$INTEL_STEP_CURR.corners.rpt
report_pvt -nosplit > ./reports/$INTEL_DESIGN_NAME.$INTEL_STEP_CURR.pvt.rpt

# EOF
