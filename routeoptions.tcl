apr/check_floorplan.tcl:  set_app_options -name place.floorplan.sliver_size -value ${narrow_channel_width}um
apr/clock_route.tcl:report_app_options route.*
apr/cts.tcl:report_app_options clock_opt.*
apr/fix_hold.tcl:set_app_options -name opt.timing.effort -value high
apr/fix_hold.tcl:set_app_options -name refine_opt.flow.optimize_layers -value true
apr/fix_hold.tcl:set_app_options -name refine_opt.flow.optimize_ndr -value true
apr/fix_hold.tcl:set_app_options -name opt.area.effort -value ultra
apr/fix_hold.tcl:set_app_options -name opt.common.buffer_area_effort -value ultra
apr/fix_hold.tcl:#set_app_options -name extract.extract_min_cross_diagonal -value true
apr/fix_hold.tcl:set_app_options -name extract.long_net_pessimism_removal -value true
apr/fix_hold.tcl:set_app_options -as_user_default -name refine_opt.hold.effort -value medium
apr/fix_hold.tcl:report_app_options refine_opt.*
apr/fptocts.tcl:set_app_options -name place.coarse.continue_on_missing_scandef -value true
apr/freeze_clock_nets.tcl:set_app_options -name cts.compile.fix_clock_tree_sinks -value true
apr/incr_detailroute.tcl:  set_app_options -name route.detail.force_max_number_iterations -value true
apr/incr_route_opt.tcl:set_app_options -name route_opt.eco_route.mode -value detail
apr/incr_route_opt.tcl:report_app_options route_opt.*
apr/phy_cell_warnings:PDC app_options settings =========
apr/phy_cell_warnings:PDC app_options settings =========
apr/phy_cell_warnings:PDC app_options settings =========
apr/phy_cell_warnings:PDC app_options settings =========
apr/place_opt.tcl:  set_app_options -name place_opt.flow.do_spg -value true
apr/place_opt.tcl:report_app_options place_opt.*
apr/refine_opt.tcl:report_app_options refine_opt.*
apr/route_options.tcl:set_app_options -name route.common.threshold_noise_ratio -value 0.25
apr/route_trackassign.tcl:set_app_options -name route.detail.eco_max_number_of_iterations -value 10
apr/route_trackassign.tcl:set_app_options -name route_opt.eco_route.mode -value track
apr/run_ref.dot2.8m_108.tp0.tcl:set_app_options -name place.coarse.continue_on_missing_scandef -value true
apr/tool_constraints.tcl:set_app_options -name time.disable_recovery_removal_checks -value false
apr/tool_constraints.tcl:set_app_options -name time.remove_clock_reconvergence_pessimism -value true
apr/tool_constraints.tcl:set_app_options -name time.frequency_based_max_cap -value true
apr/tool_constraints.tcl:  set_app_options -name opt.common.user_instance_name_prefix -value clock_
apr/tool_constraints.tcl:  set_app_options -name cts.common.user_instance_name_prefix -value cts_
apr/tool_constraints.tcl:  set_app_options -name opt.common.user_instance_name_prefix -value ${INTEL_STEP_CURR}_
apr/tool_constraints.tcl:set_app_options -name opt.timing.effort -value high
apr/tool_constraints.tcl:set_app_options -name opt.area.effort -value medium
apr/tool_constraints.tcl:#set_app_options -name opt.leakage.effort -value medium
apr/tool_constraints.tcl:set_app_options -name opt.common.buffer_area_effort -value medium
apr/tool_constraints.tcl:set_app_options -name opt.common.buffering_for_advanced_technology -value true 
apr/tool_constraints.tcl:set_app_options -name opt.common.max_fanout -value 30
apr/tool_constraints.tcl:#set_app_options -name opt.tie_cell.max_fanout -value 1
apr/tool_constraints.tcl:set_app_options -name time.high_fanout_net_threshold -value 100
apr/tool_constraints.tcl:#set_app_options -name place.legalize.enable_prerouted_net_check -value false
apr/tool_constraints.tcl:set_app_options -name place.coarse.max_density -value 0.6
apr/tool_constraints.tcl:set_app_options -name place.coarse.congestion_driven_max_util -value 0.9
apr/tool_constraints.tcl:set_app_options -name place.coarse.target_routing_density -value 0.7
apr/tool_constraints.tcl:set_app_options -name place.coarse.pin_density_aware -value true
apr/tool_constraints.tcl:set_app_options -name place.coarse.detect_detours -value true
apr/tool_constraints.tcl:#set_app_options -name place.coarse.icg_auto_bound -value true
apr/tool_constraints.tcl:set_app_options -name place_opt.initial_drc.global_route_based -value 1
apr/tool_constraints.tcl:set_app_options -name place_opt.flow.optimize_icgs -value true
apr/tool_constraints.tcl:set_app_options -name place_opt.congestion.effort -value high
apr/tool_constraints.tcl:set_app_options -name place_opt.initial_place.two_pass -value true
apr/tool_constraints.tcl:set_app_options -name place_opt.initial_place.effort -value high
apr/tool_constraints.tcl:set_app_options -name place_opt.final_place.effort -value high
apr/tool_constraints.tcl:set_app_options -name place_opt.flow.optimize_layers -value auto
apr/tool_constraints.tcl:set_app_options -name place_opt.flow.optimize_ndr -value true
apr/tool_constraints.tcl:  set_app_options -name refine_opt.flow.optimize_layers -value true
apr/tool_constraints.tcl:  set_app_options -name refine_opt.flow.optimize_ndr -value true
apr/tool_constraints.tcl:set_app_options -name refine_opt.place.effort -value high
apr/tool_constraints.tcl:#set_app_options -name refine_opt.congestion.effort -value high
apr/tool_constraints.tcl:set_app_options -name cts.common.verbose -value 1
apr/tool_constraints.tcl:set_app_options -name cts.common.max_fanout -value $INTEL_CTS_MAX_FANOUT
apr/tool_constraints.tcl:set_app_options -name clock_opt.flow.optimize_ndr -value true
apr/tool_constraints.tcl:set_app_options -name cts.compile.enable_global_route -value true
apr/tool_constraints.tcl:#set_app_options -name clock_opt.flow.enable_ccd -value true
apr/tool_constraints.tcl:set_app_options -name clock_opt.place.effort -value high
apr/tool_constraints.tcl:#set_app_options -name clock_opt.congestion.effort -value high
apr/tool_constraints.tcl:set_app_options -name route.global.timing_driven -value true
apr/tool_constraints.tcl:  set_app_options -name route.global.crosstalk_driven -value true
apr/tool_constraints.tcl:set_app_options -name route.global.macro_corner_track_utilization -value 95
apr/tool_constraints.tcl:#set_app_options -name route_opt.flow.enable_ccd -value true
apr/tool_constraints.tcl:#set_app_options -name route_opt.flow.enable_cto -value true
apr/tool_constraints.tcl:set_app_options -name route_opt.flow.enable_power -value true
apr/tool_constraints.tcl:set_app_options -name route_opt.flow.xtalk_reduction -value true
apr/tool_constraints.tcl:set_app_options -name route.detail.optimize_tie_off_effort_level -value high
apr/tool_constraints.tcl:set_app_options -name time.si_enable_analysis -value true
apr/tool_constraints.tcl:set_app_options -name extract.enable_coupling_cap -value true
apr/tool_constraints.tcl:report_app_options -non_default > ./reports/$INTEL_DESIGN_NAME.$INTEL_STEP_CURR.app_options-non_default.rpt
apr/tool_constraints.tcl:set_app_options -name plan.macro.spacing_rule_heights -value "0.00um ${INTEL_MACRO_Y_SPACING}um" ;#macros can either abut or spaced 1.890um away in Y direction
apr/tool_constraints.tcl:set_app_options -name plan.macro.spacing_rule_widths -value "0.00um ${INTEL_MACRO_X_SPACING}um" ; #macros can either abut or spaced 2.160um away in X direction
apr/w_route_trackassign.tcl:set_app_options -name route.detail.eco_max_number_of_iterations -value 10
apr/w_route_trackassign.tcl:set_app_options -name route_opt.eco_route.mode -value track
apr/w_route_trackassign.tcl:set_app_options -name route_opt.flow.enable_ccd -value true
apr/w_useful_clock_route.tcl:report_app_options route.*
apr/w_useful_clock_route.tcl:set_app_options -name clock_opt.flow.enable_ccd -value true
apr/w_useful_place_opt.tcl:  set_app_options -name place_opt.flow.do_spg -value true
apr/w_useful_place_opt.tcl:report_app_options place_opt.*
apr/w_useful_place_opt.tcl:set_app_options -list {place_opt.flow.enable_ccd true}
apr/w_useful_place_opt.tcl:set_app_options -list {place_opt.flow.enable_ccd false}
tech.dot2.8m_108.tp0/antenna_rules.tcl:set_app_options -name route.detail.diode_libcell_names -value $INTEL_ANTENNA_DIODE
tech.dot2.8m_108.tp0/antenna_rules.tcl:set_app_options -name route.detail.antenna -value true
tech.dot2.8m_108.tp0/antenna_rules.tcl:set_app_options -name route.detail.default_gate_size -value 0
tech.dot2.8m_108.tp0/antenna_rules.tcl:set_app_options -name route.detail.hop_layers_to_fix_antenna -value true
tech.dot2.8m_108.tp0/antenna_rules.tcl:#  set_app_options -name route.detail.insert_diodes_during_routing -value true
tech.dot2.8m_108.tp0/antenna_rules.tcl:set_app_options -name route.detail.default_port_external_gate_size -value 0.001
tech.dot2.8m_108.tp0/create_check_grid.tcl:  } elseif { [get_app_option_value -name shell.common.product_version] < {K-2015.06-SP1} } {
tech.dot2.8m_108.tp0/create_check_grid.tcl:    P_msg_error "$proc_name: Detect unsupported ICC2 version '[get_app_option_value -name shell.common.product_version]'!  Expect 'K-2015.06-SP1' or newer!"
tech.dot2.8m_108.tp0/create_macro_offgrid_pin_tracks.tcl:set_app_options -name route.common.track_use_area  -value true
tech.dot2.8m_108.tp0/create_macro_offgrid_pin_tracks.tcl:#report_app_options route.common.connect_within_pins_by_layer_name
tech.dot2.8m_108.tp0/create_macro_offgrid_pin_tracks.tcl:#set_app_options -name route.common.connect_within_pins_by_layer_name -value [list [list m1 via_standard_cell_pins] [list m5 via_wire_all_pins] ]
tech.dot2.8m_108.tp0/create_macro_offgrid_pin_tracks.tcl:#report_app_options route.common.connect_within_pins_by_layer_name
tech.dot2.8m_108.tp0/create_pg_grid.tcl:set_app_options -name plan.pgroute.high_capacity_mode -value true
tech.dot2.8m_108.tp0/create_pg_grid.tcl:set_app_options -name plan.pgroute.honor_signal_route_drc -value true
tech.dot2.8m_108.tp0/create_pg_grid.tcl:set_app_options -name plan.pgroute.honor_std_cell_drc -value true
tech.dot2.8m_108.tp0/create_pg_grid.tcl:set_app_options -name plan.pgroute.via_site_threshold -value 1.0
tech.dot2.8m_108.tp0/create_pg_grid.tcl:#set_app_options -name plan.pgroute.overlap_route_boundary -value true
tech.dot2.8m_108.tp0/create_pg_grid.tcl:#set_app_options -name plan.pgroute.verbose -value true
tech.dot2.8m_108.tp0/create_pg_grid.tcl:  } elseif { [get_app_option_value -name shell.common.product_version] < {K-2015.06-SP5} } {
tech.dot2.8m_108.tp0/create_pg_grid.tcl:    P_msg_error "$proc_name: Detect unsupported ICC2 version '[get_app_option_value -name shell.common.product_version]'!  Expect 'K-2015.06-SP5' or newer!"
tech.dot2.8m_108.tp0/create_pg_grid.tcl:    report_app_options plan.pgroute.*
tech.dot2.8m_108.tp0/create_pg_grid.tcl:  report_app_options plan.pgroute.* > $rpt_prefix.app_options.plan.pg_route.rpt
tech.dot2.8m_108.tp0/create_port_layer.tcl:  } elseif { [get_app_option_value -name shell.common.product_version] < {K-2015.06-SP1} } {
tech.dot2.8m_108.tp0/create_port_layer.tcl:    P_msg_error "$proc_name: Detect unsupported ICC2 version '[get_app_option_value -name shell.common.product_version]'!  Expect 'K-2015.06-SP1' or newer!"
tech.dot2.8m_108.tp0/create_top_pg_pin.tcl:  } elseif { [get_app_option_value -name shell.common.product_version] < {K-2015.06-SP1} } {
tech.dot2.8m_108.tp0/create_top_pg_pin.tcl:    P_msg_error "$proc_name: Detect unsupported ICC2 version '[get_app_option_value -name shell.common.product_version]'!  Expect 'K-2015.06-SP1' or newer!"
tech.dot2.8m_108.tp0/pre_place_bonus_fib.tcl:} elseif { [get_app_option_value -name shell.common.product_version] < {K-2015.06-SP1} } {
tech.dot2.8m_108.tp0/pre_place_bonus_fib.tcl:  P_msg_error "$scr_name: Detect unsupported ICC2 version '[get_app_option_value -name shell.common.product_version]'!  Expect 'K-2015.06-SP1' or newer!"
tech.dot2.8m_108.tp0/procs.tcl:                  set_app_options -name time.delay_calculation_style -value zero_interconnect 
tech.dot2.8m_108.tp0/procs.tcl:                  set_app_options -name time.delay_calculation_style -value auto 
tech.dot2.8m_108.tp0/procs.tcl:                set_app_options -name time.delay_calculation_style -value zero_interconnect 
tech.dot2.8m_108.tp0/procs.tcl:                set_app_options -name time.delay_calculation_style -value auto
tech.dot2.8m_108.tp0/procs.tcl:    set_app_options -name route.detail.antenna -value true
tech.dot2.8m_108.tp0/procs.tcl:    set_app_options -name abstract.allow_all_level_abstract -value true
tech.dot2.8m_108.tp0/procs.tcl:    set_app_options -name abstract.allow_all_level_abstract -value true
tech.dot2.8m_108.tp0/procs.tcl:  #set_app_options -name abstract.annotate_power -value true
tech.dot2.8m_108.tp0/procs.tcl:  #set_app_options -name abstract.enable_signal_em_analysis -value true
tech.dot2.8m_108.tp0/route_options_drc.tcl:reset_app_options route.* 
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.common.clock_topology -value normal
tech.dot2.8m_108.tp0/route_options_drc.tcl:#set_app_options -name route.common.track_auto_fill -value false
tech.dot2.8m_108.tp0/route_options_drc.tcl:#set_app_options -name route.common.track_use_area  -value true
tech.dot2.8m_108.tp0/route_options_drc.tcl:#set_app_options -name route.common.single_connection_to_pins -value standard_cell_must_join_pins
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.common.global_min_layer_mode -value allow_pin_connection
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.common.net_min_layer_mode -value soft
tech.dot2.8m_108.tp0/route_options_drc.tcl:#set_app_options -name route.common.global_min_layer_mode -value hard
tech.dot2.8m_108.tp0/route_options_drc.tcl:#set_app_options -name route.common.net_min_layer_mode -value allow_pin_connection
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.common.global_max_layer_mode -value hard
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.common.net_max_layer_mode -value hard
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.common.number_of_vias_under_global_min_layer -value 1
tech.dot2.8m_108.tp0/route_options_drc.tcl:#set_app_options -name route.common.number_of_vias_under_net_min_layer -value 4
tech.dot2.8m_108.tp0/route_options_drc.tcl:#set_app_options -name route.common.connect_within_pins_by_layer_name -value {{m1 via_wire_all_pins}}
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.common.single_connection_to_pins -value standard_cell_must_join_pins
tech.dot2.8m_108.tp0/route_options_drc.tcl:#set_app_options -name route.common.only_conn_to_must_joint_pins -value true
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.common.verbose_level -value 1
tech.dot2.8m_108.tp0/route_options_drc.tcl:#set_app_options -name route.common.connect_tie_off -value true
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.common.rotate_default_vias -value false
tech.dot2.8m_108.tp0/route_options_drc.tcl:#set_app_options -name route.common.extra_preferred_direction_wire_cost_multiplier_by_layer_name -value {{m1 20}}
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.common.mark_clock_nets_minor_change -value true
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.common.reroute_clock_shapes -value false
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.common.reroute_user_shapes -value false
tech.dot2.8m_108.tp0/route_options_drc.tcl:  set_app_options -name route.common.post_detail_route_redundant_via_insertion -value medium
tech.dot2.8m_108.tp0/route_options_drc.tcl:  set_app_options -name route.common.post_detail_route_redundant_via_insertion -value off
tech.dot2.8m_108.tp0/route_options_drc.tcl:  set_app_options -name route.common.rc_driven_setup_effort_level -value high
tech.dot2.8m_108.tp0/route_options_drc.tcl:  set_app_options -name route.common.reshield_modified_nets -value reshield
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.common.ignore_var_spacing_to_blockage -value false
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.common.ignore_var_spacing_to_pg -value true
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.common.disable_soft_end_to_end_spacing_rules -value true
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.global.timing_driven -value true
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.track.crosstalk_driven -value true
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.global.macro_corner_track_utilization -value 95
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.global.effort_level -value medium
tech.dot2.8m_108.tp0/route_options_drc.tcl:# set_app_options -name route.global.pin_access_factor -value 9
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.track.timing_driven -value true
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.track.allow_layer_change -value false
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.detail.antenna -value false
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.detail.drc_convergence_effort_level -value medium
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.detail.ignore_drc -value {{same_net_metal_space false}}
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.detail.timing_driven -value true
tech.dot2.8m_108.tp0/route_options_drc.tcl:#set_app_options -name route.detail.use_wide_wire_to_input_pin -value true
tech.dot2.8m_108.tp0/route_options_drc.tcl:#set_app_options -name route.detail.use_wide_wire_to_output_pin -value true
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.detail.optimize_wire_via_effort_level -value medium
tech.dot2.8m_108.tp0/route_options_drc.tcl:set_app_options -name route.detail.enable_nmsr_middle_track_filter -value true

