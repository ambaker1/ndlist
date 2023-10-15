# ndlist.tcl
################################################################################
# Main file for ND list package. 

# Copyright (C) 2023 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Define namespace
namespace eval ::ndlist {
    # Source all required files
    set dir [file dirname [file normalize [info script]]]
    source [file join $dir vector.tcl]
    source [file join $dir matrix.tcl]
    source [file join $dir tensor.tcl]
}

# Finally, provide the package
package provide ndlist 0.4
