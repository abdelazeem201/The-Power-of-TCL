##############################################################################
# List of procs used by this script
# 1. P_msg_error
# 2. P_msg_info

# Get lib cells to use for diode insertion.
foreach_in_collection lib [get_libs] {
  set lib [file rootname [get_object_name $lib]]
  if {[get_lib_cells -quiet ${lib}*/${INTEL_ANTENNA_DIODE}] ne ""} {
    set diode_cell_insert [get_object_name [get_lib_cells -quiet ${lib}*/${INTEL_ANTENNA_DIODE}]]
  }
}

# Check if the chosen diode cell to insert exists
if {![info exists diode_cell_insert] || $diode_cell_insert eq ""} {
  P_msg_error "No input port diode cell found in library. Please check that $INTEL_ANTENNA_DIODE is set and the cell is available in the library!"
  return
}

# Insert GNAC diode on all input ports Except Clock Ports and the Ports specified by The User Through Variable INTEL_NO_INPUT_DIODE_PORTS
set clock_ports [get_ports [get_attribute [all_clocks] sources -quiet]]
# Avoid tm1 ports as they are typically pad inputs
set tm1_ports [get_ports -quiet -filter {layer.name == "tm1"}]
set avoid_ports [add_to_collection [add_to_collection $clock_ports $INTEL_NO_INPUT_DIODE_PORTS] $tm1_ports]
if {[get_attribute [get_lib_cells -quiet $diode_cell_insert] dont_use] == true} {
  remove_attribute $diode_cell_insert dont_use
}
define_user_attribute -class port -type string in_diode
set ports_need_diodes [remove_from_collection [all_inputs] $avoid_ports]
set ports_with_diodes [get_ports -quiet * -filter "in_diode=~*DIODE*"]
set ports_need_diodes [remove_from_collection $ports_need_diodes $ports_with_diodes]
set cmd ""
if { [sizeof_collection $ports_need_diodes] > 0} {
  redirect legality.tmp1.rpt {add_port_protection_diodes -prefix IN_PORT_DIODE -ignore_dont_touch -diode_lib_cell [get_lib_cells $diode_cell_insert] -port $ports_need_diodes}
  set legality_check [open legality.tmp1.rpt r]
  while {[gets $legality_check one_line] >= 0} {
    if { [string first "Error: There are some cells with an illegal placement." $one_line] == -1
      && [regexp "LGL-003" $one_line] == 0
      && [string first "check_legality for block design fdkex failed!" $one_line] == -1
      && [string first "check_legality failed." $one_line] == -1 } {
      puts $one_line
    }
  }
  sh rm legality.tmp1.rpt
  set_attribute $ports_need_diodes in_diode DIODE
}
# Do an incremental legalize for diodes introduced.
set_attribute [get_cells *DIODE*] physical_status legalize_only
redirect legality.tmp.rpt {legalize_placement -cells [get_cells *DIODE*]}
set legality_check [open legality.tmp.rpt r]
while {[gets $legality_check one_line] >= 0} {
  if { [string first "Error: There are some cells with an illegal placement." $one_line] == -1
    && [regexp "LGL-003" $one_line] == 0
    && [string first "check_legality for block design fdkex failed!" $one_line] == -1
    && [string first "check_legality failed." $one_line] == -1 } {
    puts $one_line
  }
}
sh rm legality.tmp.rpt
set_attribute [get_cells *DIODE*] physical_status fixed


