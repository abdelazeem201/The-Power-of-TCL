# Script to report slack and difference between clock arrival time at launch and capture clocks
set a [report_timing -max_paths 4 -collection]
puts ""
puts "    Reporting Slack and Skew between paths"
puts ""
puts "\t StartPoint \t\t\t EndPoint \t\t\t Slack \t\t\t Skew"
puts ""

foreach_in_collection i $a {

set StartPoint [get_object_name [get_property $i launching_point]]
set EndPoint [get_object_name [get_property $i capturing_point]]
set l1 [get_property $i launching_clock_latency]
set l2 [get_property $i launching_clock_open_edge_time]
set launchClockTime [expr $l1 + $l2]
set c1 [get_property $i capturing_clock_latency]
set c2 [get_property $i capturing_clock_close_edge_time]
set captureClockTime [expr $c1 + $c2]
set Slack [get_property $i slack]
set Skew [expr $captureClockTime - $launchClockTime]
puts "$StartPoint \t $EndPoint \t $Slack \t $Skew"

}
