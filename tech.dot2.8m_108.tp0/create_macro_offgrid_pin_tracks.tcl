##############################################################
# NAME :          create_macro_offgrid_pin_tracks.tcl
#
# SUMMARY :       create macro offgrid pin tracks for macro pin connections
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists create_macro_offgrid_pin_tracks.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_OFFGRID_LAYERS
#
# PROCS USED :    None
#                         
# DESCRIPTION :   create_macro_offgrid_pin_tracks.tcl is to create offgrid pin tracks for macro pin connections
#
# EXAMPLES :      
#
###############################################################
# Check: Are there any macro cells?
if {[sizeof_collection [filter_collection [get_cells -quiet -physical_context ] "is_hard_macro==true || is_soft_macro==true"]] == 0} {
  P_msg_info "There are no macro cells in this design"
  return
}

set macros [get_cells -quiet -physical_context -filter "is_hard_macro==true || is_soft_macro==true"]

proc resize_bbox { bbox bloat_x bloat_y } {
  scan [join [join $bbox]] "%f %f %f %f" llx lly urx ury
  set bbox_new "[expr {$llx - $bloat_x}] [expr {$lly - $bloat_y}] [expr {$urx + $bloat_x}] [expr {$ury + $bloat_y}]"
  return $bbox_new
}
## Only defines track in given area
#set_route_zrt_common_options -track_use_area true
set_app_options -name route.common.track_use_area  -value true
#set_route_zrt_common_options -connect_within_pins_by_layer_name { {m5 via_wire_all_pins } }
#report_app_options route.common.connect_within_pins_by_layer_name
#set_app_options -name route.common.connect_within_pins_by_layer_name -value [list [list m1 via_standard_cell_pins] [list m5 via_wire_all_pins] ]
#report_app_options route.common.connect_within_pins_by_layer_name

global INTEL_OFFGRID_LAYERS
set debug 1
## Need to check which layers pins are on
#echo "Running add_macro_tracks for $INTEL_OFFGRID_LAYERS"
if {[info exist INTEL_OFFGRID_LAYERS] && $INTEL_OFFGRID_LAYERS != ""} {
  foreach_in_collection m [get_cells $macros] {
    foreach layer $INTEL_OFFGRID_LAYERS {
      set dir [get_attribute [get_layers $layer] routing_direction]
      echo :layer: $layer :dir: $dir :macro: [get_object_name $m]
      foreach_in_collection pin [ get_shapes -quiet -of_objects [get_pins -of_objects $m -filter "layer_name==$layer && (port_type==signal || port_type==clock)" -quiet] ] {
        set bbox [get_attr $pin bbox]
        scan [get_attr $pin bbox] "{%f %f} {%f %f}" x_ll y_ll x_ur y_ur
        if {$dir eq "horizontal"} {
          set width [format %.3f [expr $y_ur - $y_ll] ]
          set coord [expr $y_ll + 0.5*$width]
          scan [resize_bbox $bbox 0.160 0] "%f %f %f %f" xl yl xh yh

          set coord2 [expr $x_ur + 0.09]
          scan [resize_bbox "[expr $x_ur+0.045] $y_ll [expr $x_ur+0.13] $y_ur" 0 0.160] "%f %f %f %f" xl1 yl1 xh1 yh1
          set coord3 [expr $x_ll - 0.09]
          scan [resize_bbox "[expr $x_ll-0.13] $y_ll [expr $x_ll-0.045] $y_ur" 0 0.160] "%f %f %f %f" xl2 yl2 xh2 yh2
        } else {
          set width [format %.3f [expr $x_ur - $x_ll] ]
          set coord [expr $x_ll + 0.5*$width]
          scan [resize_bbox $bbox 0 0.160] "%f %f %f %f" xl yl xh yh

          set coord2 [expr $y_ur + 0.09]
          scan [resize_bbox "$x_ll [expr $y_ur+0.045] $x_ur [expr $y_ur+0.13]" 0.160 0] "%f %f %f %f" xl1 yl1 xh1 yh1
          set coord3 [expr $y_ll - 0.09]
          scan [resize_bbox "$x_ll [expr $y_ll-0.13] $x_ur [expr $y_ll-0.045]" 0.160 0] "%f %f %f %f" xl2 yl2 xh2 yh2
        }
        set new_bbox "{$xl $yl} {$xh $yh}"

        if {$debug} {
          set owner [get_attr $pin owner]
          foreach_in_collection o $owner {
            echo :pin: [get_attribute $o name]
          }
          echo :bbox: $bbox
          echo :width: $width  :coord: $coord
          echo :new_bbox: $new_bbox
	  echo ":CMD: create_track -layer $layer -bbox { $new_bbox } -count 1 -coord $coord -space [expr $width+0.001]"
        }

	create_track -layer $layer -bbox [list ${new_bbox}] -count 1 -coord $coord -space [expr $width+0.001]
        if {$dir eq "horizontal"} {
          set new_bbox2 "{$xl1 $yl1} {$xh1 $yh1}"
          create_track -layer $layer -bbox [list ${new_bbox2}]  -count 1 -coord $coord2 -dir X
          set new_bbox2 "{$xl2 $yl2} {$xh2 $yh2}"
          create_track -layer $layer -bbox [list ${new_bbox2}] -count 1 -coord $coord3 -dir X
        } else {
          set new_bbox2 "{$xl1 $yl1} {$xh1 $yh1}"
          create_track -layer $layer -bbox [list ${new_bbox2}]  -count 1 -coord $coord2 -dir Y
          set new_bbox2 "{$xl2 $yl2} {$xh2 $yh2}"
          create_track -layer $layer -bbox [list ${new_bbox2}] -count 1 -coord $coord3 -dir Y
        }
      }
    }
  }
}


