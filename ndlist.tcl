# ndlist.tcl
################################################################################
# N-Dimensional List Implementation

# Copyright (C) 2023 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Required packages
package require vutil 0.7

# Define namespace
namespace eval ::ndlist {
    # Internal variables
    variable nmap_i; # nmap index array
    array set nmap_i ""
    variable nmap_break; # nmap break passer
    variable filler 0; # Filler for nreplace
    variable temp; # Temporary ndlist object
    
    # N-dimensional list access and mapping
    namespace export ndlist; # ND list type class
    namespace export tensor matrix vector scalar; # Shorthand for new ndlist objects
    namespace export nrepeat; # Create ndlist with one value
    namespace export nreshape; # Create ndlist from a vector
    namespace export nstack; # Combine ndlists
    namespace export nswap; # Swap axes
    namespace export nget; # Get values in ndlist
    namespace export nset; # Set values in ndlist
    namespace export nreplace; # Replace values in-place
    namespace export nop; # Math operations over ndlists
    namespace export nexpr; # Expression mapping over ndlists
    namespace export nmap; # Functional map over ndlists
    namespace export i j k; # Index access commands
}

# NDLIST OBJECT VARIABLES
################################################################################

# ndlist --
#
# Object variable class for ndlists
#
# Syntax:
# ndlist new $ndtype $refName <$value>
#
# Arguments:
# ndtype        Type of ND list (0D for scalar, 1D for vector, etc.)
# refName       Variable name for garbage collection
# value         ndlist value (must be proper list, at least along 0 index)

