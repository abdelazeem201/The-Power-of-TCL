#Script to find the number of logic levels (combinational) in a timing path or group of timing paths

proc num_of_logicLevel {max_paths} {
    set a [report_timing -max_paths $max_paths -collection]
    puts "Start Point \t\t\t End Point \t\t\t Instance Count"
    foreach_in_collection i $a {
        set StartPoint [get_object_name [get_property $i launching_point]]
        set EndPoint [get_object_name [get_property $i capturing_point]]
        set Size [sizeof_collection [get_property $i timing_points]]
        set InstCount [expr $Size/2]
        puts "$StartPoint \t $EndPoint \t $InstCount"
    }
}
