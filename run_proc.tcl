##############################################################################


proc runADF {args} {
  global target_library link_library search_path mw_reference_library
  global INTEL_MW_LIB env
  global synopsys_program_name
  global suppress_errors
  global INTEL_SAVE_WD
  global INTEL_STEP_CURR

  foreach glbl [info globals INTEL_*] {
    global $glbl
  }

  if {[P_is_ICC] || [P_is_ICC2]} {
    set INTEL_STEPS $INTEL_APR_STEPS
    array set INTEL_SUBSTEPS [array get INTEL_APR_SUBSTEPS]
  } elseif {[P_is_DC]} {
    set INTEL_STEPS $INTEL_SYN_STEPS
    array set INTEL_SUBSTEPS [array get INTEL_SYN_SUBSTEPS]
  } else {
    P_msg_error "ERROR! No known tool type!"
    return 0
  }

  set pid [pid]
  set extension [P_save_extension]

  set func_name [string range [lindex [info level [info level]] 0] 2 end]
  parse_proc_arguments -args $args results

  global sh_output_log_file
  global sh_command_log_file

  ## report status if enabled (design must be open)
  if { [info exists results(-status) ] } {
    if { [P_current_design_status] } {
      P_get_design_status
      return 1
    } else {
      P_msg_error "Unable to determine status."
      return 1
    }
  }

  #########################################
  #  Setup

  # Support tmp_proj run with sync to INTEL_SAVE_WD
  if { ![info exists INTEL_SAVE_WD] } {
    set INTEL_SAVE_WD [pwd]
  }
  # If syncing data to $INTEL_SAVE_WD, make sure scripts/inputs are linked and needed dirs are in $INTEL_SAVE_WD.
  if {$INTEL_SAVE_WD != [pwd]} {
    sh ln -sf $INTEL_SAVE_WD/scripts .
    sh ln -sf $INTEL_SAVE_WD/inputs .
    if { ![file isdirectory $INTEL_SAVE_WD/$INTEL_MW_LIB] } { file mkdir $INTEL_SAVE_WD/$INTEL_MW_LIB }
    if {[P_is_DC] && [shell_is_in_topographical_mode] } {
    # DC topo needs both ddc/ & mwdb/ dirs.
      if { ![file isdirectory $INTEL_SAVE_WD/mwdb] } { file mkdir $INTEL_SAVE_WD/mwdb }
    }
    if { ![file isdirectory $INTEL_SAVE_WD/$INTEL_OUTPUTS_PATH] } { file mkdir $INTEL_SAVE_WD/$INTEL_OUTPUTS_PATH }
    if { ![file isdirectory $INTEL_SAVE_WD/$INTEL_REPORTS_PATH] } { file mkdir $INTEL_SAVE_WD/$INTEL_REPORTS_PATH }
    if { ![file isdirectory $INTEL_SAVE_WD/logs] } { file mkdir $INTEL_SAVE_WD/logs }
  }
  if { ![file isdirectory $INTEL_MW_LIB] } { file mkdir $INTEL_MW_LIB }
  if {[P_is_DC] && [shell_is_in_topographical_mode] } {
  # DC topo needs both ddc/ & mwdb/ dirs.
  if { ![file isdirectory mwdb] } { file mkdir mwdb }
  }
    if { ![file isdirectory $INTEL_OUTPUTS_PATH] } { file mkdir $INTEL_OUTPUTS_PATH }
    if { ![file isdirectory $INTEL_REPORTS_PATH] } { file mkdir $INTEL_REPORTS_PATH }

    if { [P_current_design_status] && ![info exists results(-continue)]  } {
      P_msg_error "Please specify -continue"
      P_msg_error "    or   "
      P_msg_error "close_mw_lib/close_lib and use -load "
      return 0
    }

    #########################################
    #  -Load
    if { [info exists results(-load)]  && ![file isdirectory $results(-load)] && [P_is_ICC]} {
      P_msg_error "Invalid library specified . path to MWDB required e.g. ./${INTEL_MW_LIB}/${INTEL_DESIGN_NAME}_import_design${extension}"
      return 0
    }
    if { [info exists results(-load)]  && ![file isdirectory $results(-load)] && [P_is_ICC2]} {
      P_msg_error "Invalid library specified . path to NDM required e.g. .${INTEL_MW_LIB}/${INTEL_DESIGN_NAME}_import_design${extension}"
      return 0
    }
    if { [info exists results(-load)]  && ![file exists $results(-load)] && [P_is_DC]} {
      P_msg_error "Invalid library specified . path to ddc required e.g. ./${INTEL_MW_LIB}/${INTEL_DESIGN_NAME}_import_design${extension}"
      return 0
    }
    if { [info exists results(-continue)] && [info exists results(-load)] } {
      P_msg_error "Invalid command line options! Cannot specify -load with -continue."
      return 0
    }

    if { [info exists results(-load)] && [llength $args] == 2 } {
      sh rm -rf ${INTEL_DESIGN_NAME}_${pid}${extension}
      #P_rsync $results(-load) ${INTEL_DESIGN_NAME}_${pid}${extension}
      #P_open_design $results(-load)
      #P_open_design ${INTEL_DESIGN_NAME}_${pid}${extension}
      P_open_design $results(-load)
      return 1
    }

    if { [info exists results(-load)] } {
      set load_lib $results(-load)
    }

    #########################################
    #  -Start
    # Define the name of the lib design will save to. $step_lib
    # Define lib to load and start from. $load_lib
    if { [info exists results(-start)] && ![info exists results(-load)] } {
      if {[lsearch -exact $INTEL_STEPS $results(-start)] > -1 } {
        set step_lib ${INTEL_MW_LIB}/${INTEL_DESIGN_NAME}_$results(-start)${extension}
        set load_step [lindex $INTEL_STEPS [expr [lsearch -exact $INTEL_STEPS $results(-start)] - 1]]
        if { $load_step eq "" } {
        # Starting from beginning. Don't define $load_step.
        } else {
        # If -start and user is still in tool, need to close current mw_lib and load saved one.
          if {[P_is_ICC]} {
            redirect /dev/null {[close_mw_lib]}
          } else {
            if {[sizeof_collection [current_lib -quiet]] > 0} {
              close_lib
            }
          } 
          set load_lib ${INTEL_MW_LIB}/${INTEL_DESIGN_NAME}_${load_step}${extension}
        }
      } else {
        P_msg_error "Cannot find start point $results(-start) "
        P_msg_error " Needs to be one of $INTEL_STEPS "
        return 0
        # Dont know what to do or where to start
      }
    } elseif { [info exists results(-start)] && [info exists results(-load)] } {
      P_msg_error "Cannot specify both -start and -load!"
    }

    #########################################
    #  Open Design
    # Open the $load_lib
    if { ![info exists results(-continue)] } {
      if { [info exists load_lib] } {
        if { [file exists $load_lib] } {
          P_msg_info " Starting with lib $load_lib"
          P_open_design ${load_lib}
        } else {
          P_msg_error "Cannot find MWDB to load $load_lib"
          return 0
        }
      }
    }

    #########################################
    #  -Load
    # Set step_lib when using -load
    if { [info exists results(-load)] && ![info exists results(step)] } {
      set tmp_step [lindex [file split $results(-load)] end]
      if { [info exists tmp_step] } {
        regsub "${INTEL_DESIGN_NAME}_" $tmp_step "" tmp_step
        regsub "$extension" $tmp_step "" tmp_step
        if {  [lsearch -exact $INTEL_STEPS $tmp_step] > -1 } {
          set idx [expr [lsearch -exact $INTEL_STEPS $tmp_step ] + 1 ]
          set next_step [lindex $INTEL_STEPS $idx]
          set step_lib ${INTEL_MW_LIB}/${INTEL_DESIGN_NAME}_${next_step}${extension}
          puts " STEP : $step_lib"
        } else {
          P_msg_error "specified MW $tmp_step  is not part of standard substeps "
          P_msg_error "--Valid steps :  $INTEL_STEPS "
          return 0
        }
      } else {
      # Assuming first STEP of INTEL_STEPS
      }
    }

    #########################################
    #  STEP RUN
    # Run custom steps
    #    or
    # Run through $INTEL_STEPS in order
    if { [info exists results(step)] } {
      for {set i 0 } { $i < [llength $results(step)] } {incr i} {
        set step [lindex $results(step) $i]
        if { [info exists INTEL_SUBSTEPS($step) ] } {
          lappend steps_to_run $step
          P_msg_info " $step -- $INTEL_SUBSTEPS($step)"
        } else  {
          P_msg_error "No substeps specified for step $step"
          return 0
        }
      }
      P_msg_info "Executing Custom Specified step : $results(step) "
    } else {
      set steps_done [get_completed_steps]
      set steps_to_run [P_lminus $INTEL_STEPS $steps_done]
      P_msg_info "  Completed steps $steps_done"

      if { [ info exists results(-stop)] && $results(-stop) != "" } {
        set step_stop $results(-stop)
        set substep_stop ""
        if { [string match "*:*" $results(-stop) ] } {
          set step_stop [lindex [split $results(-stop) ":" ] 0]
          set substep_stop [lindex [split $results(-stop) ":" ] 1]
        }
        if { [lsearch $steps_to_run $step_stop] > -1 } {
          if { $substep_stop != "" } {
            set completed_substeps [get_completed_substeps $step_stop]
            if { [lsearch $INTEL_SUBSTEPS($step_stop) $substep_stop] < 0 } {
              P_msg_error "Specified stop $results(-stop) needs to be one of  $INTEL_SUBSTEPS($step_stop) "
              return 0
            } elseif { [lsearch $completed_substeps $substep_stop] > -1 && [llength [lsearch -exact -all $INTEL_SUBSTEPS($step_stop) $substep_stop]] < 2} {
            # Check if step was already completed. But don't stop if there is more than one step in the step with the same name.
              P_msg_error " Specified stop $results(-stop) already executed!"
              P_msg_error "  Completed: $completed_substeps"
              P_msg_error "  Of:        $INTEL_SUBSTEPS($step_stop)"
              return 0
            }
          }
        } else {
          P_msg_error "Specified stop $results(-stop) maybe already done/ or specified incorrectly  "
          P_msg_error "Specified step Needs to be one of : $steps_to_run "
          return 0
        }
      }
    }

    #########################################
    #  Start from beginning!
    #  Create mwdb
    if { ![info exists load_lib] && ![info exists results(-continue)] } {
      P_msg_info " Starting from first step:  [lindex $steps_to_run 0]"
      set step_lib ${INTEL_DESIGN_NAME}_${pid}${extension}
      set test_lib ""
      if { [P_current_design_status] && ![info exists results(-continue)]  } {
        if {[P_is_ICC]} {
          set test_lib [get_object_name [current_mw_lib]]
        } else if {[P_is_ICC2]} {
          set test_lib [get_object_name [current_lib]]
        }
      }
      if { [file exists $step_lib] && $step_lib == $test_lib && ![info exists results(-continue)]} {
        P_msg_error " MWDB exists Please delete MWDB $step_lib to restart "
        return 0
      }
      if { [file isdirectory ${step_lib}] } {
        P_msg_info " ${step_lib} already exists! "
        P_msg_info " Deleting local version $step_lib "
        catch {file delete -force  ${step_lib}} tmpvar
        if {$tmpvar != "" } {
          catch {sh mv ${step_lib} junk${extension}} movevar
        }
      }
      if {[P_is_ICC]} {
        create_mw_lib -technology $INTEL_TECH_FILE -mw_reference_library $mw_reference_library -open $step_lib
      } elseif {[P_is_ICC2]} {
        create_lib $step_lib -technology $INTEL_TECH_FILE -ref_libs $INTEL_NDM_REF_LIBS
      }
    }

    #########################################
    # -continue
    # Continue on Existing Open MWDB

    if { [info exists results(-continue) ] && [P_is_ICC]} {
      set step_lib [get_object_name [current_mw_lib]]
    }
    if { [info exists results(-continue) ] && [P_is_ICC2]} {
      set step_lib [get_object_name [current_lib]]
    }

    #########################################
    #  MAIN LOOP
    #  For loop through steps.
    set in_step_loop 0
    set return_after_mark 0
    for {set ii 0 } {$ii < [llength $steps_to_run] } { incr ii } {
      set step [lindex $steps_to_run $ii]
      set INTEL_STEP_CURR $step
      set step_log_file ${INTEL_LOG_PATH}/${step}.log
      set step_command_log_file ${INTEL_LOG_PATH}/${step}.cmd_log

      if { [file exists ${INTEL_LOG_PATH}/${step}.log] && ![info exists results(-continue)] } {
        file copy -force ${INTEL_LOG_PATH}/${step}.log ${INTEL_LOG_PATH}/${step}.log.bak
      }
      if { [file exists ${INTEL_LOG_PATH}/${step}.cmd_log] && ![info exists results(-continue)] } {
        file copy -force ${INTEL_LOG_PATH}/${step}.cmd_log ${INTEL_LOG_PATH}/${step}.cmd_log.bak
      }
      set sh_output_log_file $step_log_file
      set sh_command_log_file $step_command_log_file
      P_msg_info " Setting log file  : $step_log_file"

      # INTEL_SKIP_SUBSTEPS: allow user to skip substeps in a STEP via INTEL_ var.
      if { [info exists INTEL_SKIP_STEP] && $INTEL_SKIP_SUBSTEPS != "" && [regexp "(^| )${step}( |$)" $INTEL_SKIP_SUBSTEPS match] } {
        P_msg_info "Skipping the following: ${step}"
        mark_step $step "Skipped"
        continue
      }

      # copy over lib to load and work within for ICC only, otherwise just read_ddc in DC.
      if { [info exists load_lib]  && ![info exists results(-continue)] } {
        if {[P_is_ICC]} {
          redirect /dev/null {[close_mw_lib ${load_lib}]}
          set step_lib  ${INTEL_DESIGN_NAME}_${pid}${extension}
          P_msg_info "Loading $load_lib (moving to $step_lib first)"
          P_msg_info "rsync-ing $load_lib to $step_lib "
          P_rsync $load_lib $step_lib
          if { [file exists [file tail $load_lib]] } {
            redirect /dev/null {[close_mw_lib ${load_lib}]}
            P_msg_info " Removing work dir copy [file tail $load_lib]"
            #file delete -force [file tail $load_lib]
            catch {file delete -force [file tail $load_lib]} tmpvar
            if {$tmpvar != "" } {
              catch {sh mv [file tail $load_lib] junk${extension}} movevar
            }
          }
          P_open_design ${step_lib}
        } elseif {[P_is_ICC2]} {
          redirect /dev/null {[close_block ${INTEL_DESIGN_NAME}]}
          set step_lib  ${INTEL_DESIGN_NAME}_${pid}${extension}
          P_msg_info "Loading $load_lib (moving to $step_lib first)"
          P_msg_info "rsync-ing $load_lib to $step_lib "
          P_rsync $load_lib $step_lib
          if { [file exists [file tail $load_lib]] } {
            redirect /dev/null {[close_lib ${load_lib}]}
            P_msg_info " Removing work dir copy [file tail $load_lib]"
            #file delete -force [file tail $load_lib]
            catch {file delete -force [file tail $load_lib]} tmpvar
            if {$tmpvar != "" } {
              catch {sh mv [file tail $load_lib] junk${extension}} movevar
            }
          }
          P_open_design ${step_lib}
        } elseif {[P_is_DC]} {
          set step_lib $load_lib
        }

      }
      set start_step_time [clock seconds]

      # Define step specific active scenarios
      if {[info exists INTEL_MCMM] && $INTEL_MCMM == 1 && ![P_is_ICC2]} {
        if { [all_scenarios] != "" } {
          set_active_scenarios [all_scenarios]
          if { [info exists INTEL_MCMM_SCENARIO_ACTIVE($step)] && $INTEL_MCMM_SCENARIO_ACTIVE($step) != "" } {
            P_msg_info "Setting the following as active scenarios in step $step :  $INTEL_MCMM_SCENARIO_ACTIVE($step)"
            set_active_scenarios $INTEL_MCMM_SCENARIO_ACTIVE($step)
          } else {
            P_msg_info "Current active scenarios : [all_active_scenarios]"
          }
          P_msg_info "Setting the following default active scenarios in step $step :  $INTEL_MCMM_SCENARIO_DEFAULT"
          current_scenario $INTEL_MCMM_SCENARIO_DEFAULT
        }
      }

      #
      # Manage substeps to be run
      # Trim substeps to be run only if -continue specified else run STEP from start.
      #
      set substeps_to_run  $INTEL_SUBSTEPS($step)
      set substeps_done ""
      if { [info exists results(-continue) ] } {
        set substeps_done [get_completed_substeps $step]
        set substeps_to_run [P_lminus $substeps_to_run $substeps_done]
      }

      P_msg_info "  ALL $step substeps : $INTEL_SUBSTEPS($step)"
      if {[P_is_ICC]} {
        P_msg_info "  Current MW lib  : [get_object_name [current_mw_lib]]"
      }
      P_msg_info "  Completed substeps : $substeps_done"
      P_msg_info "  Remaining substeps : $substeps_to_run "

      #########################################
      #  MAIN LOOP
      #  For loop through substeps.
      if { [llength $substeps_to_run]  > 0 } {
        for {set jj 0 } {$jj < [llength $substeps_to_run ] } { incr jj } {
          set substep [lindex $substeps_to_run $jj]
          # Skip STEP
          if { [info exists INTEL_SKIP_SUBSTEPS] && $INTEL_SKIP_SUBSTEPS != "" && [regexp "(^| )${step}:${substep}( |$)" $INTEL_SKIP_SUBSTEPS match] } {
            P_msg_info "Skipping the following: ${step}:${substep}"
            mark_substep $step $substep "Skipped"
            continue
          }
          P_msg_info "Executing substep $substep"
          set start_substep_time [clock seconds]

          source_if_exists ${substep}.tcl

          set duration [P_rdtConvertSeconds [expr ([clock seconds] - $start_substep_time)]]
          P_msg_info "Time to run substep $substep in (hh:mm:ss) : $duration hrs"
          mark_substep $step $substep "$duration"
          if { [info exists results(-stop)] && [string match $results(-stop) ${step}:${substep} ] > 0 } {
            if { [P_lminus $INTEL_SUBSTEPS($step) [get_completed_substeps $step]] == "" } {
            # Don't return yet, make sure you Mark the STEP as done and set time stamps
              set return_after_mark 1
            } else {
              P_msg_info "Stopping per users request: -stop ${step}:${substep}"
              return
            }
          }
        }

        set duration [P_rdtConvertSeconds [expr ([clock seconds] - $start_step_time)]]
        P_msg_info "Time to run step $step in (hh:mm:ss) : $duration hrs"
        set mem_fp [expr [mem]/1024.0]
        if { $mem_fp > 1024.0 } {
          set mem_fp [format "%7.2f GB" [expr [mem]/(1024.0*1024)]]
        } else {
          set mem_fp [format "%7.2f MB" [expr [mem]/1024.0]]
        }
        mark_step $step "$duration  $mem_fp"
      } else {
        P_msg_info "Nothing to be done for Step. All substeps already completed "
        mark_step $step "0  0"
      }
      set start_ro_time [clock seconds]

      P_msg_info "Saving design ${INTEL_DESIGN_NAME} ..."
      P_save_design $step

      if { [info exists INTEL_REPORTS($step) ] && $INTEL_REPORTS($step) != "" } {
        P_reports $step
      } else {
        P_msg_info " No report requirement specified INTEL_REPORTS($step) "
      }
      if { [info exists INTEL_OUTPUTS($step) ] && $INTEL_OUTPUTS($step) != "" } {
        P_outputs $step
      } else {
        P_msg_info " No report requirement specified INTEL_OUTPUTS($step) "
      }

      if {[P_is_ICC] || [P_is_ICC2]} {
        set save_lib  ${INTEL_DESIGN_NAME}_${step}${extension}
        P_msg_info "Saving/rsync-ing  $step_lib into ${INTEL_MW_LIB}/${save_lib}"
        P_rsync ${step_lib} "${INTEL_MW_LIB}/${save_lib}"
      }

      #Rsync results back to INTEL_SAVE_WD
      if { $INTEL_SAVE_WD != [pwd] } {
        P_msg_info "Saving/rsync-ing ${step_lib} back to $INTEL_SAVE_WD"
        P_rsync  "${INTEL_MW_LIB}/${save_lib}" "${INTEL_SAVE_WD}/${INTEL_MW_LIB}/${save_lib}"
        sh rm -rf ${INTEL_SAVE_WD}/reports/${INTEL_DESIGN_NAME}.${step}.*
        sh rm -rf ${INTEL_SAVE_WD}/outputs/${INTEL_DESIGN_NAME}.${step}.*
        if { [glob -nocomplain reports/${INTEL_DESIGN_NAME}.${step}.*] != "" } {
          sh cp -pf reports/${INTEL_DESIGN_NAME}.${step}.* ${INTEL_SAVE_WD}/reports/
        }
        if { [glob -nocomplain outputs/${INTEL_DESIGN_NAME}.${step}.*] != "" } {
          sh cp -pf outputs/${INTEL_DESIGN_NAME}.${step}.* ${INTEL_SAVE_WD}/outputs/
        }
        sh cp -pf logs/${step}.* ${INTEL_SAVE_WD}/logs/
      }
      set duration [P_rdtConvertSeconds [expr ([clock seconds] - $start_ro_time)]]
      P_msg_info "Time to create reports and outputs for $step in (hh:mm:ss) : $duration hrs"

      if {$return_after_mark == 1} {
        set return_after_mark 0
        P_msg_info "Stopping per users request: -stop ${step}:${substep}"
        return
      }

      if { [info exists load_lib] } {
        unset load_lib
      }
      if { [info exists results(-continue)] } {
        unset results(-continue)
      }
      if { [info exists results(-stop)] && [string match $results(-stop) $step] > 0 } {
        P_msg_info " Stopping at $step as required by -stop $results(-stop)"
        return
      }
    }
}

