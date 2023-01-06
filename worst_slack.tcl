# Script to report worst slack for all clock group

set_global timing_report_group_based_mode true
foreach_in_collection path [sort_collection [report_timing -max_slack 1000000 -collection] path_group] {

set size [sizeof_collection $path]
set path_group [get_property -quiet $path path_group_name]
set wns [get_property -quiet $path slack]
set view [get_property -quiet $path view_name]
puts "Clock group: $path_group View: $view WNS: $wns"

}
