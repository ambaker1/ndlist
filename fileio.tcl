# fileio.tcl
################################################################################
# File input/output for matrices

# Copyright (C) 2025 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Define namespace and exported commands
namespace eval ::ndlist {
    # File import/export commands
    namespace export readFile writeFile readMatrix writeMatrix
    # Data conversion commands
    namespace export mat2txt txt2mat mat2csv csv2mat
}

# readFile --
#
# Loads data from file
#
# Syntax:
# readFile <$options ...> <-newline> $file
#
# Arguments:
# options:          Options to pass to "fconfigure".
# -newline:         Read the last newline (default ignores last newline).
# file:             File to read from.

proc ::ndlist::readFile {args} {
    # Check for -newline option
    if {[lindex $args end-1] eq "-newline"} {
        set nonewline false
        set args [lreplace $args end-1 end-1]
    } else {
        set nonewline true
    }
    # Check arity
    if {[llength $args] == 0 || [llength $args] % 2 == 0} {
        return -code error "wrong # args: should be\
                \"readFile ?option value ...? ?-newline? file\""
    }
    # Interpret input
    set options [lrange $args 0 end-1]
    set file [lindex $args end]
    # Open file for reading, and try to configure and read data.
    set fid [open $file r]
    try {
        fconfigure $fid {*}$options
        # Read data from file
        if {$nonewline} {
            set data [read -nonewline $fid]
        } else {
            set data [read $fid]
        }
    } finally {
        close $fid
    }
    return $data
}

# writeFile --
# 
# Overwrite file with data, with additional options
#
# Syntax:
# writeFile <$options ...> $file $data
#
# Arguments:
# options:          Options to pass to "fconfigure".
# -nonewline:       Option to not write a final newline.
# file:             File to write to.
# data:             Raw data to write to file.

proc ::ndlist::writeFile {args} {
    # Check for -nonewline option
    if {[lindex $args end-2] eq "-nonewline"} {
        set nonewline true
        set args [lreplace $args end-2 end-2]
    } else {
        set nonewline false
    }
    # Check arity
    if {[llength $args] < 2 || [llength $args] % 2 == 1} {
        return -code error "wrong # args: should be \
                \"writeFile ?option value ...? ?-nonewline? file data\""
    }
    # Interpret input
    set options [lrange $args 0 end-2]
    set file [lindex $args end-1]
    set data [lindex $args end]
    # Open file for writing, and try to configure and write data.
    file mkdir [file dirname $file]
    set fid [open $file w]
    try {
        fconfigure $fid {*}$options
        # Write data to file
        if {$nonewline} {
            puts -nonewline $fid $data
        } else {
            puts $fid $data
        }
    } finally {
        close $fid
    }
    return
}

# readMatrix --
#
# Loads matrix from file, dynamically converting from text or CSV
#
# Syntax:
# readMatrix <$options ...> <-newline> $file
#
# Arguments:
# options:          Options to pass to "fconfigure".
# -newline:         Read the last newline (default ignores last newline).
# file:             File to read from.

proc ::ndlist::readMatrix {args} {
    # Interpret input
    set options [lrange $args 0 end-1]
    set file [lindex $args end]
    # Read data
    set data [readFile {*}$options $file]
    # Convert based on filename extension, and return value
    if {[file extension $file] eq ".csv"} {
        set matrix [csv2mat $data]
    } else {
        set matrix [txt2mat $data]
    }
    return $matrix
}

# writeMatrix --
# 
# Write matrix to file, dynamically converting to text or CSV.
#
# Syntax:
# writeMatrix <$options ...> $file $matrix
#
# Arguments:
# options:          Options to pass to "fconfigure".
# -nonewline:       Option to not write a final newline.
# file:             File to write to.
# matrix:           Matrix to convert and write to file.

proc ::ndlist::writeMatrix {args} {
    # Interpret input
    set options [lrange $args 0 end-2]
    set file [lindex $args end-1]
    set matrix [lindex $args end]
    # Convert based on filename extension, and write to file
    if {[file extension $file] eq ".csv"} {
        set data [mat2csv $matrix]
    } else {
        set data [mat2txt $matrix]
    }
    writeFile {*}$options $file $data
}