::vutil::type create ndlist ::ndlist::ndlist {
    constructor {ndtype refName args} {
        set (ndims) [::ndlist::GetNDims $ndtype]
        next $refName {*}$args
    }
    method SetValue {value} {
        if {[catch {::ndlist::GetShape $(ndims) $value} result]} {
            return -code error $result
        }
        next $value
    }
    method info {args} {
        set (shape) [my shape]
        next {*}$args
    }
    
    # $ndobj ndims <$ndims>
    #
    # Query or set the dimensionality.
    
    method ndims {{ndims ""}} {
        if {$ndims ne ""} {
            # Check if ndims is valid, then assign it
            if {[catch {::ndlist::GetShape $ndims $(value)} result]} {
                return -code error $result
            }
            set (ndims) $ndims
        }
        return $(ndims)
    }
    
    # $ndobj shape <$axis>
    #
    # Query the shape of the ndobj, for all dimensions or a specified dim.
    
    method shape {{axis ""}} {
        # Switch for type
        if {$axis == ""} {
            return [::ndlist::GetShape $(ndims) $(value)]
        } elseif {$axis >= 0 && $axis < $(ndims)} {
            # Get single dimension (along first index)
            return [llength [lindex $(value) {*}[lrepeat $axis 0]]]
        } else {
            return -code error \
                    "axis must be between 0 and [expr {$(ndims) - 1}]"
        }
    }
    
    # $ndobj reshape $n ...
    #
    # Reshape an ndobj (must be 1D or higher), and return self.
    #
    # Arguments:
    # $n ...        New dimensions (and dimensionality)
    
    method reshape {n args} {
        # Flatten the ndlist to a vector (1D)
        set vector $(value)
        for {set i 1} {$i < $(ndims)} {incr i} {
            set vector [concat {*}$vector]
        }
        # Reshape the ndlist (throws error if dimensions do not match)
        if {[llength $args] == 0} {
            set (value) $vector
        } else {
            set (value) [::ndlist::nreshape $vector $n {*}$args]
        }
        # Assign new dimensionality and return self
        set (ndims) [expr {[llength $args] + 1}]
        return [self]
    }
    
    # $ndobj size
    #
    # Get total size of array (number of elements)
    
    method size {} {
        set size 1
        foreach dim [my shape] {
            set size [expr {$size * $dim}]
        }
        return $size
    }
    
    # Modify left assigment to verify dimensionality
    method <- {objName args} {
        # Verify that objName is an ndlist
        if {![::vutil::type isa ndlist $objName]} {
            return -code error "\"$objName\" is not an ndlist"
        }
        # Verify same ND
        if {[$objName ndims] != $(ndims)} {
            return -code error "incompatible dimensionality"
        }
        next $objName {*}$args
    }
    export <-
    
    # := --
    #
    # Calls nexpr to do ndlist math. Overrides values, keeps dimensionality.
    
    method := {expr} {
        my = [uplevel 1 [list ::ndlist::nexpr $expr]]
    }
    export :=
    
    # Basic operators, same as for vutil float type (calls nop)
    method += {expr} {
        my = [::ndlist::nop [self] + [uplevel 1 [list expr $expr]]]
    }
    method -= {expr} {
        my = [::ndlist::nop [self] - [uplevel 1 [list expr $expr]]]
    }
    method *= {expr} {
        my = [::ndlist::nop [self] * [uplevel 1 [list expr $expr]]]
    }
    method /= {expr} {
        my = [::ndlist::nop [self] / [uplevel 1 [list expr $expr]]]
    }
    export += -= *= /=
    
    # @ --
    #
    # Method to get or set a value (or ranges of values) in an ndlist
    #
    # Syntax:
    # $ndobj @ $i $j $k; # nget, returns value
    # $ndobj @ $i $j $k &; # nget, returns temporary object
    # $ndobj @ $i $j $k --> $refName; # nget, creates new object
    # $ndobj @ $i $j $k = $value; # nset, by value
    # $ndobj @ $i $j $k := $expr; # nset, by expression
    # $ndobj @ $i $j $k *= $expr; # nset, by 
    # $ndobj1 @ $i $j $k <- $ndobj2; # nset, by object (must match dimension)
    
    method @ {args} {
        # Get value (returns raw data)
        if {[llength $args] == $(ndims)} {
            return [::ndlist::nget $(value) {*}$args]
        }
        # Get temporary object
        if {[llength $args] == $(ndims) + 1} {
            set indices [lrange $args 0 end-1]
            if {[lindex $args end] eq "&"} {
                # Anonymous object creation
                set results [::ndlist::NGet $(value) {*}$indices]
                set subdims [lassign $results sublist]
                set ndtype "[llength $subdims]D"
                return [::vutil::new ndlist $ndtype ::ndlist::temp $sublist]
            }
        }
        # Object manipulation
        if {[llength $args] == $(ndims) + 2} {
            set indices [lrange $args 0 end-2]
            set op [lindex $args end-1]; # Assigment operator
            switch $op {
                = { # Value assignment (returns self)
                    set sublist [lindex $args end]
                    ::ndlist::nset (value) {*}$indices $sublist
                    return [self]
                }
                & { 
                }
                := { # nexpr assigment (returns self)
                    set expr [lindex $args end]
                    set sublist [uplevel 1 [list ::ndlist::nexpr $expr]]
                    ::ndlist::nset (value) {*}$indices $sublist
                    return [self]
                }
                += { # nop addition (returns self)
                    set expr [lindex $args end]
                    set sublist [::ndlist::nop [my @ {*}$indices &] + \
                            [uplevel 1 [list expr $expr]]]
                    ::ndlist::nset (value) {*}$indices $sublist
                    return [self]
                }
                -= { # nop subtraction (returns self)
                    set expr [lindex $args end]
                    set sublist [::ndlist::nop [my @ {*}$indices &] - \
                            [uplevel 1 [list expr $expr]]]
                    ::ndlist::nset (value) {*}$indices $sublist
                    return [self]
                }
                *= { # nop multiplication (returns self)
                    set expr [lindex $args end]
                    set sublist [::ndlist::nop [my @ {*}$indices &] * \
                            [uplevel 1 [list expr $expr]]]
                    ::ndlist::nset (value) {*}$indices $sublist
                    return [self]
                }
                /= { # nop division (returns self)
                    set expr [lindex $args end]
                    set sublist [::ndlist::nop [my @ {*}$indices &] / \
                            [uplevel 1 [list expr $expr]]]
                    ::ndlist::nset (value) {*}$indices $sublist
                    return [self]
                }
                <- { # Object assigment (returns self)
                    set objName [lindex $args end]
                    # Verify that objName is an ndlist
                    if {![::vutil::type isa ndlist $objName]} {
                        return -code error "\"$objName\" is not an ndlist"
                    }
                    # Verify same ND
                    if {[$objName ndims] != $(ndims)} {
                        return -code error "incompatible dimensionality"
                    }
                    # Perform assigment (checks dimensions)
                    ::ndlist::nset (value) {*}$indices [$objName]
                    return [self]
                }
                --> { # Object creation (returns new object)
                    set refName [lindex $args end]
                    upvar 1 $refName refVar
                    # Use "NGet" to also return the new dimensions
                    set results [::ndlist::NGet $(value) {*}$indices]
                    set subdims [lassign $results sublist]
                    set ndtype "[llength $subdims]D"
                    return [::vutil::new ndlist $ndtype refVar $sublist]
                }
                
            }
        }
        # Error cases
        switch $(ndims) {
            0 { # Scalar
                return -code error "wrong # args: should be\
                        \"ndobj @ ?= value | <- obj | --> refName?"
            }
            1 { # Vector
                return -code error "wrong # args: should be\
                        \"ndobj @ i ?= value | <- obj | --> refName?"
            }
            2 { # Matrix
                return -code error "wrong # args: should be\
                        \"ndobj @ i j ?= value | <- obj | --> refName?"
            }
            3 { # 3D tensor
                return -code error "wrong # args: should be\
                        \"ndobj @ i j k ?= value | <- obj | --> refName?"
            }
            default { # Higher order tensor
                return -code error "wrong # args: should be \"ndobj @\
                        i1 ... i$(ndims) ?= value | <- obj | --> refName?"
            }
        }
    }
    export @
    
    # $ndobj T <$axis1 $axis2> <&>
    #
    # Get transpose of ndlist (or swap axes)
    # 
    # Arguments:
    # axis1:        Axis to swap with axis 2 (default 0)
    # axis2:        Axis to swap with axis 1 (default 1)
    # &:            Option to return temporary ndobj
    
    method T {args} {
        # Trim pointer reference argument
        if {[lindex $args end] eq "&"} {
            set mode ndobj
            set args [lrange $args 0 end-1]
        } else {
            set mode value
        }
        # Switch for arity
        if {[llength $args] == 0} {
            # Default transpose case
            if {$(ndims) <= 1} {
                set result $(value) 
            } else {
                set result [::ndlist::nswap $(value)]
            }
        } elseif {[llength $args] == 2} {
            # Axis swap case
            lassign [lsort -integer $args] axis1 axis2
            if {$axis2 >= $(ndims)} {
                return -code error "axis out of range"
            }
            set result [::ndlist::nswap $(value) $axis1 $axis2]
        } else {
            return -code error "wrong # args: should be\
                    \"ndobj T ?axis1 axis2? ?&?\""
        }
        # Return either value or temporary ndobj
        switch $mode {
            value {
                return $result
            }
            ndobj {
                return [::ndlist::TempObj $(ndims) $result]
            }
        }
    }
    export T
}; # end "ndlist" type declaration

