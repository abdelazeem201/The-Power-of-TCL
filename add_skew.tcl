#The timing reports from report_timing do not include the exact skew value. Having the skew value makes it easier to debug the timing path.

#The script provided in the Code section will calculate the skew value and add it to the report.

#!/usr/bin/tclsh
set timing_rpt [lindex $argv 0]

set read1 [open $timing_rpt r]
set out1 [ open $timing_rpt\.skew w]

set skew 0
set mode SETUP

puts "Saving $timing_rpt.skew timing report with Skew colum"
while {[gets $read1 line] >= 0} {
  if {[regexp "Other End Arrival Time" $line]} {
    set capture_clock_arrival [lindex $line end]
  }
  if {[regexp "Beginpoint Arrival Time" $line]} {
    set Begin_point_arrival [lindex $line end]
  }
  if {[regexp "\\+ Hold|\\- Setup" $line]} {
    set mode [lindex $line end-1]
  }
  if {[regexp "Beginpoint Arrival Time" $line]} {
    if {[regexp "Setup" $mode]} {
      set skew [expr $capture_clock_arrival - $Begin_point_arrival]
    } elseif { [regexp "Hold" $mode]} {
      set skew [expr $Begin_point_arrival - $capture_clock_arrival ]
    }
    puts $out1 $line
    puts $out1 " Skew = $skew"
  } else {
    puts $out1 $line
  }
}
close $read1
close $out1
