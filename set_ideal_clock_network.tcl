##############################################################################

# Set ideal network for clocks
foreach_in_collection mode [all_modes] {
  current_mode $mode
  set_ideal_network [all_fanout -clock_tree -flat]
}