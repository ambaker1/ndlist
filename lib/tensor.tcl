# tensor.tcl
################################################################################
# Tensor (ND-list) implementation

# Copyright (C) 2025 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Define namespace and exported commands
namespace eval ::ndlist {    
    variable map_index ""; # Linear index of mapping
    variable map_shape ""; # Shape of nmap list
    namespace export ndlist nshape nsize; # ND-list basics
    namespace export nfull nrand; # ND-list initialization
    namespace export nflatten nreshape; # Reshaping an ND-list
    namespace export nrepeat nexpand npad nextend; # Expanding an ND-list
    namespace export nget nset nreplace; # Access/modification
    namespace export nremove ninsert ncat; # Deletion/Combination
    namespace export nswapaxes nmoveaxis npermute; # Axis reordering
    namespace export napply napply2 nreduce; # Functional mapping
    namespace export nmap i j k; # Generalized mapping/looping
}

# ND-LIST BASICS
################################################################################

# ndlist --
#
# Validates an ND-list, and returns the ND-list.
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
    # Check if it is a valid ND-list, and try to shape it into one.
    if {![IsShape $ndlist {*}[GetShape $ndims $ndlist]]} {
        return -code error "not a valid ${ndims}D-list"
    }
    return $ndlist
}

# nshape --
# 
# Get shape of ND-list
#
# Syntax:
# nshape $nd $ndlist <$axis>
#
# Arguments:
# nd                Number of dimensions (e.g. 1D, 2D, etc.)
# ndlist            ND-list to get dimensions of
# axis              Axis to get dimension along. Blank for all.

proc ::ndlist::nshape {nd ndlist {axis ""}} {
    # Interpret and validate input
    set ndims [GetNDims $nd]
    # Switch for output type
    if {$axis eq ""} {
        return [GetShape $ndims $ndlist]
    }
    ValidateAxis $ndims $axis
    # Get single dimension (along first index)
    llength [lindex $ndlist {*}[lrepeat $axis 0]]
}

# nsize --
#
# Get the size of an ND-list (number of elements, product of the shape)
# For rank 0, it returns blank.
#
# Syntax:
# nsize $nd $ndlist
#
# Arguments:
# nd:               Number of dimensions (e.g. 1D, 2D, etc.)
# ndlist:           ND-list to get dimensions of

proc ::ndlist::nsize {nd ndlist} {
    set ndims [GetNDims $nd]
    # Scalar case (no size)
    if {$ndims == 0} {
        return
    }
    # Get size (product of shape)
    product [GetShape $ndims $ndlist]
}

# ND-LIST CREATION/EXPANSION
################################################################################

# nfull --
#
# Create an ND-list filled with one value
#
# Syntax:
# nfull $value $n ...
#
# Arguments:
# value         Value to repeat
# n ...         Shape of ND-list

proc ::ndlist::nfull {value args} {
    set ndlist $value
    foreach n [lreverse $args] {
        if {$n == 0} {
            return
        }
        set ndlist [lrepeat $n $ndlist]
    }
    return $ndlist
}

# nrand --
# 
# Generate an ND-list filled with random values between 0 and 1
#
# Syntax:
# nrand $n ...
#
# Arguments:
# n ...         Shape of resulting ND-list

