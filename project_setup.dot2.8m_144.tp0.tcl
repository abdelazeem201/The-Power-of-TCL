##############################################################################

####################################
#Tool Environment Variables
####################################

######################################
#Library Variables
######################################
# Variables used to set PVT conditions
set INTEL_PROCESS(WORST)     1.0
set INTEL_VOLTAGE(WORST)     0.77
set INTEL_TEMPERATURE(WORST) 125
set INTEL_PROCESS(BEST)      1.0
set INTEL_VOLTAGE(BEST)      0.89
set INTEL_TEMPERATURE(BEST)  -40


# Variable used to set operating condition. Valid values are bc_wc, on_chip_variation.
set INTEL_ANALYSIS_TYPE             "bc_wc"

# Max and Min operating condition used during set_operating_condition setting
set INTEL_MAX_OPCON       typical_1.00
set INTEL_MIN_OPCON       typical_1.00

# Include the names of all memories, io's etc to be used in the block. An example is given below
# set INTEL_HARD_MACRO_NAME         [list macro1 macro2]

set INTEL_MACRO_X_SPACING 2.160
set INTEL_MACRO_Y_SPACING 1.890

########################################
#Design Variables:
########################################

############SYN, APR and PV#############
########################################

# Top level block name for Physical Design
set INTEL_DESIGN_NAME   ""

# Max and min routing layers. These variables are used by set_ignored_layers icc command and various other tcl scripts.
set INTEL_MAX_ROUTING_LAYER                  "m6"
set INTEL_MIN_ROUTING_LAYER                  "m2"
set INTEL_RC_IGNORE_LAYERS                   "m1 m7 m8"
# Override the min routing layer contraint during placement only. Used in tool_constraints.tcl.
# This has proven to improve post route QOR by reducing RC in placement.
set INTEL_MIN_ROUTING_LAYER_OVERRIDE(place)           "m2"
set INTEL_MIN_ROUTING_LAYER_OVERRIDE(post_place)      "m2"

#SYN setup
dict lappend INTEL_SYN_LIBS target b15_un_p1222_2x1r0_psss_0.770v_125c_ccst.ldb
dict lappend INTEL_SYN_LIBS target b15_vn_p1222_2x1r0_psss_0.770v_125c_ccst.ldb 
dict lappend INTEL_SYN_LIBS target b15_wn_p1222_2x1r0_psss_0.770v_125c_ccst.ldb 
dict lappend INTEL_SYN_LIBS target b15_yn_p1222_2x1r0_psss_0.770v_125c_ccst.ldb 

dict set INTEL_SYN_LIBS link_lib {}
dict lappend INTEL_SYN_LIBS search_path $env(INTEL_STDCELLS)/ccs/un 
dict lappend INTEL_SYN_LIBS search_path $env(INTEL_STDCELLS)/ccs/vn 
dict lappend INTEL_SYN_LIBS search_path $env(INTEL_STDCELLS)/ccs/wn 
dict lappend INTEL_SYN_LIBS search_path $env(INTEL_STDCELLS)/ccs/yn 

dict lappend INTEL_SYN_LIBS mw_ref $env(INTEL_STDCELLS)/milkyway/un/b15_un 
dict lappend INTEL_SYN_LIBS mw_ref $env(INTEL_STDCELLS)/milkyway/vn/b15_vn 
dict lappend INTEL_SYN_LIBS mw_ref $env(INTEL_STDCELLS)/milkyway/wn/b15_wn 
dict lappend INTEL_SYN_LIBS mw_ref $env(INTEL_STDCELLS)/milkyway/yn/b15_yn 

