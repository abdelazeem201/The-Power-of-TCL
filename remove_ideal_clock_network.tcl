###############################################################################

foreach_in_collection mode [all_modes] {
  current_mode $mode
  set clk_fo_objs [all_fanout -clock_tree -flat]
  if { [sizeof_collection $clk_fo_objs] > 0 } {
    remove_ideal_network $clk_fo_objs
  } else {
    P_msg_warn "No clock fanout found to remove ideal network in mode '[get_object_name $mode]'!"
  }
  # Other non-clock ideal networks?
  remove_ideal_network -all
}
