############################################################
# NAME :          connect_sec_pg_power_switch.tcl
#
# SUMMARY :       connect power switch secondaryPG pins
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists connect_sec_pg_power_switch.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_PS_SEC_PG(array) INTEL_DOTPROCESS INTEL_UPF_POWER_NETS
#
# PROCS USED :    P_msg_info P_create_offgrid_tracks P_check_and_insert_ladders 
#                         
# DESCRIPTION :   connect_sec_pg_power_switch.tcl is to connect the secondary PG pin of power switch
#
# EXAMPLES :      
#
#############################################################

define_user_attribute -class via -type boolean _sec_hookup_ -persistent

# Check if there are power switches in design if not return
set all_ps_cells [get_cells -hierarchical -filter "ref_name =~b15psbf10* || ref_name=~b15psbf20*"]

if { [sizeof_collection $all_ps_cells] == 0 } {
  P_msg_info "No power switches found in design"
  return
}

catch {unset tmp}

#Need to place cells before ladders are added, if not you get errors saying 
#cells are not placed
set _unplaced_cells ""
set _unplaced_cells [get_cells -quiet -hier -filter {is_placed==false}]
#Run quick placement - no optimization is done, just places cells
if {[sizeof_collection $_unplaced_cells]>0} {create_placement -effort very_low}

foreach_in_collection pd [get_power_domains -hier *] {
  if {[sizeof_collection [get_power_strategies -quiet -domain $pd -filter {type==SWITCH}]]>0} { 
    set pd_name [get_attr $pd full_name]
    set ps_name [get_attr [get_power_strategies -domain $pd -filter {type==SWITCH}] name];
    redirect -variable rpt_pd {report_power_domain $pd}
    set switch_line [regexp -inline -lineanchor -linestop \
      {^Power Switch\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)} $rpt_pd]
    set aon_pwr [lindex $switch_line 5]
    if { [llength [split $aon_pwr "/"]] > 0 } {
      if { [lsearch $INTEL_UPF_POWER_NETS [lindex [split $aon_pwr "/"] end]] > -1 } {
        set aon_pwr [lindex [split $aon_pwr "/"] end]
      }
    }
    set tmp($pd_name) $aon_pwr
    set cells [get_cells -hier *${ps_name}*] 
    #P_create_offgrid_tracks -cells $cells -pins vcc_in -skip_rg
    if {[info exists INTEL_PS_SEC_PG($pd_name)] && $INTEL_PS_SEC_PG($pd_name) !=""} {
      set via_ladder $INTEL_PS_SEC_PG($pd_name)
    } else {
      set via_ladder $INTEL_PS_SEC_PG(default)
    }

    #set via_ladder constraints on pins, then insert them
    foreach_in_collection c [list $cells] {
      set cn [get_object_name $c]
      set pn $cn/vcc_in
      set_via_ladder_constraints -pins $pn $via_ladder
    }
    insert_via_ladders -verbose true -clean false -allow_drc true -allow_patching true -allow_samenet_intersection true -ignore_rippable_shapes true
    #to report via ladder constrainst execute 'report_via_ladder_constraints'
    #to remove via ladder constraints execute 'remove_via_ladder_constraints [[-cell <list of cell instances> [-pin <pinname>]]
    #connect via ladder inserted to AON strap
    #Check for switches that dont have ladders, and retry inserting them if there are any
    #-all checks and inserts missing ladders as well as preroute vias to connect ladder to PG

    if { $INTEL_DOTP == "dot2" } {
      set reinsert_prv1 ""
      set onecell ""
      set tag "_sec_hookup_"
      foreach_in_collection onecell $cells {
        set cell_name [get_object_name $onecell]
        set bbox [get_attr $onecell bbox]       
        set _pg_vias "";                     
        set _pg_vias [get_objects_by_location -class via -within $bbox -filter ${tag}==true -quiet]  
        if {[sizeof_collection $_pg_vias]>0} { 
          P_msg_info "PG via connection exists over $cell_name. Please run P_remove_via_ladder on cell before inserting"
          continue                                                                                                  
        } else {                                                                                                    
          append_to_collection -unique reinsert_prv1 $onecell                                                                   
        }                                             
      } 

      if { [sizeof_collection $reinsert_prv1] > 0 } {
        foreach_in_collection cell1 $reinsert_prv1 {
          set cell_name [get_object_name $cell1]
          set bbox [get_attr $cell1 bbox]
          set shapes_on_ps [get_objects_by_location -class shape -within $bbox -filter "is_via_ladder==true && shape_use == user_route && net_type == power && layer_name == m5" -quiet]
          if { [sizeof_collection $shapes_on_ps] > 0 } {
            foreach_in_collection oneshape $shapes_on_ps {
              set oneLayoutShape [get_shapes $oneshape]  
              set onepoints [get_attr $oneLayoutShape points]   
              set x1 [lindex $onepoints 0 0]
              set y1 [lindex $onepoints 0 1]    
              set x2 [lindex $onepoints 1 0]
              set y2 [lindex $onepoints 1 1]    
              set y1_1 [expr $y1 - 0.270]
              set y2_1 [expr $y2 + 0.270]
              set  lbox "{$x1 $y1_1} {$x2 $y2_1}"
              set_attribute $oneLayoutShape points "$lbox"
            }
          }
        }
      }
    }
    P_check_and_insert_ladders -cells $cells
  }
}

# check open in vcc connection of ps cells
set all_ps_cells [get_cells -hierarchical -filter "ref_name =~b15psbf10* || ref_name=~b15psbf20*"]
if {[sizeof_collection $all_ps_cells]>0} {
  foreach_in_collection one_ps_cell $all_ps_cells {
    P_check_and_insert_ladders -cells $one_ps_cell -prv_connect
  }
}

#mark cells as unplaced and place them outside the design boundary
if {[sizeof_collection $_unplaced_cells]>0} {
  set_snap_setting -enabled false
  set_attribute $_unplaced_cells  physical_status unplaced
  reset_placement
  move_objects -x 0 -y 0 $_unplaced_cells
  set_snap_setting -enabled true
}
#to remove via ladders based on net, execute the following
#  remove_via_ladders -nets $net 