#APR Setup
dict lappend INTEL_APR_LIBS un  $env(INTEL_STDCELLS)/ndm/un/${INTEL_FDK_LIB}_un.ndm
dict lappend INTEL_APR_LIBS un  $env(INTEL_STDCELLS)/ndm/un/${INTEL_FDK_LIB}_un_ls.ndm
dict lappend INTEL_APR_LIBS un  $env(INTEL_STDCELLS)/ndm/un/${INTEL_FDK_LIB}_un_layonly.ndm
dict lappend INTEL_APR_LIBS vn  $env(INTEL_STDCELLS)/ndm/vn/${INTEL_FDK_LIB}_vn.ndm
dict lappend INTEL_APR_LIBS vn  $env(INTEL_STDCELLS)/ndm/vn/${INTEL_FDK_LIB}_vn_ls.ndm
dict lappend INTEL_APR_LIBS vn  $env(INTEL_STDCELLS)/ndm/vn/${INTEL_FDK_LIB}_vn_layonly.ndm
dict lappend INTEL_APR_LIBS wn  $env(INTEL_STDCELLS)/ndm/wn/${INTEL_FDK_LIB}_wn.ndm
dict lappend INTEL_APR_LIBS wn  $env(INTEL_STDCELLS)/ndm/wn/${INTEL_FDK_LIB}_wn_ls.ndm
dict lappend INTEL_APR_LIBS wn  $env(INTEL_STDCELLS)/ndm/wn/${INTEL_FDK_LIB}_wn_layonly.ndm
dict lappend INTEL_APR_LIBS yn  $env(INTEL_STDCELLS)/ndm/yn/${INTEL_FDK_LIB}_yn.ndm
dict lappend INTEL_APR_LIBS yn  $env(INTEL_STDCELLS)/ndm/yn/${INTEL_FDK_LIB}_yn_ls.ndm
dict lappend INTEL_APR_LIBS yn  $env(INTEL_STDCELLS)/ndm/yn/${INTEL_FDK_LIB}_yn_layonly.ndm

#PV Setup
dict lappend INTEL_PV_LIBS max $env(INTEL_STDCELLS)/ccs/un/b15_un_p1222_2x1r0_psss_0.770v_125c_ccst.ldb
dict lappend INTEL_PV_LIBS max $env(INTEL_STDCELLS)/ccs/vn/b15_vn_p1222_2x1r0_psss_0.770v_125c_ccst.ldb
dict lappend INTEL_PV_LIBS max $env(INTEL_STDCELLS)/ccs/wn/b15_wn_p1222_2x1r0_psss_0.770v_125c_ccst.ldb
dict lappend INTEL_PV_LIBS max $env(INTEL_STDCELLS)/ccs/yn/b15_yn_p1222_2x1r0_psss_0.770v_125c_ccst.ldb

dict lappend INTEL_PV_LIBS min $env(INTEL_STDCELLS)/ccs/un/b15_un_p1222_2x1r0_pfff_0.890v_-40c_ccst.ldb
dict lappend INTEL_PV_LIBS min $env(INTEL_STDCELLS)/ccs/vn/b15_vn_p1222_2x1r0_pfff_0.890v_-40c_ccst.ldb
dict lappend INTEL_PV_LIBS min $env(INTEL_STDCELLS)/ccs/wn/b15_wn_p1222_2x1r0_pfff_0.890v_-40c_ccst.ldb
dict lappend INTEL_PV_LIBS min $env(INTEL_STDCELLS)/ccs/yn/b15_yn_p1222_2x1r0_pfff_0.890v_-40c_ccst.ldb

dict lappend INTEL_PV_LIBS noise $env(INTEL_STDCELLS)/ccs/un/b15_un_p1222_2x1r0_pfff_0.890v_125c_ccsn.ldb
dict lappend INTEL_PV_LIBS noise $env(INTEL_STDCELLS)/ccs/vn/b15_vn_p1222_2x1r0_pfff_0.890v_125c_ccsn.ldb
dict lappend INTEL_PV_LIBS noise $env(INTEL_STDCELLS)/ccs/wn/b15_wn_p1222_2x1r0_pfff_0.890v_125c_ccsn.ldb
dict lappend INTEL_PV_LIBS noise $env(INTEL_STDCELLS)/ccs/yn/b15_yn_p1222_2x1r0_pfff_0.890v_125c_ccsn.ldb

