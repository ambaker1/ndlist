# ndobj.tcl
################################################################################
# Object-oriented implementation of ND-lists

# Copyright (C) 2025 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Define namespace and exported commands
namespace eval ::ndlist {
    variable ref; # Reference map for ndlists.
    namespace export narray neval nexpr
}

# ValidateRefName --
#
# Validate the reference name for ND objects.

proc ::ndlist::ValidateRefName {refName} {
    if {![regexp {^(::+|\w+)+$} $refName]} {
        return -code error "invalid object reference name \"$refName\""
    }
    return $refName
}

# Create narray class.



::oo::class create ::ndlist::narray {
    superclass ::ndlist::ValueContainer
    variable myValue myDims autoDims
   
    # Constructor
    # ::ndlist::narray new $refName <$value> <$nd>
    #
    # Arguments:
    # refName       Variable for garbage collection
	# value			Value for ndlist. Default ""
    # ndims         Number of dimensions. "auto" for auto.
    
    constructor {refName {value ""} {ndims "auto"}} {
        # Validate reference name
        ::ndlist::ValidateRefName $refName
        # Determine ndims (or autoDims)
        if {$ndims eq "auto"} {
            set autoDims 1
        } else {
            set autoDims 0
            set myDims [::ndlist::GetNDims $ndims]
        }
        next $refName $value
    }
    
    # Uplevel is modified to call ::ndlist::neval, handling object references.
    method Uplevel {level body} {
        next $level [list ::ndlist::neval $body [self]]
    }
    
    # SetValue is modified to determine ND-list dimensions.
    method SetValue {value} {
        if {$autoDims} {
            set myDims [::ndlist::GetNDims auto $value]
        }
        next [::ndlist::ndlist $value $myDims]
    }

    # $object ndims --
    #
    # Query or set the number of dimensions of the object.
    #
    # nd        Number of dimensions. Blank for query, "auto" for auto-dims.
    #           Default blank for query.
    
    method ndims {{nd ""}} {
        # Query case
        if {$nd eq ""} {
            return $myDims
        }
        # Modify dimensions
        set ndims [::ndlist::GetNDims $nd $myValue]
        ::ndlist::ndlist $myValue $ndims
        set autoDims [expr {$nd eq "auto"}]
        set myDims $ndims
    }
    
    # $object shape --
    #
    # Get dimensions of ND-array
    #
    # axis      Axis to get dimension along. Default blank for all.
    
    method shape {} {
        ::ndlist::GetShape $myDims $myValue
    }
    
    # $object size --
    #
    # Get size of ND-array
    
    method size {} {
        ::ndlist::nsize $myValue $myDims
    }
        
    # $object remove $index <$axis> --
    #
    # Remove portion of ND-array. Returns object.
    #
    # axis      Axis to remove from. Default 0.
    
    method remove {index {axis 0}} {
        my SetValue [::ndlist::nremove $myValue $index $axis]
    }
    
    # $object insert $index <$axis> --
    #
    # Insert values into ND-array. Returns object.
    #
    # axis      Axis to insert at. Default 0
    
    method insert {index sublist {axis 0}} {
        my SetValue [::ndlist::ninsert $myValue $index $sublist $axis $myDims]
    }
    
    # $object @ $i ... <$op $arg ...> --
    #
    # Index into the object
    #
    # Arguments:
    # i ...         Index arguments. Must match ndims.
    # op arg ...    Index operators, explained below:
    #   = value             Value assignment.
    #   := expr             Expression assignment.
    #   --> varName         Create new object from range.
    #   | method arg ...    Temp object evaluation.
    #   & refName body      Evaluate body with range assigned to ref var.
    
    method @ {args} {
        # Get indices from input
        if {[llength $args] < $myDims} {
            return -code error "wrong # of indices: want $myDims"
        }
        set indices [lrange $args 0 $myDims-1]
        set args [lrange $args $myDims end]
        # Check arity
        if {[llength $args] == 0} {
            tailcall my GetIndexValue $indices
        }
        # Interpret input
        set args [lassign $args op]
        switch $op {
            = { # Assignment to range.
                if {[llength $args] != 1} {
                    return -code error "wrong # args: should be\
                            \"[self] @ i ... = value\""
                }
                tailcall my SetIndexValue $indices [lindex $args 0]
            }
            := { # Math evaluation. 
                if {[llength $args] != 1} {
                    return -code error "wrong # args: should be\
                            \"[self] @ i ... := expr\""
                }
                my CopyIndexObject $indices temp
                uplevel 1 [list $temp := [lindex $args 0]]
                tailcall my SetIndexValue $indices [$temp]
            }
            --> { # Copy range to new element.
                if {[llength $args] != 1} {
                    return -code error "wrong # args: should be\
                            \"[self] @ i ... --> varName\""
                }
                tailcall my CopyIndexObject $indices [lindex $args 0]
            }
            | { # Copy to temp, evaluate in temp.
                if {[llength $args] == 0} {
                    return -code error "wrong # args: should be\
                            \"[self] @ i ... | method ?arg ...?\""
                }
                tailcall my TempIndexObject $indices {*}$args
            }
            & { # Copy range to temp, run RefEval in caller, set range, return.
                if {[llength $args] != 2} {
                    return -code error "wrong # args: should be\
                            \"[self] @ i ... & refName body\""
                }
                my CopyIndexObject $indices temp
                set result [uplevel 1 [list $temp & {*}$args]]
                # If variable is deleted, throw error.
                if {[info commands $temp] eq ""} {
                    return -code error "cannot unset reference to range"
                }
                my SetIndexValue $indices [$temp]
                return $result
            }
            default {
                return -code error "unknown operator \"$op\":\
                        want =, :=, -->, or |"
            }
        }
    }
    export @
    
    # my GetIndexValue --
    #
    # Index into an ND-list object.
    #
    # Arguments:
    # indices       Index inputs
    
    method GetIndexValue {indices} {
        # Interpret input
        if {[llength $indices] != $myDims} {
            return -code error "wrong # of indices: want $myDims"
        }
        ::ndlist::nget $myValue {*}$indices
    }
    
    # my SetIndexValue $indices $value --
    #
    # Set a range of an ND-list object.
    #
    # Arguments:
    # indices       Index inputs
    # value         Value to assign with
    
    method SetIndexValue {indices value} {
        # Interpret input
        if {[llength $indices] != $myDims} {
            return -code error "wrong # of indices: want $myDims"
        }
        # Validate input, and call nset.
        set ndims [my GetIndexDims $indices]
        ::ndlist::nset myValue {*}$indices [::ndlist::ndlist $value $ndims]
        return [self]
    }
    
    # my GetIndexDims $indices --
    #
    # Get dimensions of index input
    #
    # Arguments:
    # indices       Index inputs
    
    method GetIndexDims {indices} {
        set myShape [my shape]
        set indexArgs [::ndlist::ParseIndices $myShape {*}$indices]
        set indexShape [::ndlist::GetIndexShape $myShape {*}$indexArgs]
        return [llength $indexShape]
    }
    
    # my CopyIndexObject $indices $varName --
    #
    # Copy range to new variable
    #
    # Arguments:
    # indices       Index inputs
    # varName       Variable to tie to object.
    
    method CopyIndexObject {indices varName} {
        # Interpret input
        if {[llength $indices] != $myDims} {
            return -code error "wrong # of indices: want $myDims"
        }
        # Get new ndims and value.
        set value [my GetIndexValue $indices]
        if {$autoDims} {
            set ndims auto
        } else {
            set ndims [my GetIndexDims $indices]
        }
        tailcall [self class] new $varName $value $ndims
    }
    
    # my TempIndexObject $indices $method $arg ... --
    #
    # Copy range to new variable
    #
    # Arguments:
    # indices       Index inputs
    # method        Method to invoke on temporary object.
    # arg ...       Additional arguments for method
    
    method TempIndexObject {indices method args} {
        # Interpret input
        if {[llength $indices] != $myDims} {
            return -code error "wrong # of indices: want $myDims"
        }
        my CopyIndexObject $indices temp
        set result [uplevel 1 [list $temp $method {*}$args]]
        if {$result eq $temp} {
            set result [$temp]
        }
        return $result
    }
}

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
# Map over ND objects. 
# References must have matching dimensions or be scalar.
#
# Syntax:
# neval $body <$self> <$ndimsVar>
#
# Arguments:
# body          Tcl script, with @ref notation for object references.
# self          Object to refer to with "@.". Default blank.
# ndimsVar       Variable to store resulting ndims in. Default blank.

