#############################################################
# NAME :          set_pg_grid_config.dot2.8m_108.tcl
#
# SUMMARY :       define PG grid for .2 108pp tp0.
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists set_pg_grid_config.dot2.8m_108.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_POWER_PLAN_2_PG_GRID_CONFIG(array) INTEL_UPF INTEL_POWER_PLAN 
#
# PROCS USED :    None
#                         
# DESCRIPTION :   set_pg_grid_config.dot2.8m_108.tcl is to define the PG grid for .2 108pp tp0.
#
# EXAMPLES :      
#
###############################################################

# P/G grid configurations for P1222.2 dot process  cell library tp0 track pattern.

# NOTE: See create_pg_grid.tcl for syntax of INTEL_PG_GRID_CONFIG var.
set INTEL_POWER_PLAN_2_PG_GRID_CONFIG(mesh_nonupf) {
  m1 {
    pullback 0.08
    ground {
      pitch 0.216
      offset,width {
        0  0.068
      }
    }
    power {
      pitch 0.216
      offset,width {
        0.108  0.068
      }
    }
  }
  m2 {
    pullback 0.08
    ground {
      pitch 1.26
      offset,width {
        0  0.044
      }
    }
    power {
      pitch 1.26
      offset,width {
        0.630  0.044
      }
    }
  }
  m3 {
    pullback 0.08
    ground {
      pitch 1.08
      offset,width {
        0.00 0.044
      }
    }
    power {
      pitch 1.08
      offset,width {
        0.54  0.044
      }
    }
  }
  m4 {
    pullback 0.08
    ground {
      pitch 1.26
      offset,width {
        0.00  0.044
      }
    }
    power {
      pitch 1.26
      offset,width {
        0.63  0.044
      }
    }
  }
  m5 {
    pullback 0.08
    ground {
      pitch 1.08
      offset,width {
        0.00  0.044
      }
    }
    power {
      pitch 1.08
      offset,width {
        0.54  0.044
      }
    }
  }
  m6 {
    pullback 0.080
    ground {
      pitch 2.520
      offset,width {
        0.00  0.160
      }
    }
    power {
      pitch 2.520
      offset,width {
        1.260  0.160
      }
    }
  }
  m7 {
    pullback 0.27
    ground {
      pitch 8.64
      offset,width {
        0.00  1.08
      }
    }
    power {
      pitch 8.64
      offset,width {
        4.32  1.08
      }
    }
  }
}

# TODO: Check if need extra m6 power_va_primary, i.e. 2 * 0.108 width per 3.192 pitch, to match m6 ground.
# TODO: Check if even necessary for m4 & m5 power_va_aon, since they compromise m4 & m5 power_va_primary, 3 instead 6 per 6.384 & 1 instead 2 per 3.36 pitches respectively.
set INTEL_POWER_PLAN_2_PG_GRID_CONFIG(mesh_upf_1aosv) {
 m1 {
    pullback 0.08
    ground {
      pitch 0.216
      offset,width {
        0.000  0.068

      }
    }
    power_va_primary {
      pitch 0.216
      offset,width {
        0.108  0.068
      }
    }
  }
  m2 {
    pullback 0.08
    ground {
      pitch 1.26
      offset,width {
        0.000  0.044
      }
    }
    power_va_primary {
      pitch 1.26
      offset,width {
        0.630  0.044
      }
    }
  }
  m3 {
    pullback 0.08
    ground {
      pitch 1.08
      offset,width {
        0.00 0.044
      }
    }
    power_va_primary {
      pitch 1.08
      offset,width {
        0.54  0.044
      }
    }
  }
  m4 {
    pullback 0.08
    ground {
      pitch 1.26
      offset,width {
        0.00  0.044
      }
    }
    power_va_primary {
      pitch 1.26
      offset,width {
        0.63  0.044
      }
    }
  }
  m5 {
    pullback 0.08
    ground {
      pitch 1.08
      offset,width {
        0.00  0.044
      }
    }
    power_va_primary {
      pitch 1.08
      offset,width {
        0.54  0.044
      }
    }
  }
  m6 {
    pullback 0.08
    ground {
      pitch 2.52
      offset,width {
        0.000  0.160
      }
    }
    power_va_primary {
      pitch 5.04
      offset,width {
        1.26  0.160
      }
    }
    power_va_aon {
      pitch 5.04
      offset,width {
        3.78  0.160
      }
    }
  }
 m7 {
    pullback 0.27
    ground {
      pitch 8.64
      offset,width {
        0.00  1.08
      }
    }
    power_all_aon {
      pitch 8.64
      offset,width {
        4.32  1.08
      }
    }
  }
}