define_proc_attributes runADF \
  -info "ICF Flow Control" \
  -define_args { \
                 {step "Custom step/s to execute" step list optional } \
                 {-load "Load a mwdb" step string optional} \
                 {-start "Step start" step string optional} \
                 {-stop "Step stop" step string optional } \
                 {-continue "Continue with current mwdb in memory" "" boolean  optional } \
                 {-status "Report status" "" boolean optional } \
}


proc P_get_design_status {args} {
  foreach glbl [info globals INTEL_*] {
    global $glbl
  }
  parse_proc_arguments -args $args results


  if { [P_current_design_status] } {
  # Cell open
  } else {
    P_msg_error "Unable to determine status. No MW cel open"
    return 0
  }

  if {[P_is_ICC] || [P_is_ICC2]} {
    set INTEL_STEPS $INTEL_APR_STEPS
    array set INTEL_SUBSTEPS [array get INTEL_APR_SUBSTEPS]
  } elseif {[P_is_DC]} {
    set INTEL_STEPS $INTEL_SYN_STEPS
    array set INTEL_SUBSTEPS [array get INTEL_SYN_SUBSTEPS]
  } else {
    P_msg_error "ERROR! No known tool type!"
    return 0
  }

  redirect -variable aa {list_attributes -class [P_get_class]}
  set steps_run [get_completed_steps]
  #set custom_steps [P_lminus $steps_run $INTEL_STEPS]
  set steps_not_run [P_lminus $INTEL_STEPS $steps_run]
  P_msg_info " Steps run : $steps_run"
  if { ! [info exists results(-verbose)]  && ![info exists results(step)]} {
    puts "============================================================================================================="
    puts "      STEP  Name      :  Duration/Status "
    puts "-------------------------------------------------------------------------------------------------------------"
    for {set i 0 } { $i < [llength $steps_run] } { incr i} {
      set step [lindex $steps_run $i]
      puts " [format %30s $step ] : [get_attribute -quiet [P_get_current] step:${step}]"
    }
    for {set i 0 } { $i < [llength $steps_not_run] } { incr i} {
      set step [lindex $steps_not_run $i]
      puts " [format %30s $step ] : Not Run/Skipped"
    }
    return
  }
  if { ![info exists results(-verbose)] && [info exists results(step)] } {
    set step $results(step)
    set steps_run [P_lcommon [get_completed_steps] $results(step)]
    puts "============================================================================================================="
    puts "                  STEP  Name    :  [format %10s $step]  : [get_attribute -quiet [P_get_current] step:${step}]"
    puts "                          Step  :  Duration    :  Script Used "
    puts "-------------------------------------------------------------------------------------------------------------"
    for {set j 0 } {$j < [llength $INTEL_SUBSTEPS($step) ] } { incr j } {
      set step [lindex $INTEL_SUBSTEPS($step) $j]
      redirect -variable file {P_source_if_exists ${substep}.tcl -display}
      set substep_duration [get_attribute -quiet [P_get_current] step_${step}:${substep}]
      if {$substep_duration == ""} { set substep_duration "Skipped " }
      puts " [format %30s $step] :  $substep_duration  :$file "
    }
    return

  }
  if { ![info exists results(step)] } {
    for {set i 0 } { $i < [llength $steps_run] } { incr i} {
      set step [lindex $steps_run $i ]
      puts "============================================================================================================="
      puts "                  Step  Name    :  [format %10s $step]  : [get_attribute -quiet [P_get_current] step:${step}]"
      puts "                       substep  :  Duration    :  Script Used "
      puts "-------------------------------------------------------------------------------------------------------------"
      for {set j 0 } {$j < [llength $INTEL_SUBSTEPS($step) ] } { incr j } {
        set substep [lindex $INTEL_SUBSTEPS($step) $j]
        redirect -variable file {P_source_if_exists ${substep}.tcl -display}
        set substep_duration [get_attribute -quiet [P_get_current] step_${step}:${substep}]
        if {$substep_duration == ""} { set substep_duration "Skipped " }
        puts " [format %30s $substep] :  $substep_duration  :$file "
      }
    }
  }
  for {set i 0 } { $i < [llength $steps_not_run] } { incr i} {
    set step [lindex $steps_not_run $i ]
    puts "============================================================================================================="
    puts "  Step  Name    :   $step "
    puts "    Status      :   Not Run / Skipped"
    puts "-------------------------------------------------------------------------------------------------------------"
    puts "                          Step  :  Duration  :  Script Used "
    puts "-------------------------------------------------------------------------------------------------------------"
    for {set j 0 } {$j < [llength $INTEL_SUBSTEPS($step) ] } { incr j } {
      set substep [lindex $INTEL_SUBSTEPS($step) $j]
      redirect -variable file {P_source_if_exists ${substep}.tcl -display}
      puts " [format %30s $substep] :  Not Run   :$file "
    }
  }

}

