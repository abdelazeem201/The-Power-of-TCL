#############################################################
# NAME :          tech_config.tcl
#
# SUMMARY :       define .2 108pp tech module related variables.
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists tech_config.dot2.8m_108.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_PROCESS_NAME INTEL_LAYERSTACK INTEL_DOTP INTEL_FDK_LIB INTEL_LIB_TYPE INTEL_TRACKPATTERN INTEL_LIB_VENDOR INTEL_EXTEND_MW_LAYERS INTEL_GDS_OUT_LAYER_MAP INTEL_TECH_FILE INTEL_MAX_TLUPLUS_FILE INTEL_MAX_TLUPLUS_EMUL_FILE INTEL_TLUPLUS_MAP_FILE INTEL_STDCELL_TILE INTEL_STDCELL_BONUS_GATEARRAY_TILE INTEL_STDCELL_CORE2H_TILE INTEL_VA_ISO_CELL INTEL_DEBUG_CELLS INTEL_TAP_CELLS INTEL_NWELL_TAP_CELL INTEL_ANTENNA_DIODE INTEL_BONUS_GATEARRAY_CELLS INTEL_STDCELL_FILLER_CELLS INTEL_CHECK_GRID_CONFIG
#
# PROCS USED :    None
#                         
# DESCRIPTION :   tech_config.dot2.8m_108.tcl is to define .2 108pp tech module related variables
#
# EXAMPLES :      
#
##############################################################

set INTEL_PROCESS_NAME  "p1222"
set INTEL_LAYERSTACK    $env(INTEL_LAYERSTACK)
set INTEL_DOTP          dot2
set INTEL_FDK_LIB       b15
set INTEL_LIB_TYPE      8m_108
set INTEL_TRACKPATTERN  tp0
set INTEL_LIB_VENDOR    ""

# Specify if you want to use extended MWDB layers
set INTEL_EXTEND_MW_LAYERS 1

#######################################
#Tech File Variables
#######################################

set INTEL_GDS_OUT_LAYER_MAP       $env(INTEL_PDK)/apr/synopsys/${INTEL_LAYERSTACK}/${INTEL_LIB_TYPE}${INTEL_LIB_VENDOR}_${INTEL_TRACKPATTERN}/1222Ndm2GdsLayerMap
set INTEL_TECH_FILE               $env(INTEL_PDK)/apr/synopsys/${INTEL_LAYERSTACK}/${INTEL_LIB_TYPE}${INTEL_LIB_VENDOR}_${INTEL_TRACKPATTERN}/p1222_icc2.tf
set INTEL_MAX_TLUPLUS_FILE        $env(INTEL_PDK)/apr/synopsys/${INTEL_LAYERSTACK}/${INTEL_LIB_TYPE}${INTEL_LIB_VENDOR}_${INTEL_TRACKPATTERN}/pcss.tluplus
set INTEL_MIN_TLUPLUS_FILE        $env(INTEL_PDK)/apr/synopsys/${INTEL_LAYERSTACK}/${INTEL_LIB_TYPE}${INTEL_LIB_VENDOR}_${INTEL_TRACKPATTERN}/pcff.tluplus
set INTEL_MAX_TLUPLUS_EMUL_FILE   $env(INTEL_PDK)/apr/synopsys/${INTEL_LAYERSTACK}/${INTEL_LIB_TYPE}${INTEL_LIB_VENDOR}_${INTEL_TRACKPATTERN}/pcss.mfill.tluplus
set INTEL_MIN_TLUPLUS_EMUL_FILE   $env(INTEL_PDK)/apr/synopsys/${INTEL_LAYERSTACK}/${INTEL_LIB_TYPE}${INTEL_LIB_VENDOR}_${INTEL_TRACKPATTERN}/pcff.mfill.tluplus
set INTEL_TLUPLUS_MAP_FILE        $env(INTEL_PDK)/extraction/starrc/${INTEL_LAYERSTACK}/cmdfiles/asic.starrc.map

# Modular grid x and y
set INTEL_MD_GRID_X                 0.108
set INTEL_MD_GRID_Y                 0.630

# White space number
set INTEL_WS_X                      0.432
set INTEL_WS_Y                      0.630

#######################################
# Use/dont use library cell list for APR steps
#######################################

#######################################
#_TechMod_=floorplan
#######################################
set INTEL_STDCELL_TILE                   "core"
set INTEL_STDCELL_BONUS_GATEARRAY_TILE   "bonuscore"
set INTEL_STDCELL_CORE2H_TILE            "core2h"


