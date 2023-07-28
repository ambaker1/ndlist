package require tin 0.7
tin depend vutil 0.7
set dir [tin mkdir -force ndlist 0.1]
file copy pkgIndex.tcl ndlist.tcl README.md LICENSE $dir
