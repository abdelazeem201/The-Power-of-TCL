# Script to report logics between reg-to-reg. This script can be modified for different path groups:
group_path -from [all_registers] -to [all_registers] -name GRP
set a [report_timing -path_group GRP -max_paths 100 -collection]
foreach_in_collection i $a {
    set StartPoint [get_object_name [get_property $i launching_point]]
    set EndPoint [get_object_name [get_property $i capturing_point]]
    set points [get_property $i timing_points]
    puts ""
    puts "Timing points between $StartPoint and $EndPoint"
    puts ""
    foreach_in_collection j $points {
        set p [get_object_name [get_property $j pin]]
        puts $p
    }
}
