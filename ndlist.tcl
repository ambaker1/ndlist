# ndlist.tcl
################################################################################
# N-Dimensional List Implementation

# Copyright (C) 2023 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Required packages
package require vutil 1.1

# Define namespace
namespace eval ::ndlist {
    # Internal variables
    variable nmap_i; # nmap index array
    array unset nmap_i
    variable nmap_break; # nmap break passer
    
    # N-dimensional list access and mapping
    namespace export ndlist nrepeat; # Create ndlists
    namespace export nshape nsize; # Get dimensions and size
    namespace export nflatten nreshape; # Reshape an ndlist
    namespace export ntranspose ninsert; # Transpose and combine ndlists
    namespace export nget nset nreplace; # ndlist access/modification
    namespace export tensor matrix vector scalar; # ndobjects
    namespace export nop; # Math mapping over ndlists
    namespace export neval nexpr; # ND version of vutil leval and lexpr
    namespace export nmap i j k; # Functional mapping over ndlists
    namespace export nfill; # Fill blanks with a value.
    namespace export range; # Index range
}

# BASIC NDLIST CREATION AND METADATA
################################################################################

# ndlist --
#
# Create an ndlist of specific dimensionality out of the given values.
#
# Syntax:
# ndlist $nd $value
#
# Arguments:
# nd            Number of dimensions (e.g. 1D, 2D, etc.)
# value         Value to create an ndlist from.

proc ::ndlist::ndlist {nd value args} {
    # Interpret input
    set ndims [GetNDims $nd]
    set ndlist $value
    # Check if it is a valid ndlist, and try to shape it into one.
    if {![IsShape $ndlist {*}[GetShape $ndims $ndlist]]} {
        set ndlist [Expand $ndlist {*}[MaxShape $ndims $ndlist]]
    }
    return $ndlist
}

# nrepeat --
#
# Create an ndlist filled with one value
#
# Syntax:
# nrepeat $shape $value
#
# Arguments:
# shape         List of dimensions
# value         Value to repeat

proc ::ndlist::nrepeat {shape value} {
    set ndlist $value
    foreach n [lreverse $shape] {
        set ndlist [lrepeat $n $ndlist]
    }
    return $ndlist
}

# GetNDims --
#
# Get dimensionality from nd string (uses regex pattern).
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

# MaxShape --
#
# Get shape of ndlist given its ndims
# Recursively determines the maximum dimensions.
#
# Syntax:
# MaxShape $ndims $ndlist

# Arguments:
# ndims         Dimensionality
# ndlist        Ragged ndlist

proc ::ndlist::MaxShape {ndims ndlist} {
    # Scalar base case
    if {$ndims == 0} {
        return
    }
    # Vector base case
    if {$ndims == 1} {
        # Vector
        return [llength $ndlist]
    }
    # Matrix base case
    if {$ndims == 2} {
        # Matrix
        set maxdim 0; # maximum number of columns
        foreach ndrow $ndlist {
            if {[llength $ndrow] > $maxdim} {
                set maxdim [llength $ndrow]
            }
        }
        return [list [llength $ndlist] $maxdim]
    }
    # Recursion for higher dimensions
    incr ndims -1
    set maxdims [lrepeat $ndims 0]
    # Get maximum dimensions from sublists
    foreach ndrow $ndlist {
        set maxdims [lmap maxdim $maxdims dim [MaxShape $ndims $ndrow] {
            expr {$dim > $maxdim ? $dim : $maxdim}
        }]
    }
    return [list [llength $ndlist] {*}$maxdims]
}

# Expand --
#
# Expand an ndlist to specified shape. Not the same as "nreshape".
# If the given dimensions are smaller, it will throw an error.
# Fills with blanks.
#
# Syntax:
# Expand $ndlist $n1 $n2 ...
#
# Arguments:
# ndlist        ND list to expand
# n1 n2 ...     New dimensions (must be greater)

