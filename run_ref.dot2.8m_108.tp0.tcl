
################################################################################
#
# INTEL REFERENCE FLOW
# 
# Tool            : synopsys
# Flow            : apr
# Process         : 1222
# Dot             : dot2
# Library         : 8m_108
# Track Pattern   : tp0
# 
#
################################################################################



################################################################################
# Environment Setup
#   The following environment variables need to be set for 
#   proper flow operation.
################################################################################
 setenv INTEL_ASIC          /scratch/HCL/APR
 setenv INTEL_PDK           /scratch/IntelPDK/pdk222_r1.0HF8
 setenv INTEL_RUNSETS       /scratch/IntelPDK/pdk222_r1.0HF8/runsets
 setenv INTEL_STDCELLS      /scratch/IntelPDK/LIB/lib222_7t_108pp_base_e.2.0
 setenv INTEL_IP_LIBS       /scratch/IntelPDK/lib/ip_libs_updated
 setenv INTEL_IP_NDMS       /scratch/IntelPDK/lib/memory_ip
 setenv INTEL_IO_LIBS       /scratch/IntelPDK/20170810_ip222padlib_sdio_1v8
 setenv INTEL_LAYERSTACK     be2
 setenv INTEL_TECHOPTION     2
 setenv INTEL_TIC           /scratch/IntelPDK/lib/tic222_r1.0HF2
################################################################################


################################################################################
# Technology Setup
################################################################################

source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/tech_config.tcl


################################################################################
# Project Setup
################################################################################
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/procs.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/apr_procs.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/run_proc.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/tooltype.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/procs_common.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/aliases.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/project_setup.dot2.8m_108.tp0.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/flow_setup.tcl
file mkdir reports outputs logs


################################################################################
# Block Setup
#   Customize the following variables according to design specifics.
#   Please refer to the project setup file for further customizations.
#
#   Example data exists in the following directory: $INTEL_ASIC/examples
#
#
################################################################################
set INTEL_DESIGN_NAME mkSoc
#set INTEL_FP_BOUNDARY           "{0 0} {[expr $INTEL_MD_GRID_X * 400*5] [expr $INTEL_MD_GRID_Y * 401]}"
set INTEL_FP_BOUNDARY           "{0 0} {3800 3800}"

#set INTEL_SDC_FILE 1
#set INTEL_INPUT_SDC /scratch/HCL/Bharath/Shakthi/SHAKTHI/mkSoc_Bharath/syn_partition/output/mkSoc.dc_compile_ultra_1.sdc


################################################################################
# Library Setup
################################################################################
source $env(INTEL_ASIC)/asicflows/synopsys/apr/library.tcl
create_lib $INTEL_DESIGN_NAME.nlib -technology $INTEL_TECH_FILE -ref_libs $INTEL_NDM_REF_LIBS


#set_ref_libs -add $env(INTEL_ASIC)/asicflows/synopsys/apr/inputs/mkfpu.nlib
#set_ref_libs -add $env(INTEL_ASIC)/asicflows/synopsys/apr/inputs/mkdmem.nlib
#set_ref_libs -add $env(INTEL_ASIC)/asicflows/synopsys/apr/inputs/mkriscv.nlib
#set_ref_libs -add $env(INTEL_ASIC)/asicflows/synopsys/apr/inputs/mkimem.nlib


################################################################################
#
# Flow Step : import_design
#
################################################################################

#-------------------------------------------------------------------------------
# Variable settings
#-------------------------------------------------------------------------------
set INTEL_STEP_CURR import_design

#-------------------------------------------------------------------------------
# Intel Technology Modules used in this step
#-------------------------------------------------------------------------------
# lib_cell_purpose.tcl

#-------------------------------------------------------------------------------
# Flow substeps:
#-------------------------------------------------------------------------------
source $env(INTEL_ASIC)/asicflows/synopsys/apr/import_design.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/dont_use.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/lib_cell_purpose.tcl
###change
source $env(INTEL_ASIC)/asicflows/synopsys/apr/dont_use_nn.tcl
#####
source $env(INTEL_ASIC)/asicflows/synopsys/apr/create_scenarios.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/read_constraints.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/create_path_group.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/set_isolate_ports.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/connect_pg_net.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/change_names.tcl