# GetNDims --
#
# Get dimensionality from ndtype string.
#
# Syntax:
# GetNDims $ndtype
#
# Arguments:
# ndtype        Dimension type, example 0D, 1D, 2D, 3D, etc.

proc ::ndlist::GetNDims {ndtype} {
    if {![IsNDType $ndtype]} {
        return -code error "Invalid ND syntax"
    }
    return [string range $ndtype 0 end-1]
}

# IsNDType --
#
# Check if a string is an NDType string. (uses regex pattern)
#
# Syntax:
# IsNDType $string
#
# Arguments:
# string        String to check. Returns true if it is a dimension string.

proc ::ndlist::IsNDType {string} {
    regexp {^(0|[1-9]\d*)[dD]$} $string
}

# tensor --
#
# Shorthand to create a new ndlist of arbitrary dimension
#
# Syntax:
# tensor $ndtype $refName <$value>
#
# Arguments:
# refName       Variable name for garbage collection
# value         Value to initialize 

proc ::ndlist::tensor {ndtype refName args} {
    upvar 1 $refName refVar
    ndlist new $ndtype refVar {*}$args
}

# matrix --
#
# Shorthand to create a new 2D ndlist.
#
# Syntax:
# matrix $refName <$value>
#
# Arguments:
# refName       Variable name for garbage collection
# value         Value to set matrix to

