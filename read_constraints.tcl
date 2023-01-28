############################################################################

#############################
# List of procs used in this script
# None
############################


########################
# Design Constraints
########################
if {[file exists ./inputs/$INTEL_DESIGN_NAME.mcmm.tcl]} {
# expect to read in scenario based constraint files in <design>.mcmm.tcl so don't do anything here
} else {
  if {[info exists INTEL_SDC_FILE] && $INTEL_SDC_FILE==1} {
    if {[info exists INTEL_INPUT_SDC] && $INTEL_INPUT_SDC != ""} {
     read_sdc $INTEL_INPUT_SDC
    } elseif {[file exists $env(INTEL_ASIC)/asicflows/synopsys/apr/inputs/$INTEL_DESIGN_NAME.sdc]} {
#read_sdc /scratch/HCL/Bharath/Shakthi/mkSoc_oct12/output/mkfpu.sdc
#read_sdc /scratch/HCL/Bharath/Shakthi/Syn_part_V23_oct24/fpu/output/mkfpu.dc_compile_ultra_1.sdc
read_sdc $env(INTEL_ASIC)/asicflows/synopsys/apr/inputs/mkSoc.sdc
    } else {
      puts "==>FATAL: ./inputs/$INTEL_DESIGN_NAME.syn.sdc file does not exists... Exiting..."
      exit
    }
  } else {

  #CLOCKS
  #-------
    if {[file exists  ./inputs/constraints/$INTEL_DESIGN_NAME.clocks.tcl]} {
      puts "==>INFORMATION: Sourcing the $INTEL_DESIGN_NAME.clocks.tcl file"
      source -echo -verbose ./inputs/constraints/$INTEL_DESIGN_NAME.clocks.tcl
    } else {
      puts "==>FATAL: ./inputs/constraints/$INTEL_DESIGN_NAME.clocks.tcl file does not exists... Exiting..."
      exit
    }

    #IO, Loading Constraints, Timing Exception File
    #------------------------------------------------
    if {[file exists  ./inputs/constraints/$INTEL_DESIGN_NAME.constraints.tcl]} {
      puts "==>INFORMATION: Sourcing the design constraints file"
      source -echo -verbose ./inputs/constraints/$INTEL_DESIGN_NAME.constraints.tcl
    } else {
      puts "==>FATAL: ./inputs/constraints/$INTEL_DESIGN_NAME.constraints.tcl file does not exists... Exiting..."
      exit
    }
  }
}

################
#Read SAIF file
################

if {[info exists INTEL_SAIF] && $INTEL_SAIF==1} {
  foreach_in_collection scen [all_scenarios] {
    if {![info exists INTEL_SAIF_INSTANCE] || $INTEL_SAIF_INSTANCE == ""} {
      set INTEL_SAIF_INSTANCE $INTEL_DESIGN_NAME
      puts "==>INFORMATION: setting INTEL_SAIF_INSTANCE to $INTEL_DESIGN_NAME since user hasn't set INTEL_SAIF_INSTANCE varible"
    } else {
      puts "==>INFORMATION: INTEL_SAIF_INSTANCE has been set to $INTEL_SAIF_INSTANCE by the user"
    }
    set saif_file ./inputs/$INTEL_DESIGN_NAME.[get_object_name $scen].saif
    read_saif -path $INTEL_SAIF_INSTANCE -scenarios $scen $saif_file
    puts "==>INFORMATION: read_saif $INTEL_DESIGN_NAME.saif -path $INTEL_SAIF_INSTANCE"
  }
}