# Order of the 2 always-on power nets is based on $INTEL_UPF_POWER_NETS var, i.e. {aon,1 aon,2}.
# TODO: Check if even necessary for m4 & m5 power_va_aon, since they compromise m4 & m5 power_va_primary, 1 instead 3 per 3.192 & 5.04 pitches respectively.
set INTEL_POWER_PLAN_2_PG_GRID_CONFIG(mesh_upf_2aosv) {
 m1 {
    pullback 0.08
    ground {
      pitch 0.216
      offset,width {
        0.000  0.068
      }
    }
    power_va_primary {
      pitch 0.216
      offset,width {
        0.108  0.068
      }
    }
  }
  m2 {
    pullback 0.08
    ground {
      pitch 1.26
      offset,width {
        0.000  0.044
      }
    }
    power_va_primary {
      pitch 1.26
      offset,width {
        0.630  0.044
      }
    }
  }
  m3 {
    pullback 0.08
    ground {
      pitch 1.08
      offset,width {
        0.00 0.044
      }
    }
    power_va_primary {
      pitch 1.08
      offset,width {
        0.54  0.044

      }
    }
  }
  m4 {
    pullback 0.08
    ground {
      pitch 1.26
      offset,width {
        0.00  0.044
      }
    }
    power_va_primary {
      pitch 1.26
      offset,width {
        0.63  0.044
      }
    }
  }
  m5 {
    pullback 0.08
    ground {
      pitch 1.08
      offset,width {
        0.00  0.044
      }
    }
    power_va_primary {
      pitch 1.08
      offset,width {
        0.54  0.044
      }
    }
  }
  m6 {
    pullback 0.08
    ground {
      pitch 2.52
      offset,width {
        0.000  0.160
      }
    }
    power_va_primary {
      pitch 2.52
      offset,width {
        1.26  0.160
      }
    }
    power_va_aon,1 {
      pitch 2.52
      offset,width {
        0.63  0.160
      }
    }
    power_va_aon,2 {
      pitch 2.52
      offset,width {
        1.89  0.160
      }
    }
  }
 m7 {
    pullback 0.27
    ground {
      pitch 8.64
      offset,width {
        0.00  1.08
      }
    }
    power_all_aon,1 {
      pitch 8.64
      offset,width {
        2.16  1.08
      }
    }
    power_all_aon,2 {
      pitch 8.64
      offset,width {
        4.32  1.08
      }
    }
  }
}

if { $INTEL_UPF } {
  if { $INTEL_POWER_PLAN == {mesh_upf_1aosv} } {
    set INTEL_PG_GRID_CONFIG $INTEL_POWER_PLAN_2_PG_GRID_CONFIG($INTEL_POWER_PLAN)
  } elseif { $INTEL_POWER_PLAN == {mesh_upf_2aosv} } {
    set INTEL_PG_GRID_CONFIG $INTEL_POWER_PLAN_2_PG_GRID_CONFIG($INTEL_POWER_PLAN)
  } else {
    P_msg_error "$scr_name: Unsupported UPF power plan '$INTEL_POWER_PLAN' defined by 'INTEL_POWER_PLAN' var!  Expect 1 of 'mesh_upf_1aosv mesh_upf_2aosv'!"
  }
} else {
  set INTEL_PG_GRID_CONFIG $INTEL_POWER_PLAN_2_PG_GRID_CONFIG(mesh_nonupf)
}

# EOF

