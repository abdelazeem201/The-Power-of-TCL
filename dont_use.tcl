##############################################################################

###############################################
# List of procs used by this script
# 1. P_msg_info
#
# Required Variables:
#   INTEL_DONT_USE
##################################################

set dont_use_default $INTEL_DONT_USE

#Check for zero max cap cells and append to list
set max_cap_zero_cells [get_attribute [get_lib_cells -of_objects [get_lib_pins */*/* -filter " max_capacitance == 0" -quiet] -quiet] name -quiet]
lappend dont_use_default $max_cap_zero_cells {SPECIAL: Cells with max_capacitance=0 in the lib file}

source -echo $env(INTEL_ASIC)/asicflows/synopsys/apr/dont_use_nn.tcl

set _dont_use_cells ""

if { ![info exists ::synopsys_program_name] } {
  P_msg_warn "Unsupported Tcl program for '[file tail [info script]]' script!  Skip!"
} elseif { $::synopsys_program_name == {icc2_shell} } {
  if {[info exists INTEL_UPF] && $INTEL_UPF} {
    set pm_libcells [get_lib_cells -quiet -filter "defined(level_shifter_type)" */${INTEL_FDK_LIB}*]
    set pm_libs [get_libs -of_objects $pm_libcells]
    foreach attr_name {dont_use dont_touch} {
      if { [sizeof_collection $pm_libcells] > 0 } {
        P_msg_warn "Setting attribute '$attr_name' for level shifter cell to prevent tool optimzing level shifters ..."
        set_attribute $pm_libcells $attr_name true
      }
    }
  }
  set_message_info -id ATTR-12 -limit 1
  set dont_use_lib_cell_patt {}
  set dont_use_lib_cells {}
  foreach {lib_cell_patt desc} $dont_use_default {
    lappend dont_use_lib_cell_patt $lib_cell_patt
    append_to_collection -unique dont_use_lib_cells [get_lib_cells -quiet "*/[join $lib_cell_patt { */}]"]
  }
  P_msg_info "Set purpose 'none' for [sizeof_collection $dont_use_lib_cells] lib cells of patterns '[join $dont_use_lib_cell_patt]'."
  if { [sizeof_collection $dont_use_lib_cells] > 0 } {
    set_lib_cell_purpose -include none $dont_use_lib_cells
  }
  unset dont_use_lib_cell_patt dont_use_lib_cells
} elseif { $::synopsys_program_name == {dc_shell} || $::synopsys_program_name == {icc_shell} } {
  P_msg_info "Setting SYN/APR dont_use cells"
  set dont_use_list [set dont_use_default]
  P_msg_info "Setting dont_use on seleted cells based on dont_use_default in the ASIC flow"
  foreach {cell_type cell_description} $dont_use_list {
    P_msg_info "Setting dont_use on $cell_type\n   because $cell_description"
    foreach cell_name $cell_type {
      set _dont_use_cells [get_lib_cells */$cell_name -quiet]
      if {[sizeof_collection $_dont_use_cells] > 0} {
        set_dont_use $_dont_use_cells
        foreach_in_collection lib_pin [get_lib_pins -of_objects $_dont_use_cells] {
          set attribute [get_attribute $lib_pin clock_gate_out_pin -quiet]
          if {$attribute == "true"} {
            set_dont_use $_dont_use_cells -power
          }
        }

      } else {
        P_msg_info " no '$cell_name' cells found in libraries loaded in the design "
      }
    }
  }

  if { $::synopsys_program_name == {icc_shell} } {
    set cell_list "${INTEL_FDK_LIB}tih00wnz00"
  } else {
    set cell_list {}
  }
  foreach cell_name $cell_list {
    puts "INFORMATION: removing dont_use from cell $cell_name "
    remove_attribute [get_lib_cells */$cell_name] dont_use
    remove_attribute [get_lib_cells */$cell_name] dont_touch
  }

  if {[info exists INTEL_UPF] && $INTEL_UPF} {
      set pm_libcells [get_lib_cells -quiet -filter "(is_isolation_cell == true || defined(level_shifter_type) || retention_cell =~ * || always_on == true)" */${INTEL_FDK_LIB}*]
    set pm_libs [get_libs -of_objects $pm_libcells]
    foreach attr_name {dont_use dont_touch} {
      set bad_pm_libcells [filter_collection $pm_libcells "$attr_name == true"]
      if { [sizeof_collection $bad_pm_libcells] > 0 } {
        P_msg_warn "Detected power-management (isolation, level-shifter, retention & always-on non-clock) lib cells in that have attribute '$attr_name' set to 'true'!  Removing their attribute '$attr_name' as they are necessary for UPF flow ..."
        remove_attribute $bad_pm_libcells $attr_name
      }
    }
  }
} else {
  P_msg_warn "Unsupported Synopsys tool '$::synopsys_program_name' for '[file tail [info script]]' script!  Skip!"
}

