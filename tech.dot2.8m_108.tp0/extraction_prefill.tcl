##############################################################
# NAME :          extraction_prefill.tcl
#
# SUMMARY :       set extraction options for prefill runs
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists extraction_prefill.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     None
#
# PROCS USED :    None
#                         
# DESCRIPTION :   extraction_prefill.tcl is to set extraction options for prefill runs.
#
# EXAMPLES :      
#
###################################################################################################
# Extraction Options
####################################

set_extraction_options \
  -real_metalfill_extraction none \
  -late_ccap_threshold 0.0005 \
  -early_ccap_threshold 0.0005 \
  -late_ccap_ratio 0.03 \
  -early_ccap_ratio 0.03 \
  -virtual_shield_extraction false 
set_parasitic_parameters -corners WORST -late_spec max_mfill_tluplus -early_spec max_mfill_tluplus
set_parasitic_parameters -corners BEST -late_spec min_mfill_tluplus -early_spec min_mfill_tluplus

report_parasitic_parameters
report_extraction_options