define_proc_attributes P_get_design_status \
  -info "Get design status" \
  -define_args { \
                 {step "status of specific" step list optional } \
                 {-verbose  "detail status report" "" boolean optional } \
}


proc P_rsync {from to} {
#catch {sh rsync --archive --verbose --delete --exclude="*@*" --exclude="*_INIT_RT_*" --exclude="*_fdksave_*" --exclude="*.lock"  ${from}/ ${to} } tmpvar
#puts $tmpvar
  if { [file exists $to] } {
    sh rm -rf $to
  }
  save_lib -as $to
}

proc P_open_design {arg} {

  global INTEL_DESIGN_NAME mw_reference_library mw_design_library INTEL_TECH_FILE INTEL_MAX_TLUPLUS_FILE INTEL_TLUPLUS_MAP_FILE

  if {[P_is_ICC]} {
    open_mw_lib $arg
    open_mw_cel $INTEL_DESIGN_NAME
  } elseif {[P_is_ICC2]} {
    open_lib $arg 
    open_block ${INTEL_DESIGN_NAME}
  } elseif {[P_is_DC]} {
    if { [shell_is_in_topographical_mode] } {
      redirect -variable aa {current_mw_lib}
      if { [string match "*No current milkyway library*" $aa] } {
        if {[file exists ./mwdb/${INTEL_DESIGN_NAME}_syn_LIB]} {
          open_mw_lib mwdb/${INTEL_DESIGN_NAME}_syn_LIB
        } else {
          file delete -force -- ./mwdb/${INTEL_DESIGN_NAME}_syn_LIB
          set_app_var mw_design_library ./mwdb/${INTEL_DESIGN_NAME}_syn_LIB
          create_mw_lib -technology $INTEL_TECH_FILE  -mw_reference_library $mw_reference_library $mw_design_library
          open_mw_lib $mw_design_library
        }
      }
      set_tlu_plus_files -max_tluplus $INTEL_MAX_TLUPLUS_FILE -min_tluplus $INTEL_MAX_TLUPLUS_FILE -tech2itf_map $INTEL_TLUPLUS_MAP_FILE
    }
    read_ddc $arg
  } else {
    P_msg_error "ERROR! No known tool type!"
  }

}

