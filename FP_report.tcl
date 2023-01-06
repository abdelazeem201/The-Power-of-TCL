# Script to report the endpoint, the startpoint and slack of top 1000 failing paths

set rpt [report_timing -max_paths 1000 -max_slack 0 -collection]
foreach_in_collection r $rpt {
    puts "Endpoint: [get_property [get_property $r capturing_point] hierarchical_name] \t Startpoint: [get_property [get_property $r launching_point] hierarchical_name] \t Slack: [get_property $r slack]"
}
