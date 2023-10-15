if {![package vsatisfies [package provide Tcl] 8.6]} {return}
package ifneeded ndlist 0.3.1 [list source [file join $dir ndlist.tcl]]
