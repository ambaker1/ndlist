# ndlist.tcl
################################################################################
# Main file for ND list package. 

# Copyright (C) 2025 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Define namespace
namespace eval ::ndlist {
    # Source all required files
    set dir [file dirname [file normalize [info script]]]
    source [file join $dir lib vector.tcl]
    source [file join $dir lib matrix.tcl]
    source [file join $dir lib tensor.tcl]
    source [file join $dir lib ndapi.tcl]
    source [file join $dir lib vutil.tcl]
    source [file join $dir lib ndobj.tcl]
    source [file join $dir lib table.tcl]
    source [file join $dir lib fileio.tcl]
}

# Finally, provide the package
package provide ndlist 0.11
