# ndapi.tcl
################################################################################
# Core API for manipulating ND-lists

# Copyright (C) 2025 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# GetNDims --
#
# Get dimensionality from ND string (uses regex pattern).
# Either a single digit or with a "D" after.
# e.g. "0" or "0D", or "3" or "3d"
# Alternatively, if nd is "auto", it dynamically chooses the rank from the
# value provided.
# Returns error if invalid syntax
#
# Syntax:
# GetNDims $nd <$value>
#
# Arguments:
# nd        Number of dimensions (e.g. 2D), or "auto" to dynamically get rank.
# value     ndlist for dynamically determining rank. Default blank.

proc ::ndlist::GetNDims {nd {value ""}} {
    if {$nd eq "auto"} {
        set rank 0
        while {[string is list $value] && $value ne [lindex $value 0]} {
            set value [lindex $value 0]
            incr rank
        }
        return $rank
    }
    if {![IsNDType $nd]} {
        return -code error "invalid ND syntax"
    }
    string trimright $nd {dD}
}

# IsNDType --
#
# Returns whether an input is an ND string
#
# Syntax:
# IsNDType $arg
#
# Arguments:
# arg:          Argument to check

proc ::ndlist::IsNDType {arg} {
    regexp {^(0|[1-9]\d*)[dD]?$} $arg
}

# ValidateAxis --
#
# Validates axis input
#
# Syntax:
# ValidateAxis $ndims $axis
# 
# Arguments:
# ndims             Number of dimensions (Inf for arbitrary dimensions)
# axis              Axis integer (must be 0-(N-1))

proc ::ndlist::ValidateAxis {ndims axis} {
    if {![string is integer -strict $axis]} {
        return -code error "expected integer, but got \"$axis\""
    }
    if {$axis < 0 || $axis >= $ndims} {
        return -code error "axis out of range"
    }
}

# GetShape --
#
# Private procedure to get list of dimensions of an ND-list along first index
# Returns error if there is a null dimension along a non-zero axis.
#
# Syntax:
# GetShape $ndims $ndlist
#
# Arguments:
# ndims         Number of dimensions
# ndlist        ND-list to get dimensions from

proc ::ndlist::GetShape {ndims ndlist} {
    # Null case
    if {[llength $ndlist] == 0} {
        return [lrepeat $ndims 0]
    }
    # Get list of dimensions (along first index)
    set dims ""
    foreach axis [range $ndims] {
        if {[llength $ndlist] == 0} {
            return -code error "null dimension along non-zero axis"
        }
        lappend dims [llength $ndlist]
        set ndlist [lindex $ndlist 0]
    }
    return $dims
}

# IsShape --
#
# Verify that the ND-list is of the specified shape
#
# Syntax:
# IsShape $ndlist $n ...
#
# Arguments:
# ndlist        ND-list to check
# n ...       Shape of ND-list

proc ::ndlist::IsShape {ndlist args} {
    # Scalar base case
    if {[llength $args] == 0} {
        return 1
    }
    # Interpret input
    set args [lassign $args n]
    # Vector base case
    if {[llength $ndlist] != $n} {
        return 0
    }
    # Recursion
    foreach ndrow $ndlist {
        if {![IsShape $ndrow {*}$args]} {
            return 0
        }
    }
    return 1
}

# GetMaxShape --
#
# Get maximum dimensions of multiple ND-lists (for expanding)
#
# Syntax:
# GetMaxShape $ndims $arg ...
#
# Arguments:
# ndims         Number of dimensions (e.g. 1D, 2D, etc.)
# arg ...       ND-lists to get max shape from

proc ::ndlist::GetMaxShape {ndims args} {
    set shapes [lmap ndlist $args {GetShape $ndims $ndlist}]
    lmap dims [transpose $shapes] {max $dims}
}

# ParseIndices --
# 
# Loop through index inputs - returning required information for getting/setting
# Returns index arguments - paired list of index type and index list.
#
# Syntax:
# ParseIndices $dims $index ...
#
# Arguments:
# dims          Shape to index into
# index ...     Index inputs (e.g. :, {0 3}, 0:10, end*)

proc ::ndlist::ParseIndices {dims args} {
    set iArgs ""; # paired list of index type and index list (meaning varies)
    foreach dim $dims index $args {
        lappend iArgs {*}[ParseIndex $dim $index]
    }
    return $iArgs
}

# ParseIndex --
# 
# Used for parsing index input (i.e. list of indices, range 0:10, etc)
# Returns index type and corresponding values.
#
# Syntax:
# lassign [ParseIndex $n $index] iType iList
#
# Arguments:
# n             Size of list
# index         Index input (e.g. :, {0 3}, 0:10, end*)
# 
# Returns:
# iType     Type of index (A, R, L, or S)
# iList     List of indices corresponding with type
#   A:          Empty
#   R:          Range start and stop
#   L:          List of indices 
#   S:          Single index (flattens list)

