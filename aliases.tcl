##############################################################################
### General Aliases
alias runicc  runADF
alias runicc2  runADF
alias rundc   runADF
alias runICC  runADF
alias runICC2  runADF
alias runDC   runADF
alias so      source
alias h       history
alias cls     sh clear
alias cdn     current_design
alias pv      printvar
alias source_if_exists P_source_if_exists
alias PS      P_source_if_exists
alias ps      P_source_if_exists

### Aliases for read
alias rdv     read_verilog
alias rdb     read_db
alias rdc     read_ddc

### Aliases for reports
alias rn      report_net -connections -verbose
alias rc      report_cell -connections -verbose
alias rtf     report_transitive_fanout
alias rtt     report_transitive_fanin
alias ra      report_attribute
alias rt      report_timing -nets -capacitance -transition_time -input_pins -nosplit -significant_digits 1
alias rt2     {rt -to}

### Aliases for constraints
alias sid     set_input_delay
alias sod     set_output_delay
alias set_mcp set_multicycle_path
alias set_fp  set_false_path

### Other aliases
alias gp      get_pins
alias ga      get_attribute
alias gn      get_nets
alias ac      all_connected
alias rmd     remove_design
alias ai      all_fanin -flat -to
alias ao      all_fanout -flat -from
alias afi     all_fanin -flat -start -to
alias afo     all_fanout -flat -end -from
alias cs      change_selection
alias rmb     remove_placement_keepout
alias gtp     get_timing_path


if { [P_is_PSYN] || [P_is_ICC] } {
  ### Aliases for Physical compiler
  alias rn   report_net -connections -verbose -physical -nosplit
  alias rc   report_cell -connections -verbose -physical -nosplit
  alias rt   report_timing -transition_time -nets -capacitance -input_pins -nosplit -physical -significant_digits 3
  alias rtns report_timing -transition_time -nets -capacitance -input_pins -nosplit -physical -significant_digits 3
  alias rtm  report_timing -transition_time -nets -capacitance -input_pins -nosplit -delay_type min -significant_digits 3 -physical
  alias rtf  report_transitive_fanout -nosplit -from
  alias rtt  report_transitive_fanin -nosplit -to
  alias gs   get_selection
  alias rct  report_clock_timing -type latency -verbose -nosplit -physical -nets
  alias gc   get_cells
  alias gfc  get_flat_cells
  alias gfn  get_flat_nets
  alias gfp  get_flat_pins
}

### Aliases for PrimeTime
if { [P_is_PT] } {
  alias rtM   report_timing -nosplit -nets -delay_type max -input_pins -significant_digits 0 -capacitance
  alias rt    report_timing -nosplit -nets -delay_type max -input_pins -significant_digits 0 -capacitance -transition_time
  alias rtm   report_timing -nosplit -nets -delay_type min -input_pins -significant_digits 0 -capacitance
  alias rtl   report_timing_location
  alias rnl   report_net_location
  alias rtMl  report_timing_location -delay_type max  -significant_digits 0 -pba path
  alias rtml  report_timing_location -delay_type min  -significant_digits 0 -pba path
  alias rtp   report_timing -nosplit -nets -delay_type min -input_pins -significant_digits 0 -path_type full_clock_expanded
  alias rtnM  report_timing -nosplit -nets -delay_type max -input_pins -significant_digits 0 -capacitance -crosstalk_delta
  alias rtnm  report_timing -nosplit -nets -delay_type min -input_pins -significant_digits 0 -capacitance -crosstalk_delta
  alias sc    sizeof_collection
  alias fc    filter_collection
  alias rfc   remove_from_collection
  alias rdc   report_delay_calculation -nosplit -cross
  alias rtf   report_transitive_fanout -nosplit -from
  alias rtt   report_transitive_fanin -nosplit -to
  alias gc    get_cells
  alias ga    get_attribute
  alias sad   set_annotated_delay
  alias ra    report_attribute -nosplit -application -class
  alias ai    all_fanin -flat -trace all -to
  alias ao    all_fanout -flat -trace all -from
  alias afia  all_fanin -flat -start -trace all -to
  alias afoa  all_fanout -flat -end -trace all -from
  alias get_flat_cells get_cells -hierarchical *
  alias gfc   get_flat_cells
}