proc P_save_design {arg} {

  global INTEL_DESIGN_NAME
  global INTEL_MCMM
  global INTEL_MW_LIB
  if {[P_is_ICC]} {
    if {$INTEL_MCMM == 1} {
      save_mw_cel -as ${INTEL_DESIGN_NAME} -scenarios [all_scenarios]
    } else {
      save_mw_cel -as ${INTEL_DESIGN_NAME}
    }
  } elseif {[P_is_ICC2]} {
    save_block -as ${INTEL_DESIGN_NAME}
  } elseif {[P_is_DC]} {
    write_file -format ddc -hierarchy -output $INTEL_MW_LIB/${INTEL_DESIGN_NAME}_${arg}.ddc
  } else {
    P_msg_error "ERROR! No known tool type!"
  }

}

# Proc P_current_design_status
# Returns 1 if the design is loaded.
# Returns 0 if the design isn't loaded.
proc P_current_design_status {} {

  global INTEL_DESIGN_NAME

  if {[P_is_ICC]} {
    redirect -variable aa {current_mw_lib}
    if { [string match "*No current milkyway library*" $aa] } {
      return 0
    } else {
      return 1
    }
  } elseif {[P_is_ICC2]} {
    redirect -variable aa {current_block}
    if { [string match "*Current block is not defined*" $aa] } {
      return 0
    } else {
      return 1
    }
  } elseif {[P_is_DC]} {
    redirect -variable aa {current_design}
    if { [string match "*Current design is not defined*" $aa] } {
      return 0
    } else {
      return 1
    }
  } else {
    P_msg_error "ERROR! No known tool type!"
  }

}

