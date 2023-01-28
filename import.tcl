
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
 setenv INTEL_ASIC          /scratch/HCL/top_apr
 setenv INTEL_PDK           /scratch/IntelPDK/lib/pdk222_r1.0HF8
 setenv INTEL_RUNSETS       /scratch/IntelPDK/lib/pdk222_r1.0HF8/runsets
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

set_ref_libs -add $env(INTEL_ASIC)/asicflows/synopsys/apr/inputs/mkdmem.nlib
set_ref_libs -add $env(INTEL_ASIC)/asicflows/synopsys/apr/inputs/mkriscv.nlib
set_ref_libs -add $env(INTEL_ASIC)/asicflows/synopsys/apr/inputs/mkimem.nlib
set_ref_libs -add $env(INTEL_ASIC)/asicflows/synopsys/apr/inputs/mkfpu.nlib
set_ref_libs -add $env(INTEL_STDCELLS)/ndm_ln_1/b15_ln.ndm


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