#-------------------------------------------------------------------------------
# Save step lib database
#-------------------------------------------------------------------------------
save_block -label import_design
save_lib
mark_step import_design

################################################################################
#
# Flow Step : floorplan
#
################################################################################

#-------------------------------------------------------------------------------
# Variable settings
#-------------------------------------------------------------------------------
set INTEL_STEP_CURR floorplan

#-------------------------------------------------------------------------------
# Intel Technology Modules used in this step
#-------------------------------------------------------------------------------
# lib_cell_purpose.tcl
# extraction_settings_prefill.tcl
# create_site_rows.tcl
# set_wiretracks.tcl
# create_macro_offgrid_pin_tracks.tcl
# create_macro_ws.tcl
# create_rectilinear_routing_blockage.tcl
# set_pg_grid_config.tcl
# create_pg_grid.tcl
# create_boundary_ws.tcl
# create_boundary_blockage.tcl
# add_tap_cells.tcl
# pre_place_fiducial.tcl
# pre_place_bonus_fib.tcl
# create_top_pg_pin.tcl
# create_check_grid.tcl

#-------------------------------------------------------------------------------
# Flow substeps:
#-------------------------------------------------------------------------------
source $env(INTEL_ASIC)/asicflows/synopsys/apr/dont_use.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/lib_cell_purpose.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/dont_use_nn.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/tool_constraints.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/extraction_settings_prefill.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/init_floorplan.tcl

save_block -label without_macro_fp
save_lib
mark_step without_macro_fp

source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/create_site_rows.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/set_wiretracks.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/macro_placement.tcl

save_block -label with_macro_fp
save_lib
mark_step with_macro_fp

source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/create_macro_offgrid_pin_tracks.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/create_macro_ws.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/create_rectilinear_routing_blockage.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/connect_pg_net.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/set_pg_grid_config.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/create_pg_grid.tcl

#place_pins -self
#source $env(INTEL_ASIC)/asicflows/synopsys/apr/io_placement.tcl

source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/create_boundary_ws.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/create_boundary_blockage.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/add_tap_cells.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/pre_place_fiducial.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/pre_place_bonus_fib.tcl


source $env(INTEL_ASIC)/asicflows/synopsys/apr/insert_antenna_diodes_on_input.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/check_floorplan.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/create_top_pg_pin.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/create_check_grid.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/connect_pg_net.tcl

#-------------------------------------------------------------------------------
# Save step lib database
#-------------------------------------------------------------------------------
save_block -label floorplan
save_lib
mark_step floorplan

P_reports floorplan

set_app_options -name place.coarse.continue_on_missing_scandef -value true

################################################################################
#
# Flow Step : place
#
################################################################################

#-------------------------------------------------------------------------------
# Variable settings
#-------------------------------------------------------------------------------
set INTEL_STEP_CURR place

#-------------------------------------------------------------------------------
# Intel Technology Modules used in this step
#-------------------------------------------------------------------------------
# lib_cell_purpose.tcl
# extraction_settings_prefill.tcl

#-------------------------------------------------------------------------------
# Flow substeps:
#-------------------------------------------------------------------------------
source $env(INTEL_ASIC)/asicflows/synopsys/apr/dont_use.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/lib_cell_purpose.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/dont_use_nn.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/tool_constraints.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/extraction_settings_prefill.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/set_ideal_clock_network.tcl
#source $env(INTEL_ASIC)/asicflows/synopsys/apr/place_opt.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/w_useful_place_opt.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/connect_pg_net.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/change_names.tcl

#-------------------------------------------------------------------------------
# Save step lib database
#-------------------------------------------------------------------------------
save_block -label place
save_lib
mark_step place

P_reports place


################################################################################
#
# Flow Step : cts
#
################################################################################