dict lappend INTEL_PV_LIBS power $env(INTEL_STDCELLS)/ccs/un/b15_un_p1222_2x1r0_pfff_0.890v_-40c_ccst.ldb
dict lappend INTEL_PV_LIBS power $env(INTEL_STDCELLS)/ccs/vn/b15_vn_p1222_2x1r0_pfff_0.890v_-40c_ccst.ldb
dict lappend INTEL_PV_LIBS power $env(INTEL_STDCELLS)/ccs/wn/b15_wn_p1222_2x1r0_pfff_0.890v_-40c_ccst.ldb
dict lappend INTEL_PV_LIBS power $env(INTEL_STDCELLS)/ccs/yn/b15_yn_p1222_2x1r0_pfff_0.890v_-40c_ccst.ldb

# MW Power net Name
set INTEL_POWER_NET    vcc
set INTEL_GROUND_NET   vss

# Variable to enable the usage of SDC file. If set to 1, read ./inputs/${INTEL_DESIGN_NAME}.syn.sdc. If set to 0, read ./inputs/constraints/clocks.tcl and ./inputs/constraints/constraints.tcl
set INTEL_SDC_FILE      0


# Variable to use scan flops or not (if 1, compile -scan otherwise -scan is not used). If var set to 1 then, Synthesis will run compile -scan and compiled netlist will have scan flops.
set INTEL_SCAN_REPLACE_FLOPS 1

#Variable to insert scan chain, if set to 1, DC will insert scan chain and  write out ./outputs/${INTEL_DESIGN_NAME}.scandef. APR will read in ./inputs/${INTEL_DESIGN_NAME}.scandef and run place_opt -optimize_dft
set INTEL_INSERT_SCAN   0

# If set to 1, enables UPF flow for synthesis and APR.
set INTEL_UPF     0

# Set RTL & post-synthesis UPF version, either 1.0 or 2.0.
set INTEL_UPF_VERSION   1.0

# Set the list of nets incase of UPF design
set INTEL_UPF_POWER_NETS {vss vcc}

# If set to 1, synthesis and APR flow will read ./inputs/constraints/${INTEL_DESIGN_NAME}.saif and optimizes dynamic power.
set INTEL_SAIF      0

# Variable used to define the hierarchical instance (top/instA) for which switching activity is annotated. If not defined then top level design name will be assumed
set INTEL_SAIF_INSTANCE   ""

# The maximum number of cores to be used.
set INTEL_NUM_CPUS                  4

# Macro NDM reference libs to be added in block_setup.tcl per design.
# E.g.
#set INTEL_MACRO_NDM_REF_LIBS {
#  $macro1_dir/$macro1.ndm
#  $macro2_dir/$macro2.ndm
#  $macro3_dir/$macro3.ndm
#}
set INTEL_MACRO_NDM_REF_LIBS {}

############SYN Specific################
########################################

# If set to 1 then DC will read the .def file for floorplan from ./inputs/floorplan/${INTEL_DESIGN_NAME}.def
set INTEL_TOPO_DEF      0

# Variable to set insert_clock_gating (if 1 then insert_clock_gating and compile_ultra -clock_gate is used)
set INTEL_INSERT_CLOCKGATES         1

# Set to 1, to invoke synopsys physical guidance to generate ddc/mwdb for seed placement to APR. DEF file must be provided and INTEL_TOPO_DEF set to 1.
set INTEL_SPG                       0

# Set to 1, to enable congestion optimization
set INTEL_CONGESTION_OPTIMIZE       0

# If set to 1 then ICC will read .ddc file from ./inputs/${INTEL_DESIGN_NAME}.syn.ddc
set INTEL_DDC                       0

###########APR Specific #################
#####################################################################

#Input file name variables - Provide full paths to file names. Examples provided below.
#Note - if variable not set, default path and filename (as shown in example below) will be assumed.

# set INTEL_INPUT_NETLIST ./inputs/<INTEL_DESIGN_NAME>.syn.vg
# set INTEL_INPUT_SCANDEF ./inputs/<INTEL_DESIGN_NAME>.syn.scandef
# set INTEL_INPUT_DEF ./inputs/floorplan/<INTEL_DESIGN_NAME>.floorplan.def
# set INTEL_INPUT_UPF ./inputs/upf/<INTEL_DESIGN_NAME>.syn.upf
# set INTEL_INPUT_SDC ./inputs/<INTEL_DESIGN_NAME>.syn.sdc

