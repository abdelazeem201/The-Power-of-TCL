##############################################################################
# This file sets up procedures used by the APR flows                         #
# This file is sectioned according to steps and tcl files which use them     #
##############################################################################

##########################################
# Common Procedures
##########################################
# P_msg_info: Used by all flows to provide info messages

if {[info exists synopsys_program_name]} {
  create_command_group {flow_procs}
}

########################################################################################################
# Procedure   : P_get_power_domain_info
# Description : This proc is used to query power domain information from report_power_domain report

proc P_get_power_domain_info { args} {
  parse_proc_arguments -args $args flag

  redirect -variable rpt_pd  {report_power_domain $flag(-pwr_domain)}
  set ps_search_line [regexp -inline -lineanchor -linestop -all {^Power Switch\s+:\s+(\S+)$} $rpt_pd]
  set num_ps [expr [llength $ps_search_line] / 2]
  set va [lindex [regexp -inline -lineanchor -linestop {^Voltage Area\s+:\s+(\S+)$} $rpt_pd] 1]

  #Storing Power Switch Info
  if {[info exists flag(-ps_name)]} {
  set ps_array [list ]
  set search_line [regexp -inline -lineanchor -linestop -all {.*} $rpt_pd]
  set index [expr [lsearch $search_line *$flag(-ps_name)*] + 1]
  set search 1
  while {$search == 1} {
    set line [lindex $search_line $index]
    if {$line == ""} {
      incr index
      continue
    } elseif {[regexp -inline {^\s+} $line] == ""} {
      set search 0
    } else {
      lappend ps_array $line
      incr index
    }
  }
}

switch -- $flag(-query) {
  num_ps {
    set result $num_ps
  }
  ps_names {
    set index 1
    set result [list ]
    while {$index < [expr $num_ps * 2]} {
      lappend result [lindex $ps_search_line $index]
      incr index 2
    }
  }
  ps_enable_control_a {
    set control_line [regexp -inline {\s+Control\(s\)\s+:\s+(\S+)\((\S+)\)} [lindex [lsearch -inline -all $ps_array *Control*] 0]]
    set result [lindex $control_line 1]
  }
  ps_enable_control_b {
    set control_line [regexp -inline {\s+Control\(s\)\s+:\s+(\S+)\((\S+)\),\s+(\S+)\((\S+)\)} [lindex [lsearch -inline -all $ps_array *Control*] 0]]
    set result [lindex $control_line 3]
  }
  ps_enable_control_a_refpin {
    set control_line [regexp -inline {\s+Control\(s\)\s+:\s+(\S+)\((\S+)\)} [lindex [lsearch -inline -all $ps_array *Control*] 0]]
    set result [lindex $control_line 2]
  }
  ps_enable_control_b_refpin {
    set control_line [regexp -inline {\s+Control\(s\)\s+:\s+(\S+)\((\S+)\),\s+(\S+)\((\S+)\)} [lindex [lsearch -inline -all $ps_array *Control*] 0]]
    set result [lindex $control_line 4]
  }
  ps_ack_port_a {
    set ack_line [regexp -inline {\s+Ack\(s\)\s+:\s+(\S+)\((\S+)\)} [lindex [lsearch -inline -all $ps_array *Ack*] 0]]
    set result [lindex $ack_line 1]
  }
  ps_ack_port_b {
    set ack_line [regexp -inline {\s+Ack\(s\)\s+:\s+(\S+)\((\S+)\),\s+(\S+)\((\S+)\)} [lindex [lsearch -inline -all $ps_array *Ack*] 0]]
    set result [lindex $ack_line 3]
  }
  ps_ack_port_a_refpin {
    set ack_line [regexp -inline {\s+Ack\(s\)\s+:\s+(\S+)\((\S+)\)} [lindex [lsearch -inline -all $ps_array *Ack*] 0]]
    set result [lindex $ack_line 2]
  }
  ps_ack_port_b_refpin {
    set ack_line [regexp -inline {\s+Ack\(s\)\s+:\s+(\S+)\((\S+)\),\s+(\S+)\((\S+)\)} [lindex [lsearch -inline -all $ps_array *Ack*] 0]]
    set result [lindex $ack_line 4]
  }
  primary_pwr {
    if {$num_ps == 0} {
      set result [lindex [split [get_object_name [get_attribute [get_voltage_areas $va] power_net]] /] end]
    } else {
      set result [get_object_name [get_attribute [get_voltage_areas $va] power_net]]
    }
  }
  aon_pwr {
    set result [lindex [split [lindex [regexp -inline -lineanchor -linestop -all {^\s+Input\(s\)\s+:\s+(\S+)$} [lindex [lsearch -inline -all $ps_array *Input*] 0]] 1] /] end]
  }
  gnd {
    set result [lindex [split [get_object_name [get_attribute [get_voltage_areas $va] ground_net]] /] end]
  }
  voltage_area {
    set result $va
  }
}
return $result
}