# Example:
# narray new x {{hello world} {foo bar}} 1D
# neval {string toupper @x}; # {{HELLO WORLD} {FOO BAR}}

proc ::ndlist::neval {body {self ""} {ndimsVar ""}} {
    variable ref; # Reference array
    # Get references
    lassign [RefSub $body] body refNames 
    # Get values and shapes from object references
    set refRanks ""
    set refValues "" 
    foreach {refName index} $refNames {
        # Get object for reference
        if {$refName eq "."} {
            # Self-reference
            if {$self eq ""} {
                return -code error "no self reference object provided"
            }
            set object $self
        } else {
            # Variable reference
            upvar 1 $refName refVar
            if {![info exists refVar]} {
                return -code error "\"$refName\" does not exist"
            }
            if {[array exists refVar]} {
                return -code error "\"$refName\" is an array"
            }
            set object $refVar
        }
        # Check that the reference is pointing to a valid object.
        if {![info object isa object $object]} {
            return -code error "\"$object\" is not an object"
        }
        if {![info object isa typeof $object ::ndlist::narray]} {
            return -code error "\"$object\" is not an ND object"
        }
        # Index if needed
        if {$index ne ""} {
            $object @ {*}[split $index ,] --> object
        }
        # Get object ndims and value for mapping.
        lappend refRanks [$object ndims]
        lappend refValues [$object]
    }
    # Get ndims of mapping
    if {$ndimsVar ne ""} {
        upvar 1 $ndimsVar ndims
    }
    # Choose maximum reference ndims
    set ndims [expr {[llength $refRanks] == 0 ? 0 : [max $refRanks]}]
    
    # Save old reference mapping, and initialize.
    set oldRefs [array get ref]
    array unset ref
    # Assign scalars and build map list
    set varMap ""; # varName value ...
    foreach refValue $refValues refRank $refRanks {refName index} $refNames {
        if {$refRank == 0} {
            # Scalar. Set value directly.
            set ::ndlist::ref($refName.$index) $refValue
        } else {
            # Not a scalar (ndims > 0)
            lappend varMap ::ndlist::ref($refName.$index) $refValue
        }
    }
    # Try to evaluate user-input
    try {
        if {[llength $varMap] == 0} {
            uplevel 1 $body
        } else {
            uplevel 1 [list ::ndlist::nmap $ndims {*}$varMap $body]
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
# nexpr $expr <$self> <$ndimsVar>
#
# Arguments:
# expr          Math expression, with @ref notation for object references.
# self          Object to refer to with "@.". Default blank.
# ndimsVar      Variable to store resulting ndims in. Default blank.

# Example:
# narray new x {1.0 2.0 3.0}
# narray new y 5.0
# nexpr {@x + @y}; # {6.0 7.0 8.0}

proc ::ndlist::nexpr {expr {self ""} {ndimsVar ""}} {
    tailcall neval [list expr $expr] $self $ndimsVar
}
