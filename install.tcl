package require tin 1.0
tin add -auto vutil https://github.com/ambaker1/vutil install.tcl 4.0-
tin depend vutil 4.0
set dir [tin mkdir -force ndlist 0.9]
file copy pkgIndex.tcl ndlist.tcl ndapi.tcl ndobj.tcl $dir
file copy vector.tcl matrix.tcl tensor.tcl table.tcl fileio.tcl $dir
file copy README.md LICENSE $dir