proc ::ndlist::ParseIndex {n index} {
    # Check length of input
    if {[llength $index] != 1} {
        # List of indices (user entered)
        return [list L [lmap index $index {Index2Integer $n $index}]]
    }
    # All index notation
    if {$index eq {:}} {
        return [list A ""]
    }
    # Single index notation
    if {[string index $index end] eq {*}} {
        # Single index notation (flatten along this dimension)
        return [list S [Index2Integer $n [string range $index 0 end-1]]]
    }
    # Single index, not range notation
    if {![string match *:* $index]} {
        return [list L [Index2Integer $n $index]]
    }
    # Range index notation
    set parts [split $index :]
    # Simple range case ($start:$stop)
    if {[llength $parts] == 2} {
        lassign $parts start stop
        set start [Index2Integer $n $start]
        set stop [Index2Integer $n $stop]
        if {$start == 0 && $stop == ($n - 1)} {
            # 0:end case
            return [list A ""]
        }
        # Normal range
        return [list R [list $start $stop]]               
    }
    # Skipped range case ($start:$step:$stop)
    if {[llength $parts] == 3} {
        lassign $parts start step stop
        set start [Index2Integer $n $start]
        set stop [Index2Integer $n $stop]
        if {![string is integer -strict $step]} {
            return -code error "expected integer but got \"$step\""
        }
        # Special case for forward range with step of 1
        if {$step == 1 && $start <= $stop} {
            if {$start == 0 && $stop == ($n - 1)} {
                # 0:1:end case
                return [list A ""]
            }
            # Normal range
            return [list R [list $start $stop]]
        }
        # Special case for reverse range with step of -1
        if {$step == -1 && $start >= $stop} {
            return [list R [list $start $stop]]
        }
        # Normal case
        return [list L [range $start $stop $step]]
    }
    return -code error "invalid range index notation: should be \
            \"start:stop\" or \"start:step:stop\""
}

# Index2Integer --
#
# Private function, converts end+-integer index format into integer
# Negative indices get converted, such that -1 is end, -2 is end-1, etc.
#
# Syntax:
# Index2Integer $n $index
#
# Arguments:
# n:            Length of list to index
# index:        Index notation (integer?[+-]integer? or end?[+-]integer?)

proc ::ndlist::Index2Integer {n index} {
    # Default case (skip regexp, much faster)
    if {[string is integer -strict $index]} {
        set i $index
    } else {
        # Check if index is valid format
        set match [regexp -inline {^(end|[+-]?[0-9]+)([+-][0-9]+)?$} $index]
        if {[llength $match] == 0} {
            return -code error "bad index \"$index\": must be\
                    integer?\[+-\]integer? or end?\[+-\]integer?"
        }
        # Convert end to n-1 if needed
        set base [lindex $match 1]
        if {$base eq {end}} {
            set base [expr {$n - 1}]
        }
        # Handle offset
        set offset [lindex $match 2]
        if {$offset eq {}} {
            set i $base
        } else {
            set i [expr {$base + $offset}]
        }
    }
    # Handle negative index (from end)
    if {$i < 0} {
        set i [expr {$i % $n}]
    }
    # Check if in range
    if {$i >= $n} {
        return -code error "index out of range"
    }
    return $i
}

# GetIndexShape --
#
# Get shape of indexed range. 
#
# Syntax:
# GetIndexShape $dims $iType $iList ...
#
# Arguments:
# dims          Shape to index into
# iType ...     Index types
# iList ...     Index lists

proc ::ndlist::GetIndexShape {dims args} {
    concat {*}[lmap dim $dims {iType iList} $args {
        GetIndexDim $dim $iType $iList
    }]
}

# GetIndexDim --
#
# Get the size of the indexed range.
#
# Syntax:
# GetIndexDim $n $iType $iList
#
# Arguments:
# n         Length of list.
# iType     Type of index (returned from ParseIndex).
# iList     List corresponding with index type.

proc ::ndlist::GetIndexDim {n iType iList} {
    switch $iType {
        A { # All indices
            return $n
        }
        R { # Range of indices
            lassign $iList start stop
            if {$start <= $stop} {
                return [expr {$stop - $start + 1}]
            } else {
                return [expr {$start - $stop + 1}]
            }
        }
        L { # List of indices
            return [llength $iList]
        }
        S { # Single index
            return
        }
    }
}

# UnravelIndex --
#
# Unravel a flat index to its coordinates
#
# Syntax:
# UnravelIndex $i $n ...
#
# Arguments:
# i             Flat index into ND list
# n ...         Shape of ND list

proc ::ndlist::UnravelIndex {i n args} {
    # Base case
    if {[llength $args] == 0} {
        return [expr {$i % $n}]
    }
    # Recursion
    set N [product $args]
    concat [expr {$i / $N}] [UnravelIndex [expr {$i % $N}] {*}$args]
}