########## Main Command Variables ###################################
# The following variables set the options to main APR commands like place_opt, psynopt, etc

# place_opt.tcl may append additional switches "-power", "-layer_optimization", "-optimize_dft" or "-spg" conditionally based on other INTEL_* conrol vars.
set INTEL_PLACE_CMD "place_opt"

# used in psynopt.tcl
set INTEL_POST_PLACE_CMD "refine_opt"

# used in cts.tcl
set INTEL_CLK_OPT_CMD "clock_opt -from build_clock -to build_clock"
set INTEL_POST_CTS_OPT_CMD "refine_opt -from inc_opto"

# route_trackassign.tcl may append "-power" switch conditionally based on other INTEL_* conrol vars.
set INTEL_ROUTE_TRACK_ASSIGN_CMD "route_auto -stop_after_track_assignment true"

# used in initial_detailroute.tcl
set INTEL_INITIAL_DETAIL_ROUTE_CMD "route_detail"

# used in incr_route_opt.tcl
set INTEL_INCR_ROUTE_OPT_CMD "route_opt"

# used in incr_eco_detail_route.tcl
set INTEL_INCR_ECO_DETAIL_ROUTE_CMD "route_detail -incremental true"

# used in incr_detailroute.tcl
set INTEL_INCR_DETAIL_ROUTE_OPT_CMD "route_detail -incremental true"


set INTEL_PROCESS_NAME p1222
set INTEL_STDCELL_TILE_HEIGHT 0.63
set INTEL_FLIP_FIRST_ROW 0

# The following variables are also used, but defined in other parts of project_setup.tcl, by the runset based pg hookup.
# INTEL_UPF, INTEL_MW_POWER_NET, INTEL_MW_GROUND_NET, INTEL_STDCELL_TILE, INTEL_DFM_RELEASE_DIR


#############Floorplan##################

#set INTEL_FP_INPUT                 "BOUNDARY" ; # DEF(import fp def)|FP_TCL(import fp tcl)|""

# Example
# set INTEL_FP_BOUNDARY             "{0 0} {[expr $INTEL_MD_GRID_X * 400] [expr $INTEL_MD_GRID_Y * 400]}";


set INTEL_METAL_LAYERS {m2 m3 m4 m5 m6 m7 m8}
set INTEL_HORIZONTAL_LAYERS {m2 m4 m6 m8}
set INTEL_VERTICAL_LAYERS {m1 m3 m5 m7}
set INTEL_MAX_PG_LAYER "m7"
set INTEL_MIN_PG_LAYER "m1"

# Sets the terminal length for each metal layer for use in P_create_pg_terminals procedure during FRAM generation.
set INTEL_TERM_LENGTH "m1 0.120 m2 0.160 m3 0.160 m4 0.160 m5 0.160 m6 0.160 m7 0.160"

#### PG pullback values ####
# Set pullback values for primary power nets at voltage area boundary. If no pullback is specified (or) if they are always-on nets, they run till voltage area boundary.

set pg_pullback(va) {"m1 0.040" "m2 0.040" "m3 0.040" "m4 0.040" "m5 0.040" "m6 0.040" "m7 0.27"}

# Set pullback values for macros
set pg_pullback(macro) {"m1 0.160" "m2 0.160" "m3 0.160" "m4 0.160" "m5 0.160" "m6 0.160" "m7 0.27"}


# Define layers for ports
set INTEL_PORT_LAYERS "m5 m6"

# Define macro offgrid layers for offgrid track creation
#set INTEL_OFFGRID_LAYERS "m2 m3 m4 m5 m6"

#The example below shows how to override default RG values for macro reference (iromu1r0w6144d16w1spu0p) for layers m4 and m5.
#set INTEL_MACRO_RG_LIST(iromu1r0w6144d16w1spu0p) "m4 0.10 -0.10 m5 -0.210 -0.210"

#The example below shows how to completely exclude some macro references.
#set INTEL_MACRO_EXCLUSION_LIST [list iromu1r0w6144d16w1spu0p iromu1r0w6144d16w1spu1p]

#Update the list of ports where you don't need diode insertion
set INTEL_NO_INPUT_DIODE_PORTS ""