proc ::ndlist::matrix {refName args} {
    upvar 1 $refName refVar
    ndlist new 2D refVar {*}$args
}

# vector --
#
# Shorthand to create a new 1D ndlist.
#
# Syntax:
# vector $refName <$value>
#
# Arguments:
# refName       Variable name for garbage collection
# value         Value to set vector to

proc ::ndlist::vector {refName args} {
    upvar 1 $refName refVar
    ndlist new 1D refVar {*}$args
}

# scalar --
#
# Shorthand to create a new 0D ndlist.
#
# Syntax:
# scalar $refName <$value>
#
# Arguments:
# refName       Variable name for garbage collection
# value         Value of scalar

proc ::ndlist::scalar {refName args} {
    upvar 1 $refName refVar
    ndlist new 0D refVar {*}$args
}

# TempObj --
#
# Returns a temporary object (overwritten every time a new temp object is made)

proc ::ndlist::TempObj {ndims ndlist} {
    variable temp
    ndlist new ${ndims}D temp $ndlist
}

# NDLIST INITIALIZATION
################################################################################

# nrepeat --
#
# Create an ndlist filled with one value
#
# Syntax:
# nrepeat $value $n1 $n2 ...
#
# Arguments:
# value         Value to repeat
# n1 n2 ...     Dimensions of ndlist

proc ::ndlist::nrepeat {value args} {
    set ndlist $value
    foreach n [lreverse $args] {
        set ndlist [lrepeat $n $ndlist]
    }
    return $ndlist
}

# nreshape --
#
# Reshape a vector to an ndlist, given dimensions.
#
# Syntax:
# nreshape $vector $n $m ...
#
# Arguments:
# vector:       Vector to reshape into ndlist
# n m ...:      New dimensions (must have at least two)

proc ::ndlist::nreshape {vector n m args} {
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
    # If more dimensions are provided, enter recursion.
    if {[llength $args] > 0} {
        return [lmap row $matrix {nreshape $row $m {*}$args}]
    }
    # Return the reshaped ndlist
    return $matrix
}

# NDLIST COMBINATION/MANIPULATION
################################################################################

# nstack --
#
# Stack ndlists along a dimension
#
# Syntax:
# nstack $ndobj1 $ndobj2 $axis <&>
# nstack $ndtype $ndlist1 $ndlist2 $axis <&>
#
# Arguments:
# ndobj1 ndobj2:    Ndlist objects to stack
# axis:             Axis to stack along
# &:                Option to return temporary ndobj
# ndtype:           Number of dimensions (e.g. 1D, 2D, etc.)
# ndlist1 ndlist2:  Ndlists to stack