proc ::ndlist::nrand {args} {
    # Base case
    if {[llength $args] == 0} {
        return [::tcl::mathfunc::rand]
    }
    # Recursion
    set args [lassign $args n]
    lmap x [lrepeat $n {}] {
        nrand {*}$args
    }
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
# arg ...       New shape (and dimensions). One axis may be dynamic (*)

proc ::ndlist::nreshape {vector args} {
    set size [llength $vector]
    # Scalar case
    if {[llength $args] == 0} {
        if {$size != 1} {
            return -code error "incompatible dimensions"
        }
        # Note: 1 element list can be converted to scalar.
        return [lindex $vector 0]
    }
    # Vector case (allow for dynamic "*")
    if {[llength $args] == 1} {
        set arg [lindex $args 0]
        if {$size != $arg && $arg ne "*"} {
            return -code error "incompatible dimensions"
        }
        return $vector
    }
    # Matrix and higher-dimensional case (allow for one dynamic axis)
    set dynamic [lsearch -all -exact $args "*"]
    if {[llength $dynamic] > 1} {
        return -code error "can only make one axis dynamic"
    }
    if {[llength $dynamic] == 1} {
        set subsize [product [lreplace $args $dynamic $dynamic]]
        lset args $dynamic [expr {$size/$subsize}]
    }
    # Check compatibility
    if {[product $args] != $size} {
        return -code error "incompatible dimensions"
    }
    # Call recursive handler
    RecReshape $vector {*}$args
}

# RecReshape --
#
# Recursive handler for reshaping an ND-list
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

# nflatten --
#
# Flatten an ND-list to a vector (1D-list)
# If rank is 0, it creates a 1D-list with one element.
#
# Syntax:
# nflatten $nd $ndlist
#
# Arguments:
# nd            Number of dimensions (e.g. 1D, 2D, etc.)
# ndlist        ND-list to reshape dimensions of

proc ::ndlist::nflatten {nd ndlist} {
    # Interpret input and get dimensionality
    set ndims [GetNDims $nd]
    # Handle scalar case
    if {$ndims == 0} {
        # Create a one-element list
        return [list $ndlist]
    }
    # Flatten the ND-list
    set vector $ndlist
    for {set i 1} {$i < $ndims} {incr i} {
        set vector [concat {*}$vector]
    }
    return $vector
}

# nrepeat --
#
# Repeat an ND-list multiple times along an axis
#
# Syntax:
# nrepeat $ndlist $n ...
#
# Arguments:
# ndlist        ND-list to repeat
# n ...         Number of times to repeat ND-list along the axis.

proc ::ndlist::nrepeat {ndlist args} {
    # Scalar case
    if {[llength $args] == 0} {
        return $ndlist
    }
    # Validate integer inputs
    foreach n $args {
        if {![string is integer -strict $n]} {
            return -code error "expected integer but got \"$n\""
        }
        if {$n <= 0} {
            return -code error "bad count \"$n\": must be integer > 0"
        }
    }
    # Trivial case
    if {[lsearch -exact -integer -not $args 1] == -1} {
        return $ndlist
    }
    # Call recursive handler
    RecRepeat $ndlist {*}$args
}

# RecRepeat --
#
# Recursive handler for nexpand. 
#
# Syntax:
# RecRepeat $ndlist $n ...
#
# Arguments:
# ndlist        ND-list to expand
# n ...         Number of times to repeat at each level.

proc ::ndlist::RecRepeat {ndlist n args} {
    # Base case
    if {[llength $args] == 0} {
        if {$n == 1} {
            return $ndlist
        }
        return [lrepeat $n {*}$ndlist]
    }
    # Recursion
    if {$n == 1} {
        return [lmap ndrow $ndlist {
            RecRepeat $ndrow {*}$args
        }]
    }
    lrepeat $n {*}[lmap ndrow $ndlist {
        RecRepeat $ndrow {*}$args
    }]
}

# nexpand --
#
# Expands an ND-list to new dimensions.
# New dimensions must match or be divisible by old dimensions.
# For example, 1x1, 2x1, 4x1, 1x3, 2x3 and 4x3 are compatible with 4x3.
#
# Syntax:
# nexpand $ndlist $arg ...
#
# Arguments:
# ndlist        ND-list to expand
# arg ...       New shape. -1 to keep shape at that dimension.

proc ::ndlist::nexpand {ndlist args} {    
    # Get dimensions
    set dims [GetShape [llength $args] $ndlist]
    set args [lmap dim $dims arg $args {expr {$arg == -1 ? $dim : $arg}}]
    # Get number of repetitions at every level
    nrepeat $ndlist {*}[lmap dim $dims arg $args {
        if {$arg % $dim} {
            return -code error "incompatible dimensions"
        } else {
            # Compute number of repetitions by integer division.
            expr {$arg / $dim}
        }
    }]
}

# npad --
# 
# Pad an ND-list with a value.
# 
# Syntax:
# npad $ndlist $value $n ...
#
# Arguments:
# ndlist        ND-list to expand
# n ...         Amount to pad. 0 for none. 

proc ::ndlist::npad {ndlist value args} {
    # Check input
    foreach arg $args {
        if {![string is integer -strict $arg] || $arg < 0} {
            return -code error "bad count \"$arg\": must be >= 0"
        }
    }
    # Null case
    if {[llength $ndlist] == 0} {
        return [nfull $value {*}$args]
    }
    # Get dimensions
    set dims [GetShape [llength $args] $ndlist]
    # Call recursive handler
    RecPad $ndlist $value $dims {*}$args
}

# RecPad --
# 
# Recursive function that pads an ND-list to a new shape.
# Assumes that inputs are non-negative.
#
# Syntax:
# RecPad $ndlist $value $n ...
#
# Arguments:
# ndlist        ND-list to pad
# value         Value to pad with
# dims          Shape of ND-list
# n ...         Amount to pad.

proc ::ndlist::RecPad {ndlist value dims n args} {
    # Base case
    if {[llength $args] == 0} {
        if {$n == 0} {
            return $ndlist
        } else {
            return [concat $ndlist [lrepeat $n $value]]
        }
    }
    # Recursion case
    set dims [lrange $dims 1 end]; # trim dims
    # Skip case
    if {$n > 0} {
        set ndlist [concat $ndlist [nfull $value $n {*}$dims]]
    }
    lmap ndrow $ndlist {
        RecPad $ndrow $value $dims {*}$args
    }
}

# nextend --
#
# Extend an ND-list to a new shape, filling with a single value.
# 
# Syntax:
# nextend $ndlist $value $arg ...
#
# Arguments:
# ndlist        ND-list to expand
# arg ...       New shape, greater than or equal to old.
#               -1 to maintain shape at axis.

proc ::ndlist::nextend {ndlist value args} {
    # Get dimensions
    set dims [GetShape [llength $args] $ndlist]
    # Pad the ndlist based on the difference between new and old.
    npad $ndlist $value {*}[lmap dim $dims arg $args {
        expr {$arg == -1 ? 0 : $arg - $dim}
    }]
}


# ND-LIST ACCESS/MODIFICATION
################################################################################

# nget --
# 
# Get portion of ND-list using index notation.
#
# Syntax:
# nget $ndlist $i1 $i2 ...
#
# Arguments:
# ndlist        ND-list value
# i1 i2 ...     Separate arguments for index dimensions

proc ::ndlist::nget {ndlist args} {
    # Get number of dimensions
    set ndims [llength $args]
    # Scalar case
    if {$ndims == 0} {
        return $ndlist
    }
    # Parse indices
    set dims [GetShape $ndims $ndlist]
    set iArgs [ParseIndices $dims {*}$args]
    # Call recursive handler
    RecGet $ndlist {*}$iArgs
}

# RecGet --
#
# Private recursive handler for nget
#
# Syntax:
# RecGet $ndlist $iType $iList ...
# 
# Arguments:
# ndlist                ND-list to get values from
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

# nset --
# 
# Set portion of ND-list using index notation.
# Simply calls nreplace to set new value of ND-list.
#
# Syntax:
# nset $varName $i ... $sublist
#
# Arguments:
# varName       Variable where an ND-list is stored
# i ...         Indices to set at
# sublist       Sublist to set with (must be expandable)

# Examples:
# > set a {1 2 3 4}
# > nset a 0:1 {foo bar}
# > puts $a
# foo bar 3 4

proc ::ndlist::nset {varName args} {
    upvar 1 $varName ndlist
    if {![info exists ndlist]} {
        set ndlist ""
    }
    set ndlist [nreplace $ndlist {*}$args]
}

# nreplace --
#
# Replace portion of ND-list - return new list, same rank.
# Calls nremove when setting to blank, unless if all indices are dot indexes.
#
# Syntax:
# nreplace $ndlist $index ... $sublist
# 
# Arguments:
# ndlist        Valid ND-list
# index ...     Indices to replace at
# sublist       Sublist to replace with (must be expandable)
#               If blank and all other indices are "*", calls nremove.

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
    set iArgs [ParseIndices $dims {*}$indices]; # type list type list ...
    set iTypes [lmap {iType iList} $iArgs {set iType}]
    
    # Check for simple lset case
    if {[lsearch -exact -not $iTypes S] == -1} {
        # Linear case (just lset)
        if {$ndims == 1} {
            return [lset ndlist [lindex $iArgs 1 0] $sublist]
        }
        # Higher dimension case (ensure that indices are in range)
        set indices [lmap {iType iList} $iArgs {lindex $iList 0}]
        return [lset ndlist {*}$indices $sublist]
    }
    # Check for removal case
    if {[llength $sublist] == 0} {
        set axes [lsearch -all -exact -not $iTypes A]
        if {[llength $axes] == 0} {
            # Trivial case
            return
        } elseif {[llength $axes] == 1} {
            # Call nremove
            set axis [lindex $axes 0]
            return [nremove $ndlist [lindex $indices $axis] $axis]
        } else {
            return -code error "can only remove along one axis"
        }
    }
    # Expand sublist if needed based on index dimensions.
    set sublist [nexpand $sublist {*}[GetIndexShape $dims {*}$iArgs]]
    # Call recursive handler
    RecReplace $ndlist $sublist {*}$iArgs
}

