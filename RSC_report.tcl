redirect clock_sink.rpt {
    foreach_in_collection ck [all_clocks] {
        puts "Clock_Name No_of_register_sinks Sink_list"
        puts "#####################################"
    puts "[get_object_name $ck] [sizeof_collection [all_registers -clock $ck]] [get_object_name [all_registers -clock $ck]]\n"
    }
}
