package require tin 1.0
tin depend vutil 1.1
set dir [tin mkdir -force ndlist 0.1.1]
file copy pkgIndex.tcl ndlist.tcl README.md LICENSE $dir
