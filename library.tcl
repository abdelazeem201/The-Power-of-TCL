###########################################################################
# Description: This file sets up libraries for the entire design
###########################################################################

# NOTE: This is a reference of what could be done. You can use hard paths here.
set INTEL_NDM_REF_LIBS {}
if {[info exists INTEL_APR_LIBS]} {
  dict for {key val} $INTEL_APR_LIBS {
    lappend INTEL_NDM_REF_LIBS {*}$val
  }
} else {
  P_msg_warn "INTEL_APR_LIBS not defined. Please check!"
}
