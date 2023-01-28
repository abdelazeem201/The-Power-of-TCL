##############################################################################


################################################################################
# Procedure   : P_run_CheckDiskSpace
# Description : This script will check the use percentage and cautions the user

proc P_run_CheckDiskSpace { } {

#set threshold
  set lowLimit "95%"

  set perc [exec df -k . | awk {{print $4}} | sed -n "2,14 p"]

  #define condition
  if {$perc > $lowLimit} {
    echo "\n CAUTION: Available Disk Space is at $perc , Your disk space is approaching full and is less than the default low limits set. Please ensure sufficient diskspace to run complete APR flow on the design.\n"
  } else {
    echo "\n Available Disk Space is at $perc. Disk space is design dependant, continue to monitor the available space on your disk.\n"
  }

}


################################################################################

############################################################
# Procedure   : P_lsearch
# Input(s)    : ?mode? ;# Optional, can be "-glob", "-regexp", "-exact"
#                      ;# Default: -glob
#                list  ;# List to search
#                pattern ;# Search pattern
# Output(s)   : list ;# List containing all elements matching the pattern
# Help line   : Returns list containing all elements matching specified pattern
# Description : This is a "modified" lsearch command.  lsearch only returns
#               the index of the first element it finds in the list.  This
#               procedure finds all the elements matching the pattern
#               and returns all the elements as a list.
#               Default "mode" is "-glob"
#
# Example(s)  : <set list1 "My1 My2 Your1 Your2 SoMe SOME"
#               <T_lsearch $list1 "My1"
#               >"My1"
#
#               <T_lsearch $list1 "My"
#               >""
#               Note that "My" does not match anything, however "My*"
#               will match.
#
#               <T_lsearch $list1 "My*"
#               >"My1 My2"
#
#               <T_lsearch $list1 "*2"
#               >"My2 Your2"
#
#               <T_lsearch $list1 "Some"
#               >"My2 Your2"
#
#               <T_lsearch -regexp $list1 "^(S)+(\[oO])+"
#               >"SoMe SOME"
#
# Note(s)     :
#
proc P_lsearch { args } {
  set return_val ""

  set convert ""

  # Get all the arguments
  set mode ""
  set list ""
  set pattern ""
  if {[regexp "^(-)" $args] == 1} {
    set mode [lindex $args 0]
    set i 1
  } else {
    set mode "-glob"
    set i 0
  }
  set list [lindex $args $i]
  set pattern [lindex $args [incr i]]

  # Build the list of elements that match the pattern
  # Have to do the following cause TCL will not accept "" as
  # the mode
  if {$convert != ""} {
    set index [lsearch $mode [string $convert $list] [string $convert $pattern]]
  } else {
    set index [lsearch $mode $list $pattern]
  }
  while {$index >= 0} {
  # Append the element found to the return list
    lappend return_val [lindex $list $index]
    # Remove the element from the original list
    set list [lrange $list [expr $index + 1] end]
    if {$convert != ""} {
      set index [lsearch $mode [string $convert $list] [string $convert $pattern]]
    } else {
      set index [lsearch $mode $list $pattern]
    }
  }
  return $return_val
}

############################################################
# Procedure   : P_lminus
# Input(s)    : list1  ;# First list
#               list2  ;# Second list
# Output(s)   : list
# Help line   : Takes out list2 elements from list1, i.e. list1 - list2
# Description : For each element in list2, this function finds
#               exact matching element in list1 and removes it.
#               It returns the new list1 with all list2 elements
#               removed.
# Example(s)  : <set list1 "a b c"
#               <set list2 "d c"
#               <T_lminus $list1 $list2
#               >"a b"
# Note(s)     :
proc P_lminus { args } {
  set list1 [lindex $args 0]
  set list2 [lindex $args 1]
  set return_list $list1
  set found ""
  set element ""
  foreach element $list2 {
    set found [lsearch -exact $return_list $element]
    if {$found != -1} {
      set return_list [lreplace $return_list $found $found]
    }
  }
  return $return_list
}


############################################################
# Procedure   : P_lminus_r (REVERSE OF P_lminus)
# Input(s)    : list1  ;# First list
#               list2  ;# Second list
# Output(s)   : list
# Help line   : Takes out list2 elements from list1, i.e. list1 - list2 IN REVERSE
# Description : For each element in list2, this function finds
#               exact matching element in list1 and removes it.
#               It returns the new list1 with all list2 elements
#               removed.
# Example(s)  : <set list1 "a b c"
#               <set list2 "d c"
#               <T_lminus $list1 $list2
#               >"a b"
# Note(s)     :
proc P_lminus_r {args} {

  set list1 [lindex $args 0]
  set list2 [lindex $args 1]
  set return_list $list1
  set found ""
  set element ""
  foreach element $list2 {
    set found [lindex [lsearch -all -exact $return_list $element] end]
    if {$found != -1} {
      set return_list [lreplace $return_list $found $found]
    }
  }
  return $return_list
}

