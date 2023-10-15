package require tin 1.0
set dir [tin mkdir -force ndlist 0.4]
file copy pkgIndex.tcl ndlist.tcl vector.tcl matrix.tcl tensor.tcl $dir
file copy README.md LICENSE $dir