# Voltage area separation cell for UPF design
set INTEL_VA_ISO_CELL */b15zdnnvian1d03x5

###############################################################
# Local fiducial and bonus FIB cells
#  Note: Local fiducials are inserted before place step.
#        Bonus FIB cells are only preplaced
###############################################################
set INTEL_DEBUG_CELLS [dict create {*}{
  pre_place {
    local_fid {
      ref_cell_list {b15qfd1x2an1nnpx5}
      x_step  {50.22}    y_step  {50.4}
      x_start {25.11}   y_start {12.6}
      prefix  {local_fiducial_preplace}
    }
    bonus_fib {
      ref_cell_list {
      {b15qgbar1an1n64x5}
      {b15qgbar1an1n64x5}
      {b15qbnna2bh1n16x5 b15qbnno2bh1n16x5 b15qbnbf1bh1n32x5 b15qbnin1bh1n40x5}
      {b15qbnff4bh1n08x5 b15qbnlf4bh1n08x5}
      {b15qbnna2bh1n16x5 b15qbnno2bh1n16x5 b15qbnbf1bh1n32x5 b15qbnin1bh1n40x5}
      {b15qgbar1an1n64x5}
      {b15qgbar1an1n64x5}
      }
      x_step {110.16}    y_step {110.25}
      x_start {55.08}   y_start {27.5625}
      prefix  {garrayfib}
      width_scale {1.5} height_scale {2.0}
    }
  }
}]

###############################################################
# Tap insert
###############################################################
set INTEL_TAP_CELL                       "${INTEL_FDK_LIB}ztpn00an1d00x5"
set INTEL_NWELL_TAP_CELL                 "${INTEL_FDK_LIB}ztpnw0an1n00x5"

###############################################################
# Antenna Diode
###############################################################
set INTEL_ANTENNA_DIODE            "${INTEL_FDK_LIB}ydpd00an1n00x5"

###############################################################
# filler cell insertion
###############################################################
set INTEL_BONUS_GATEARRAY_CELLS    "${INTEL_FDK_LIB}qgbar1an1n64x5 ${INTEL_FDK_LIB}qgbar1an1n32x5 ${INTEL_FDK_LIB}qgbar1an1n16x5 ${INTEL_FDK_LIB}qgbar1an1n08x5 ${INTEL_FDK_LIB}qgbar1an1n04x5"
set INTEL_STDCELL_FILLER_CELLS     "${INTEL_FDK_LIB}zdnn00an1n03x5 ${INTEL_FDK_LIB}zdnn00an1n02x5 ${INTEL_FDK_LIB}zdnn00an1n01x5"
set INTEL_DECAP_CELLS              "${INTEL_FDK_LIB}qgbdcpan1n64x5 ${INTEL_FDK_LIB}qgbdcpan1n32x5 ${INTEL_FDK_LIB}qgbdcpan1n16x5 ${INTEL_FDK_LIB}qgbdcpan1n08x5 ${INTEL_FDK_LIB}qgbdcpan1n04x5"

# Check grid configuration for all P1222.* dot processes:
#  layer = Layer name or LayerDataType name defined in techfile for layer of stripes for check grid, as specified by DIFFCHECK layer for P1222.* dot processes.
#  dir = Direction of layer stripes for check grid.
#  width = Width of layer stripes for check grid, as specified by DG_01 rule for P1222.* dot processes.  Measured in orthogonal of stripe direction.
#  pitch = Pitch between same side of edges of adjacent layer stripes for check grid, as specified by (DG_01 + DG_02) or PG_02 rule for P1222.* dot processes, must be > width.  Measured in orthogonal of stripe direction.
#  offset = Offset from partition boundary to side edge of 1st layer stripe for check grid, as specified by DG_04 or PG_04 rule for P1222.* dot processes, must be > -width && <= pitch - width.  Measured in orthogonal of stripe direction.
#  pullback = Space between partition/macro boundaries to ends of layer stripes for check grid.  Measured in stripe direction.
# NOTE: Sanity check included for pitch values to ensure INTEL_MD_GRID_X & INTEL_MD_GRID_Y are exact multiples of pitches of vertical & horizontal stripes respectively.
set INTEL_CHECK_GRID_CONFIG {
  diffCheck {
    dir       horizontal
    width     0.031
    pitch     0.090
    offset    -0.0155
    pullback  0.000
  }
}

