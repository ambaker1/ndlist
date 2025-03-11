package require tin 2.0
set dir [tin mkdir -force ndlist 0.10]
file copy pkgIndex.tcl ndlist.tcl ndapi.tcl ndobj.tcl $dir
file copy vector.tcl matrix.tcl tensor.tcl table.tcl fileio.tcl $dir
file copy vutil.tcl $dir
file copy README.md LICENSE $dir
