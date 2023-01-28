############################################################
# NAME :          antenna_rules.tcl
#
# SUMMARY :       define antenna rules
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists antenna_rules.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_ANTENNA_DIODE
#
# PROCS USED :    None
#                         
# DESCRIPTION :   antenna_rules.tcl is to set NAC rules for router.
#
# EXAMPLES :      
#
#############################################################
puts "#INFO-MSG: Setting NAC rules prior to routing"

set metal_ratio 5000
set max_metal_ratio 5000

set max_via_ratio 550
set via0_ratio 9
set via1_ratio 360
set via2_ratio 360
set via3_ratio 360
set via4_ratio 420
set via5_ratio 420
set via6_ratio 550
set via7_ratio 550

set v_dmode 1

remove_antenna_rules

define_antenna_rule -mode 1 -diode_mode $v_dmode -metal_ratio $max_metal_ratio -cut_nratio $max_via_ratio  -cut_pratio $max_via_ratio \
  -metal_area_to_ngate_diffusion_length_ratio 35

define_antenna_layer_rule -mode 1 -layer {m1}  -ratio $metal_ratio -nratio 10000 -pratio 3000 -area_to_ngate_diffusion_length_ratio 300  -diode_ratio {0 1 1 0 0}
define_antenna_layer_rule -mode 1 -layer {m2}  -ratio $metal_ratio -nratio 10000 -pratio 3000 -area_to_ngate_diffusion_length_ratio 300  -diode_ratio {0 1 1 0 0}
define_antenna_layer_rule -mode 1 -layer {m3}  -ratio $metal_ratio -nratio 10000 -pratio 3000 -area_to_ngate_diffusion_length_ratio 300  -diode_ratio {0 1 1 0 0}
define_antenna_layer_rule -mode 1 -layer {m4}  -ratio $metal_ratio -nratio 10000 -pratio 3000 -area_to_ngate_diffusion_length_ratio 300  -diode_ratio {0 1 1 0 0}
define_antenna_layer_rule -mode 1 -layer {m5}  -ratio $metal_ratio -nratio 10000 -pratio 3000 -area_to_ngate_diffusion_length_ratio 300  -diode_ratio {0 1 1 0 0}
define_antenna_layer_rule -mode 1 -layer {m6}  -ratio $metal_ratio -nratio 10000 -pratio 3000 -area_to_ngate_diffusion_length_ratio 300  -diode_ratio {0 1 1 0 0}
define_antenna_layer_rule -mode 1 -layer {m7}  -ratio $metal_ratio -nratio 10000 -pratio 3000 -area_to_ngate_diffusion_length_ratio 300  -diode_ratio {0 1 1 0 0}

define_antenna_layer_rule -mode 1 -layer {v0}  -nratio $via0_ratio  -pratio $via0_ratio  -diode_ratio {0 1 1 0 0}
define_antenna_layer_rule -mode 1 -layer {v1}  -nratio $via1_ratio  -pratio $via1_ratio  -diode_ratio {0 1 1 0 0}
define_antenna_layer_rule -mode 1 -layer {v2}  -nratio $via2_ratio  -pratio $via2_ratio  -diode_ratio {0 1 1 0 0}
define_antenna_layer_rule -mode 1 -layer {v3}  -nratio $via3_ratio  -pratio $via3_ratio  -diode_ratio {0 1 1 0 0}
define_antenna_layer_rule -mode 1 -layer {v4}  -nratio $via4_ratio  -pratio $via4_ratio  -diode_ratio {0 1 1 0 0}
define_antenna_layer_rule -mode 1 -layer {v5}  -nratio $via5_ratio  -pratio $via5_ratio  -diode_ratio {0 1 1 0 0}
define_antenna_layer_rule -mode 1 -layer {v6}  -nratio $via6_ratio  -pratio $via6_ratio  -diode_ratio {0 1 1 0 0}
define_antenna_layer_rule -mode 1 -layer {v7}  -nratio $via7_ratio  -pratio $via7_ratio  -diode_ratio {0 1 1 0 0}

report_antenna_rules > reports/dump_antenna.rules

puts "#INFO-MSG: Set NAC rules before routing"

set_app_options -name route.detail.diode_libcell_names -value $INTEL_ANTENNA_DIODE
set_app_options -name route.detail.antenna -value true
set_app_options -name route.detail.default_gate_size -value 0
set_app_options -name route.detail.hop_layers_to_fix_antenna -value true
# route_opt segv with diode insertion enabled
#  set_app_options -name route.detail.insert_diodes_during_routing -value true
set_app_options -name route.detail.default_port_external_gate_size -value 0.001



