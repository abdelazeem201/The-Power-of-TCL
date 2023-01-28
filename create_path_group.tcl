##############################################################################

###################################
# List of procs used in this script
# None
###############################

#------------------------
#Create Paths groups
#-----------------------

set nonclockports [all_inputs]
foreach_in_collection ck [all_clocks] {
  redirect /dev/null { set nonclockports [remove_from_collection $nonclockports [ get_ports [ get_object_name $ck ]]] }
}
redirect  /dev/null {group_path -name INPUTS -from $nonclockports}

group_path -name OUTPUTS -to [all_outputs]
group_path -name COMB -from [all_inputs] -to [all_outputs]

if {[sizeof_collection [all_registers]] !=0} {
  group_path -name REG2REG -from [all_registers] -to [all_registers]
}

if {[info exists INTEL_HARD_MACRO_NAME] && $INTEL_HARD_MACRO_NAME != ""} {
  set hard_macro_cells ""
  set mc_pin  ""
  foreach hard_macro_name $INTEL_HARD_MACRO_NAME {
    set hard_macro_cells [get_attribute  [get_cells -hierarchical -quiet -filter ref_name==$hard_macro_name] full_name]
    foreach hard_macro_cell $hard_macro_cells {
      set mc_pin [add_to_collection $mc_pin [get_pins -quiet ${hard_macro_cell}/* ]]
    }
  }
  group_path -name MACRO -from $mc_pin -to  [all_registers]
  group_path -name MACRO -from  [all_registers]  -to $mc_pin
}



