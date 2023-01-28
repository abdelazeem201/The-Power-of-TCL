set list1 [get_attribute -objects "[get_lib_cells {b15_nn*/* b15_hn*/*}]" -name name]

set list2 [get_attribute -objects "[get_lib_cells {b15_nn*/b15zdnn* b15_nn*/b15qfd* b15_nn*/b15qgbar* b15_hn*/b15qbn* b15_nn*/b15ztpn* b15_nn*/b15ydpd* b15_nn*/b15qgbdc*}]" -name name]

foreach elem $list1 {set x($elem) 1}
foreach elem $list2 {unset x($elem)}
set custom_dont_use_list2 [array names x]
set custom_dont_use_list {}

foreach current_variable $custom_dont_use_list2 {

	lappend custom_dont_use_list "b15_*/$current_variable"

}