proc P_save_extension {} {
  if {[P_is_ICC2]} {
    return ".nlib"
  } elseif {[P_is_ICC]} {
    return "_LIB"
  } elseif {[P_is_DC]} {
    return ".ddc"
  } else {
    P_msg_error "ERROR! No known tool type!"
  }
}

proc P_get_class {} {
  if {[P_is_ICC]} {
    return "mw_cel"
  } elseif {[P_is_ICC2]} {
    return "block"
  } elseif {[P_is_DC]} {
    return "design"
  } else {
    P_msg_error "ERROR! No known tool type!"
  }
}

proc P_get_current {} {
  set command "current_"
  append command [P_get_class]
  redirect /dev/null {set obj [eval $command]}
  return $obj
}


proc mark_step {step {comment ""}} {
  set done_steps ""
  if {$comment eq ""} { set comment "Marked/Skipped" }
  if { [P_current_design_status] } {
    set done_steps [get_attribute -quiet [P_get_current] completed_steps]
    lappend done_steps $step
    set additional_option ""
    if {[P_is_ICC2]} {
      set additional_option "-persistent"
    }
    if {$additional_option != "" } {
      define_user_attribute -class [P_get_class] -type string step:${step} -quiet $additional_option 
      set_attribute -quiet [P_get_current] step:$step $comment
      define_user_attribute -class [P_get_class] -type string  completed_steps -quiet $additional_option 
      set_attribute -quiet [P_get_current] completed_steps $done_steps
    } else {
      define_user_attribute -class [P_get_class] -type string step:${step} -quiet  
      set_attribute -quiet [P_get_current] step:$step $comment
      define_user_attribute -class [P_get_class] -type string  completed_steps -quiet  
      set_attribute -quiet [P_get_current] completed_steps $done_steps
    }
  }
}