#######################################
# Required dont use list
#######################################
# List the dont_use_list in the following format
# {cell_names} {reason of not using them}

set INTEL_DONT_USE [list \
  "vcc" {SPECIAL: voltage pins} \
  "vssx" {SPECIAL: voltage pins} \
  "${INTEL_FDK_LIB}qgbbf*" {FILL_ONLY:Functional bonus cells. Used during ECO mode} \
  "${INTEL_FDK_LIB}qgbao*" {FILL_ONLY:Functional bonus cells. Used during ECO mode} \
  "${INTEL_FDK_LIB}qgbbd*" {FILL_ONLY:Functional bonus cells. Used during ECO mode} \
  "${INTEL_FDK_LIB}qgbbf*" {FILL_ONLY:Functional bonus cells. Used during ECO mode} \
  "${INTEL_FDK_LIB}qgbca*" {FILL_ONLY:Functional bonus cells. Used during ECO mode} \
  "${INTEL_FDK_LIB}qgbco*" {FILL_ONLY:Functional bonus cells. Used during ECO mode} \
  "${INTEL_FDK_LIB}qgbff*" {FILL_ONLY:Functional bonus cells. Used during ECO mode} \
  "${INTEL_FDK_LIB}qgbin*" {FILL_ONLY:Functional bonus cells. Used during ECO mode} \
  "${INTEL_FDK_LIB}qgblf*" {FILL_ONLY:Functional bonus cells. Used during ECO mode} \
  "${INTEL_FDK_LIB}qgbmx*" {FILL_ONLY:Functional bonus cells. Used during ECO mode} \
  "${INTEL_FDK_LIB}qgbna*" {FILL_ONLY:Functional bonus cells. Used during ECO mode} \
  "${INTEL_FDK_LIB}qgbno*" {FILL_ONLY:Functional bonus cells. Used during ECO mode} \
  "${INTEL_FDK_LIB}qgboa*" {FILL_ONLY:Functional bonus cells. Used during ECO mode} \
  "${INTEL_FDK_LIB}qgbxo*" {FILL_ONLY:Functional bonus cells. Used during ECO mode} \
  "${INTEL_FDK_LIB}qgbdc*" {FILL_ONLY:Functional bonus cells} \
  "${INTEL_FDK_LIB}qgbdp*" {FILL_ONLY:Functional bonus cells} \
  "${INTEL_FDK_LIB}qgbth*" {FILL_ONLY:Functional bonus cells} \
  "${INTEL_FDK_LIB}qgbtl*" {FILL_ONLY:Functional bonus cells} \
  "${INTEL_FDK_LIB}qgbar*" {FILL_ONLY:Functional bonus cells} \
  "${INTEL_FDK_LIB}cbf*"      {RTL_ONLY: RTL instantiation required. Clock logical cells} \
  "${INTEL_FDK_LIB}cdiyr*"      {RTL_ONLY: RTL instantiation required. Clock logical cells} \
  "${INTEL_FDK_LIB}cinv*"      {RTL_ONLY: RTL instanttiation required. Clock logical cells} \
  "${INTEL_FDK_LIB}clb*"       {RTL_ONLY: RTL instantiation required. Clock logical cells} \
  "${INTEL_FDK_LIB}cmbn*"      {RTL ONLY: RTL instantiation required. Clock logical cells} \
  "${INTEL_FDK_LIB}cpsan*"     {RTL ONLY: RTL instantiation required. Clock logical cells} \
  "${INTEL_FDK_LIB}cpsbf*"    {RTL ONLY: RTL instantiation required. Clock logical cells} \
  "${INTEL_FDK_LIB}cpsin*"     {RTL ONLY: RTL instantiation required. Clock logical cells} \
  "${INTEL_FDK_LIB}cpsor*"     {RTL ONLY: RTL instantiation required. Clock logical cells} \
  "${INTEL_FDK_LIB}csb*"       {RTL ONLY: RTL instantiation required. Clock logical cells} \
  "${INTEL_FDK_LIB}fmy20*"       {2 stage Synchronizer} \
  "${INTEL_FDK_LIB}fmy30*"       {3 stage Synchronizer} \
  "${INTEL_FDK_LIB}tihi00*"      {Tie high cell} \
  "${INTEL_FDK_LIB}tilo00*"      {Tie low cell} \
  "${INTEL_FDK_LIB}bfm*"      {ROUTE_ONLY: Min delay buffers. Use during hold fixing} \
   ]

