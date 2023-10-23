package require tin 1.0
set dir [tin mkdir -force ndlist 0.6.1]
file copy pkgIndex.tcl ndlist.tcl ndapi.tcl $dir
file copy vector.tcl matrix.tcl tensor.tcl $dir
file copy README.md LICENSE $dir
