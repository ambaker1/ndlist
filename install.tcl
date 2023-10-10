package require tin 1.0
package require math 1.2.5
tin depend vutil 2.2
set dir [tin mkdir -force ndlist 0.3]
file copy pkgIndex.tcl ndlist.tcl README.md LICENSE $dir