proc ::ndlist::nstack {args} {
    # Interpret input
    if {[IsNDType [lindex $args 0]]} {
        # nstack $ndtype $ndlist1 $ndlist2 $axis <&>
        # Check arity
        if {[llength $args] == 4} {
            set mode value
        } elseif {[llength $args] == 5 && [lindex $args end] eq "&"} {
            set mode ndobj
        } else {
            return -code error "wrong # args: should be\
                    \"nstack ndtype ndlist1 ndlist2 axis ?&?\"" 
        }
        lassign $args ndtype ndlist1 ndlist2 axis
        set ndims [GetNDims $ndtype]
    } else {
        # nstack $ndobj1 $ndobj2 $axis <&>
        # Check arity
        if {[llength $args] == 3} {
            set mode value
        } elseif {[llength $args] == 4 && [lindex $args end] eq "&"} {
            set mode ndobj
        } else {
            return -code error "wrong # args: should be\
                    \"nstack ndobj1 ndobj2 axis ?&?\"" 
        }
        lassign $args ndobj1 ndobj2 axis
        # Check if ndlist objects
        if {![::vutil::type isa ndlist $ndobj1]} {
            return -code error "\"$ndobj1\" is not an ndlist object"
        }
        if {![::vutil::type isa ndlist $ndobj2]} {
            return -code error "\"$ndobj2\" is not an ndlist object"
        }
        # Check that they have the same dimensions
        set ndims [$ndobj1 ndims]
        if {[$ndobj2 ndims] != $ndims} {
            return -code error "incompatible dimensionality"
        }
        set ndlist1 [$ndobj1]
        set ndlist2 [$ndobj2]
    }
    # Check validity of ndims/axis
    if {![string is integer -strict $axis]} {
        return -code error "axis must be integer"
    }
    if {$axis >= $ndims} {
        return -code error "axis out of range"
    }
    # Check dimensions
    set dims1 [GetShape $ndims $ndlist1]
    set dims2 [GetShape $ndims $ndlist2]
    set i 0
    foreach dim1 $dims1 dim2 $dims2 {
        if {$dim1 ne $dim2 && $i != $axis} {
            return -code error "incompatible dimensions along axis $i"
        }
        incr i
    }
    # Perform stack
    set result [RecStack $ndlist1 $ndlist2 $axis]
    # Return either value or temporary ndobj
    switch $mode {
        value {
            return $result
        }
        ndobj {
            return [TempObj $ndims $result]
        }
    }
}

# RecStack --
# 
# Recursive handler for nstack (after dimensions were checked)
#
# Arguments:
# ndlist1 ndlist2:      ndlists to stack
# axis:                 Axis to stack along

proc ::ndlist::RecStack {ndlist1 ndlist2 axis} {
    # Base case
    if {$axis == 0} {
        return [concat $ndlist1 $ndlist2]
    }
    # Recursion
    incr axis -1
    lmap ndrow1 $ndlist1 ndrow2 $ndlist2 {
        RecStack $ndrow1 $ndrow2 $axis
    }
}

# nswap --
#
# Swaps axes (by default just transposes)
#
# Syntax:
# nswap $ndlist <$axis1 $axis2>
# ndlist:       ND list to manipulate
# axis1:        Axis to swap with axis 2 (default 0)
# axis2:        Axis to swap with axis 1 (default 1)

proc ::ndlist::nswap {ndlist args} {
    # Interpret input
    if {[llength $args] == 0} {
        set axis1 0
        set axis2 1
    } elseif {[llength $args] == 2} {
        lassign [lsort -integer $args] axis1 axis2
        if {$axis1 < 0} {
            return -code error "axes out of range"
        }
    } else {
        return -code error "wrong # args: should be\
                \"nswap ndlist ?axis1 axis2?\""
    }
    # Perform axis swap
    RecSwap $ndlist $axis1 $axis2
}

# RecSwap --
# 
# Recursive handler for nswap (after axes are checked)
#
# Arguments:
# ndlist:           ND list to manipulate
# axis1:            Axis to swap with axis 2
# axis2:            Axis to swap with axis 1