########################################
# UPF Floorplan vars


# UPF always-on supply nets as defined in UPF loaded to design.
# 1 must be ground net.  The other 1 is power net for single always-on supply voltage, or the other 2 are power nets for dual always-on supply voltage.
# Order of always-on power nets in INTEL_UPF_POWER_NETS determines mapping to aon,1 & aon,2 in INTEL_PG_GRID_CONFIG for dual always-on supply UPF.
set INTEL_UPF_POWER_NETS {vss vcc}

# UPF power plan to implement P/G grids.
# Supported values are mesh_upf_1aosv (single always-on supply voltage) & mesh_upf_2aosv (dual always-on supply voltages).
set INTEL_POWER_PLAN mesh_upf_1aosv

# Lib cell of power switch cells to be inserted in staggered array configuration in shutdown voltage areas.
# Supports both single control & dual control power switch lib cell, but must match control of UPF power switch strategy.
set INTEL_POWER_SWITCH(default) b15psbf20bu1qfkx5
# Define different power switch lib cells for specifc power domains if necessary.  To be added in block_setup.tcl per design.
# E.g.
#set INTEL_POWER_SWITCH($power_domain) <cell_name>

# Horizontal pitch between power switch cells of adjacent staggered columns in staggered array.  Must be multiple of $INTEL_MD_GRID_X.
set INTEL_PS_X_PITCH(default) 17.28
# Vertical pitch between power switch cells of adjacent staggered rows in staggered array.  Must be multiple of $INTEL_MD_GRID_Y.
set INTEL_PS_Y_PITCH(default) 10.08
# Define different horizontal & vertical pitches for specifc power domains if necessary.  To be added in block_setup.tcl per design.
# E.g.
#set INTEL_PS_X_PITCH($power_domain) 17.28
#set INTEL_PS_Y_PITCH($power_domain) 10.08

# A pair of adjacent metal layers with always-on P/G grid templates in INTEL_PG_GRID_CONFIG to align power switch cells.
# NOTE: If there are more than 1 offsets for P/G template, use the 1st offset.
set INTEL_PS_ALIGN_PG_GRID(mesh_upf_1aosv) {{m6 power_va_aon} {m7 power_all_aon}}
set INTEL_PS_ALIGN_PG_GRID(mesh_upf_2aosv) {{m6 power_va_aon,1 power_va_aon,2} {m7 power_all_aon,1 power_all_aon,2}}

# Connection mode among power switch cells supported by -mode option of connect_power_switch command, i.e. hfn, daisy or fishbone.
set INTEL_PS_CONNECT_CONFIG(default) daisy
# Start corner/point of power switch cell for daisy or fishbone mode as supported by -start_point option of connect_power_switch command, i.e. lower_left, upper_left, lower_right or upper_right.
set INTEL_PS_CONNECT_CORNER(default) lower_left
# Define different connection modes & start corners for specifc power domains if necessary.  To be added in block_setup.tcl per design.
# E.g.
#set INTEL_PS_CONNECT_CONFIG($power_domain) fishbone
#set INTEL_PS_CONNECT_CORNER($power_domain) upper_right

#Define ladders to use for power switch connections
set INTEL_PS_SEC_PG(default) "VL2644_1"

#Define ladders to use for aon connections
set INTEL_SEC_PG "VL2413 VL2412 VL2421 VL2422"

