

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

if {0} {

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
source $env(INTEL_ASIC)/asicflows/synopsys/apr/route_trackassign.tcl
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



