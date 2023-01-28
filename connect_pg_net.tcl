# connect_pg_net.tcl

# Connect P/G pins of cells to P/G nets.
if { !$INTEL_UPF } {
  if { $INTEL_STEP_CURR eq {import_design} } {
    create_net -power $INTEL_POWER_NET
    create_net -ground $INTEL_GROUND_NET
  }
}

connect_pg_net

# EOF