proc mark_substep {step substep {comment ""}} {
  global INTEL_SYN_SUBSTEPS INTEL_APR_SUBSTEPS

  if {[P_is_ICC] || [P_is_ICC2]} {
    array set INTEL_SUBSTEPS [array get INTEL_APR_SUBSTEPS]
  } elseif {[P_is_DC]} {
    array set INTEL_SUBSTEPS [array get INTEL_SYN_SUBSTEPS]
  } else {
    P_msg_error "ERROR! No known tool type!"
    return 0
  }

  if {$comment eq ""} { set comment "Marked/Skipped" }
  if {[P_is_ICC2]} {
    define_user_attribute -class [P_get_class] -type string  step:${step} -quiet -persistent
    define_user_attribute -class [P_get_class] -type string  completed_substeps:${step} -quiet -persistent
    define_user_attribute -class [P_get_class] -type string  step_${step}:${substep} -quiet -persistent
  } else {
    redirect /dev/null {define_user_attribute -class [P_get_class] -type string  step:${step} -quiet }
    redirect /dev/null {define_user_attribute -class [P_get_class] -type string  completed_substeps:${step} -quiet}
    redirect /dev/null {define_user_attribute -class [P_get_class] -type string  step_${step}:${substep} -quiet}
  } 
  redirect -variable aa {list_attributes -class [P_get_class]}
  if { [P_current_design_status] } {
    set done_substeps [get_completed_substeps $step]
    foreach index [lsearch -all  $INTEL_SUBSTEPS($step) $substep] {
      if {[lindex $done_substeps $index] != $substep } {
        set done_substeps [linsert $done_substeps $index $substep]
        break
      }
    }
    redirect /dev/null {set_attribute [P_get_current] completed_substeps:${step} $done_substeps}
    redirect /dev/null {set_attribute [P_get_current] step_${step}:${substep} $comment}
  }

}