# Movebounds along voltage area boundaries for level-shifter & isolation cells, as well as to extend always-on P/G grids across voltage areas.
#
# INTEL_LS_BOUND($voltage_area,outer) = List of margins of outer movebound from sides of single-shape voltage area starting from lower left-most edge in clockwise order.
# INTEL_LS_BOUND_CELLS($voltage_area,outer) = List of cell patterns of level-shifter & isolation cells with parent location in UPF for outer movebound of single-shape voltage area.
#
# INTEL_LS_BOUND($voltage_area,$voltage_area_shape,outer) = List of margins of outer movebound from sides of 1 of the multiple disjoint shapes of voltage area starting from lower left-most edge in clockwise order.
# INTEL_LS_BOUND_CELLS($voltage_area,$voltage_area_shape,outer) = List of cell patterns of level-shifter & isolation cells with parent location in UPF for outer movebound of 1 of the multiple disjoint shapes of voltage area.
#
# INTEL_LS_BOUND($voltage_area,inner) = List of margins of inner movebound from sides of single-shape voltage area starting from lower left-most edge in clockwise order.
# INTEL_LS_BOUND_CELLS($voltage_area,inner) = List of cell patterns of level-shifter & isolation cells with self location in UPF for inner movebound of single-shape voltage area.
#
# INTEL_LS_BOUND($voltage_area,$voltage_area_shape,inner) = List of margins of inner movebound from sides of 1 of the multiple disjoint shapes of voltage area starting from lower left-most edge in clockwise order.
# INTEL_LS_BOUND_CELLS($voltage_area,$voltage_area_shape,inner) = List of cell patterns of level-shifter & isolation cells with self location in UPF for inner movebound of 1 of the multiple disjoint shapes of voltage area.
#
# NOTE:
#   Movebound margins & cells for single-shape voltage area can also be specified using the format with explicit voltage area shape, but not vice-versa.
#   Number of margins for a voltage area shape must be either match the number of sides or empty.
#   Margins must be either positive number or 0 for no movebound at the given side.
#   Margins of vertical edges must be multiple of placement site width and >= width of vertical halo cell + widest level-shifter/isolation cell.
#   Margins of horizontal edges must be multiple of row height and >= 2 rows (level-shifter cells are double-height).
#

#############Placement##################

set INTEL_CRITICAL_RANGE           "2000";
set INTEL_AREA_CRITICAL_RANGE      "not_set";
set INTEL_POWER_CRITICAL_RANGE     "not_set";

## Set to 1 to enable Layer Promotion
set INTEL_LAYER_PROMOTION           0

# Set to "magnet" for magnet placement, "port" for placing cells close to ports and "" to let place_opt place the iso cells.
set INTEL_ISOCELL_PLACER            ""

################CTS#####################

set INTEL_CTS_NETS                          ""
set INTEL_CTS_MAX_ROUTING_LAYER(DEFAULT)    "m6"
set INTEL_CTS_MIN_ROUTING_LAYER(DEFAULT)    "m5"
set INTEL_CTS_LEAF_MIN_LAYER                "m5"
set INTEL_CTS_LEAF_MAX_LAYER                "m6"
set INTEL_ENABLE_CLOCK_SPACING              "1" ; #Enables/disables clock cell spacing for IR/EM
set INTEL_CTS_MAX_FANOUT                    "24"
set INTEL_CTS_ADVANCED_DRC_FIXING           "true"

######################################
# CTS NDR SETUP
######################################
set INTEL_ENABLE_CLOCK_NDR "1"
set INTEL_CTS_NDR_RULE(DEFAULT) "ndr_defaultW_3T_noSh_Lth"

########################################################################
# NDR definitions for each clock in the design
#   Note - If INTEL_ENABLE_CLOCK_NDR is set to '0', then default routing
#          rules are used for clocks
########################################################################
#set INTEL_CTS_NDR_RULE(clk) "ndr_defaultW_3T_Sh"
#set INTEL_CTS_MAX_ROUTING_LAYER(clk) "m6"
#set INTEL_CTS_MIN_ROUTING_LAYER(clk) "m5"
##############Routing###################
set INTEL_ZROUTE_VIA_DBL           "1"     ;# Redundant via insertion

############# MCMM Flow Specific Variables ################
# Comments on MCMM Flow:
# The prerequisite for running the MCMM flow is:
#   1) The library.tcl is updated to include PVTs referenced here by set_operating_conditions. Macros PVT must match the PVT of the stdcell libraries for the tools to link to them correctly.
#   2) The variable below be set for each scenario created.
#
# All MCMM related setup is now done through create_scenarios.tcl. If something custom is required, please copy the file over locally an modify as needed.

# When using MCMM (set INTEL_MCMM 1), it is set to 0 by default
# Also need to set all the MCMM variables below (example provided below)
set INTEL_MCMM 0

############Power variables#############

