# core.tcl
################################################################################
# Core procedures for ND list creation, metadata, and indexing/modification

# Copyright (C) 2023 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Define namespace and exported commands
namespace eval ::ndlist {    
    namespace export ndlist nshape nsize; # Basics
    namespace export nrepeat nreshape nexpand; # Creation
    namespace export nget nset nreplace; # Access/modification
    namespace export ninsert nstack; # Combination
    namespace export nflatten nswapaxes; # Manipulation
    namespace export napply napply2 nop nop2 nreduce; # Functional mapping
    namespace export nmap nexpr; # Generalized mapping
}

# NDLIST BASICS
################################################################################

# ndlist --
#
# Validates an ND list, and returns the ND list.
#
# Syntax:
# ndlist $nd $value
#
# Arguments:
# nd            Number of dimensions (e.g. 1D, 2D, etc.)
# value         Value to create an ndlist from.

proc ::ndlist::ndlist {nd value} {
    # Interpret input
    set ndims [GetNDims $nd]
    set ndlist $value
    # Check if it is a valid ndlist, and try to shape it into one.
    if {![IsShape $ndlist {*}[GetShape $ndims $ndlist]]} {
        return -code error "not a valid ${ndims}D list"
    }
    return $ndlist
}

# GetNDims --
#
# Get dimensionality from ND string (uses regex pattern).
# Either a single digit or with a "D" after.
# e.g. "0" or "0D", or "3" or "3d"
# Returns error if invalid syntax
#
# Syntax:
# GetNDims $nd
#
# Arguments:
# nd        Number of dimensions (e.g. 1D, 2D, etc.)

