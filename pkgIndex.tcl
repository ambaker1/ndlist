if {![package vsatisfies [package provide Tcl] 8.6 9.0]} {return}
package ifneeded ndlist 0.13 [list source [file join $dir ndlist.tcl]]
