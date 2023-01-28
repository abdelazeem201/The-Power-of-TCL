##############################################################
# NAME :          fill_kor.tcl
#
# SUMMARY :       create fill KOR layer for design
#
# REQUIRED :      yes
# 
# USAGE :         P_source_if_exists fill_kor.tcl
#
# ARGUMENTS :     None
#
# VARIABLES :     INTEL_MAX_ROUTING_LAYER
#
# PROCS USED :    None
#                         
# DESCRIPTION :   fill_kor.tcl is to generate fill KOR layer (:93) for design
#
# EXAMPLES :      
#
###############################################################
proc P_create_fill_kor {} {
  global INTEL_MAX_ROUTING_LAYER
  set datatype 93
  set layer_name_postfix "_fill_kor"
  set x_bloat 0.000
  set y_bloat 0.000

  set all_layers  [get_attribute [get_layers -filter "layer_type==interconnect"] name]
  set layer_index [lsearch [get_attribute [get_layers -filter "layer_type==interconnect"] name] $INTEL_MAX_ROUTING_LAYER]
  set fill_kor_layers [lreplace $all_layers [expr $layer_index +1] [llength $all_layers]]
  P_msg_info "Creating m*_fill_kor on layers: $fill_kor_layers"

  foreach metal_layer $fill_kor_layers {
     set layer ${metal_layer}${layer_name_postfix}
  
     if {[get_shapes -quiet -filter "layer_name==$layer"] != "" } {
        P_msg_info "Removing existing $layer layer"     
        remove_objects [get_shapes -quiet -filter "layer_name==$layer"]
     }
     P_msg_info "Creating fill kor - $layer"

     set die [get_attribute -quiet [get_core_area] boundary]
     set m ""
     #set m [get_cells -quiet -hier -filter "is_hard_macro==true || is_soft_macro==true"]
     #append_to_collection m [remove_from_collection [get_cells -hier -quiet *halo* ] [get_cells -hier -quiet *halo_va*]]

     if {$m != ""} {
       set core [compute_polygons -operation not -objects1 $die -objects2 $m]
     } else {
       set core $die
     }

     set core [resize_polygon -size "$x_bloat $y_bloat" -objects $core]
     create_shape -shape_type poly -boundary [get_attribute $core poly_rects.point_list] -layer ${layer}:${datatype}
  }
}

P_create_fill_kor