# RecReplace --
#
# Private recursive handler for nreplace
#
# Syntax:
# RecReplace $ndlist $sublist $iType $iList ...
#
# Arguments:
# ndlist        ND-list to modify (pass by value)
# sublist       ND-list to substitute at specified indices
# iType ...     Index type. See ParseIndex.
# iList ...     Index list. See ParseIndex.

proc ::ndlist::RecReplace {ndlist sublist iType iList args} {
    # Base case
    if {[llength $args] == 0} {
        return [Replace $ndlist $sublist $iType $iList]
    }
    # Get portion of ND-list to perform substitution
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
    Replace $ndlist $sublist $iType $iList
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

# NDLIST REMOVAL/COMBINATION
################################################################################

# nremove --
#
# Remove portion of ND-list - return value.
#
# Syntax:
# nremove $ndlist $index <$axis>
# 
# Arguments:
# ndlist        Valid ND-list
# index         Index to remove at (using index notation)
# axis          Axis to remove along.

proc ::ndlist::nremove {ndlist index {axis 0}} {
    # Get removal type
    set dim [nshape [expr {$axis + 1}] $ndlist $axis]
    lassign [ParseIndex $dim $index] iType iList
    
    # Trivial case (remove all)
    if {$iType eq "A"} {
        return
    }
    # Handle "L" case, indices must be sorted and unique.
    if {$iType eq "L"} {
        set iList [lsort -integer -decreasing -unique $iList]
        set iDim [llength $iList]
    } elseif {$iType eq "S"} {
        set iDim 1; # Single removal
    } else {
        # Default case (call normal index parser)
        set iDim [GetIndexDim $dim $iType $iList]
    }
    # Null case
    if {$dim == $iDim} {
        return
    }
    # Call recursive removal handler
    RecRemove $ndlist $axis $iType $iList
}

# RecRemove --
#
# Private recursive handler for removing elements from ND-lists
#
# Syntax:
# RecRemove $ndlist $axis $iType $iList
#
# Arguments:
# ndlist:       ND-list to modify
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

# ninsert --
#
# Insert ND-list in other ND-lists, verifying that dimensions are compatible.
# If referencing from start, it inserts before.
# If referencing from end, it inserts after.
#
# Syntax:
# ninsert $nd $ndlist $index $sublist <$axis>
#
# Arguments:
# nd            Number of dimensions
# ndlist        ND-list to modify
# index         Index to insert at
# sublist       ND-list to insert
# axis          Axis to insert along. Default 0.

proc ::ndlist::ninsert {nd ndlist index sublist {axis 0}} {
    # Get number of dimensions, axis, shape, and insertion index.
    set ndims [GetNDims $nd]
    ValidateAxis $ndims $axis
    set dims [GetShape $ndims $ndlist]
    set i [Index2Integer [expr {[lindex $dims $axis] + 1}] $index]
    # Null tensor case (inserting null D-list does nothing)
    if {[llength $sublist] == 0} {
        return $ndlist
    }
    # Verify that dimensions agree on all axes except for the insert axis
    set subdims [GetShape $ndims $sublist]
    if {[lreplace $dims $axis $axis] ne [lreplace $subdims $axis $axis]} {
        return -code error "incompatible dimensions"
    }
    # Perform recursive insertion
    RecInsert $ndlist $i $sublist $axis
}

# RecInsert --
# 
# Recursive handler for ninsert (after dimensions were checked)
#
# Syntax:
# RecInsert $ndlist $i $sublist $axis
#
# Arguments:
# ndlist        ND-list to modify
# i             Index to insert at
# sublist       Sublist to insert
# axis          Axis to insert along

proc ::ndlist::RecInsert {ndlist i sublist axis} {
    # Base case
    if {$axis == 0} {
        return [linsert $ndlist $i {*}$sublist]
    }
    # Recursion
    incr axis -1
    lmap ndrow $ndlist subrow $sublist {
        RecInsert $ndrow $i $subrow $axis
    }
}

# ncat --
#
# Combine ND-lists by concatenation.
# Special case of ninsert.
#
# Syntax:
# ncat $nd $ndlist1 $ndlist2 <$axis>
#
# Arguments:
# nd                Number of dimensions
# ndlist1 ndlist2   ND-lists to stack
# axis              Axis to stack along. Default 0.

proc ::ndlist::ncat {nd ndlist1 ndlist2 {axis 0}} {
    ninsert $nd $ndlist1 end $ndlist2 $axis
}

# NDLIST AXIS MANIPULATION
################################################################################

# nswapaxes --
#
# Swaps two axes
#
# Syntax:
# nswapaxes $ndlist $axis1 $axis2
#
# Arguments:
# ndlist        ND-list to manipulate
# axis1         Axis to swap with axis 2
# axis2         Axis to swap with axis 1

proc ::ndlist::nswapaxes {ndlist axis1 axis2} {
    ValidateAxis Inf $axis1
    ValidateAxis Inf $axis2
    # Trivial case (same axis)
    if {$axis1 == $axis2} {
        return $ndlist
    }
    # Call recursive handler
    if {$axis1 < $axis2} {
        RecSwapAxes $ndlist $axis1 $axis2
    } else {
        RecSwapAxes $ndlist $axis2 $axis1
    }
}

# RecSwapAxes --
# 
# Recursive handler for ntranspose (after axes are checked)
#
# Arguments:
# ndlist:           ND-list to manipulate
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

# nmoveaxis --
#
# Move an axis from a source axis to target axis.
# e.g. 0 1 2 3 4 -> 4 0 1 2 3
#
# Syntax:
# nmoveaxis $ndlist $source $target
#
# Arguments:
# ndlist            ND-list to iterate over
# source            Source axis
# target            Target axis

proc ::ndlist::nmoveaxis {ndlist source target} {
    ValidateAxis Inf $source
    ValidateAxis Inf $target
    # Trivial case (no move)
    if {$source == $target} {
        return $ndlist
    }
    # Call recursive handler
    RecMoveAxis $ndlist $source $target
}

# RecMoveAxis --
#
# Private recursive function for moving an axis.
#
# Syntax:
# RecMoveAxis $ndlist $source $target
#
# Arguments:
# ndlist            ND-list to iterate over
# source            Source axis
# target            Target axis

proc ::ndlist::RecMoveAxis {ndlist source target} {
    # Base cases
    if {$source == 0} {
        return [MoveFront2Back $ndlist $target]
    }
    if {$target == 0} {
        return [MoveBack2Front $ndlist $source]
    }
    # Recursion
    incr source -1
    incr target -1
    lmap ndrow $ndlist {
        RecMoveAxis $ndrow $source $target
    }
}

# MoveFront2Back --
#
# Private recursive function for moving an axis to the back of the ND-list.
#
# Syntax:
# MoveFront2Back $ndlist $axis
#
# Arguments:
# ndlist            ND-list to iterate over
# axis              Target axis

proc ::ndlist::MoveFront2Back {ndlist axis} {
    # Base case
    if {$axis == 1} {
        return [transpose $ndlist]
    }
    # Recursion
    incr axis -1
    lmap ndrow [transpose $ndlist] {
        MoveFront2Back $ndrow $axis
    }
}

# MoveBack2Front --
#
# Private recursive function for moving an axis to the front of the ND-list.
#
# Syntax:
# MoveBack2Front $ndlist $axis
#
# Arguments:
# ndlist            ND-list to iterate over
# axis              Source axis

proc ::ndlist::MoveBack2Front {ndlist axis} {
    # Base case
    if {$axis == 1} {
        return [transpose $ndlist]
    }
    # Recursion
    incr axis -1
    transpose [lmap ndrow $ndlist {
        MoveBack2Front $ndrow $axis
    }]
}

# npermute --
#
# Reorders the ND-list according to list of axes.
#
# Syntax:
# npermute $ndlist $axis ...
#
# Arguments:
# ndlist        ND-list to manipulate
# axis ...      New order of axes. e.g. 2 0 1, or 2 3 0 1

proc ::ndlist::npermute {ndlist args} {
    # Get dimensionality and check validity of axes list
    set ndims [llength $args]
    # Validate axes
    foreach axis $args {
        ValidateAxis $ndims $axis
    }
    # Null case (same axis list)
    if {$args eq [range $ndims]} {
        return $ndlist
    }
    # Make sure there are no duplicates
    if {[llength [lsort -integer -unique $args]] != $ndims} {
        return -code error "invalid axes list: duplicates"
    }
    # Get index lists for axis swap.
    set dims [GetShape $ndims $ndlist]
    set indicesList [cartprod {*}[lmap dim $dims {range $dim}]]
    # Initialize new ND-list
    set newList [nfull {} {*}[lmap axis $args {lindex $dims $axis}]]
    # Fill new ND-list
    foreach indices $indicesList {
        set newIndices [lmap axis $args {lindex $indices $axis}]
        lset newList {*}$newIndices [lindex $ndlist {*}$indices]
    }
    return $newList
}

# ND-LIST MAPPING
################################################################################

# napply --
#
# Apply a function to a ND-list
#
# Syntax:
# napply $nd $command $ndlist $arg ...
#
# Arguments:
# nd                Number of dimensions (e.g. 1D, 2D, etc.)
# command           Command prefix
# ndlist            ND-list to iterate over
# arg ...           Additional arguments to append to command.

proc ::ndlist::napply {nd command ndlist args} {
    RecApply 1 [GetNDims $nd] $command $ndlist {*}$args
}

# RecApply --
#
# Recursive handler for napply
#
# Syntax:
# RecApply $level $ndims $command $ndlist $arg...
# 
# Arguments:
# level             Level to evaluate at
# ndims             Number of dimensions at the current recursion level.
# command           Command prefix
# ndlist            ND-list to iterate over
# arg...            Additional arguments to append to command.

proc ::ndlist::RecApply {level ndims command ndlist args} {
    incr level
    # Base case
    if {$ndims == 0} {
        set command [linsert $command end $ndlist {*}$args]
        return [uplevel $level $command]
    }
    # Recursion
    incr ndims -1
    lmap ndrow $ndlist {
        RecApply $level $ndims $command $ndrow {*}$args
    }
}

# napply2 --
#
# Apply a function over two ND-lists
#
# Syntax:
# napply2 $nd $command $ndlist1 $ndlist2 $arg ...
#
# Arguments:
# nd                Number of dimensions (e.g. 1D, 2D, etc.)
# command           Command prefix
# ndlist1 ndlist2   ND-lists to iterate over
# arg ...           Additional arguments to append to command.

proc ::ndlist::napply2 {nd command ndlist1 ndlist2 args} {
    set ndims [GetNDims $nd]
    set dims [GetMaxShape $ndims $ndlist1 $ndlist2]
    set ndlist1 [nexpand $ndlist1 {*}$dims]
    set ndlist2 [nexpand $ndlist2 {*}$dims]
    RecApply2 1 $ndims $command $ndlist1 $ndlist2 {*}$args
}

# RecApply2 --
#
# Recursive handler for napply2
#
# Syntax:
# RecApply2 $level $ndims $command $ndlist1 $ndlist2 $arg...
# 
# Arguments:
# level             Level to evaluate at
# ndims             Number of dimensions at the current recursion level.
# command           Command prefix
# ndlist1 ndlist2   ND-lists to iterate over
# arg...            Additional arguments to append to command.

proc ::ndlist::RecApply2 {level ndims command ndlist1 ndlist2 args} {
    incr level
    # Base case
    if {$ndims == 0} {
        set command [linsert $command end $ndlist1 $ndlist2 {*}$args]
        return [uplevel $level $command]
    }
    # Recursion
    incr ndims -1
    lmap ndrow1 $ndlist1 ndrow2 $ndlist2 {
        RecApply2 $level $ndims $command $ndrow1 $ndrow2 {*}$args
    }
}

# nreduce --
#
# Use a reducing function to process an ND-list along an axis.
# Function must take a 1D list as an input and return a value.
#
# Syntax:
# nreduce $nd $command $ndlist <$axis> <$arg ...>
#
# Arguments:
# nd                Number of dimensions (e.g. 1D, 2D, etc.)
# command           Function to apply along axis.
# ndlist            ND-list to reduce.
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
    ValidateAxis $ndims $axis
    # Move axis to reduce to back of ND-list, and reduce.
    set ndlist [nmoveaxis $ndlist $axis [expr {$ndims - 1}]]
    napply [expr {$ndims - 1}] $command $ndlist {*}$args
}

