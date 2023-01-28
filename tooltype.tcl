##############################################################################
#
# Procedures to  return 1/0 if running under certain tools.
# Enable these for ALL tools so if/then logic can be used no matter where
#

proc P_is_synopsys_tool { args } {
  parse_proc_arguments -args $args arg

  global synopsys_program_name
  global sh_product_version
  global INTEL_SYNOPSYS_PROGRAM_SUITE

  if {![info exists INTEL_SYNOPSYS_PROGRAM_SUITE]} {
    set INTEL_SYNOPSYS_PROGRAM_SUITE(DC)   {dc_shell design_vision design_analyzer de_shell}
    set INTEL_SYNOPSYS_PROGRAM_SUITE(PT)   {pt_shell primetime}
    set INTEL_SYNOPSYS_PROGRAM_SUITE(PSYN) {psyn_shell psyn_gui}
    set INTEL_SYNOPSYS_PROGRAM_SUITE(ICC)  {icc_shell}
    set INTEL_SYNOPSYS_PROGRAM_SUITE(ICC2)  {icc2_shell}
  }

  if {[info exists synopsys_program_name] && $synopsys_program_name != ""} {
  # Valid tool name?
    if {[lsearch -exact [array names INTEL_SYNOPSYS_PROGRAM_SUITE] $arg(tool)] == -1} {
      P_warning "Tool '$arg(tool)' not programmed in 'INTEL_SYNOPSYS_PROGRAM_SUITE'"
      return 0
    }
    # Does synopsys_program_name match the programmed strings?
    if {[lsearch -exact $INTEL_SYNOPSYS_PROGRAM_SUITE($arg(tool)) $synopsys_program_name] == -1} {
      return 0
    }
    # If the version is given, does it match current version?
    if {[info exists sh_product_version] && \
        [info exists arg(version)]} {
      if {![string match $arg(version) $sh_product_version]} {
        return 0
      }
    }
    # All checks passed, return 1
    return 1
  } else {
    return 0
  }
  return 1
}
define_proc_attributes P_is_synopsys_tool \
  -info "Returns 1 if procedure was executed within the given Synopsys tool & version, 0 otherwise" \
  -define_args {
    {tool "Name of synopsys tool (as programmed in 'INTEL_SYNOPSYS_PROGRAM_SUITE')" toolname string required}
    {version "Version of synopsys tool"                                        version  string optional}
}


proc P_is_DC { args } {

  set tool_name "DC"
  parse_proc_arguments -args $args arg
  if {[info exists arg(version)]} {
    return [P_is_synopsys_tool $tool_name $arg(version)]
  } else {
    return [P_is_synopsys_tool $tool_name]
  }
}
define_proc_attributes P_is_DC \
  -info "Returns 1 if current Synopsys tool is specified version (optional) of Design-Compiler/Design-Vision/Design-Analyzer, 0 otherwise" \
  -define_args {
    {version "Version of DC"                                                   version  string optional}
}


proc P_is_PT { args } {
  set tool_name "PT"
  parse_proc_arguments -args $args arg
  if {[info exists arg(version)]} {
    return [P_is_synopsys_tool $tool_name $arg(version)]
  } else {
    return [P_is_synopsys_tool $tool_name]
  }
}
define_proc_attributes P_is_PT \
  -info "Returns 1 if current Synopsys tool is specified version (optional) of PrimeTime, 0 otherwise" \
  -define_args {
    {version "Version of PT"                                                   version  string optional}
}


proc P_is_PSYN { args } {
  set tool_name "PSYN"
  parse_proc_arguments -args $args arg
  if {[info exists arg(version)]} {
    return [P_is_synopsys_tool $tool_name $arg(version)]
  } else {
    return [P_is_synopsys_tool $tool_name]
  }
}
define_proc_attributes P_is_PSYN \
  -info "Returns 1 if current Synopsys tool is specified version (optional) of Physical-Compiler, 0 otherwise" \
  -define_args {
    {version "Version of PSYN"                                                   version  string optional}
}

proc P_is_PC { args } {
  return [P_is_PSYN $args]
}


# Command to check if you are in icc_shell
proc P_is_ICC { args } {
  set tool_name "ICC"
  parse_proc_arguments -args $args arg

  if {[info exists arg(version)]} {
    return [P_is_synopsys_tool $tool_name $arg(version)]
  } else {
    return [P_is_synopsys_tool $tool_name]
  }
}
define_proc_attributes P_is_ICC \
  -info "Returns 1 if current Synopsys tool is specified version (optional) of IC-Compiler, 0 otherwise" \
  -define_args {
    {version "Version of ICC"                                                   version  string optional}
}

# Command to check if you are in icc_shell
proc P_is_ICC2 { args } {
  set tool_name "ICC2"
  parse_proc_arguments -args $args arg

  if {[info exists arg(version)]} {
    return [P_is_synopsys_tool $tool_name $arg(version)]
  } else {
    return [P_is_synopsys_tool $tool_name]
  }
}
define_proc_attributes P_is_ICC2 \
  -info "Returns 1 if current Synopsys tool is specified version (optional) of IC-Compiler, 0 otherwise" \
  -define_args {
    {version "Version of ICC"                                                   version  string optional}
}

# some synopsys tool (don't care which)
proc P_is_SNPS { } {
  global sh_product_version
  if {[info exists sh_product_version]} {
    return 1
  } else {
    return 0
  }
}

proc P_is_ENCOUNTER { } {
  global encounterVersion
  if {[info exists encounterVersion]} {
    return 1
  } else {
    return 0
  }
}
proc P_is_FE { } {
  return [P_is_ENCOUNTER]
}