#-------------------------------------------------------------------------------
# Variable settings
#-------------------------------------------------------------------------------
set INTEL_STEP_CURR cts

#-------------------------------------------------------------------------------
# Intel Technology Modules used in this step
#-------------------------------------------------------------------------------
# lib_cell_purpose.tcl
# extraction_settings_prefill.tcl
# route_options_drc.tcl

#-------------------------------------------------------------------------------
# Flow substeps:
#-------------------------------------------------------------------------------
source $env(INTEL_ASIC)/asicflows/synopsys/apr/dont_use.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/lib_cell_purpose.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/dont_use_nn.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/tool_constraints.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/extraction_settings_prefill.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/cts_ndr_rules.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/cts_options.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/remove_ideal_clock_network.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/cts.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/route_options_drc.tcl
#source $env(INTEL_ASIC)/asicflows/synopsys/apr/clock_route.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/w_useful_clock_route.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/create_clock_shield.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/freeze_clock_nets.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/update_clocks.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/fix_hold.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/connect_pg_net.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/change_names.tcl

#-------------------------------------------------------------------------------
# Save step lib database
#-------------------------------------------------------------------------------
save_block -label cts
save_lib
mark_step cts

P_reports cts


################################################################################
#
# Flow Step : route
#
################################################################################

#-------------------------------------------------------------------------------
# Variable settings
#-------------------------------------------------------------------------------
set INTEL_STEP_CURR route

#-------------------------------------------------------------------------------
# Intel Technology Modules used in this step
#-------------------------------------------------------------------------------
# lib_cell_purpose.tcl
# extraction_settings_prefill.tcl
# route_options_drc.tcl

#-------------------------------------------------------------------------------
# Flow substeps:
#-------------------------------------------------------------------------------
source $env(INTEL_ASIC)/asicflows/synopsys/apr/dont_use.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/lib_cell_purpose.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/dont_use_nn.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/tool_constraints.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/extraction_settings_prefill.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/route_options.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/route_options_drc.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/report_pre_route.tcl
#source $env(INTEL_ASIC)/asicflows/synopsys/apr/route_trackassign.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/w_route_trackassign.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/initial_detailroute.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/incr_create_clock_shield.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/check_routes.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/connect_pg_net.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/change_names.tcl

#-------------------------------------------------------------------------------
# Save step lib database
#-------------------------------------------------------------------------------
save_block -label route
save_lib
mark_step route

P_reports route


################################################################################
#
# Flow Step : post_route
#
################################################################################

#-------------------------------------------------------------------------------
# Variable settings
#-------------------------------------------------------------------------------
set INTEL_STEP_CURR post_route

#-------------------------------------------------------------------------------
# Intel Technology Modules used in this step
#-------------------------------------------------------------------------------
# lib_cell_purpose.tcl
# extraction_settings_prefill.tcl
# route_options_drc.tcl
# antenna_rules.tcl
# add_filler_cells.tcl
# create_port_layer.tcl
# remove_boundary_blockage.tcl

#-------------------------------------------------------------------------------
# Flow substeps:
#-------------------------------------------------------------------------------
source $env(INTEL_ASIC)/asicflows/synopsys/apr/dont_use.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/lib_cell_purpose.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/dont_use_nn.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/tool_constraints.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/extraction_settings_prefill.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/route_options.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/route_options_drc.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/antenna_rules.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/incr_route_opt.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/incr_eco_detail_route.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/incr_create_clock_shield.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/add_filler_cells.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/incr_detailroute.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/check_routes.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/connect_pg_net.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/create_port_layer.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/tech.dot2.8m_108.tp0/remove_boundary_blockage.tcl
source $env(INTEL_ASIC)/asicflows/synopsys/apr/change_names.tcl

#-------------------------------------------------------------------------------
# Save step lib database
#-------------------------------------------------------------------------------
save_block -label post_route
save_lib
mark_step post_route



################################################################################
#
# Save final database and generate reports
#
################################################################################

P_outputs post_route
P_reports post_route

################################################################################
# Run_ref complete
################################################################################