# Variable is used to enable VCD/SAIF file read for PTPX Power Calculation ./inputs/${INTEL_DESIGN_NAME}.vcd/.fsdb/.saif. Specify the full path of the activity file name.
set INTEL_ACTIVITY_FILE    ""

# Specifies a path prefix that is to be stripped from all the object names read from the VCD file. This option is applied to strip the testbench/instance path from the VCD file.
set INTEL_STRIP_PATH         ""

# Variables used to specify the map file while using VCD from RTL. Give full path of the file. Map file will make sure that RTL names in the VCD match with those in the gate-level netlist.
set INTEL_RTL_VCD_MAP_FILE     ""

# Variable used to set average or peak power_analysis type. Valid values are avg, peak.
set INTEL_POWER_ANALYSIS     "avg"

  ####################
  # ICC2 dont_use/lib_cell_purpose variables in the order they are applied.
  # 1. The dont_use_default var is used by ICC2 to disable specific lib cells for the entire APR2 flow, which are enabled by default in stdcell libs.
  # 2. The INTEL_LIB_CELL_PURPOSE_LIST(exclude,*) vars are used by ICC2 to disable specific lib cells during only specified purposes of APR2 flow, which are enabled by default in stdcell libs.
  # 3. The INTEL_LIB_CELL_PURPOSE_LIST(include,*) vars are used by ICC2 to enable specific lib cells during only specified purposes of APR2 flow, which are disabled by default in stdcell libs, or disabled in the dont_use_default var above, or disabled in the INTEL_LIB_CELL_PURPOSE_LIST(exclude,*) vars of same purpose.
  # Hence, lib cells are enabled by default if NOT disabled by default in stdcell libs and NOT in the dont_use_default var above and NOT in the INTEL_LIB_CELL_PURPOSE_LIST(exclude,*) vars.
  # NOTE: Same lib cell can be set in more than 1 purposes of INTEL_LIB_CELL_PURPOSE_LIST(*,*) vars if so applicable.

  # Lib cells NOT used during delay & electrical design rule optimization, except overwritten by INTEL_LIB_CELL_PURPOSE_LIST(include,optimization) var.
set INTEL_LIB_CELL_PURPOSE_LIST(exclude,optimization) {}

# Lib cells used only during delay & electrical design rule optimization.
set INTEL_LIB_CELL_PURPOSE_LIST(include,optimization) {b15tihi00au1n03x5 b15tilo00au1n03x5} ;# Tie-high cell.

# Lib cells NOT used during power optimization, except overwritten by INTEL_LIB_CELL_PURPOSE_LIST(include,power) var.
set INTEL_LIB_CELL_PURPOSE_LIST(exclude,power) {}

# Lib cells used only during power optimization.
set INTEL_LIB_CELL_PURPOSE_LIST(include,power) {}

# Lib cells NOT used during clock-tree synthesis, except overwritten by INTEL_LIB_CELL_PURPOSE_LIST(include,cts) var.
set INTEL_LIB_CELL_PURPOSE_LIST(exclude,cts) {b15*} ;# CTS_ONLY: No other cells allowed except those listed in INTEL_LIB_CELL_PURPOSE_LIST(include,cts) var.

# Lib cells used only during clock-tree synthesis.
set INTEL_LIB_CELL_PURPOSE_LIST(include,cts) {b15cbf* b15cin* b15cilb* b15clb0* b15cmbn*} ;# CTS_ONLY: Clock cells.

# Lib cells NOT used during hold fixing, except overwritten by INTEL_LIB_CELL_PURPOSE_LIST(include,hold) var.
set INTEL_LIB_CELL_PURPOSE_LIST(exclude,hold) {}

# Lib cells used only during hold fixing.
set INTEL_LIB_CELL_PURPOSE_LIST(include,hold) {b15bfm*} ;# ROUTE_ONLY: Min delay buffers/inverters.

#################################################################################
##                PV/STA variables
#################################################################################
set INTEL_RC_CORNER(MAX) "pcss"
set INTEL_RC_CORNER(MIN) "pcff"
#### INTEL_STA_RUN_TYPE is a mandatory variable can be  {max,min,noise,power}
set INTEL_STA_RUN_TYPE ""
set INTEL_PT_ERC_CHECK_ENABLE 0