# ND-LIST LOOPING
################################################################################

# nmap --
# 
# General purpose mapping function for ND-lists
#
# Syntax:
# nmap $nd $varName $ndlist ... $body; # lmap style, returns value.
# 
# Arguments:
# nd            Number of dimensions (e.g. 1D, 2D, etc.)
# varName       Variable name to iterate with (lmap style)
# ndlist        ND-list to iterate over (lmap style)
# body          Body to evaluate at every iteration

proc ::ndlist::nmap {nd args} {
    variable map_index
    variable map_shape
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
    # Create varName-ndlist mapping with flattened ndlists.
    foreach varName $varNames ndlist $ndlists {
        lappend varMap [list $varName] $ndlist
    }
    # Save old map index and shape. 
    set oldmap_index $map_index
    set oldmap_shape $map_shape
    # Perform linear mapping, then reshape and return.
    try {
        set map_index -1
        set map_shape $dims
        set body "incr ::ndlist::map_index; $body"
        set vector [uplevel 1 [list lmap {*}$varMap $body]]
        # Null case
        if {[llength $vector] == 0} {
            return
        }
        nreshape $vector {*}$dims
    } finally {
        set map_index $oldmap_index
        set map_shape $oldmap_shape
    }
}

# i,j,k --
#
# Get index of nmap loop. 
# "j" and "k" are shorthand for "i 1" and "i 2", respectively.
#
# Syntax:
# i <$axis>
# j
# k
#
# Arugments:
# axis          Axis to get. Default 0 for first axis. -1 for linear index.

proc ::ndlist::i {{axis 0}} {
    variable map_index
    variable map_shape
    if {$map_index eq ""} {
        return -code error "invoked \"i\" outside of nmap loop"
    }
    # -1 case (return linear index)
    if {$axis == -1} {
        return $map_index
    }
    ValidateAxis [llength $map_shape] $axis
    # Get index list for given map index
    set indices [UnravelIndex $map_index {*}$map_shape]
    # Return desired index
    lindex $indices $axis
}
proc ::ndlist::j {} {i 1}
proc ::ndlist::k {} {i 2}
