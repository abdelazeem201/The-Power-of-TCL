#The script provided in the Code section can be used to perform checks about the existing standard cell rows in the design.
#For example, in the case of an MSV design, some site XYZ rows are created in the default power domain even if there are no site XYZ standard cells bound to that default power domain. 
#In such cases, it is necessary to check the power domain libraries bound to that site and the related sites.

proc get_site_by_lib {} {
    Puts "Execute get_site_by_lib TCL proc..."
      global site_by_lib
      if [info exists site_by_lib] {unset site_by_lib}
      foreach_in_collection lib [get_libs *] {
            set libName [get_object_name $lib]
            set site_by_lib($libName) ""
      }
      foreach libCellPt [dbGet [dbGet head.allCells.objType libCell -p ].baseClass core -p] {
            set libCellSiteName [dbGet $libCellPt.site.name]
                foreach_in_collection lib [get_libs -of_objects [get_lib_cells [dbGet $libCellPt.name]]] {
                  set libName [get_object_name $lib]
                  if {![regexp $libCellSiteName $site_by_lib($libName)]} {
                    lappend site_by_lib($libName) $libCellSiteName
                  }
            }
      }
      foreach_in_collection lib [get_libs *] {
            set libName [get_object_name $lib]
            Puts "\tLib Name: $libName ; Sites: $site_by_lib($libName)"
      }
      Puts "End of get_site_by_lib TCL proc execution\n"
}
