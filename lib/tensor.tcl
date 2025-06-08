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
    variable ref; # Reference map for neval.
    namespace export ndims nshape nsize; # ND-list basics
    namespace export ndims_multiple; # Get/check ndims for compatibility
    namespace export nfull nrand; # ND-list initialization
    namespace export nflatten nreshape; # Reshaping an ND-list
    namespace export nrepeat nexpand npad nextend; # Expanding an ND-list
    namespace export nget nset nreplace; # Access/modification
    namespace export nremove ninsert ncat; # Deletion/Combination
    namespace export nswapaxes nmoveaxis npermute; # Axis reordering
    namespace export napply napply2 nreduce; # Functional mapping
    namespace export nmap i j k; # Generalized mapping/looping
    namespace export neval nexpr; # Element-wise evaluation/math
    
    # Polish notation for element-wise math
    variable mathops {~ ! - + * << ** / % >> & | ^ == != < <= > >=}
    foreach op $mathops {
        proc $op. {arg args} "::ndlist::MathOp $op \$arg {*}\$args"
        namespace export $op.
    }
}

# ND-LIST BASICS
################################################################################

# EVERYTHING IS AN NDLIST. STRINGS ARE 0D-LISTS. LISTS ARE 1D-LISTS.

# ndims --
#
# Returns the rank of the ndlist if "auto",
# otherwise validates the input rank.
#
# Syntax:
# ndims $ndlist <$rank>
#
# Arguments:
# value         Value to check for ndlist validity.
# rank          Number of dimensions. Default "auto"

proc ::ndlist::ndims {ndlist {rank auto}} {
    if {$rank eq "auto"} {
        return [GetNDims $ndlist]
    }
    # User-specified
    set ndims $rank
    ValidateNDims $ndims
    if {![IsNDList $ndims $ndlist]} {
        return -code error "not a valid ${ndims}D-list"
    }
    return $ndims
}

# ndims_multiple --
#
# Returns the rank of the ndlist if "auto",
# otherwise validates the input rank.
#
# Syntax:
# ndims $ndlist <$rank>
#
# Arguments:
# value         Value to check for ndlist validity.
# rank          Number of dimensions. Default "auto"

proc ::ndlist::ndims_multiple {ndlists {rank auto}} {
    if {[llength $ndlists] == 0} {
        return -code error "ndlists must have length > 0"
    }
    if {$rank eq "auto"} {
        return [GetMaxNDims {*}$ndlists]
    }
    # User-specified
    set ndims $rank
    ValidateNDims $ndims
    foreach ndlist $ndlists {
        if {![IsNDList $ndims $ndlist]} {
            return -code error "not a valid ${ndims}D-list"
        }
    }
    return $ndims
}

# nshape --
# 
# Get shape of ND-list
#
# Syntax:
# nshape $ndlist <$rank>
#
# Arguments:
# ndlist            ND-list to get dimensions of
# axis              Axis to get dimension along. Default blank for all.
# rank              Number of dimensions. Default auto.

proc ::ndlist::nshape {ndlist {rank auto}} {
    GetShape [ndims $ndlist $rank] $ndlist
}

# nsize --
#
# Get the size of an ND-list (number of elements, product of the shape)
# For rank 0, it returns blank.
#
# Syntax:
# nsize $ndlist <$rank>
#
# Arguments:
# ndlist:           ND-list to get dimensions of
# rank              Number of dimensions (e.g. 2D). Default "auto"

