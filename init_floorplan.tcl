##############################################################################
# Script: init_floorplan.tcl
# Description: initial floorplan based on user specified parameters
# List of procs used by this script
# 1. P_msg_error
# 2. P_msg_info
# 3. P_msg_warn

################################################################################################
# If $INTEL_FP_INPUT == DEF , inputs/floorplan/$INTEL_DESIGN_NAME.floorplan.def must contain:
# DIEAREA: Defines partition size (supports rectilinear shapes)
# COMPONENTS: Defines macro locations.  If no macros in the design, ignore.
# PINS: Defines locations of input and output ports
# Any TRACKS or ROW is ignored and reset.
################################################################################################
# If $INTEL_FP_INPUT  == FP_TCL, inputs/floorplan/$INTEL_DESIGN_NAME.floorplan.tcl must contain:
# create_boundary or create_die_area: Defines partition size (supports rectilinear shapes)
# create_voltage_area(optional): for UPF designs
# set_attribute <macro> orientation|origin|is_placed...: Defines macro locations.  If no macro in the design, ignore.
# set_attribute <terminal> bbox|layer|access_direction...: Defines locations of input and output ports
# Any create_track or add_row is ignored and reset.
#################################################################################################

######################################################
# Create floorplan according to input type defined
######################################################
if { [info exists INTEL_DESIGN_WIDTH] || [info exists INTEL_DESIGN_HEIGHT] } {
  P_msg_fatal "Variables INTEL_DESIGN_WIDTH & INTEL_DESIGN_HEIGHT have been obsoleted and replaced by INTEL_FP_BOUNDARY var!  For rectangular boundary, set INTEL_FP_BOUNDARY {{0 0} {$INTEL_DESIGN_WIDTH $INTEL_DESIGN_HEIGHT}} in 'block_setup.tcl' file."
}

if { [info exists INTEL_FP_INPUT] && $INTEL_FP_INPUT ne ""} {
  if { $INTEL_FP_INPUT eq {DEF} } {
    if { [info exists INTEL_INPUT_DEF] } {
      P_msg_info "Reading floorplan of input format '$INTEL_FP_INPUT' from '$INTEL_INPUT_DEF' ..."
      read_def -add_def_only_objects all $INTEL_INPUT_DEF
    } else {
      P_msg_info "Reading floorplan of input format '$INTEL_FP_INPUT' from './inputs/floorplan/${INTEL_DESIGN_NAME}.floorplan.def' ..."
      read_def -add_def_only_objects all ./inputs/floorplan/${INTEL_DESIGN_NAME}.floorplan.def
    }
  } elseif { $INTEL_FP_INPUT eq {FP_TCL} } {
    P_msg_info "Reading floorplan of input format '$INTEL_FP_INPUT' from './inputs/floorplan/${INTEL_DESIGN_NAME}.floorplan.tcl' ..."
    source ./inputs/floorplan/${INTEL_DESIGN_NAME}.floorplan.tcl
  } else {
    P_msg_error "Unsupport floorplan input format '$INTEL_FP_INPUT' defined by 'INTEL_FP_INPUT' var!"
  }
} else {
  if { [info exists INTEL_FP_BOUNDARY] } {
    P_msg_info "Creating floorplan with boundary '$INTEL_FP_BOUNDARY' ..."
    set_attribute -objects [current_block] -name boundary -value $INTEL_FP_BOUNDARY
  } else {
    P_msg_error "Missing 'INTEL_FP_BOUNDARY' var!"
  }
} 


#######################################################################################
# Re-create floorplan for DEF/TCL and create_floorplan for floorplanning from scratch
#######################################################################################
set init_fp_keep_opt {}
if { [info exists INTEL_FP_INPUT] && ( $INTEL_FP_INPUT eq {DEF} || $INTEL_FP_INPUT eq {FP_TCL} )} {
  if { [sizeof_collection [set terms [get_terminals -quiet *]]] > 0 } {
    append init_fp_keep_opt { io }
    P_msg_info "Detect & keep placements of [sizeof_collection $terms] terminals from floorplan input format '$INTEL_FP_INPUT'."
  }
  if { [sizeof_collection [set cells [get_cells -quiet -physical_context -filter {(design_type == macro || design_type == module) && is_placed == true} *]]] > 0 } {
    append init_fp_keep_opt { macro }
    P_msg_info "Detect & keep placements of [sizeof_collection $cells] macro cells from floorplan input format '$INTEL_FP_INPUT'."
  }
  if { [sizeof_collection [set cells [get_cells -quiet -physical_context -filter {(design_type == black_box || design_type == module) && is_placed == true} *]]] > 0 } {
    append init_fp_keep_opt { block } 
    P_msg_info "Detect & keep placements of [sizeof_collection $cells] macro cells from floorplan input format '$INTEL_FP_INPUT'."
  } 
}
if {[info exists init_fp_keep_opt] && $init_fp_keep_opt != ""} {
  initialize_floorplan -site_def $INTEL_STDCELL_TILE -keep_boundary -flip_first_row false -coincident_boundary true -keep_placement $init_fp_keep_opt
} else {
  initialize_floorplan -site_def $INTEL_STDCELL_TILE -keep_boundary -flip_first_row false -coincident_boundary true
}

######################################
# Read in VA tcl in case of UPF mode
######################################
if { $INTEL_UPF } {
# TODO: Preserve voltage areas from Tcl floorplan.
  P_msg_info "Reading voltage areas from './inputs/$INTEL_DESIGN_NAME.voltage_area.tcl' ..."
  source ./inputs/$INTEL_DESIGN_NAME.voltage_area.tcl
  if { [info exists INTEL_FP_INPUT] && $INTEL_FP_INPUT == {DEF} } {
    associate_mv_cells -power_switches
  }
}