############################################################
# Procedure   : P_true
# Input(s)    : value ;# Can be anything!
# Output(s)   : 0 ;# when value = false or 0 or ""
#               1 ;# when value = true or 1 or non-empty string
#               $value ;# when value is numeric and non-zero
# Help line   : Returns 0 or 1 or $value depeninding on contents of value
# Description : Returns 0 when value is "false" or "0" or ""
#               Returns 1 when value is "true" or non-empty string
#               Returns $value when value is numeric and non-zero
# Example(s)  : <set a 4
#               <T_true $a
#               >4
#
#               <set b ""
#               <if {[P_true $b]} {
#               <  puts "List not empty!"
#               <} else {
#               <  puts "nothing!"
#               <}
#               >nothing!
#
# Note(s)     :
#
proc P_true { args } {

  set value [lindex $args 0]

  # numeric
  if {[string match {[0-9]} $value]} {
    if {$value != 0} {
      return $value
    } else {
      return 0
    }
  } elseif {$value == "false" || $value == ""} {
    return 0
  } elseif {$value == "true" || $value != ""} {
    return 1
  }
}

############################################################
# Procedure   : P_eval
# Input(s)    : cmd
# Output(s)   : none
# Help line   : Returns 0/1 based on successful execution of the
#               Tcl command "cmd".  Prints error msg to stderr if it fails.
# Description : Executed the "cmd" if it is a valid tcl command.
#               If an error is produced during execution,
#               gives out the command at execution and the
#               error message.
# Example(s)  : <if {[P_eval {puts some}]} {
#               < puts "ok!"
#               <}
#               >ok!
#
#               <if {[P_eval {puts some some}]} {
#               < puts "ok!"
#               <}
#               >T_eval: Error executing: "puts some some"
#               >can not find channel named "some"
#
# Note(s)     :
#
proc P_eval { args } {

  set cmd [lindex $args 0]
  set success 1
  set error_msg ""
  set catch_val 0

  if {[info complete $cmd]} {
    set catch_val [catch {eval $cmd} error_msg]

    # puts "Executing $cmd"
    if {$catch_val == 1} {
      puts stderr "T_eval-ERROR: Error executing: \"$cmd\""
      puts stderr "T_eval-ERROR: $error_msg"
      set success 0
    }
  } else {
    puts stderr "T_eval-ERROR: \"$cmd\" is not a complete tcl command"
    set success 0
  }

  return $success
}



############################################################
# Procedure   : P_lcommon
# Input(s)    : list1  ;# First list
#               list2  ;# Second list
# Output(s)   : list
# Description : Returns a list of common elements in both lists
#
proc P_lcommon { args } {
  set list1 [lindex $args 0]
  set list2 [lindex $args 1]

  set return_list ""
  if { [llength $list1] > [llength $list2] } {
    set nlist1 $list2
    set nlist2 $list1
  } else {
    set nlist1 $list1
    set nlist2 $list2
  }
  foreach element $nlist1 {
    set add [expr [lsearch -exact $nlist2 $element] != -1]
    set redundunt [expr [lsearch -exact $return_list $element] != -1]
    if {[expr $add && !$redundunt] } {
      lappend return_list $element
    }
  }
  return $return_list
}


############################################################
# Procedure   : P_sel2list
# Input(s)    : selection ;# Any selection
# Output(s)   : list ;# Selection contents in list form
# Help line   : Converts PrimeTime/DesignCompiler TCL selection to list
# Description : Converts PrimeTime/DesignCompiler TCL selection to list
#               Looks at global variable synopsys_program_name to figure
#               out which program is currently using this proc.
#               Only accepts one selection!
#
# Example(s)  :  <set some [get_cell *]
#                >CELL1 CELL1/CELL11
#                <set some
#                >_sel445
#                <set lll [P_sel2list $some]
#                <set lll
#                >CELL1 CELL1/CELL11
#
# Note(s)     : - global variable synopsys_program_name has to exist and
#                 has to be a non-empty string.
#               - Only accepts one selection
#
proc P_sel2list { args } {
  global synopsys_program_name

  set sel [lindex $args 0]

  if {[info exists synopsys_program_name] && \
      $synopsys_program_name != ""} {

    if {[llength $sel] == 1} {
      if {[string match "_sel*" $sel] == 1} {
      # get_attribute works for a single object only in PT!!!
      #if {$synopsys_program_name == "pt_shell" || \
      #    $synopsys_program_name == "primetime"} {
        set return_val ""
        foreach_in_collection ss $sel {
          lappend return_val [get_object_name $ss]
        }
        #} else {
        # This is not working!  Maybe a Synopsys bug!
        #set return_val [get_attribute $sel full_name]
        #}
        return $return_val
      } else {
        return $sel
      }
    } else {
      return $sel
    }
  } else {
    P_msg_warn "This procedure will only work from within Synopsys tools"
    return $args
  }
}
