set fp1 [open "trans_cell.name" r]
foreach i [split [read $fp1] \n] {
set l [get_object_name [get_lib_cells -quiet -of_objects [get_cell -of $i]]]
set sub [regsub -all {l1n[0-9][0-9]} $l l1n*]
#puts $sub
set libs [get_object_name [get_lib_cells -quiet $sub]]
#set mod [regsub -all b15_ln/ $l ""] 
set index [lsearch $libs $l]
#puts $index

set new_lib [lindex $libs [expr $index +1]]
#puts [get_object_name $new_lib]
puts "size_cell [get_object_name [get_cells -of $i]] [get_object_name $new_lib]"
}