proc ::ndlist::GetNDims {nd} {
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

# IsShape --
#
# Verify that the ndlist is of the specified shape
#
# Syntax:
# IsShape $ndlist $n $m ...
#
# Arguments:
# ndlist        ndlist to check
# n m ...       shape of ndlist

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

# GetShape --
#
# Private procedure to get list of dimensions of an ndlist along first index
#
# Syntax:
# GetShape $ndims $ndlist
#
# Arguments:
# ndims         Number of dimensions
# ndlist        ND list to get dimensions from

proc ::ndlist::GetShape {ndims ndlist} {
    # Get list of dimensions (along first index)
    set dims ""
    foreach i [lrepeat $ndims {}] {
        lappend dims [llength $ndlist]
        set ndlist [lindex $ndlist 0]
    }
    return $dims
}

# nshape --
# 
# Get shape of ndlist
#
# Syntax:
# nshape $nd $ndlist <$axis>
#
# Arguments:
# nd                Number of dimensions (e.g. 1D, 2D, etc.)
# ndlist            ND list to get dimensions of
# axis              Axis to get dimension along. Blank for all.

proc ::ndlist::nshape {nd ndlist {axis ""}} {
    # Interpret and validate input
    set ndims [GetNDims $nd]
    if {![string is integer $axis]} {
        return -code error "axis must be integer"
    }
    # Switch for output type
    if {$axis eq ""} {
        return [GetShape $ndims $ndlist]
    } elseif {$axis >= 0 && $axis < $ndims} {
        # Get single dimension (along first index)
        return [llength [lindex $ndlist {*}[lrepeat $axis 0]]]
    } else {
        return -code error "axis must be between 0 and [expr {$ndims - 1}]"
    }
}

# nsize --
#
# Get the size of an ndlist (number of elements, product of the shape)
# For rank 0, it returns blank.
#
# Syntax:
# nsize $nd $ndlist
#
# Arguments:
# nd:               Number of dimensions (e.g. 1D, 2D, etc.)
# ndlist:           ND list to get dimensions of

proc ::ndlist::nsize {nd ndlist} {
    set ndims [GetNDims $nd]
    # Scalar case (no size)
    if {$ndims == 0} {
        return
    }
    # Get size (product of shape)
    return [product [GetShape $ndims $ndlist]]
}

# NDLIST CREATION
################################################################################

# nrepeat --
#
# Create an ndlist filled with one value
#
# Syntax:
# nrepeat $value $arg ...
#
# Arguments:
# value         Value to repeat
# arg ...       Shape of ndlist

proc ::ndlist::nrepeat {value args} {
    set ndlist $value
    foreach n [lreverse $args] {
        set ndlist [lrepeat $n $ndlist]
    }
    return $ndlist
}

# nreshape --
#
# Reshape a vector to different dimensions.
#
# Syntax:
# nreshape $vector $arg ...
#
# Arguments:
# vector        1D list to reshape into matrix or higher-dimensional tensor
# arg ...       New shape (and dimensions)

proc ::ndlist::nreshape {vector args} {
    # Scalar case
    if {[llength $args] == 0} {
        if {[llength $vector] != 1} {
            return -code error "incompatible dimensions"
        }
        # Note: 1 element list can be converted to scalar.
        return [lindex $vector 0]
    }
    # Vector case
    if {[llength $args] == 1} {
        if {[llength $vector] != [lindex $args 0]} {
            return -code error "incompatible dimensions"
        }
        return $vector
    }
    # Matrix and higher-dimensional case
    set size [product $args]
    if {[llength $vector] != $size} {
        return -code error "incompatible dimensions"
    }
    RecReshape $vector {*}$args
}

# RecReshape --
#
# Recursive handler for reshaping an ndlist
#
# Syntax:
# RecReshape $vector $n $m <$arg...>
#
# Arguments:
# vector        List to reshape into a matrix
# n m           Matrix dimensions
# arg...        Dimensions of each matrix element. Default scalar.

proc ::ndlist::RecReshape {vector n m args} {
    # Create matrix
    set rowSize [product [list $m {*}$args]]
    set i -$rowSize
    set j -1
    set matrix [lmap x [lrepeat $n {}] {
        lrange $vector [incr i $rowSize] [incr j $rowSize]
    }]
    # Base case
    if {[llength $args] == 0} {
        return $matrix
    }
    # Recursion
    lmap row $matrix {
        RecReshape $row $m {*}$args
    }
}

# nexpand --
#
# Expands an ndlist to new dimensions.
# New dimensions must match or be divisible by old dimensions.
# For example, 1x1, 2x1, 4x1, 1x3, 2x3 and 4x3 are compatible with 4x3.
#
# Syntax:
# nexpand $ndlist $arg ...
#
# Arguments:
# ndlist        ND list to expand
# arg ...       New shape (and dimensions)

proc ::ndlist::nexpand {ndlist args} {    
    set dims1 $args
    set dims0 [GetShape [llength $dims1] $ndlist]
    foreach dim0 $dims0 dim1 $dims1 {
        if {$dim0 != $dim1} {
            return [RecExpand $ndlist $dims0 $dims1]
        }
    }
    return $ndlist
}

# RecExpand --
#
# Recursive handler for nexpand. 

#
# Syntax:
# RecExpand $ndlist $dims0 $dims1
#
# Arguments:
# ndlist        ND list to expand
# dims0         Old dimensions list
# dims1         New dimensions list

proc ::ndlist::RecExpand {ndlist dims0 dims1} {
    # Base case
    if {[llength $dims0] == 0} {
        return $ndlist
    }
    # Recursion
    set dims0 [lassign $dims0 n0]
    set dims1 [lassign $dims1 n1]
    # Same dimension case
    if {$n1 == $n0} {
        return [lmap ndrow $ndlist {
            RecExpand $ndrow $dims0 $dims1
        }]
    }
    # Singleton dimension case
    if {$n0 == 1} {
        return [lrepeat $n1 [RecExpand [lindex $ndlist 0] $dims0 $dims1]]
    }
    # Stride dimension case
    if {$n1 % $n0 == 0} {
        return [lrepeat [expr {$n1/$n0}] {*}[lmap ndrow $ndlist {
            RecExpand $ndrow $dims0 $dims1
        }]]
    }
    # Error case
    return -code error "incompatible dimensions"
}

# NDLIST ACCESS/MODIFICATION
################################################################################

# nget --
# 
# Get portion of ndlist using ndlist index notation.
#
# Syntax:
# nget $ndlist $i1 $i2 ...
#
# Arguments:
# ndlist        ND list value
# i1 i2 ...     Separate arguments for index dimensions

proc ::ndlist::nget {ndlist args} {
    # Get number of dimensions
    set indices $args
    set ndims [llength $indices]
    # Scalar case
    if {$ndims == 0} {
        return $ndlist
    }
    # Parse indices
    set dims [GetShape $ndims $ndlist]
    set iArgs [lassign [ParseIndices $indices $dims] iDims iLims]
    # Process limits and dimensions
    foreach dim $dims iLim $iLims iDim $iDims {
        if {$iLim >= $dim} {
            return -code error "index out of range"
        }
    }
    # Return ndims and the sublist
    return [RecGet $ndlist {*}$iArgs]
}

# RecGet --
#
# Private recursive handler for nget
#
# Syntax:
# RecGet $ndlist $iType $iList ...
# 
# Arguments:
# ndlist                ndlist to get values from
# iType, iList, ...     Index type and corresponding list. See ParseIndex.

proc ::ndlist::RecGet {ndlist iType iList args} {
    # Base case
    if {[llength $args] == 0} {
        return [Get $ndlist $iType $iList]
    }
    # Flatten for "S" case
    if {$iType eq "S"} {
        RecGet [Get $ndlist $iType $iList] {*}$args
    } else {
        lmap ndrow [Get $ndlist $iType $iList] {
            RecGet $ndrow {*}$args
        }
    }
}

# Get --
#
# Base case for RecGet
#
# Syntax:
# Get $list $iType $iList
#
# Arguments:
# list          List to get values from.
# iType         Index type. See ParseIndex.
# iList         Index list corresponding with index type. See ParseIndex

proc ::ndlist::Get {list iType iList} {
    # Switch for index type
    switch $iType {
        A { # All indices
            return $list
        }
        L { # List of indices
            return [lmap i $iList {
                lindex $list $i
            }]
        }
        R { # Range of indices
            lassign $iList i1 i2
            if {$i2 >= $i1} {
                return [lrange $list $i1 $i2]
            } else {
                return [lreverse [lrange $list $i2 $i1]]
            }
        }
        S { # Single index (flatten)
            set i [lindex $iList 0]
            return [lindex $list $i]
        }
    }
}

# GetNewNDims --
#
# Using the slice index style, return the number of dimensions of the new list.
#
# Syntax:
# GetNewNDims $indices
#
# Arguments:
# indices       List of index inputs

proc ::ndlist::GetNewNDims {indices} {
    llength [lsearch -all -not -index 0 $indices {*\*}]
}

# ParseIndices --
# 
# Loop through index inputs - returning required information for getting/setting
# Returns a list - iDims, iLims, then iArgs, where iArgs is a key-value list
# iDims iLims iType iList iType iList ...
#
# Syntax:
# ParseIndices $inputs $dims
#
# Arguments:
# inputs        Index inputs (e.g. *, {0 3}, 0:10, end.)
# dims          Shape to index into

proc ::ndlist::ParseIndices {inputs dims} {
    set iDims ""; # dimensions of indexed region
    set iLims ""; # Maximum indices for indexed region
    set iArgs ""; # paired list of index type and index list (meaning varies)
    foreach input $inputs dim $dims {
        # Parse index notation
        lassign [ParseIndex $input $dim] iType iList 
        # Determine size of indexed range and limit.
        switch $iType {
            A { # All indices
                set iDim $dim
                set iLim [expr {$dim - 1}]
            }
            R { # Range of indices
                lassign $iList start stop
                if {$start <= $stop} {
                    set iDim [expr {$stop - $start + 1}]
                    set iLim $stop
                } else {
                    set iDim [expr {$start - $stop + 1}]
                    set iLim $start
                }
            }
            L { # List of indices
                set iDim [llength $iList]
                set iLim [max $iList]
            }
            S { # Single index
                set iDim 0
                set iLim $iList
            }
        }
        # Append to result
        lappend iDims $iDim
        lappend iLims $iLim
        lappend iArgs $iType $iList
    }
    return [list $iDims $iLims {*}$iArgs]
}

# ParseIndex --
# 
# Used for parsing index input (i.e. list of indices, range 0:10, etc)
#
# Returns:
# iType:    Type of index (A, R, L, or S)
# iList:    List of indices corresponding with type.
#   A:      Empty
#   R:      Range start and stop
#   L:      List of indices 
#   S:      Single index (flattens list)

proc ::ndlist::ParseIndex {input n} {
    # Check length of input
    if {[llength $input] != 1} {
        # List of indices (user entered)
        return [list L [lmap index $input {Index2Integer $index $n}]]
    }
    # Single index, colon, or range notation
    set index [lindex $input 0]
    # All index notation
    if {$index in {* :}} {
        return [list A ""]
    }
    # Single index notation
    if {[string index $index end] eq {.}} {
        # Single index notation (flatten along this dimension)
        return [list S [Index2Integer [string range $index 0 end-1] $n]]
    }
    # Single index, not range notation
    if {![string match *:* $index]} {
        return [list L [Index2Integer $index $n]]
    }
    # Range index notation
    set parts [split $index :]
    # Simple range case ($start:$stop)
    if {[llength $parts] == 2} {
        lassign $parts start stop
        set start [Index2Integer $start $n]
        set stop [Index2Integer $stop $n]
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
        set start [Index2Integer $start $n]
        set stop [Index2Integer $stop $n]
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
        # Normal case (call range function)
        return [list L [range $start $stop $step]]
    }
    return -code error "invalid range index notation: should be \
            \"start:stop\" or \"start:step:stop\""
}

# Index2Integer --
#
# Private function, converts end+-integer index format into integer
# Negative indices get converted, such that -1 is end, -2 is end-1, etc.
# Throws error if index is out of range.
#
# Arguments:
# index:        Tcl index format (integer?[+-]integer? or end?[+-]integer?)
# n:            Length of list to index

proc ::ndlist::Index2Integer {index n} {
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
    # Check if out of range
    if {$i >= $n} {
        return -code error "index out of range"
    }
    return $i
}

# nset --
# 
# Set portion of ndlist using ndlist index notation.
# Simply calls nreplace to set new value of ndlist.
#
# Syntax:
# nset $varName $i1 $i2 ... $sublist
#
# Arguments:
# varName       Variable where a valid ndlist is stored
# i1 i2 ...     Separate arguments for index dimensions
# sublist       Sublist to set (must agree in dimension or unity)
#               If blank, removes elements (must remove only along one axis)

# Examples:
# > set a {1 2 3 4}
# > nset a 0:1 {foo bar}
# > puts $a
# foo bar 3 4

proc ::ndlist::nset {varName args} {
    upvar 1 $varName ndlist
    # Initialize ndlist if not set yet
    if {![info exists ndlist]} {
        set ndlist ""
    }
    set ndlist [nreplace $ndlist {*}$args]
    return $ndlist
}

# nreplace --
#
# Replace portion of ndlist - return new list, same dimension. 
#
# Syntax:
# nreplace $ndlist $i1 $i2 ... $sublist
# 
# Arguments:
# ndlist        Valid ndlist
# i1 i2 ...     Separate arguments for index dimensions
# sublist       Sublist to replace with (must agree in dimension or unity)
#               If blank, removes elements (must remove only along one axis)

proc ::ndlist::nreplace {ndlist args} {
    # Interpret input
    set indices [lrange $args 0 end-1]; # $i ...
    set sublist [lindex $args end]
    # Get number of dimensions
    set ndims [llength $indices]
    # Scalar case
    if {$ndims == 0} {
        return $sublist
    }
    # Parse indices
    set dims [GetShape $ndims $ndlist]
    set iArgs [lassign [ParseIndices $indices $dims] iDims iLims]
    # Switch for replacement type (removal or substitution)
    if {[llength $sublist] == 0} {
        # Removal/deletion    
        # Get axis to delete along
        set axis -1
        set i 0
        foreach {iType iList} $iArgs {
            if {$iType ne "A"} {
                if {$axis != -1} {
                    return -code error "can only delete along one axis"
                }
                set axis $i
            }
            incr i
        }
        # Trivial case (removal of all)
        if {$axis == -1} {
            return ""
        }
        # Get axis information
        set dim [lindex $dims $axis]
        set iDim [lindex $iDims $axis]
        set iLim [lindex $iLims $axis]
        set iType [lindex $iArgs [expr {$axis * 2}]]
        set iList [lindex $iArgs [expr {$axis * 2 + 1}]]
        # Handle "L" case, indices must be sorted and unique.
        if {$iType eq "L"} {
            set iList [lsort -integer -decreasing -unique $iList]
            set iDim [llength $iList]
        } elseif {$iType eq "S"} {
            set iDim 1; # Single removal
        }
        # Get new dimension along removal axis
        set subdim [expr {$dim - $iDim}]
        # Check for null case
        if {$subdim == 0} {
            return ""
        }
        # Get new dimensions
        set subdims [lreplace $dims $axis $axis $subdim]
        # Call recursive removal handler and return with new dimensions
        set ndlist [RecRemove $ndlist $axis $iType $iList]
    } else {
        # Substitution/replacement
        # Process input dimensions
        set subdims ""
        foreach iDim $iDims {
            if {$iDim > 0} {
                lappend subdims $iDim
            }
        }
        # Expand sublist if needed based on index dimensions.
        set sublist [nexpand $sublist {*}$subdims]
        # Call recursive replacement handler
        set ndlist [RecReplace $ndlist $sublist {*}$iArgs]
    }
    # Return updated list
    return $ndlist
}

# RecRemove --
#
# Private recursive handler for removing elements from ndlists
#
# Syntax:
# RecRemove $ndlist $axis $iType $iList
#
# Arguments:
# ndlist:       ndlist to modify
# axis:         Axis to remove on
# iType         Index type, "A" not allowed. See ParseIndex.
# iList         Index list. See ParseIndex.

proc ::ndlist::RecRemove {ndlist axis iType iList} {
    # Base case
    if {$axis == 0} {
        return [Remove $ndlist $iType $iList]
    }
    # Recursion case
    incr axis -1
    set ndlist [lmap ndrow $ndlist {
        RecRemove $ndrow $axis $iType $iList
    }]
    return $ndlist
}

# Remove --
#
# Base case for RecRemove
#
# Syntax:
# Remove $list $iType $iList
# 
# Arguments:
# list          List to remove elements from
# iType         Index type, "A" not allowed. See ParseIndex.
# iList         Index list. See ParseIndex.

proc ::ndlist::Remove {list iType iList} {
    # Base case
    switch $iType {
        L { # Subset of indices
            foreach i $iList {
                set list [lreplace $list $i $i]
            }
        }
        R { # Range of indices
            lassign $iList i1 i2
            if {$i2 >= $i1} {
                set list [lreplace $list $i1 $i2]
            } else {
                set list [lreplace $list $i2 $i1]
            }
        }
        S { # Single index (same as L for removal)
            set i [lindex $iList 0]
            set list [lreplace $list $i $i]
        }
    }
    return $list
}

# RecReplace --
#
# Private recursive handler for nreplace
#
# Syntax:
# RecReplace $ndlist $sublist $iType $iList ...
#
# Arguments:
# ndlist        ndlist to modify (pass by value)
# sublist       ndlist to substitute at specified indices
# iType ...     Index type. See ParseIndex.
# iList ...     Index list. See ParseIndex.

proc ::ndlist::RecReplace {ndlist sublist iType iList args} {
    # Base case
    if {[llength $args] == 0} {
        return [Replace $ndlist $sublist $iType $iList]
    }
    # Get portion of ndlist to perform substitution
    set ndrows [Get $ndlist $iType $iList]
    # Recursively replace elements in sublist
    if {$iType eq "S"} {
        set sublist [RecReplace $ndrows $sublist {*}$args]
    } else {
        set sublist [lmap ndrow $ndrows subrow $sublist {
            RecReplace $ndrow $subrow {*}$args
        }]
    }
    # Finally, replace at this level.
    return [Replace $ndlist $sublist $iType $iList]
}

# Replace --
#
# Base case (list) for RecReplace 
#
# Syntax:
# Replace $list $sublist iType iList
#
# Arguments:
# list          list to modify (pass by value)
# sublist       list of values to substitute at specified indices
# iType         Index type. See ParseIndex.
# iList         Index list. See ParseIndex.

proc ::ndlist::Replace {list sublist iType iList} {
    # Switch for index type
    switch $iType {
        A { # All indices
            set list $sublist
        }
        L { # Subset of indices
            foreach i $iList subrow $sublist {
                lset list $i $subrow
            }
        }
        R { # Range of indices
            lassign $iList i1 i2
            if {$i2 >= $i1} {
                set list [lreplace $list $i1 $i2 {*}$sublist]
            } else {
                set list [lreplace $list $i2 $i1 {*}[lreverse $sublist]]
            }
        }
        S { # Single index (flatten)
            set i [lindex $iList 0]
            lset list $i $sublist
        }
    }
    return $list
}

# NDLIST COMBINATION
################################################################################

# ninsert --
#
# Insert ndlists in other ndlists, verifying that dimensions are compatible.
#
# Syntax:
# ninsert $nd $ndlist $index $sublist <$axis>
#
# Arguments:
# nd            Number of dimensions
# ndlist        ndlist to modify
# index         Index to insert at
# sublist       ndlist to insert
# axis          Axis to insert along. Default 0.

proc ::ndlist::ninsert {nd ndlist index sublist {axis 0}} {
    # Get number of dimensions and ndlist shape
    set ndims [GetNDims $nd]
    # Check validity of ndims/axis
    if {![string is integer -strict $axis]} {
        return -code error "axis must be integer"
    }
    if {$axis < 0 || $axis >= $ndims} {
        return -code error "axis out of range"
    }
    # Verify that dimensions agree on all axes except for the insert axis
    set dims [GetShape $ndims $ndlist]
    set subdims [GetShape $ndims $sublist]
    set i 0
    foreach dim $dims subdim $subdims {
        if {$dim ne $subdim && $i != $axis} {
            return -code error "incompatible dimensions along axis $i"
        }
        incr i
    }
    # Perform recursive insertion
    return [RecInsert $ndlist $axis $index $sublist]
}

# RecInsert --
# 
# Recursive handler for ninsert (after dimensions were checked)
#
# Syntax:
# RecInsert $ndlist $axis $index $arg...
#
# Arguments:
# ndlist        ndlist to modify
# axis          axis to insert along
# index         index to insert at
# arg...        sublists to insert.

proc ::ndlist::RecInsert {ndlist axis index sublist} {
    # Base case
    if {$axis == 0} {
        return [linsert $ndlist $index {*}$sublist]
    }
    # Recursion
    incr axis -1
    lmap ndrow $ndlist subrow $sublist {
        RecInsert $ndrow $axis $index $subrow
    }
}

# nstack --
#
# Combine ndlists (special case of ninsert)
#
# Syntax:
# nstack $nd $ndlist1 $ndlist2 <$axis>
#
# Arguments:
# nd                Number of dimensions
# ndlist1 ndlist2   ND lists to stack
# axis              Axis to stack along. Default 0.

proc ::ndlist::nstack {nd ndlist1 ndlist2 {axis 0}} {
    ninsert $nd $ndlist1 end $ndlist2 $axis
}

# NDLIST MANIPULATION
################################################################################

# nflatten --
#
# Flatten an ndlist to a vector (1D)
# If nd is 0D, it creates a 1D list.
#
# Syntax:
# nflatten $nd $ndlist
#
# Arguments:
# nd            Number of dimensions (e.g. 1D, 2D, etc.)
# ndlist        ND list to reshape dimensions of

proc ::ndlist::nflatten {nd ndlist} {
    # Interpret input and get dimensionality
    set ndims [GetNDims $nd]
    # Handle scalar case
    if {$ndims == 0} {
        # Create a one-element list
        return [list $ndlist]
    }
    # Flatten the ndlist
    set vector $ndlist
    for {set i 1} {$i < $ndims} {incr i} {
        set vector [concat {*}$vector]
    }
    return $vector
}

# nswapaxes --
#
# Swaps axes
#
# Syntax:
# nswapaxes $ndlist $axis1 $axis2
#
# Arguments:
# ndlist        ND list to manipulate
# axis1         Axis to swap with axis 2
# axis2         Axis to swap with axis 1

proc ::ndlist::nswapaxes {ndlist axis1 axis2} {
    # Get axes in order
    lassign [lsort -integer [list $axis1 $axis2]] axis1 axis2
    # Check axes
    if {$axis1 < 0} {
        return -code error "axes out of range"
    }
    # Trivial case (same axis)
    if {$axis1 == $axis2} {
        return $ndlist
    }
    RecSwapAxes $ndlist $axis1 $axis2
}

# RecSwapAxes --
# 
# Recursive handler for ntranspose (after axes are checked)
#
# Arguments:
# ndlist:           ND list to manipulate
# axis1:            Axis to swap with axis 2
# axis2:            Axis to swap with axis 1 (must be greater than axis2)

proc ::ndlist::RecSwapAxes {ndlist axis1 axis2} {
    # Check if at axis to swap
    if {$axis1 == 0} {
        # First transpose
        set ndlist [transpose $ndlist]; # (ijk -> jik)
        # Base case
        if {$axis2 == 1} {
            return $ndlist
        }
        # Recursion (pass axis1 to axis2 position, and axis2 to axis1+1)
        incr axis2 -1
        set ndlist [lmap ndrow $ndlist {
            set ndrow [RecSwapAxes $ndrow $axis1 $axis2]; # (jik -> jki)
        }]
        # Final transpose
        return [transpose $ndlist]; # (jki -> kji)
    }
    # Simple recursion to get to first swap axis
    incr axis1 -1
    incr axis2 -1
    lmap ndrow $ndlist {
        RecSwapAxes $ndrow $axis1 $axis2
    }
}

# NDLIST MAPPING
################################################################################

# napply --
#
# Apply a function to a ND List
#
# Syntax:
# napply $nd $command $ndlist $arg ...
#
# Arguments:
# nd                Number of dimensions (e.g. 1D, 2D, etc.)
# command           Command prefix
# ndlist            ND list to iterate over
# arg ...           Additional arguments to append to command.

proc ::ndlist::napply {nd command ndlist args} {
    RecApply [GetNDims $nd] $command $ndlist {*}$args
}

# RecApply --
#
# Recursive handler for napply
#
# Syntax:
# RecApply $ndims $command $ndlist $arg...
# 
# Arguments:
# ndims             Number of dimensions at the current recursion level.
# command           Command prefix
# ndlist            ND list to iterate over
# arg...            Additional arguments to append to command.

proc ::ndlist::RecApply {ndims command ndlist args} {
    # Base case
    if {$ndims == 0} {
        return [eval [linsert $command end $ndlist {*}$args]]
    }
    # Recursion
    incr ndims -1
    lmap ndrow $ndlist {
        RecApply $ndims $command $ndrow {*}$args
    }
}

# napply2 --
#
# Apply a function over two ND lists
#
# Syntax:
# napply2 $nd $command $ndlist1 $ndlist2 $arg ...
#
# Arguments:
# nd                Number of dimensions (e.g. 1D, 2D, etc.)
# command           Command prefix
# ndlist1 ndlist2   ND lists to iterate over
# arg ...           Additional arguments to append to command.

proc ::ndlist::napply2 {nd command ndlist1 ndlist2 args} {
    set ndims [GetNDims $nd]
    set dims [GetMaxShape $ndims $ndlist1 $ndlist2]
    set ndlist1 [nexpand $ndlist1 {*}$dims]
    set ndlist2 [nexpand $ndlist2 {*}$dims]
    RecApply2 $ndims $command $ndlist1 $ndlist2 {*}$args
}

# RecApply2 --
#
# Recursive handler for napply2
#
# Syntax:
# RecApply2 $ndims $command $ndlist1 $ndlist2 $arg...
# 
# Arguments:
# ndims             Number of dimensions at the current recursion level.
# command           Command prefix
# ndlist1 ndlist2   ND lists to iterate over
# arg...            Additional arguments to append to command.

proc ::ndlist::RecApply2 {ndims command ndlist1 ndlist2 args} {
    # Base case
    if {$ndims == 0} {
        return [eval [linsert $command end $ndlist1 $ndlist2 {*}$args]]
    }
    # Recursion
    incr ndims -1
    lmap ndrow1 $ndlist1 ndrow2 $ndlist2 {
        RecApply2 $ndims $command $ndrow1 $ndrow2 {*}$args
    }
}

# nreduce --
#
# Use a reducing function to process an ND list along an axis.
# Function must take a 1D list as an input and return a value.
#
# Syntax:
# nreduce $nd $command $ndlist <$axis> <$arg ...>
#
# Arguments:
# nd                Number of dimensions (e.g. 1D, 2D, etc.)
# command           Function to apply along axis.
# ndlist            ND list to reduce.
# axis              Axis to reduce along over. Default 0.
# arg ...           Additional arguments to append to command.
# 
# Example:
# nreduce 2 max $x; # Gets maximum values for each column.
# nreduce 2 max $x 1; # Gets maximum values for each row.

proc ::ndlist::nreduce {nd command ndlist {axis 0} args} {
    # Interpret input
    set ndims [GetNDims $nd]
    if {$ndims == 0} {
        return -code error "cannot reduce a scalar"
    }
    if {![string is integer -strict $axis]} {
        return -code error "expected integer, got \"$axis\""
    }
    if {$axis < 0 || $axis >= $ndims} {
        return -code error "axis out of range"
    }
    # Move axis to reduce to back of ND list
    set ndlist [MoveAxisToBack $ndims $ndlist $axis] 
    # Reduce the ND list.
    napply [incr ndims -1] $command $ndlist {*}$args
}

# MoveAxisToBack --
#
# Private recursive function for moving an axis to the back of the ND list.
#
# Syntax:
# MoveAxisToBack $ndims $ndlist $axis
#
# Arguments:
# ndims             Number of dimensions
# ndlist            ND list to iterate over
# axis              Axis to move to back

proc ::ndlist::MoveAxisToBack {ndims ndlist axis} {
    # Base case
    if {$ndims == 1} {
        return $ndlist
    }
    # Recursion
    incr ndims -1
    if {$axis == 0} {
        set ndlist [transpose $ndlist]; # (ijk -> jik)
    } else {
        incr axis -1
    }
    lmap ndrow $ndlist {
        MoveAxisToBack $ndims $ndrow $axis; # (jik -> jki)
    }
}

# nmap --
# 
# General purpose mapping function for ND lists
# If "continue" or "break" are used, it will return an error.
#
# Syntax:
# nmap $nd $varName $ndlist ... $body; # lmap style, returns value.
# 
# Arguments:
# nd            Number of dimensions (e.g. 1D, 2D, etc.)
# varName       Variable name to iterate with (lmap style)
# ndlist        ndlist to iterate over (lmap style)
# body          Body to evaluate at every iteration

proc ::ndlist::nmap {nd args} {
    # Check arity
    if {[llength $args] == 1 || [llength $args] % 2 == 0} {
        return -code error "wrong # args: should be\
                \"nmap nd varName ndlist ?varName ndlist ...? body\""
    }
    # Interpret input
    set ndims [GetNDims $nd]
    set varMap [lrange $args 0 end-1]
    set varNames [dict keys $varMap]
    set ndlists [dict values $varMap]
    set body [lindex $args end]
    # Handle scalar case
    if {$ndims == 0} {
        uplevel 1 [list lassign $ndlists {*}$varNames]
        return [uplevel 1 $body]
    }
    # Expand all ndlists to have the same shape, and then flatten.
    set dims [GetMaxShape $ndims {*}$ndlists]
    set ndlists [lmap ndlist $ndlists {nexpand $ndlist {*}$dims}]
    set ndlists [lmap ndlist $ndlists {nflatten $ndims $ndlist}]
    # Update varName-ndlist mapping with flattened ndlists.
    set varMap ""
    foreach varName $varNames ndlist $ndlists {
        lappend varMap [list $varName] $ndlist
    }
    # Perform linear mapping in caller, then reshape and return.
    nreshape [uplevel 1 [list lmap {*}$varMap $body]] {*}$dims
}

# GetMaxShape --
#
# Get maximum dimensions of multiple ND lists (for expanding)
#
# Syntax:
# GetMaxShape $ndims $arg ...
#
# Arguments:
# ndims         Number of dimensions (e.g. 1D, 2D, etc.)
# arg ...       ND lists to get max shape from

proc ::ndlist::GetMaxShape {ndims args} {
    set shapes [lmap ndlist $args {GetShape $ndims $ndlist}]
    lmap dims [transpose $shapes] {max $dims}
}

# ND LIST MATH MAPPING
################################################################################

# nop --
#
# Simple math operations on ndlists.
#
# Syntax:
# nop $nd $ndlist $op $arg ...
#
# Arguments:
# nd            Number of dimensions (e.g. 1D, 2D, etc.)
# ndlist        ND list to iterate over
# op            Valid mathop (see tcl::mathop documentation)
# arg ...       Values to perform mathop with 
#
# Matrix examples:
# nop 2D $matrix /; # Performs reciprocal
# nop 2D $matrix -; # Negates values
# nop 2D $matrix !; # Boolean negation
# nop 2D $matrix + 5 1; # Adds 5 and 1 to each matrix element
# nop 2D $matrix ** 2; # Squares entire matrix
# nop 2D $matrix in {1 2 3}; # Returns boolean matrix, if values are in a list

proc ::ndlist::nop {nd ndlist op args} {
    napply [GetNDims $nd] ::tcl::mathop::$op $ndlist {*}$args
}

# nop2 --
#
# Simple math operations over two ND lists (element-wise)
#
# Syntax:
# nop2 $nd $ndlist1 $op $ndlist2 $arg ...
#
# Arguments:
# nd                Number of dimensions (e.g. 1D, 2D, etc.)
# ndlist1 ndlist2   ND lists to iterate over
# op                Valid mathop (see tcl::mathop documentation)
# arg ...           Additional values to perform mathop with 
#
# Matrix examples:
# nop2 2D $A + $B

proc ::ndlist::nop2 {nd ndlist1 op ndlist2 args} {
    napply2 [GetNDims $nd] ::tcl::mathop::$op $ndlist1 $ndlist2 {*}$args
}

# nexpr --
#
# Generalized math mapping (uses nmap)
#
# Syntax:
# nexpr $nd $varName $ndlist <$varName $ndlist ...> $expr
#
# Arguments:
# varName ...   Variable(s) to map with
# ndlist ...    ND list(s) to map over.
# expr          Tcl math expression to evaluate.

proc ::ndlist::nexpr {nd args} {
    # Check arity
    if {[llength $args] == 1 || [llength $args] % 2 == 0} {
        return -code error "wrong # args: should be\
                \"nexpr nd varName ndlist ?varName ndlist ...? expr"
    }
    # Interpret input
    set ndims [GetNDims $nd]
    set varMap [lrange $args 0 end-1]
    set expr [lindex $args end]
    # Call modified nmap
    tailcall nmap $ndims {*}$varMap [list expr $expr]
}
