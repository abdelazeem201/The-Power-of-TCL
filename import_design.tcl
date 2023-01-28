##############################################################################

if { [info exists INTEL_INPUT_NETLIST] && $INTEL_INPUT_NETLIST != "" } {
  set netlist $INTEL_INPUT_NETLIST
} else {
  #set netlist ./inputs/$INTEL_DESIGN_NAME.syn.vg
  #set netlist ./inputs/mkfpu.v
  set netlist $env(INTEL_ASIC)/asicflows/synopsys/apr/inputs/mkSoc.v 
}

if {[file exists $netlist] } {
  P_msg_info "Reading Verilog netlist from '$netlist' ..."
  read_verilog $netlist -top $INTEL_DESIGN_NAME

  if { $INTEL_UPF } {
    if { [info exists INTEL_INPUT_UPF] && $INTEL_INPUT_UPF != "" } {
      P_msg_info "Reading UPF intent from '$INTEL_INPUT_UPF' ..."
      load_upf $INTEL_INPUT_UPF
    } else {
      P_msg_info "Reading UPF intent from './inputs/$INTEL_DESIGN_NAME.syn.upf' ..."
      load_upf ./inputs/$INTEL_DESIGN_NAME.syn.upf
    }
    if { [info exists INTEL_UPF_VERSION] && $INTEL_UPF_VERSION >= 2.0 } {
      P_msg_info "Reading UPF 2.0 supply net mappings from './inputs/$INTEL_DESIGN_NAME.supply_net.upf' ..."
      load_upf ./inputs/$INTEL_DESIGN_NAME.supply_net.upf
    }
    commit_upf
  }

  link_block
} else {
  P_msg_fatal "Input verilog netlist '$netlist' not found. Exiting..."
}

if { [info exists INTEL_SPG_DEF] && $INTEL_SPG_DEF } {
  P_msg_info "Checking for SPG DEF file.."
  if {![file exists ./inputs/$INTEL_DESIGN_NAME.syn.def]} {
    P_msg_fatal "INTEL_SPG_DEF has been set to 1. Expecting def file ./inputs/$INTEL_DESIGN_NAME.syn.def for seed placement. Exiting..."
  } else {
    P_msg_info "SPG DEF file existence: ${INTEL_DESIGN_NAME}.syn.def exists. Will be used for seed placement."
  }
}

# Need to set parasitic tech names for TLU+ parasitic model files here in design because not set in NDM libs.
read_parasitic_tech -name max_mfill_tluplus -tlup $INTEL_MAX_TLUPLUS_EMUL_FILE -layermap $INTEL_TLUPLUS_MAP_FILE
read_parasitic_tech -name min_mfill_tluplus -tlup $INTEL_MIN_TLUPLUS_EMUL_FILE -layermap $INTEL_TLUPLUS_MAP_FILE
read_parasitic_tech -name max_tluplus -tlup $INTEL_MAX_TLUPLUS_FILE -layermap $INTEL_TLUPLUS_MAP_FILE
read_parasitic_tech -name min_tluplus -tlup $INTEL_MIN_TLUPLUS_FILE -layermap $INTEL_TLUPLUS_MAP_FILE