# Datatype conversions
################################################################################

# Conform2Matrix --
#
# Expand rows to have the same length.
#
# Syntax:
# Conform2Matrix $matrix
#
# Arguments:
# matrix        Nested list to conform into a matrix.

proc ::ndlist::Conform2Matrix {matrix} {
    set m 0
    # Get number of columns
    foreach row $matrix {
        if {[llength $row] > $m} {
            set m [llength $row]
        }
    }
    # Expand matrix if needed.
    lmap row $matrix {
        if {[llength $row] < $m} {
            lappend row {*}[lrepeat [expr {$m-[llength $row]}] {}]
        }
        set row
    }
}

# mat2txt --
#
# Convert from matrix to space-delimited text. 
# Note that rows are Tcl lists.
#
# Syntax:
# mat2txt $matrix
#
# Arguments:
# matrix:       Matrix value

proc ::ndlist::mat2txt {matrix} {
    join [Conform2Matrix $matrix] \n
}

# txt2mat --
#
# Convert from space-delimited text to matrix
# Newlines can be escaped inside curly braces
# Ignores blank lines
#
# Syntax:
# txt2mat $text
#
# Arguments:
# text:     Text to convert.

proc ::ndlist::txt2mat {text} {
    set matrix ""
    set row ""
    foreach line [split $text \n] {
        # Add to row, and handle escaped newlines
        append row $line
        if {[string is list $row]} {
            lappend matrix $row
            set row ""
        } else {
            append row \n
        }
    }
    # Validate and return matrix
    return [Conform2Matrix $matrix]
}

# mat2csv --
#
# Convert from matrix to comma-separated values
#
# Arguments:
# matrix:       Matrix to convert

proc ::ndlist::mat2csv {matrix} {
    set csvLines ""
    # Validate matrix and loop through rows
    foreach row [Conform2Matrix $matrix] {
        set csvRow ""
        foreach val $row {
            # Perform escaping if required
            if {[string match "*\[\",\r\n\]*" $val]} {
                set val "\"[string map [list \" \"\"] $val]\""
            }
            lappend csvRow $val
        }
        lappend csvLines [join $csvRow ,]
    }
    return [join $csvLines \n]
}

# csv2mat --
#
# Convert from comma-separated values to matrix
# Ignores blank lines
#
# Syntax:
# csv2mat $csv
#
# Arguments:
# csv:          CSV string to convert

proc ::ndlist::csv2mat {csv} {
    # Initialize variables
    set matrix ""; # Output matrix
    set csvRow ""; # CSV-formatted row of data
    set val ""; # Value in matrix row
    
    # Split csv by newline and loop through lines
    foreach line [split $csv \n] {
        append csvRow $line
        # Check for escaped newline condition
        if {[regexp -all "\"" $csvRow] % 2} {
            # Odd number of quotes
            append csvRow \n
            continue
        }
        # Split csv row by comma and loop through items, creating matrix row
        set row ""; # Matrix row of data
        set blanks 0; # Number of blanks (ignore blank rows)
        foreach item [split $csvRow ,] {
            append val $item
            # Check for escaped comma condition
            if {[regexp -all "\"" $val] % 2} {
                # Odd number of quotes
                append val ,
                continue
            }
            # Check if escaped (commas, newlines, or quotes)
            if {[regexp "\"" $val]} {
                # Remove outer escaping quotes
                set val [string range $val 1 end-1]
                # Check for escaped quotes
                if {[regexp "\"" $val]} {
                    # Replace with normal quotes
                    set val [regsub -all "\"\"" $val "\""]
                }
            }
            if {$val eq ""} {
                incr blanks
            }
            # Add to row
            lappend row $val
            # Clear val
            set val ""
        }
        # Add to matrix
        lappend matrix $row
        # Clear csv row
        set csvRow ""
    }
    # Validate and return matrix
    return [Conform2Matrix $matrix]
}
