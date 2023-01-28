##############################################################
# NAME :          lib_cell_purpose.tcl
#
# SUMMARY :       define ICC2 lib cell purpose based on the defined list
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists lib_cell_purpose.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_LIB_CELL_PURPOSE_LIST INTEL_UPF
#
# PROCS USED :    None
#                         
# DESCRIPTION :   lib_cell_purpose.tcl is to define ICC2 lib cell purpose based on the defined list
#
# EXAMPLES :      
#
###############################################################

####################
# ICC2 dont_use/lib_cell_purpose variables in the order they are applied.
# 1. dont_use_required.tcl is used by ICC2 to disable specific lib cells for entire APR flow, which are enabled by default in the stdcell libs
# 2. The lib_cell_purpose_list(exclude,*) vars are used by ICC2 to disable specific lib cells during only specified purposes of APR2 flow, which are enabled by default in stdcell libs.
# 3. The lib_cell_purpose_list(include,*) vars are used by ICC2 to enable specific lib cells during only specified purposes of APR2 flow, which are disabled by default in stdcell libs, or disabled in the dont_use_default var above, or disabled in the lib_cell_purpose_list(exclude,*) vars of same purpose.
# Hence, lib cells are enabled by default if NOT disabled by default in stdcell libs and NOT in the dont_use_default var above and NOT in the lib_cell_purpose_list(exclude,*) vars.
# Required variable: 
#   INTEL_LIB_CELL_PURPOSE_LIST
# NOTE: 
#   Same lib cell can be set in more than 1 purposes of lib_cell_purpose_list(*,*) vars if so applicable.

array set lib_cell_purpose_list [array get INTEL_LIB_CELL_PURPOSE_LIST]

set_message_info -id ATTR-12 -limit 1
set_message_info -id ATTR-11 -limit 1

if { ![info exists ::synopsys_program_name] } {
  P_msg_warn "Unsupported Tcl program for '[file tail [info script]]' script!  Skip!"
} elseif { $::synopsys_program_name == {icc2_shell} } {
  set err_num 0
  foreach select_purpose [lsort [array names lib_cell_purpose_list]] {
    lassign [split $select_purpose ,] select purpose
    if { [lsearch -exact {exclude include} $select] < 0 } {
      incr err_num
      P_msg_error "Invalid select '$select' of purpose '$purpose' for lib cell patterns '[join $lib_cell_purpose_list($select,$purpose)]' defined by 'lib_cell_purpose_list($select,$purpose)' var!  Expect 1 purpose among 'exclude include'!  Skip!"
    }
    if { [lsearch -exact {optimization power cts hold all} $purpose] < 0 } {
      incr err_num
      P_msg_error "Invalid purpose '$purpose' of select '$select' for lib cell patterns '[join $lib_cell_purpose_list($select,$purpose)]' defined by 'lib_cell_purpose_list($select,$purpose)' var!  Expect 1 purpose among 'optimization power cts hold all'!  Skip!"
    }
  }
  if { $err_num > 0 } {
    P_msg_error "Abort '[file tail [info script]]' due to $err_num errors above!"
    return
  }
  foreach purpose {optimization power cts hold all} {
    if { $purpose != {all} || [info exists lib_cell_purpose_list(exclude,$purpose)] } {
      set excl_lib_cells [get_lib_cells -quiet "*/[join $lib_cell_purpose_list(exclude,$purpose) { */}]"]
      P_msg_info "Remove purpose '$purpose' for [sizeof_collection $excl_lib_cells] lib cells of patterns '[join $lib_cell_purpose_list(exclude,$purpose)]' defined by 'lib_cell_purpose_list(exclude,$purpose)' var."
      if { [sizeof_collection $excl_lib_cells] > 0 } {
        set_lib_cell_purpose -exclude $purpose $excl_lib_cells
      }
    }
    if { $purpose != {all} || [info exists lib_cell_purpose_list(include,$purpose)] } {
      set incl_lib_cells [get_lib_cells -quiet "*/[join $lib_cell_purpose_list(include,$purpose) { */}]"]
      P_msg_info "Set purpose '$purpose' for [sizeof_collection $incl_lib_cells] lib cells of patterns '[join $lib_cell_purpose_list(include,$purpose)]' defined by 'lib_cell_purpose_list(include,$purpose)' var."
      if { [sizeof_collection $incl_lib_cells] > 0 } {
        set_lib_cell_purpose -include $purpose $incl_lib_cells
        if { [sizeof_collection [set dt_lib_cells [filter_collection $incl_lib_cells {dont_touch == true}]]] > 0 } {
          P_msg_info "Set dont_touch to 'false' for [sizeof_collection $dt_lib_cells] among [sizeof_collection $incl_lib_cells] lib cells of select 'include' & purpose '$purpose' defined by 'lib_cell_purpose_list(include,$purpose)' var."
          set_attribute -objects $dt_lib_cells -name dont_touch -value false
        }
      }
    }
  }
  unset excl_lib_cells incl_lib_cells
  unset -nocomplain dt_lib_cells
  set_message_info -id ATTR-12 -limit 0
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
    set cell_list "${fdk_lib}tih00wnz00"
  } else {
    set cell_list {}
  }
  foreach cell_name $cell_list {
    puts "INFORMATION: removing dont_use from cell $cell_name "
    remove_attribute [get_lib_cells */$cell_name] dont_use
    remove_attribute [get_lib_cells */$cell_name] dont_touch
  }

  if {[info exists INTEL_UPF] && $INTEL_UPF} {
    set pm_libcells [get_lib_cells -quiet -filter "(is_isolation_cell == true || defined(level_shifter_type) || retention_cell =~ * || always_on == true)" */$fdk_lib*]
    set pm_libs [get_libs -of_objects $pm_libcells]
    foreach attr_name {dont_use dont_touch} {
      set bad_pm_libcells [filter_collection $pm_libcells "$attr_name == true"]
      if { [sizeof_collection $bad_pm_libcells] > 0 } {
        P_msg_warn "Detected power-management (isolation, level-shifter, retention & always-on non-clock) lib cells in that have attribute '$attr_name' set to 'true'!  Removing their attribute '$attr_name' as they are necessary for UPF flow ..."
        remove_attribute $bad_pm_libcells $attr_name
      }
    }
  }
} elseif { $::synopsys_program_name == {pt_shell} } {
  define_user_attribute pt_dont_use -quiet -type boolean -class lib_cell

  set dont_use_list $dont_use_pt_eco
  set dont_use_collection ""

  foreach {cell_type cell_description} $dont_use_list {
    echo  "INFO: Setting dont_use on $cell_type\n   because $cell_description"
    foreach cell_name $cell_type {
      set dont_use_collection [add_to_collection $dont_use_collection [get_lib_cells  */$cell_name -quiet]]
    }
  }

  foreach_in_collection  current_dont_use_cell $dont_use_collection {
    set_user_attribute -class lib_cell [get_lib_cells -quiet  $current_dont_use_cell] pt_dont_use true
  }
} else {
  P_msg_warn "Unsupported Synopsys tool '$::synopsys_program_name' for '[file tail [info script]]' script!  Skip!"
}


