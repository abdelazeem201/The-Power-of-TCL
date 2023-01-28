##############################################################################

#####################################
# List of procs used in script
# None
################################


## making the net names case insensitive to avoid false violation from LVS
define_name_rules standard_netnames -case_insensitive -type net

if {[info exists INTEL_STEP_CURR] && $INTEL_STEP_CURR != ""} {
  set change_name_log_file ./logs/${INTEL_STEP_CURR}.change_names.log
} else {
  set change_name_log_file ./logs/change_names.log
}


puts "==>INFORMATION: Running default verilog rule , check log file $change_name_log_file"
change_names -hierarchy -verbose -rules verilog >> $change_name_log_file

puts "==>INFORMATION: Running name rule 'standard_netnames_verilog', check log file $change_name_log_file"
change_names -hierarchy -verbose -rules standard_netnames >> $change_name_log_file


