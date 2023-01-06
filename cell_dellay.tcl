#Script to report cell delays above/below a specified value

#Use below script to get cell delays above 0.1 value. You can change the value based on your requirement. You can replace ">" with "<" if you need to report cell delay below a specific value.

foreach_in_collection timing_path [report_timing -collection -max_paths 10000 -max_slack 10] {
  foreach_in_collection tp [get_property $timing_path timing_points] {
    set delay [get_property $tp delay]
    if {$delay > 0.1} {
    puts "[get_property $tp hierarchical_name] [get_property $tp delay]"
  }
 }
}
