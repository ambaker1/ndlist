# fileio.tcl
################################################################################
# Adds the Tcl9 read/write file utilities to Tcl8

# Copyright (C) 2025 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

namespace eval ::ndlist {
    namespace export readFile writeFile
}

# readFile --
#
# Loads data from file
#
# Syntax:
# readFile $filename <$mode>
#
# Arguments:
# filename:             File to read from.
# mode:                 Options: text, binary. Default "text".

proc ::ndlist::readFile {filename {mode text}} {
    # Parse the arguments
    set MODES {binary text}
    set ERR [list -level 1 -errorcode [list TCL LOOKUP MODE $mode]]
    set mode [tcl::prefix match -message "mode" -error $ERR $MODES $mode]

    # Read the file
    set f [open $filename [dict get {text r binary rb} $mode]]
    try {
        return [read $f]
    } finally {
        close $f
    }
}

# writeFile --
#
# Writes data to a file
#
# Syntax:
# writeFile $filename <$mode> $data
#
# Arguments:
# filename:             File to read from.
# mode:                 Options: text, binary. Default "text".
# data:                 Data to write to file (no new line)

proc ::ndlist::writeFile {filename args} {
    # Parse the arguments
    switch [llength $args] {
        1 { # writeFile $filename $data
            set mode text
            set data [lindex $args 0]
        }
        2 { # writeFile $filename $mode $data
            lassign $args mode data
            # Parse the arguments
            set MODES {binary text}
            set ERR [list -level 1 -errorcode [list TCL LOOKUP MODE $mode]]
            set mode [tcl::prefix match -message "mode" -error $ERR $MODES $mode]
        }
        default {
            return -code error "wrong # args:\
                    should be \"writeFile filename ?mode? data\""
        }
    }
    # Write the file
    set f [open $filename [dict get {text w binary wb} $mode]]
    try {
        puts -nonewline $f $data
        return
    } finally {
        close $f
    }
}
