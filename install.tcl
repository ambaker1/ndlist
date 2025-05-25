package require tin 2.1
set dir [tin mkdir -force ndlist 0.11.1]
file copy README.md LICENSE pkgIndex.tcl ndlist.tcl lib $dir
