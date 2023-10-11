package require tin 1.0
set dir [tin mkdir -force ndlist 0.3]
file copy pkgIndex.tcl ndlist.tcl core.tcl linalg.tcl ltools.tcl stat.tcl \
        README.md LICENSE $dir