proc unmark_step {step} {
  set done_steps ""
  if { [P_current_design_status] } {
    redirect /dev/null {redirect -variable aa {list_attributes -class [P_get_class]}}
    set done_steps [get_attribute [P_get_current] completed_steps]
    set done_steps [P_lminus $done_steps $step]
    redirect /dev/null {set_attribute [P_get_current] completed_steps $done_steps}
    foreach substep [get_completed_substeps $step] { unmark_substep $step $substep }
  }
}


proc unmark_substep {step substep} {
  redirect -variable aa {list_attributes -class [P_get_class]}
  set steps_run [P_lsearch $aa step*]
  set attr_to_remove [P_lsearch $steps_run step_${step}:$substep]
  foreach attr $attr_to_remove {
    redirect /dev/null {remove_attribute -quiet [P_get_current] $attr}
  }
  set done_substeps [get_attribute [P_get_current] completed_substeps:${step}]
  set updated_done_substeps [P_lminus_r $done_substeps $substep]
  redirect /dev/null {set_attribute [P_get_current] completed_substeps:${step} $updated_done_substeps}
  redirect /dev/null {redirect -variable aa {list_attributes -class [P_get_class]}}
  set done_steps [get_attribute [P_get_current] completed_steps]
  set done_steps [P_lminus $done_steps $step]
  redirect /dev/null {set_attribute [P_get_current] completed_steps $done_steps}
}


proc get_completed_steps {args} {
  parse_proc_arguments -args $args results

  set done_steps ""
  if { [P_current_design_status] } {
    if { [info exists results(step)] } {
      redirect -variable aa {list_attributes -class [P_get_class]}
      set done_steps [ get_attribute [P_get_current] completed_steps]
      foreach done_step $done_steps {
        if {$done_step eq $results(step)} {
          return $done_step
        }
      }
    } else {
      redirect -variable aa {list_attributes -class [P_get_class]}
      set done_steps [ get_attribute [P_get_current] completed_steps]
      return $done_steps
    }
  } else {
    return $done_steps
  }
}
define_proc_attributes get_completed_steps \
  -info "Get a list of complted steps" \
  -define_args { \
                 {step "Return step if it had completed." step list optional }
}


proc get_completed_substeps {step} {
  set done_substeps ""
  if { [P_current_design_status] } {
    redirect -variable aa {list_attributes -class [P_get_class]}
    set done_substeps [ get_attribute [P_get_current] completed_substeps:${step} -quiet]
    return $done_substeps
  } else {
    return $done_substeps
  }
}


