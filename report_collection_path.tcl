#*************************************************************************#
# DISCLAIMER: The code is provided for EDA users                          #
# to use at their own risk. The code may require modification to          #
# satisfy the requirements of any user. The code and any modifications    #
# to the code may not be compatible with current or future versions of    #
# Cadence products. THE CODE IS PROVIDED \"AS IS\" AND WITH NO WARRANTIES,#
# INCLUDING WITHOUT LIMITATION ANY EXPRESS WARRANTIES OR IMPLIED          #
# WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.          #
#*************************************************************************#

  foreach_in_collection path $paths {
  set startPointPtr [get_property $path launching_point]
  set startPointName [get_object_name $startPointPtr]
  set launchingClockLatency [get_property $path launching_clock_latency]
  Puts ""
  Puts "START POINT: $startPointName"
  Puts "Begin Point Arrival Time: $launchingClockLatency"
  #
  # Report the end point and its latency.
  #
  set endPointPtr [get_property $path capturing_point]
  set endPointName [get_object_name $endPointPtr]
  set capturingClockLatency [get_property $path capturing_clock_latency]
 
  Puts "END POINT: $endPointName"
  Puts "Other End Arrival Time: $capturingClockLatency"
 
  #
  # Report the setup, uncertainty, required time and slack for the path.
  #
  set setup [get_property $path setup]
  Puts ""
  Puts "Setup: $setup"
 
  set uncertainty [get_property $path clock_uncertainty]
  Puts "Uncertainty: $uncertainty"
 
  set requiredTime [get_property $path required_time]
  Puts "Required Time: $requiredTime"
 
  set slack [get_property $path slack]
  Puts "Slack: $slack"
  Puts ""
 
  #
  # Report details of the path by walking through each timing point. Note the timing points are a collection.
  #
 
  # Store timing points collection to $timingPoints.
  set timingPoints [get_property $path timing_points]
 
  # Print header.
  Puts "  +----------+--------------------------------+---------+-------+-------+--------+----------+----------+"
  Puts "[format "  | %8s | %30s | %7s | %5s | %5s | %6s | %8s | %8s |" instance arc cell slew load fanout delay arrival]"
  Puts "  +----------+--------------------------------+---------+-------+-------+--------+----------+----------+"
 
  # Variable to see if we're on the first point.
  set pointNum 1
 
  #
  # Walk through each timing point
  #
  foreach_in_collection point $timingPoints {
    set arrival [get_property $point arrival]
    set pinPtr [get_property $point pin]
    set pin [get_object_name $pinPtr]
    set direction [get_property $pinPtr direction]
    set instPtr [get_cells -of_objects $pin]
    set cell [get_property $instPtr ref_lib_cell_name]
    set inst [get_object_name $instPtr]
    set net [get_property $pinPtr net_name]
    set slew [get_property $point slew]
    set transition_type [get_property $point transition_type]
    #
    # Print timing information for each ouptut pin
    #
    if {$direction == "out"} {
      set load [get_property [get_nets $net] capacitance_max]
      set fanout [get_property $pinPtr fanout]
      if {$transition_type == "fall"} {
        set maxDelay [get_property [get_arcs -from $prevPoint -to $pin] delay_max_fall]
      } else {
        set maxDelay [get_property [get_arcs -from $prevPoint -to $pin] delay_max_rise]
      }
      Puts "[format "  | %8s | %6s (%4s) -> %6s (%4s) | %7s | %5s | %5s | %6s | %8s | %8s |" $inst $prevPoint $prevTranType $pin $transition_type $cell $slew $load $fanout $maxDelay $arrival]"
    }
    #
    # Print timing information for the first point
    #
    if {$pointNum == 1} {
      set required [expr $requiredTime - $arrival]
      set load [get_property [get_nets $net] capacitance_max]
      set fanout [get_property $pinPtr fanout]
      Puts "[format "  | %8s | %6s (%4s) %17s| %7s | %5s | %5s | %6s | %8s | %8s |" $inst $pin $transition_type "" "" $slew $load $fanout "" $arrival]"
    } else {
    #
    # Store points to report final timing arc
    #
      set point1 $prevPoint
      set point2 $pin
    }
 
    #
    # Update variables
    #
    set pointNum [expr $pointNum + 1]
    set prevPoint $pin
    set prevArrival $arrival
    set prevTranType $transition_type
  }
  #
  # Print end point timing information
  #
  set load [get_property [get_nets $net] capacitance_max]
  set fanout [get_property $pinPtr fanout]
  if {$transition_type == "fall"} {
    set maxDelay [get_property [get_arcs -from $point1 -to $point2] delay_max_fall]
  } else {
    set maxDelay [get_property [get_arcs -from $point1 -to $point2] delay_max_rise]
  }
  Puts "[format "  | %8s | %6s (%4s) %16s | %7s | %5s | %5s | %6s | %8s | %8s |" $inst $pin $transition_type "" $cell $slew $load "" $maxDelay $arrival]"
  Puts " 
   #+----------+--------------------------------+---------+-------+-------+--------+-----#-----+----------+"
   }
  ##################################################################
  # End Script
  ##################################################################
