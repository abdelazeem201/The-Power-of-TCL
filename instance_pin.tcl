# To return all the instance pins that are used in the path 
set paths [report_timing -collection]  
foreach_in_collection path $paths {
    puts ""
    set timingPoints [get_property $path timing_points]
    foreach_in_collection point $timingPoints {
            set pinPtr [get_property $point pin]
              set pin [get_object_name $pinPtr]                  
        puts $pin
    }
}