define_proc_attributes P_get_power_domain_info \
  -info "Query Power Domain Info" \
  -define_args {
    {"-pwr_domain" "Power Domain to query" "" string required}
    {"-query" "Info to query" "" one_of_string {optional value_help {values {num_ps ps_names ps_enable_control_a ps_enable_control_b ps_enable_control_a_refpin ps_enable_control_b_refpin ps_ack_port_a ps_ack_port_b ps_ack_port_a_refpin ps_ack_port_b_refpin primary_pwr aon_pwr gnd voltage_area}}}}
    {"-ps_name" "Power Switch Name" "" string optional}
}

########################################################################################################
# Procedure   : P_get_va_coordinates
# Description : This proc returns the boundary of a voltage area shape in the clock wise direction starting
#               from the lower left corner.

proc P_get_va_coordinates { args} {
  parse_proc_arguments -args $args flag

  set va_shape_name $flag(-va_shape_name)
  set va_shape [get_voltage_area_shapes $va_shape_name]
  set poly_list [get_attribute [create_poly_rect -boundary [get_attribute $va_shape boundary]] point_list]
  #Re-order poly_list if necessary
  set va_bbox_lly [lindex [get_attribute [create_poly_rect -boundary [get_attribute $va_shape boundary]] bbox] 0 1]
  set curr_index -1
  set index -1
  foreach pt $poly_list {
    incr curr_index
    set pt_x [lindex $pt 0]
    set pt_y [lindex $pt 1]
    if {[expr $pt_y == $va_bbox_lly]} {
      if {[info exists prev_x]} {
        if {[expr $pt_x < $prev_x]} {
          set index $curr_index
        }
      } else {
        set prev_x $pt_x
        set index $curr_index
      }
    }
  }

  if {$index > -1} {
    set list_1 [lrange $poly_list $index end]
    set list_2 [lrange $poly_list 0 $index-1]
    set output "$list_1 $list_2"
    set begin_pt [lindex $output 0]
    set output "$output [list $begin_pt]"
    return $output
  }
}

define_proc_attributes P_get_va_coordinates \
  -info "Return voltage area shape coordinates" \
  -define_args {
    {"-va_shape_name" "Name of voltage area shape" "" string required}
}


########################################
# Procedure : report_lib_cell_purpose

if { [info commands report_lib_cell_purpose] == {} } {
  proc report_lib_cell_purpose args {
    parse_proc_arguments -args $args opts
    set proc_name [namespace tail [lindex [info level 0] 0]]
    if { [info exists opts(-lib_cells)] } {
      if { [string match _sel* $opts(-lib_cells)] } {
        if { [set obj_class [lsort -unique [get_attribute -objects $opts(-lib_cells) -name object_class]]] != {lib_cell} } {
          error "$proc_name: Invalid object class '$obj_class' of collection '[get_object_name $opts(-lib_cells)]' for -lib_cells option!  Expect 'lib_cell' object class only!"
        } else {
          set lib_cells $opts(-lib_cells)
        }
      } else {
        set lib_cells {}
        foreach lib_cell_name $opts(-lib_cells) {
          set lcells [get_lib_cells -quiet $lib_cell_name]
          if { [sizeof_collection $lcells] == 0 } {
            error "$proc_name: Failed to find any lib cell matching name '$lib_cell_name' by -lib_cells option in design!"
          } else {
            append_to_collection -unique lib_cells $lcells
          }
        }
      }
    } else {
      set lib_cells [sort_collection -dictionary [get_lib_cells -quiet */*] full_name]
    }
    set col_fmt {%-48s %-12s %-12s %-26s %-30s %-30s}
    echo [format $col_fmt {Lib cell} dont_touch dont_use included_purposes excluded_purposes valid_purposes]
    echo [format $col_fmt  --------  ---------- -------- ----------------- ----------------- --------------]
    set_message_info -id ATTR-11 -limit 1
    set lib_cell_num 0
    foreach_in_collection lib_cell $lib_cells {
      incr lib_cell_num
      set line_txt [get_object_name $lib_cell]
      foreach attr {dont_touch dont_use included_purposes excluded_purposes valid_purposes} {
        lappend line_txt [list [get_attribute -quiet -objects $lib_cell -name $attr]]
      }
      echo [format $col_fmt {*}$line_txt]
    }
    echo "Total $lib_cell_num lib cells."
    set_message_info -id ATTR-11 -limit 0
  }

  define_proc_attributes report_lib_cell_purpose \
    -info "Report purpose related attributes (dont_touch, dont_use & *_purposes) of lib cells set by set_lib_cell_purpose." \
    -define_args {
      {-lib_cells "Lib cells to report purpose related attributes. Default: All lib cells" list_or_collection list optional}
  }
}

