# set_isolate_ports.tcl

# To prevent side load on I/O ports
set_isolate_ports -type buffer [get_ports *]
report_isolate_ports -all > ./reports/$INTEL_DESIGN_NAME.$INTEL_STEP_CURR.isolate_ports.rpt

# EOF