proc ::ndlist::RecSwap {ndlist axis1 axis2} {
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
            set ndrow [RecSwap $ndrow $axis1 $axis2]; # (jik -> jki)
        }]
        # Final transpose
        return [Transpose $ndlist]; # (jki -> kji)
    }
    # Simple recursion to get to first swap axis
    incr axis1 -1
    incr axis2 -1
    lmap ndrow $ndlist {
        RecSwap $ndrow $axis1 $axis2
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

# NDLIST ACCESS
################################################################################

# nget --
# 
# Get portion of ndlist using ndlist index notation.
#
# Syntax:
# nget $ndlist $i1 $i2 ...
#
# Arguments:
# ndlist        Valid ndlist
# i1 i2 ...     Separate arguments for index dimensions

proc ::ndlist::nget {ndlist args} {
    lindex [NGet $ndlist {*}$args] 0
}

# NGet --
#
# Private implementation of nget that also returns the new dimensions.
#
# Syntax:
# NGet $ndlist $i1 $i2 ...
#
# Returns:
# $ndlist $n1 $n2 ...
#
# Arguments:
# ndlist        Valid ndlist
# i1 i2 ...     Separate arguments for index dimensions

proc ::ndlist::NGet {ndlist args} {
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
    set subdims ""
    foreach dim $dims iLim $iLims iDim $iDims {
        if {$iLim >= $dim} {
            return -code error "index out of range"
        }
        if {$iDim > 0} {
            lappend subdims $iDim
        }
    }
    # Get subset of ndlist and return with new dimensions
    return [list [RecGet $ndlist {*}$iArgs] {*}$subdims]
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

# NDLIST MODIFICATION
################################################################################

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
# Replace portion of ndlist - return new list, same dimension
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
    lindex [NReplace $ndlist {*}$args] 0
}

# NReplace --
#
# Private implementation of nreplace. Additionally returns new dimensions.
#
# Syntax:
# nreplace $ndlist $i1 $i2 ... $sublist
# 
# Arguments:
# ndlist        Valid ndlist
# i1 i2 ...     Separate arguments for index dimensions
# sublist       Sublist to replace with (must agree in dimension or unity)
#               If blank, removes elements (must remove only along one axis)

proc ::ndlist::NReplace {ndlist args} {
    # Interpret arguments
    set indices [lrange $args 0 end-1]
    set sublist [lindex $args end]
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
        return [list [RecRemove $ndlist $axis $iType $iList] {*}$subdims]
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
                break
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
        return [list [RecReplace $ndlist $sublist {*}$iArgs] {*}$subdims]
    }
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

# Expand --
#
# Expand an ndlist to specified dimension list, so that lset doesn't throw error
# Fills with "$::ndlist::filler" (default 0) which can be modified by user.
#
# Syntax:
# Expand $ndlist $n1 $n2 ...
#
# Arguments:
# ndlist        ND list to expand
# n1 n2 ...     New dimensions

proc ::ndlist::Expand {ndlist n args} {
    variable filler
    # Expand list as needed
    if {[llength $ndlist] < $n} {
        lappend ndlist {*}[lrepeat [expr {$n-[llength $ndlist]}] $filler]
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
# sublist:      ndlist to substitute at specified indices
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

# NDLIST FUNCTIONAL MAPPING COMMANDS
################################################################################

# nop --
#
# Simple math operations on ndlists.
#
# Syntax:
# nop $ndobj $op $opargs <&>
# nop $ndtype $ndlist $op $opargs <&>
#
# Arguments:
# ndobj:        ndlist object
# ndtype:       Number of dimensions (e.g. 1D, 2D, etc.)
# ndlist:       ndlist to iterate over
# op:           Valid mathop
# opargs:       Values to perform mathop with (see tcl::mathop documentation)
# &:            Option to return temporary ndobj

# Matrix examples:
# nop 2D $matrix / {}; # Performs reciprocal
# nop 2D $matrix - {}; # Negates values
# nop 2D $matrix ! {}; # Boolean negation
# nop 2D $matrix + {5 1}; # Adds 5 and 1 to each matrix element
# nop 2D $matrix ** 2; # Squares entire matrix
# nop 2D $matrix in {1 2 3}; # Returns boolean matrix, if values are in a list

proc ::ndlist::nop {args} {
    # Interpret input
    if {[IsNDType [lindex $args 0]]} {
        # nop $ndtype $ndlist $op $values <&>
        if {[llength $args] == 4} {
            set mode value
        } elseif {[llength $args] == 5 && [lindex $args end] eq "&"} {
            set mode ndobj
        } else {
            return -code error "wrong # args: should be\
                    \"nop ndtype ndlist op opargs ?&?\"" 
        }
        lassign $args ndtype ndlist op opargs
        set ndims [GetNDims $ndtype]
    } else {
        # nop $ndobj $op $values <&>
        if {[llength $args] == 3} {
            set mode value
        } elseif {[llength $args] == 4 && [lindex $args end] eq "&"} {
            set mode ndobj
        } else {
            return -code error "wrong # args: should be\
                    \"nop ndobj op opargs ?&?\"" 
        }
        lassign $args ndobj op opargs
        if {![::vutil::type isa ndlist $ndobj]} {
            return -code error "\"$ndobj\" is not an ndlist object"
        }
        set ndlist [$ndobj]
        set ndims [$ndobj ndims]
    }
    # Adjust for list operators
    if {$op in {in ni}} {
        set opargs [list $opargs]
    }
    # Perform operation
    set result [RecOp $ndims $ndlist $op {*}$opargs]
    # Return either value or temporary ndobj
    switch $mode {
        value {
            return $result
        }
        ndobj {
            return [TempObj $ndims $result]
        }
    }
}

# RecOp --
#
# Recursive handler for nop

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

# nexpr --
# 
# Create a new ndlist based on element-wise operations (calls nmap)
#
# Syntax:
# nexpr $expr <&>; # @ref style
# nexpr $ndtype $varName $ndlist ... $expr <&>; # lmap style
# 
# Arguments:
# expr:         Expression to evaluate (using @ to reference ndobjs)
# refName:      Reference variable to tie new ndobj to.
# ndtype:       Type of ndlist (e.g. 1D, 2D, etc.)
# varName:      Variable name to use in expression
# ndlist:       ndlist to iterate over

proc ::ndlist::nexpr {args} {
    # Switch for @ref body style
    if {[llength $args] < 4} {
        # nexpr $expr <&>
        if {[llength $args] == 0 || [llength $args] == 3 ||
            ([llength $args] == 2 && [lindex $args end] ne "&")
        } then {
            return -code error "wrong # args: should be \"nexpr expr ?&?\""
        }
        set args [lassign $args expr]
        tailcall nmap [list expr $expr] {*}$args
    } 
    # Normal case (in the style of lmap)
    set ndtype [lindex $args 0]
    # Check arity
    if {[llength $args] % 2} {
        # nexpr $ndtype $varName $ndlist <$varName $ndlist ...> $expr &
        if {[lindex $args end] eq "&"} {
            set varMap [lrange $args 1 end-2]
            set expr [lindex $args end-1]
            tailcall nmap $ndtype {*}$varMap [list expr $expr] &
        } else {
            return -code error "wrong # args: should be \"nexpr ndtype varName\
                    ndlist ?varName ndlist ...? expr ?&?\""
        }
    } else {
        # nexpr $ndtype $varName $ndlist <$varName $ndlist ...> $expr
        set varMap [lrange $args 1 end-1]
        set expr [lindex $args end]
        tailcall nmap $ndtype {*}$varMap [list expr $expr]
    }
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
# nmap $body <"&">; # @ref style
# nmap $ndtype $varName $ndlist ... $body <"&">; # lmap style
# 
# Arguments:
# body:         Body to evaluate
# refName:      Reference variable to tie new ndobj to.
# ndtype        Number of dimensions (e.g. 1D, 2D, etc.)
# varName       Variable name to iterate with (foreach-loop style)
# ndlist        ndlist to iterate over (foreach-loop style)

proc ::ndlist::nmap {args} {
    variable nmap_i; # array
    variable nmap_break 0; # variable to pass break with
    # Switch for @ref body style
    if {[llength $args] < 4} {
        # Basic arity check
        if {[llength $args] == 0 || [llength $args] == 3} {
            return -code error "wrong # args: should be \"nmap body ?&?\""
        }
        # Get return mode
        if {[llength $args] == 2} {
            if {[lindex $args end] eq "&"} {
                set mode ndobj
            } else {
                return -code error "wrong # args: should be \"nmap body ?&?\""
            }
        } else {
            set mode value
        }
        # Get nmap body and substitute @ refs with array elements
        set body [lindex $args 0]
        # Get mapping of refVars in body
        set exp {@\w+|@{(\\\{|\\\}|[^\\}{]|\\\\)*}}
        set varMap ""
        set ndims 0
        foreach {match submatch} [regexp -inline -all $exp $body] {
            set refName [join [string range $match 1 end]]
            upvar 1 $refName ndobj
            # Validate that reference is to ndlist object
            if {![info exists ndobj]} {
                return -code error "\"$refName\" does not exist"
            }
            if {![::vutil::type isa ndlist $ndobj]} {
                return -code error "\"$refName\" is not an ndlist object"
            }
            # Update body
            set body [regsub $match $body "\$($ndobj)"]
            # Use largest ndims
            if {[$ndobj ndims] > $ndims} {
                set ndims [$ndobj ndims]
            }
            # Update variable map
            if {![dict exists $varMap ($ndobj)]} {
                dict set varMap ($ndobj) [$ndobj]
            }
        }
        # Determine ndtype
        set ndtype ${ndims}D; # e.g. 2D
        # No ndlist objects detected. Simply evaluate as scalar.
        if {[llength $varMap] == 0} {
            # No ndlist objects found. Simply evaluate as a scalar.
            set result [uplevel 1 $body]
        } else {
            # Call normal nmap
            set result [uplevel 1 ::ndlist::nmap $ndtype $varMap [list $body]]
        }
        # Unset reference variables
        upvar 1 "" ""
        foreach key [dict keys $varMap] {
            unset $key
        }
        # Return value or assign to object
        switch $mode {
            value {
                return $result
            }
            ndobj {
                return [TempObj $ndims $result]
            }
        }
    }
    
    # Normal case (in the style of lmap)
    # Check arity and get return mode
    if {[llength $args] % 2} {
        # nmap $ndtype $varName $ndlist <$varName $ndlist ...> $body &
        if {[lindex $args end] eq "&"} {
            set mode ndobj
            set args [lrange $args 0 end-1]
        } else {
            return -code error "wrong # args: should be \"nmap ndtype varName\
                    ndlist ?varName ndlist ...? body ?&?\""
        }
    } else {
        set mode value
    }
    
    # Save old indices and initialize new
    set old_i [array get nmap_i]
    array unset nmap_i
    try { # Try to perform map, and regardless, restore old indices
        if {[llength $args] == 4} {
            # Loop over a single ndlist (simpler case)
            lassign $args ndtype varName ndlist body
            set ndims [GetNDims $ndtype]
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
            set ndtype [lindex $args 0]
            set mapping [dict get [lrange $args 1 end-1]]
            set body [lindex $args end]
            set ndims [GetNDims $ndtype]
            # Unzip varMap to varNames and ndlists
            set varNames ""
            set ndlists ""
            foreach {varName ndlist} $mapping {
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
    # Return value or assign to object
    switch $mode {
        value {
            return $result
        }
        ndobj {
            return [TempObj $ndims $result]
        }
    }
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

################################################################################

# Finally, provide the package
package provide ndlist 0.1