proc ::ndlist::nsize {ndlist {rank auto}} {
    set ndims [ndims $ndlist $rank]
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
# nfull $value $shape
#
# Arguments:
# value         Value to repeat
# shape         Shape of ND-list

proc ::ndlist::nfull {value shape} {
    set ndlist $value
    foreach n [lreverse $shape] {
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
# nrand $shape
#
# Arguments:
# shape         Shape of resulting ND-list

proc ::ndlist::nrand {shape} {
    # Base case
    if {[llength $shape] == 0} {
        return [::tcl::mathfunc::rand]
    }
    # Recursion
    set shape [lassign $shape n]
    lmap x [lrepeat $n {}] {
        nrand $shape
    }
}

# nreshape --
#
# Reshape a vector to different dimensions.
#
# Syntax:
# nreshape $vector $shape
#
# Arguments:
# vector        1D list to reshape into matrix or higher-dimensional tensor
# shape         New shape (and dimensions). One axis may be dynamic (-1)

proc ::ndlist::nreshape {vector shape} {
    set size [llength $vector]
    # Scalar case
    if {[llength $shape] == 0} {
        if {$size != 1} {
            return -code error "incompatible dimensions"
        }
        # Note: 1 element list can be converted to scalar.
        return [lindex $vector 0]
    }
    # Vector case (allow for dynamic "-1")
    if {[llength $shape] == 1} {
        if {$size != [lindex $shape 0] && [lindex $shape 0] != -1} {
            return -code error "incompatible dimensions"
        }
        return $vector
    }
    # Matrix and higher-dimensional case (allow for one dynamic axis)
    set dynamic [lsearch -all -exact $shape -1]
    if {[llength $dynamic] > 1} {
        return -code error "can only make one axis dynamic"
    }
    if {[llength $dynamic] == 1} {
        set subsize [product [lreplace $shape $dynamic $dynamic]]
        lset shape $dynamic [expr {$size/$subsize}]
    }
    # Check compatibility
    if {[product $shape] != $size} {
        return -code error "incompatible dimensions"
    }
    # Call recursive handler
    RecReshape $vector {*}$shape
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
# nflatten $ndlist <$rank>
#
# Arguments:
# ndlist        ND-list to reshape dimensions of
# rank          Number of dimensions (e.g. 2D). Default "auto"

proc ::ndlist::nflatten {ndlist {rank auto}} {
    # Interpret input and get dimensionality
    set ndims [ndims $ndlist $rank]
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
# repeats       Number of times to repeat ND-list along the axis.

proc ::ndlist::nrepeat {ndlist repeats} {
    # Scalar case
    if {[llength $repeats] == 0} {
        return $ndlist
    }
    # Validate integer inputs
    foreach repeat $repeats {
        if {![string is integer -strict $repeat]} {
            return -code error "expected integer but got \"$repeat\""
        }
        if {$repeat <= 0} {
            return -code error "bad count \"$repeat\": must be integer > 0"
        }
    }
    # Trivial case (all are 1)
    if {[lsearch -exact -integer -not $repeats 1] == -1} {
        return $ndlist
    }
    # Call recursive handler
    RecRepeat $ndlist {*}$repeats
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
# shape         New shape. -1 to keep shape at that dimension.

proc ::ndlist::nexpand {ndlist shape} {    
    # Get dimensions
    set shape1 [GetShape [llength $shape] $ndlist]
    set shape2 [lmap n1 $shape1 n2 $shape {expr {$n2 == -1 ? $n1 : $n2}}]
    # Get number of repetitions at every level
    nrepeat $ndlist [lmap n1 $shape1 n2 $shape2 {
        if {$n2 % $n1} {
            return -code error "incompatible dimensions"
        } else {
            # Compute number of repetitions by integer division.
            expr {$n2 / $n1}
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
# pads          Amount to pad along each axis. 0 for none, negative to prepend

proc ::ndlist::npad {ndlist value pads} {
    # Check input
    foreach pad $pads {
        if {![string is integer -strict $pad]} {
            return -code error "expected integer, but got \"$pad\""
        }
    }
    # Null case
    if {[llength $ndlist] == 0} {
        return [nfull $value $pads]
    }
    # Get dimensions
    set dims [GetShape [llength $pads] $ndlist]
    # Call recursive handler
    RecPad $ndlist $value $dims {*}$pads
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
# n ...         Amount to pad. If negative, prepends.

proc ::ndlist::RecPad {ndlist value dims n args} {
    # Base case
    if {[llength $args] == 0} {
        if {$n == 0} {
            return $ndlist
        } elseif {$n > 0} {
            return [concat $ndlist [lrepeat $n $value]]
        } else {
            return [concat [lrepeat [expr {-$n}] $value] $ndlist]
        }
    }
    # Recursion case
    set dims [lrange $dims 1 end]; # trim dims
    # Skip case
    if {$n > 0} {
        set ndlist [concat $ndlist [nfull $value [concat $n $dims]]]
    } elseif {$n < 0} {
        set ndlist [concat [nfull $value [concat [expr {-$n}] $dims]] $ndlist]
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
# nextend $ndlist $value $shape
#
# Arguments:
# ndlist        ND-list to expand
# arg ...       New shape, greater than or equal to old.
#               -1 to maintain shape at axis.

proc ::ndlist::nextend {ndlist value shape} {
    # Get dimensions
    set dims [GetShape [llength $shape] $ndlist]
    # Pad the ndlist based on the difference between new and old.
    npad $ndlist $value [lmap dim $dims n $shape {
        expr {$n == -1 ? 0 : $n - $dim}
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
# nset $varName $i ... <$sublist | = $expr>
#
# Arguments:
# varName       Variable where an ND-list is stored
# i ...         Indices to set at
# sublist       Sublist to set with (must be expandable)
# expr          Expression to evaluate. Indexed range is accessible by @.

# Examples:
# > set a {1 2 3 4}
# > nset a 0:1 {foo bar}
# > puts $a
# foo bar 3 4

proc ::ndlist::nset {varName args} {
    # If no indices or expression are given, perform simple set
    if {[llength $args] < 1} {
        tailcall set $varName {*}$args
    }
    # Index/expression set
    upvar 1 $varName ndlist
    if {![info exists ndlist]} {
        set ndlist ""
    }
    set ndlist [uplevel 1 [list nreplace $ndlist {*}$args]]
}

# nreplace --
#
# Replace portion of ND-list - return new list, same rank.
# Calls nremove when setting to blank, unless if all indices are dot indexes.
#
# Syntax:
# nreplace $ndlist $index ... <$sublist | = $expr>
# 
# Arguments:
# ndlist        Valid ND-list
# index ...     Indices to replace at
# sublist       Sublist to replace with (must be expandable)
#               If blank and all other indices are ":", calls nremove.
# expr          Expression to evaluate. Indexed range is accessible by @.

proc ::ndlist::nreplace {ndlist args} {
    # Interpret input
    if {[lindex $args end-1] eq "="} {
        # User provided expression
        set indices [lrange $args 0 end-2]; # $i ...
        set expr [lindex $args end]
        set self [nget $ndlist {*}$indices]
        if {[llength $indices] == 0} {
            set rank auto
        } else {
            set rank [GetIndexNDims {*}$indices]
        }
        set sublist [uplevel 1 [list nexpr $expr $self $rank]]
    } else {
        # User provided value
        set indices [lrange $args 0 end-1]; # $i ...
        set sublist [lindex $args end]
    }
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
    set sublist [nexpand $sublist [GetIndexShape $dims {*}$iArgs]]
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
    set dim [lindex [nshape $ndlist [expr {$axis + 1}]] $axis]
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
# ninsert $ndlist $index $sublist <$axis> <$rank>
#
# Arguments:
# ndlist        ND-list to modify
# index         Index to insert at
# sublist       ND-list to insert
# axis          Axis to insert along. Default 0.
# rank          Number of dimensions (e.g. 2D). Default "auto"

proc ::ndlist::ninsert {ndlist index sublist {axis 0} {rank auto}} {
    # Get number of dimensions, axis, shape, and insertion index.
    set ndims [ndims $ndlist $rank]
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
# ncat $ndlist1 $ndlist2 <$axis> <$rank>
#
# Arguments:
# ndlist1 ndlist2   ND-lists to stack
# axis              Axis to stack along. Default 0.
# rank              Number of dimensions (e.g. 2D). Default "auto"

proc ::ndlist::ncat {ndlist1 ndlist2 {axis 0} {rank auto}} {
    ninsert $ndlist1 end $ndlist2 $axis $rank
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
# npermute $ndlist $order
#
# Arguments:
# ndlist        ND-list to manipulate
# order         New order of axes. e.g. 2 0 1, or 2 3 0 1

proc ::ndlist::npermute {ndlist order} {
    # Get dimensionality and check validity of axes list
    set ndims [llength $order]
    # Validate axes
    foreach axis $order {
        ValidateAxis $ndims $axis
    }
    # Null case (same axis list)
    if {$order eq [range $ndims]} {
        return $ndlist
    }
    # Make sure there are no duplicates
    if {[llength [lsort -integer -unique $order]] != $ndims} {
        return -code error "invalid axes list: duplicates"
    }
    # Get index lists for axis swap.
    set dims [GetShape $ndims $ndlist]
    set indicesList [cartprod {*}[lmap dim $dims {range $dim}]]
    # Initialize new ND-list
    set newList [nfull {} [lmap axis $order {lindex $dims $axis}]]
    # Fill new ND-list
    foreach indices $indicesList {
        set newIndices [lmap axis $order {lindex $indices $axis}]
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
# napply $command $ndlist <$suffix> <$rank>
#
# Arguments:
# command           Command prefix
# ndlist            ND-list to iterate over
# suffix            Additional arguments to append to command. Default blank.
# rank              Number of dimensions (e.g. 2D). Default "auto"

proc ::ndlist::napply {command ndlist {suffix ""} {rank auto}} {
    RecApply 1 [ndims $ndlist $rank] $command $ndlist {*}$suffix
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
# napply2 $command $ndlist $ndlist2 <$suffix> <$rank>
#
# Arguments:
# command           Command prefix
# ndlist1 ndlist2   ND-lists to iterate over
# suffix            Additional arguments to append to command. Default none.
# rank              Number of dimensions (e.g. 2D). Default "auto"

proc ::ndlist::napply2 {command ndlist1 ndlist2 {suffix ""} {rank auto}} {
    set ndims [ndims_multiple [list $ndlist1 $ndlist2] $rank]
    set shape [GetMaxShape $ndims $ndlist1 $ndlist2]
    set ndlist1 [nexpand $ndlist1 $shape]
    set ndlist2 [nexpand $ndlist2 $shape]
    RecApply2 1 $ndims $command $ndlist1 $ndlist2 {*}$suffix
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
# nreduce $command $ndlist <$axis> <$suffix> <$rank>
#
# Arguments:
# command           Function to apply along axis.
# ndlist            ND-list to reduce.
# axis              Axis to reduce along over. Default 0.
# arg ...           Additional arguments to append to command. Default none.
# rank              Number of dimensions (e.g. 2D). Default "auto"
# 
# Example:
# nreduce max $x; # Gets maximum values for each column.
# nreduce max $x 1; # Gets maximum values for each row.

proc ::ndlist::nreduce {command ndlist {axis 0} {suffix ""} {rank auto}} {
    # Interpret input
    set ndims [ndims $ndlist $rank]
    if {$ndims == 0} {
        return -code error "cannot reduce a scalar"
    }
    ValidateAxis $ndims $axis
    # Move axis to reduce to back of ND-list, and reduce.
    set ndlist [nmoveaxis $ndlist $axis [expr {$ndims - 1}]]
    napply $command $ndlist $suffix [expr {$ndims - 1}]
}

# ND-LIST LOOPING
################################################################################

# nmap --
# 
# General purpose mapping function for ND-lists
#
# Syntax:
# nmap <$rank> $varName $ndlist ... $body; # lmap style, returns value.
# 
# Arguments:
# rank          Number of dimensions. Default "auto"
# varName       Variable name to iterate with (lmap style)
# ndlist        ND-list to iterate over (lmap style)
# body          Body to evaluate at every iteration

proc ::ndlist::nmap {args} {
    variable map_index
    variable map_shape
    # Check arity
    if {[llength $args] < 3} {
        return -code error "wrong # args: should be\
                \"nmap ?rank? varName ndlist ?varName ndlist ...? body\""
    }
    # Get optional rank input
    if {[llength $args] % 2 == 0} {
        set args [lassign $args rank]
    } else {
        set rank "auto"
    }
    # Interpret input
    set varMap [lrange $args 0 end-1]
    set varNames [dict keys $varMap]
    set ndlists [dict values $varMap]
    set body [lindex $args end]
    set ndims [ndims_multiple $ndlists $rank]
    # Handle scalar case
    if {$ndims == 0} {
        uplevel 1 [list lassign $ndlists {*}$varNames]
        return [uplevel 1 $body]
    }
    # Expand all ndlists to have the same shape, and then flatten.
    set dims [GetMaxShape $ndims {*}$ndlists]
    set ndlists [lmap ndlist $ndlists {nexpand $ndlist $dims}]
    set ndlists [lmap ndlist $ndlists {nflatten $ndlist $ndims}]
    # Create varName-ndlist mapping with flattened ndlists.
    set varMap {}; # initialize
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
        nreshape $vector $dims
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


# RefSub --
#
# Search for pattern @ref(index)
# Returns body substituted with array references, and list of refs.
# Reference list has two parts: name and index.
# name:     Variable name that contains object. Blank for "self".
# index:    Index for narray. Blank for all.

proc ::ndlist::RefSub {body} {
    set exp {@((::+|\w+)+|\.)?(\(([^\(]*)\))?}
    set refMap ""
    foreach {match name ~ ~ index} [regexp -all -inline $exp $body] {
        dict set refMap [list $name $index] ""
    }
    set body [regsub -all $exp $body {$::ndlist::ref(\1.\4)}]
    set refNames [concat {*}[dict keys $refMap]]
    return [list $body $refNames]
}

# neval --
#
# Map over ND lists
# References must have matching dimensions or be scalar.
#
# Syntax:
# neval $body <$self> <$rank> 
#
# Arguments:
# body          Tcl script, with @ref notation for object references.
# self          ND-list to refer to with "@." Default blank for none.
# rank          Rank of mapping. Default "auto"

# Example:
# set x {{hello world} {foo bar}}
# neval {string toupper @x}; # {HELLO WORLD} {FOO BAR}
# neval {llength @.} $x 1; # 2 2

proc ::ndlist::neval {body {self ""} {rank auto}} {
    variable ref; # Reference array
    # Get references
    lassign [RefSub $body] body refNames 
    # If no references found, evaluate normally.
    if {[llength $refNames] == 0} {
        return [uplevel 1 $body]
    }
    # Get values and shapes from object references
    set ndlists "" 
    foreach {refName index} $refNames {
        # Get object for reference
        if {$refName eq "."} {
            # Self-reference
            if {$self eq ""} {
                return -code error "no self reference object provided"
            }
            set ndlist $self
        } else {
            # Variable reference
            upvar 1 $refName refVal
            if {![info exists refVal]} {
                return -code error "\"$refName\" does not exist"
            }
            if {[array exists refVal]} {
                return -code error "\"$refName\" is an array"
            }
            set ndlist $refVal
        }
        # Index if needed
        if {$index ne ""} {
            set ndlist [nget $ndlist {*}[split $index ,]]
        }
        # Get object rank and value for mapping.
        lappend ndlists $ndlist
    }
    # Save old reference mapping, and initialize.
    set oldRefs [array get ref]
    array unset ref
    # Assign scalars and build map list
    set varMap ""; # varName value ...
    foreach ndlist $ndlists {refName index} $refNames {
        if {[ndims $ndlist] == 0} {
            # Scalar. Set value directly.
            set ::ndlist::ref($refName.$index) $ndlist
        } else {
            # Not a scalar (rank > 0)
            lappend varMap ::ndlist::ref($refName.$index) $ndlist
        }
    }
    # Try to evaluate user-input
    try {
        if {[llength $varMap] == 0} {
            uplevel 1 $body
        } else {
            uplevel 1 [list ::ndlist::nmap $rank {*}$varMap $body]
        }
    } finally {
        # Reset refs (even if mapping failed)
        array unset ref
        array set ref $oldRefs
    }
}

# nexpr --
#
# Version of neval, but for math.
#
# Syntax:
# nexpr $expr <$self> <$rank>
#
# Arguments:
# expr          Math expression, with @ref notation for object references.
# self          ND-list to refer to with "@." Default blank for none.
# rank          Rank of mapping. Default "auto"

# Example:
# set x {1.0 2.0 3.0}
# set y 5.0
# nexpr {@x + @y}; # {6.0 7.0 8.0}

proc ::ndlist::nexpr {expr {self ""} {rank auto}} {
    tailcall neval [list expr $expr] $self $rank 
}

# IsNDList --
#
# Determine if an ND-list is valid for the specified number of dimensions
# Returns error if invalid syntax
#
# Syntax:
# IsNDList $ndims $ndlist
#
# Arguments:
# ndims     Number of dimensions
# ndlist    Candidate ndlist

proc ::ndlist::IsNDList {ndims ndlist} {
    IsShape $ndlist {*}[GetShape $ndims $ndlist]
}

# GetNDims --
#
# Automatically determine the rank of an ND-list
#
# Syntax:
# GetNDims $ndlist
#
# Arguments:
# ndlist        ND-list

proc ::ndlist::GetNDims {ndlist} {
    # Determine dims from depth of scalar along index 0
    set ndims 0
    set value $ndlist; # temporary value for diving into index 0
    while {[string is list $value] && $value ne [lindex $value 0]} {
        set value [lindex $value 0]
        incr ndims
    }
    # Back-pedal to the dimension that is well-formed (if needed)
    while {![IsNDList $ndims $ndlist]} {
        incr ndims -1
    }
    return $ndims
}

# GetMaxNDims --
#
# Returns the dimensions compatible with all input ndlists
#
# Syntax:
# GetMaxNDims $ndlist ...
#
# Arguments:
# ndlist ...    List of ndlists

proc ::ndlist::GetMaxNDims {args} {
    if {[llength $args] == 0} {
        return -code error "wrong # args: want \"GetMaxNDims ndlist ...\""
    }
    set ndims_list [lmap ndlist $args {GetNDims $ndlist}]
    foreach ndims [lsort -integer -decreasing $ndims_list] {
        set validRank 1
        foreach ndlist $args {
            if {![IsNDList $ndims $ndlist]} {
                set validRank 0
                break
            }
        }
        if {$validRank} {
            break
        }
    }
    return $ndims
}

# ValidateNDims --
#
# Validates ndims input
#
# Syntax:
# ValidateNDims $ndims
# 
# Arguments:
# ndims             Number of dimensions (Inf for arbitrary dimensions)
# axis              Axis integer (must be 0-(N-1))

proc ::ndlist::ValidateNDims {ndims} {
    if {![string is integer -strict $ndims]} {
        return -code error "expected integer, but got \"$ndims\""
    }
    if {$ndims < 0} {
        return -code error "ndims must be non-negative"
    }
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
    # Scalar case
    if {$ndims == 0} {
        return
    }
    # Vector case
    if {$ndims == 1} {
        return [llength $ndlist]
    }
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
    } elseif {[llength $args] == 0} {
        return 1
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

# GetIndexNDims $arg ... --
#
# Get rank of index input. 
# Does not validate the index input, just looks for slicing notation.
#
# Arguments:
# args          Index inputs

proc ::ndlist::GetIndexNDims {args} {
    llength [lsearch -all -not $args {*\*}]
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

# POLISH NOTATION ELEMENT-WISE MATH OPERATORS
################################################################################

# In Tcl, the "expr" command is notorious for making math-heavy code difficult
# to read. TIP #174 added math operators to the namespace ::tcl::mathop, which,
# when imported, allows for polish-notation math in Tcl (e.g. set y [+ $x 1])
# This expands upon that concept by adding n-dimensional math operators, using
# the suffix "." on operators (Note: a smaller subset of math ops is used)

# $op. --
#
# Simple math operations on ndlists.
#
# Syntax:
# $op. $ndlist ...
#
# Arguments:
# op            Valid mathop (see $::ndlist::mathops)
# ndlist ...    Values to perform mathop with 
#
# Matrix examples:
# /. $matrix; # Performs reciprocal
# -. $matrix; # Negates values
# !. $matrix; # Boolean negation
# +. 5 1 $matrix; # Adds 5 and 1 to each matrix element
# **. $matrix 2; # Squares entire matrix

proc ::ndlist::MathOp {op arg args} {
    # Handle common 1 and 2 arg operations for performance
    if {[llength $args] == 0} {
        return [napply ::tcl::mathop::$op $arg]
    } elseif {[llength $args] == 1} {
        set ndlist1 $arg
        set ndlist2 [lindex $args 0]
        if {[ndims $ndlist1] == 0} {
            return [napply [list ::tcl::mathop::$op $ndlist1] $ndlist2]
        } elseif {[ndims $ndlist2] == 0} {
            return [napply ::tcl::mathop::$op $ndlist1 [list $ndlist2]]
        } else {
            return [napply2 ::tcl::mathop::$op $ndlist1 $ndlist2]
        }
    }
    # General N-dimensional case
    set ndlists [linsert $args 0 $arg]
    set nargs [llength $ndlists]
    set ndims [ndims_multiple $ndlists]
    set shape [GetMaxShape $ndims {*}$ndlists]
    set ndlists [lmap ndlist $ndlists {nexpand $ndlist $shape}]
    set ndlists [lmap ndlist $ndlists {nflatten $ndlist $ndims}]
    nreshape [lmap opargs [transpose $ndlists] {
        ::tcl::mathop::$op {*}$opargs
    }] $shape
}
