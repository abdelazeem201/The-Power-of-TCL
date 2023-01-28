#############################################################
# NAME :          set_wiretracks.dot2.8m_108.tcl
#
# SUMMARY :       define .2 108pp tp0 pattern.
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists set_wiretracks.dot2.8m_108.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     None
#
# PROCS USED :    None
#                         
# DESCRIPTION :   set_wiretracks.dot2.8m_108.tcl is to create .2 108pp tp0 tracks in design
#
# EXAMPLES :      
#
#############################################################

###########################################################
# Create rule based tracks for non-uniform signal routing
###########################################################

set_message_info -id NDMUI-136 -limit 1

### Rule Based Track - non-uniform signal routing
P_msg_info "Creating width-specific wire tracks ..."

# m1
remove_track -layer m1
create_track -layer m1 -coord 0.000 -dir X -space 0.108 -end_grid_low_offset 0.068 -end_grid_high_offset 0.022 -end_grid_low_steps {0.090} -end_grid_high_steps {0.090} 

# m2
remove_track -layer m2
create_track -layer m2 -coord 0.000 -dir Y -space 0.090 

# m3
remove_track -layer m3
create_track -layer m3 -coord 0.000 -dir X -space 0.090 

# m4
remove_track -layer m4
create_track -layer m4 -coord 0.000 -dir Y -space 0.090 

# m5
remove_track -layer m5
create_track -layer m5 -coord 0.000 -dir X -space 0.090 

# m6
remove_track -layer m6
create_track -layer m6 -coord 0.000 -dir Y -space 1.260 
create_track -layer m6 -coord 0.180 -dir Y -space 1.260 
create_track -layer m6 -coord 0.270 -dir Y -space 1.260 
create_track -layer m6 -coord 0.360 -dir Y -space 1.260 
create_track -layer m6 -coord 0.450 -dir Y -space 1.260 
create_track -layer m6 -coord 0.540 -dir Y -space 1.260 
create_track -layer m6 -coord 0.630 -dir Y -space 1.260 
create_track -layer m6 -coord 0.720 -dir Y -space 1.260 
create_track -layer m6 -coord 0.810 -dir Y -space 1.260 
create_track -layer m6 -coord 0.900 -dir Y -space 1.260 
create_track -layer m6 -coord 0.990 -dir Y -space 1.260 
create_track -layer m6 -coord 1.080 -dir Y -space 1.260 

# m7
remove_track -layer m7
create_track -layer m7 -coord 0.000 -dir X -space 4.32