proc ::ndlist::Expand {ndlist n args} {
    # Expand list as needed
    if {[llength $ndlist] < $n} {
        lappend ndlist {*}[lrepeat [expr {$n-[llength $ndlist]}] ""]
    }
    # Throw error if dimension is greater than n
    if {[llength $ndlist] != $n} {
        return -code error "inconsistent dimensions"
    }
    # Base case
    if {[llength $args] == 0} {
        return $ndlist
    }
    # Recursion for higher-dimension lists
    lmap sublist $ndlist {
        Expand $sublist {*}$args
    }
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
#
# Syntax:
# nsize $nd $ndlist
#
# Arguments:
# nd:               Number of dimensions (e.g. 1D, 2D, etc.)
# ndlist:           ND list to get dimensions of

proc ::ndlist::nsize {nd ndlist} {
    GetSize [GetNDims $nd] $ndlist
}

# GetSize --
#
# Private procedure to get total size of an ndlist, using GetShape
#
# Syntax:
# GetSize $ndims $ndlist
#
# Arguments:
# ndims         Number of dimensions
# ndlist        ND list to get size of

proc ::ndlist::GetSize {ndims ndlist} {
    # Get shape using nshape
    set shape [GetShape $ndims $ndlist]
    # Compute size (product of shape)
    set size 1
    foreach dim $shape {
        set size [expr {$size * $dim}]
    }
    return $size
}

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

# nreshape --
#
# Reshape an ndlist to specified dimensions.
#
# Syntax:
# nreshape $nd $ndlist $shape
#
# Arguments:
# nd            Number of dimensions (e.g. 1D, 2D, etc.)
# ndlist        ND list to reshape dimensions of
# shape         New shape (and dimensions)

proc ::ndlist::nreshape {nd ndlist shape} {
    # Get flattened ndlist
    set vector [nflatten $nd $ndlist]
    # Switch for target dimensionality
    set ndims [llength $shape]
    if {$ndims == 0} {
        # Scalar (same as flatten)
        set newlist $vector
    } elseif {$ndims == 1} {
        # Vector (verify length, and then return vector)
        if {[lindex $args 0] != [llength $vector]} {
            return -code error "incompatible dimensions"
        }
        set newlist $vector
    } else {
        # Reshape into matrix or higher-dimension tensor
        set newlist [RecReshape $vector {*}$shape] 
    }
    return $newlist
}

# RecReshape --
#
# Recursive handler for reshaping an ndlist
#
# Syntax:
# RecReshape $vector $n $m <$arg ...>
#
# Arguments:
# vector        Vector to reshape into a matrix
# n m           Matrix dimensions
# arg ...       Dimensions of each matrix element. Default scalar.

proc ::ndlist::RecReshape {vector n m args} {
    # Get size of each "row"
    set M $m
    foreach arg $args {
        set M [expr {$M * $arg}]
    }
    # Get total size and compare with vector length
    set size [expr {$n*$M}]
    if {[llength $vector] != $size} {
        return -code error "incompatible dimensions"
    }
    # Create matrix
    set i -$M
    set j -1
    set matrix [lmap x [lrepeat $n {}] {
        lrange $vector [incr i $M] [incr j $M]
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

# ntranspose --
#
# Swaps axes (by default just transposes)
# For 0D and 1D, just returns the value.
#
# Syntax:
# ntranspose $nd $ndlist <$axis1 $axis2>
#
# Arguments:
# nd:           Number of dimensions
# ndlist:       ND list to manipulate
# axis1         Axis to swap with axis 2 (default 0)
# axis2         Axis to swap with axis 1 (default 1)

proc ::ndlist::ntranspose {nd ndlist args} {
    # Check arity
    if {[llength $args] == 0} {
        # ntranspose $nd $ndlist
        set axis1 0
        set axis2 1
    } elseif {[llength $args] == 2} {
        # ntranspose $nd $ndlist $axis1 $axis2
        lassign [lsort -integer $args] axis1 axis2
    } else {
        return -code error "wrong # args: should be\
                \"ntranspose nd ndlist ?axis1 axis2?\""
    }
    # Get dimensions
    set ndims [GetNDims $nd]
    # Switch for dimensionality (and check axes)
    if {($ndims == 0 || $ndims == 1) && $axis1 == 0 && $axis2 <= 1}  {
        # Trivial case for 0D and 1D ndlists
        return $ndlist
    } elseif {$axis1 >= 0 && $axis2 < $ndims} {
        # Check trivial case of equal axes
        if {$axis1 == $axis2} {
            return $ndlist
        }
        # Transpose
        return [RecTranspose $ndlist $axis1 $axis2]
    } else {
        return -code error "axes out of range"
    }
}

# RecTranspose --
# 
# Recursive handler for ntranspose (after axes are checked)
#
# Arguments:
# ndlist:           ND list to manipulate
# axis1:            Axis to swap with axis 2
# axis2:            Axis to swap with axis 1 (must be greater than axis2)

proc ::ndlist::RecTranspose {ndlist axis1 axis2} {
    # Check if at axis to swap
    if {$axis1 == 0} {
        # First transpose
        set ndlist [Transpose $ndlist]; # (ijk -> jik)
        # Base case
        if {$axis2 == 1} {
            return $ndlist
        }
        # Recursion (pass axis1 to axis2 position, and axis2 to axis1+1)
        incr axis2 -1
        set ndlist [lmap ndrow $ndlist {
            set ndrow [RecTranspose $ndrow $axis1 $axis2]; # (jik -> jki)
        }]
        # Final transpose
        return [Transpose $ndlist]; # (jki -> kji)
    }
    # Simple recursion to get to first swap axis
    incr axis1 -1
    incr axis2 -1
    lmap ndrow $ndlist {
        RecTranspose $ndrow $axis1 $axis2
    }
}

# Transpose --
# 
# Transposes a matrix
# Adapted from math::linearalgebra::transpose and lsearch example on Tcl wiki
# written by MJ (https://wiki.tcl-lang.org/page/Transposing+a+matrix)
# 
# Arguments:
# matrix:           Matrix to transpose

proc ::ndlist::Transpose {matrix} {
    set n [llength $matrix]
    # Null case
    if {$n == 0} {
        return
    }
    set m [llength [lindex $matrix 0]]
    if {$n == 1 && $m == 1} {
        return $matrix
    } elseif {$n > $m} {
        set i -1
        lmap x [lindex $matrix 0] {
            lsearch -all -inline -subindices -index [incr i] $matrix *
        }
    } else {
        set i -1
        lmap x [lindex $matrix 0] {
            incr i
            lmap row $matrix {lindex $row $i}
        }
    }
}

# ninsert --
#
# Insert ndlists in other ndlists, verifying that dimensions are compatible.
#
# Syntax:
# ninsert $nd $ndlist $axis $index $sublist <$axis>
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
# 
# Returns a list - iDim then iArgs, where iArgs is a key-value list
# iDims iLims iType iList iType iList ...

proc ::ndlist::ParseIndices {inputs dims} {
    set iDims ""; # dimensions of indexed region
    set iLims ""; # Maximum indices for indexed region
    set iArgs ""; # paired list of index type and index list (meaning varies)
    foreach input $inputs dim $dims {
        lassign [ParseIndex $input $dim] iDim iLim iType iList 
        lappend iDims $iDim
        lappend iLims $iLim
        lappend iArgs $iType $iList
    }
    return [list $iDims $iLims {*}$iArgs]
}

# ParseIndex --
# 
# Used for parsing index input (i.e. list of indices, range 0:10, etc
# Returns list, with first element being the index input type, and the remaining
# arguments being the index integers.

# Returns:
# iDim:     Dimension of indexed range (e.g. number of indices)
# iLim:     Largest index in indexed range
# iType:    Type of index
#   A:      All indices
#   R:      Range of indices
#   L:      List of indices 
#   S:      Single index (flattens array, iDim = 0)
# iList:    Depends on iType. For range, i1 and i2

proc ::ndlist::ParseIndex {input n} {
    # Check length of input
    if {[llength $input] == 1} {
        # Single index, colon, or range notation
        set index [lindex $input 0]
        # Check for colon (special syntax)
        if {[string match *:* $index]} {
            # Colon or range notation
            if {[string length $index] == 1} {
                # Colon notation (all indices)
                set iType A
                set iList ""
                set iDim $n
                set iLim [expr {$n - 1}]
            } else {
                # Range notation (slice)
                set parts [split $index :]
                if {[llength $parts] == 2} {
                    # Simple range
                    lassign $parts i1 i2
                    set i1 [Index2Integer $i1 $n]
                    set i2 [Index2Integer $i2 $n]
                    set iType R
                    set iList [list $i1 $i2]
                    if {$i2 >= $i1} {
                        # Forward range
                        set iDim [expr {$i2 - $i1 + 1}]
                        set iLim $i2
                    } else {
                        # Reverse range
                        set iDim [expr {$i1 - $i2 + 1}]
                        set iLim $i1
                    }
                } elseif {[llength $parts] == 3} {
                    # Skipped range
                    lassign $parts i1 step i2
                    set i1 [Index2Integer $i1 $n]
                    set i2 [Index2Integer $i2 $n]
                    if {![string is integer -strict $step]} {
                        return -code error "invalid range index notation"
                    }
                    # Deal with range case
                    if {$i2 >= $i1} {
                        if {$step == 1} {
                            # Forward range
                            set iType R
                            set iList [list $i1 $i2]
                            set iDim [expr {$i2 - $i1 + 1}]
                            set iLim $i2; # end of range
                        } else {
                            # Forward stepped range (list)
                            set iType L
                            set iList [Range $i1 $i2 $step]
                            set iDim [llength $iList]
                            set iLim [lindex $iList end]; # end of list
                        }
                    } else {
                        if {$step == -1} {
                            # Reverse range
                            set iType R
                            set iList [list $i1 $i2]
                            set iDim [expr {$i1 - $i2 + 1}]
                            set iLim $i1; # start of range
                        } else {
                            # Reverse stepped range (list)
                            set iType L
                            set iList [Range $i1 $i2 $step]
                            set iDim [llength $iList]
                            set iLim [lindex $iList 0]; # start of list
                        }
                    }
                } else {
                    return -code error "invalid range index notation"
                }
            }; # end if just colon or if range notation
        } elseif {[string index $index end] eq "*"} {
            # Single index notation (flatten along this dimension)
            set i [Index2Integer [string range $index 0 end-1] $n]
            set iType S
            set iList $i
            set iDim 0; # flattens
            set iLim $i
        } else {
            # Single index list (do not flatten)
            set i [Index2Integer $index $n]
            set iType L
            set iList $i
            set iDim 1
            set iLim $i
        }; # end parse single index
    } else {
        # List of indices (user entered)
        set iType L
        set iList [lmap index $input {Index2Integer $index $n}]
        set iDim [llength $iList]
        set iLim 0
        foreach i $iList {
            if {$i > $iLim} {
                set iLim $i
            }
        }
    }
    return [list $iDim $iLim $iType $iList]
}

# Index2Integer --
#
# Private function, converts end+-integer index format into integer
# Negative indices get converted, such that -1 is end, -2 is end-1, etc.
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
    return $i
}

# Range --
#
# Private handler to generate an integer range
#
# Syntax:
# Range $start $stop $step
# 
# Arguments:
# start:    Start of resultant range.
# stop:     End limit of resultant range.
# step:     Step size.

proc ::ndlist::Range {start stop step} {
    # Avoid divide by zero
    if {$step == 0} {
        return ""
    }
    # Get range length
    set n [expr {($stop - $start)/$step + 1}]
    # Basic cases
    if {$n <= 0} {
        return ""
    }
    if {$n == 1} {
        return $start
    }
    # General case (generate list)
    set i [expr {$start - $step}]
    lmap x [lrepeat $n {}] {incr i $step}
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
        # Expand ndlist if needed based on index limits.
        foreach dim $dims iLim $iLims {
            if {$iLim >= $dim} {
                # Get expanded dimensions and expand ndlist
                set dims [lmap dim $dims iLim $iLims {
                    expr {$iLim >= $dim ? $iLim + 1 : $dim}
                }]
                set ndlist [Expand $ndlist {*}$dims]
                break; # an expansion was done, no need to continue
            }
        }
        # Process input dimensions
        set subdims ""
        foreach iDim $iDims {
            if {$iDim > 0} {
                lappend subdims $iDim
            }
        }
        # Tile sublist if needed based on index dimensions.
        set sublist [NTile $sublist {*}$subdims]
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

# NTile --
#
# Tile an ndlist to compatible dimensions.
# A dimension of an ndlist can be tiled if it has dimension 1
#
# Syntax:
# NTile $ndlist $n1 $n2 ...
#
# Arguments:
# ndlist        ND list to tile
# n1 n2 ...     New dimensions

proc ::ndlist::NTile {ndlist args} {    
    set dims1 $args
    set dims0 [GetShape [llength $dims1] $ndlist]
    foreach dim0 $dims0 dim1 $dims1 {
        if {$dim0 != $dim1} {
            return [RecTile $ndlist $dims0 $dims1]
        }
    }
    return $ndlist
}

# RecTile --
#
# Recursive handler for NTile. 
# Tiles a compatible ndlist (dimensions must match or be unity) 
# For example, 1x1, 1x4, 4x1, and 5x4 are all compatible with 5x4.
#
# Syntax:
# RecTile $ndlist $dims0 $dims1
#
# Arguments:
# ndlist        ND list to tile
# dims0         Old dimensions list
# dims1         New dimensions list

proc ::ndlist::RecTile {ndlist dims0 dims1} {
    # Switch for base cases
    if {[llength $dims0] == 0} {
        return $ndlist
    } elseif {[llength $dims0] == 1} {
        return [Tile $ndlist $dims0 $dims1]
    }
    # Strip dimension from args
    set dims0 [lassign $dims0 n0]
    set dims1 [lassign $dims1 n1]
    if {$n0 != $n1} {
        lrepeat $n1 [RecTile [lindex $ndlist 0] $dims0 $dims1]
    } else {
        lmap ndrow $ndlist {
            RecTile $ndrow $dims0 $dims1
        }
    }
}

# Tile --
#
# Base case for RecTile. Throws error if dimensions are incompatible
#
# Syntax:
# Tile $list $n0 $n1
#
# Arguments:
# list          List to tile
# n0            Length of list
# n1            New length of list

proc ::ndlist::Tile {list n0 n1} {
    if {$n0 == $n1} {
        return $list
    } elseif {$n0 == 1} {
        return [lrepeat $n1 [lindex $list 0]]
    } else {
        return -code error "incompatible dimensions"
    }
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


# NDLIST OBJECT VARIABLE TYPE
################################################################################

# ::ndlist::ndobj --
#
# Object variable class for ndlists. Not exported.
#
# Syntax:
# ::vutil::new ndlist $refName $nd <$value>
#
# Arguments:
# refName       Variable name for garbage collection
# nd            Number of dimensions (e.g. 1D, 2D, etc.)
# value         Value of ndlist

::vutil::type create ndlist ::ndlist::ndobj {
    # Configure constructor and cloned method to configure namespace path
    constructor {refName nd args} {
        namespace path [concat [namespace path] ::ndlist]
        set (ndims) [GetNDims $nd]; # Verifies nd syntax
        next $refName {*}$args
    }
    method <cloned> {args} {
        namespace path [concat [namespace path] ::ndlist]
        next {*}$args
    }
    # SetValue creates an ndlist (this ensures that input is valid)
    method SetValue {value} {
        next [ndlist $(ndims) $value]
    }
    method info {args} {
        set (shape) [my shape]
        next {*}$args
    }
    # Modify 
    method GetOpValue {op args} {
        nop $(ndims) [my GetValue] $op {*}$args
    }
    method GetEvalValue {body {level 1}} {
        next [list ::ndlist::neval $body] $level
    }
    # Modify left assignment to ensure same dimensionality
    method SetObject {object} {
        ::vutil::type assert ndlist $object
        if {[$object ndims] != $(ndims)} {
            return -code error "incompatible dimensionality"
        }
        next $object
    }
    
    # $ndobj ndims <$nd>
    #
    # Query or set the dimensionality.
    # If increasing the dimensionality, it will call "ndlist" to expand.
    #
    # Arguments:
    # nd        Number of dimensions (e.g. 1D, 2D, etc.)  
    
    method ndims {{nd ""}} {
        if {$nd ne ""} {
            set ndims [GetNDims $nd]
            # Expand ndlist as needed
            if {$ndims > $(ndims)} {
                set (value) [ndlist $ndims [my GetValue]]
            }
            set (ndims) $ndims
        }
        return $(ndims)
    }
    
    # $ndobj shape <$axis>
    #
    # Query the shape of the ndobj, for all dimensions or a specified dim.
    #
    # Arguments:
    # axis      Axis to get shape along
    
    method shape {{axis ""}} {
        nshape $(ndims) [my GetValue] $axis
    }
    
    # $ndobj size
    #
    # Get total size of array (number of elements)
    
    method size {} {
        nsize $(ndims) [my GetValue] 
    }
    
    # $ndobj flatten
    #
    # Flatten and return self
    # Note that flattening a scalar will turn it into a 1-element vector
    
    method flatten {} {
        set (value) [nflatten $(ndims) [my GetValue]]
        set (ndims) 1
        return [self]
    }

    # $ndobj reshape $shape
    #
    # Reshape and return self
    #
    # Arguments:
    # $shape        New shape (and dimensionality)
    
    method reshape {shape} {
        # Call the nreshape proc, and assign new dimensionality
        set (value) [nreshape $(ndims) [my GetValue] $shape]
        set (ndims) [llength $shape]
        return [self]
    }
    
    # $ndobj transpose <$axis1 $axis2>
    #
    # Transpose and return self.
    #
    # Arguments:
    # axis1         Axis to swap with axis 2 (default 0)
    # axis2         Axis to swap with axis 1 (default 1)
    
    method transpose {args} {
        set (value) [ntranspose $(ndims) [my GetValue] {*}$args]
        return [self]
    }
    
    # $ndobj insert $index $sublist <$axis>
    #
    # Insert an ndlist object into another ndlist object.
    #
    # Arguments:
    # index         Index to insert at
    # sublist       ndlist to insert
    # axis          Axis to insert along. Default 0.
    
    method insert {index sublist {axis 0}} {
        set sublist [ndlist $(ndims) $sublist]
        set (value) [ninsert $(ndims) [my GetValue] $index $sublist $axis]
        return [self]
    }
    
    # $ndobj fill $filler
    #
    # Fill blanks with a value.
    #
    # Arguments:
    # filler            Filler to replace blanks.
    
    method fill {filler} {
        set (value) [nfill $(ndims) [my GetValue] $filler]
    }
    
    # @ --
    #
    # Method to get or set a value (or ranges of values) in an ndlist
    #
    # Syntax:
    # $ndobj @ $i $j $k; # nget, returns value
    # $ndobj @ $i $j $k --> $refName; # nget, creates new object
    # $ndobj @ $i $j $k <- $object; # nset, by object (must match dimension)
    # $ndobj @ $i $j $k = $sublist; # nset, by value
    # $ndobj @ $i $j $k .= $oper; # Math operator modification
    # $ndobj @ $i $j $k := $expr; # Math expression modification
    # $ndobj @ $i $j $k ::= $body; # Tcl script evaluation modification
    
    method @ {args} {
        # Interpret arguments
        set indices [lrange $args 0 $(ndims)-1]
        set args [lrange $args $(ndims) end]
        # Check arity
        if {[llength $args] == 0} {
            # Value query (nget). Return value
            # $ndobj @ $i ...
            return [nget [my GetValue] {*}$indices]
        } elseif {[llength $args] != 2} {
            return -code error "wrong # args: should be\
                    \"[self] @ i ... option value\""
        }
        # Get number of dimensions of queried range
        set ndims [GetNewNDims $indices]; # ndims of range
        # Switch for operator
        lassign $args op arg
        if {$op eq "-->"} {
            # Create new object
            # $ndobj @ $i ... --> $refName
            set refName $arg
            set ndlist [nget [my GetValue] {*}$indices]
            # Return with new object
            tailcall ::vutil::new ndlist $refName $ndims $ndlist
        } elseif {$op eq "<-"} {
            # Assign value from object (same dimensionality)
            # $ndobj @ $i ... <- $object
            set object $arg
            ::vutil::type assert ndlist $object
            # Verify same ND
            if {[$object ndims] != $ndims} {
                return -code error "incompatible dimensionality"
            }
            nset (value) {*}$indices [$object]
        } elseif {$op eq "="} {
            # Direct replacement
            # $ndobj @ $i ... = $value
            nset (value) {*}$indices [ndlist $ndims $arg]
        } elseif {$op in {.= := ::=}} {
            # Modification by reference
            # $ndobj @ $i ... <.= $oper | := $expr | ::= $body>
            # Create temporary list object for assignment
            ::vutil::new ndlist temp $ndims [nget [my GetValue] {*}$indices]
            uplevel 1 [list $temp $op $arg]
            nset (value) {*}$indices [$temp]
        } else {
            return -code error "unknown option \"$op\""
        }
        # Return self.
        return [self]
    }
    export @
}; # end "ndlist" type declaration

# Create mathop methods

# NDLIST OBJECT CREATION ALIASES COMMANDS
################################################################################

# tensor --
#
# Shorthand to create a new ndobj of arbitrary dimension
#
# Syntax:
# tensor $refName $nd <$value>
#
# Arguments:
# refName       Variable name for garbage collection
# nd            Number of dimensions (e.g. 1D, 2D, etc.)
# value         Value to initialize with

proc ::ndlist::tensor {refName nd args} {
    tailcall ndobj new $refName $nd {*}$args
}

# matrix --
# vector --
# scalar --
#
# Shorthand to create a new 2D/1D/0D ndobj.
#
# Syntax:
# matrix $refName <$value>
# vector $refName <$value>
# scalar $refName <$value>
#
# Arguments:
# refName       Variable name for garbage collection
# value         Value to set matrix to

proc ::ndlist::matrix {refName args} {
    tailcall ndobj new $refName 2D {*}$args
}
proc ::ndlist::vector {refName args} {
    tailcall ndobj new $refName 1D {*}$args
}
proc ::ndlist::scalar {refName args} {
    tailcall ndobj new $refName 0D {*}$args
}

# NDLIST FUNCTIONAL MAPPING COMMANDS
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
# ndlist        ndlist to iterate over
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
    RecOp [GetNDims $nd] $ndlist $op {*}$args
}

# RecOp --
#
# Recursive handler for nop
#
# Arguments:
# ndims         Number of dimensions
# ndlist        ndlist to iterate over
# op            Valid mathop (see tcl::mathop documentation)
# arg ...       Values to perform mathop with 

proc ::ndlist::RecOp {ndims ndlist op args} {
    # Base case
    if {$ndims == 0} {
        return [::tcl::mathop::$op $ndlist {*}$args]
    }
    # Recursion
    incr ndims -1
    lmap ndrow $ndlist {
        RecOp $ndims $ndrow $op {*}$args
    }
}

# neval --
# 
# Iterated evaluation over ndlists. 
#
# Syntax:
# neval $body <$nd $ndlist> <"-->" refName>
# 
# Arguments:
# body:         Body to evaluate
# nd:           Number of dimensions
# ndlist:       ND list to use as "$."
# refName:      Reference variable to tie new ndobj to.

proc ::ndlist::neval {body args} {
    # Interpret input
    set args [lassign [::vutil::GetRefName {*}$args] refName]
    if {[llength $args] == 2} {
        # neval $body $nd $ndlist <"-->" $refName>
        # Create temporary ndlist object to refer to.
        lassign $args nd ndlist
        ::vutil::new ndlist temp $nd $ndlist
        uplevel 1 [list $temp ::= $body]; # Calls neval
        tailcall ::vutil::new ndlist $refName $nd [$temp]
    } elseif {[llength $args] > 0} {
        return -code error "wrong # args: should be\
                \"neval body ?nd ndlist? ?--> refName?\""
    }
    # Normal case (no input list)
    # Perform @ substitution and get names of substituted variables
    lassign [::vutil::refsub $body] body subNames
    # Get variable mapping
    set varMap ""
    set ndims -1
    foreach subName $subNames {
        # Validate user input
        upvar 1 $subName subVar
        if {![info exists subVar]} {
            return -code error "\"$subName\" does not exist"
        }
        if {[array exists subVar]} {
            return -code error "\"$subName\" is an array"
        }
        ::vutil::type assert ndlist $subVar
        # Validate ndlist dimensionalities
        if {$ndims == -1} {
            set ndims [$subVar ndims]
        } elseif {[$subVar ndims] != $ndims} {
            return -code error "incompatible dimensionality"
        }
        lappend varMap ::vutil::at($subName) [$subVar]
    }
    # Handle case with no ndlist references (normal eval)
    if {$ndims == -1} {
        tailcall ::vutil::new ndlist $refName 0 [uplevel 1 $body]
    }
    # Handle case with list references (call lmap)
    try {
        set oldRefs [array get ::vutil::at]
        array unset ::vutil::at
        set ndlist [uplevel 1 [list ::ndlist::nmap $ndims {*}$varMap $body]]
    } finally {
        array unset ::vutil::at
        array set ::vutil::at $oldRefs
    }
    # Create the new ndlist
    tailcall ::vutil::new ndlist $refName $ndims $ndlist  
}

# nexpr --
# 
# Create a new ndlist based on element-wise operations (calls nmap)
#
# Syntax:
# nexpr $expr <$nd $ndlist> <"-->" refName>
# 
# Arguments:
# expr:        Expression to evaluate (using @ to reference ndobjs)
# nd:           Number of dimensions
# ndlist:       ND list to use as "$."
# refName:      Reference variable to tie new ndobj to.

proc ::ndlist::nexpr {expr args} {
    # Check arity
    if {[llength $args] == 1 || [llength $args] > 2} {
        return -code error "wrong # args: should be\
                \"nexpr expr ?nd ndlist? ?--> refName?\""
    }
    # Call neval
    tailcall neval [list expr $expr] {*}$args
}

# nmap --
# 
# Loop over ndlists. Returns new ndlist like lmap.
# Calling "continue" will skip elements at the lowest level.
# Calling "break" will exit the entire loop.
# Note that the resulting ndlist may not be a proper ndlist if "continue" or 
# "break" are called.
#
# Syntax:
# nmap $nd $varName $ndlist ... $body; # lmap style, only returns value.
# 
# Arguments:
# nd            Number of dimensions (e.g. 1D, 2D, etc.)
# varName       Variable name to iterate with (foreach-loop style)
# ndlist        ndlist to iterate over (foreach-loop style)

proc ::ndlist::nmap {nd args} {
    variable nmap_i; # array
    variable nmap_break 0; # variable to pass break with
    # Interpret args
    if {[llength $args] == 1 || [llength $args] % 2 == 0} {
        return -code error "wrong # args: should be\
                \"nmap nd varName ndlist ?varName ndlist ...? body\""
    }
    set ndims [GetNDims $nd]
    set varMap [lrange $args 0 end-1]
    set body [lindex $args end]
    # Save old indices and initialize new
    set old_i [array get nmap_i]
    array unset nmap_i
    try { # Try to perform map, and regardless, restore old indices
        if {[llength $varMap] == 2} {
            # Loop over a single ndlist (simpler case)
            lassign $varMap varName ndlist
            # Create link variable for SingleMap
            upvar 1 $varName x
            # Scalar case
            if {$ndims == 0} {
                set x $ndlist
                set result [uplevel 1 $body]
            } else {
                set result [SingleMap $ndims $ndlist $body]
            }
        } else {
            # Loop over multiple ndlists
            # Unzip varMap to varNames and ndlists
            set varNames ""
            set ndlists ""
            foreach {varName ndlist} $varMap {
                lappend varNames $varName
                lappend ndlists $ndlist
            }
            # Tile ndlists to combined dimensions
            set cdims [GetCombinedSize $ndims {*}$ndlists]
            set ndlists [lmap ndlist $ndlists {NTile $ndlist {*}$cdims}]
            # Create linkVars for MultiMap
            set i 0
            set linkVars ""
            foreach varName $varNames ndlist $ndlists {
                upvar 1 $varName x$i
                lappend linkVars x$i
                incr i
            }
            # Scalar case
            if {$ndims == 0} {
                lassign $ndlists {*}$linkVars
                set result [uplevel 1 $body]
            } else {
                set result [MultiMap $ndims $linkVars $ndlists $body]
            }
        }
    } finally {
        # Restore previous indices
        array unset nmap_i
        array set nmap_i $old_i
    }
    # Return the new ndlist
    return $result
}

# GetCombinedSize --
# 
# Get combined size for combining ndlists (in nmap)
#
# Syntax:
# GetCombinedSize $ndims $ndlist ...
#
# Arguments:
# ndims             Number of dimensions in each ndlist
# ndlist ...        ndlists to get combined dimensions of (for tiling)

proc ::ndlist::GetCombinedSize {ndims args} {
    set cdims [lrepeat $ndims 1]; # Combined dimensions
    foreach ndlist $args {
        set dims [GetShape $ndims $ndlist]
        set cdims [lmap cdim $cdims dim $dims {
            if {$cdim == 1} {
                set cdim $dim
            } elseif {$dim != 1 && $dim != $cdim} {
                return -code error "incompatible dimensions"
            }
            set cdim
        }]
    }
    return $cdims
}

# SingleMap --
#
# Private procedure to perform a single loop over ndlist
#
# Syntax:
# SingleMap $ndims $ndlist $body <$axis>
#
# Arguments:
# ndims         Number of dimensions of ndlist
# ndlist        ndlist to loop over
# body          Body to evaluate in caller's caller.
# axis           Recursion variable. Initializes as zero. (depth)

proc ::ndlist::SingleMap {ndims ndlist body {axis 0}} {
    variable nmap_i
    variable nmap_break
    set nmap_i($axis) -1
    if {$ndims == 1} {
        # Base case
        set result [uplevel 1 [list lmap x $ndlist "
            incr nmap_i($axis)
            uplevel 1 [list $body]
        "]]
        # Check for break
        if {$nmap_i($axis) != [llength $ndlist] - 1} {
            set nmap_break 1
        }
        return $result
    } 
    # Recursion case
    tailcall lmap x $ndlist "
        incr nmap_i($axis)
        if {\$nmap_break} {break}
        SingleMap [incr ndims -1] \$x [list $body] [incr axis]
    "
}

# MultiMap --
#
# Used for when there are multiple ndlists.
#
# Syntax:
# MultiMap $ndims $linkVars $ndlists $body <$axis>
# 
# Arguments:
# ndims         Number of dimensions at the current recursion level.
# linkVars      Variables in caller that link to caller's caller.
# ndlists       Lists to iterate over.
# body          Body to evaluate in caller's caller.
# axis          Recursion variable. Initializes as zero. (depth)

proc ::ndlist::MultiMap {ndims linkVars ndlists body {axis 0}} {
    variable nmap_i
    variable nmap_break
    # Create link-value mapping
    set linkMap ""; # mapping of link vars to ndlists
    foreach linkVar $linkVars ndlist $ndlists {
        lappend linkMap $linkVar $ndlist
    }
    # Initialize index
    set nmap_i($axis) -1
    # Base case
    if {$ndims == 1} {
        set result [uplevel 1 [list lmap {*}$linkMap "
            incr nmap_i($axis)
            uplevel 1 [list $body]
        "]]
        # Check for break
        if {$nmap_i($axis) != [llength $ndlist] - 1} {
            set nmap_break 1
        }
        return $result
    }
    # Recursion case
    set linkRef ""; # list of references to link variables
    foreach linkVar $linkVars {
        append linkRef "\$$linkVar "
    }
    tailcall lmap {*}$linkMap "
        incr nmap_i($axis)
        if {\$nmap_break} {break}
        MultiMap [incr ndims -1] [list $linkVars] \[list $linkRef\] \
                [list $body] [incr axis]
    "
}

# i --
#
# Access nmap indices (also works with nexpr)
#
# Syntax:
# i <$axis>
#
# Arguments:
# axis          Dimension to get index from. Default 0

proc ::ndlist::i {{axis 0}} {
    variable nmap_i
    return $nmap_i($axis)
}

# j --
#
# Access second-level nmap index (shorthand for [i 1])

proc ::ndlist::j {} {
    return [i 1]
}

# k --
#
# Access third-level nmap index (shorthand for [i 2])

proc ::ndlist::k {} {
    return [i 2]
}

# nfill --
#
# Fill all blanks in an ndlist with a value.
#
# Syntax:
# nfill $nd $ndlist $filler
#
# Arguments:
# nd                Number of dimensions (e.g. 1D, 2D, etc.)
# ndlist            ND list to get dimensions of
# filler            Filler to replace blanks.

proc ::ndlist::nfill {nd ndlist filler} {
    nmap $nd value $ndlist {
        expr {$value eq "" ? $filler : $value}
    }
}

# range --
#
# Utility to generate integer range
# 
# range $n
# range $start $stop
# range $start $stop $step
#
# Arguments:
# n:        Number of integers
# start:    Start of resultant range.
# stop:     End limit of resultant range.
# step:     Step size. Default 1 or -1, depending on direction.

proc ::ndlist::range {args} {
    # Switch for arity
    if {[llength $args] == 1} {
        # Basic case
        set n [lindex $args 0]
        if {![string is integer -strict $n] || $n < 0} {
            return -code error "n must be integer >= 0"
        }
        set start 0
        set stop [expr {$n - 1}]
        set step 1
    } elseif {[llength $args] == 2} {
        lassign $args start stop
        if {![string is integer -strict $start]} {
            return -code error "start must be integer"
        }
        if {![string is integer -strict $stop]} {
            return -code error "stop must be integer"
        }
        set step [expr {$stop > $start ? 1 : -1}]
    } elseif {[llength $args] == 3} {
        lassign $args start stop step
        if {![string is integer -strict $start]} {
            return -code error "start must be integer"
        }
        if {![string is integer -strict $stop]} {
            return -code error "stop must be integer"
        }
        if {![string is integer -strict $step]} {
            return -code error "step must be integer"
        }
    } else {
        return -code error "wrong # args: should be \"range n\",\
                \"range start stop\", or \"range start stop step\""
    }
    return [Range $start $stop $step]
}

################################################################################

# Finally, provide the package
package provide ndlist 0.2
