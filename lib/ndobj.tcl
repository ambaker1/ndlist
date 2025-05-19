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

# Dynamically determine rank of ndlist 

proc ::ndlist::GetRank {value} {
    set rank 0
    while {$value ne [lindex $value 0]} {
        set value [lindex $value 0]
        incr rank
    }
    return $rank
}

# Create narray class.

::oo::class create ::ndlist::narray {
    superclass ::ndlist::ValueContainer
    variable myValue myRank
   
    # Constructor
    # ::ndlist::narray new $refName <$value>
    #
    # Arguments:
    # refName       Variable for garbage collection
	# value			Value for ndlist. Default ""
    
    constructor {refName {value ""}} {
        # Validate reference name
        ::ndlist::ValidateRefName $refName
        next $refName $value
    }
    
    # Uplevel is modified to call ::ndlist::neval, handling object references.
    method Uplevel {level body} {
        next $level [list ::ndlist::neval $body [self]]
    }
    
    # SetValue is modified to validate ND-list rank.
    method SetValue {value} {
        set myRank [::ndlist::GetRank $value]
        next [::ndlist::ndlist $myRank $value]
    }

    # $object rank --
    #
    # Query the number of dimensions of the object. Same as rank.
    
    method GetRank {} {
        return $myRank
    }
    method rank {} {
        my GetRank
    }
    
    # $object shape <$axis> --
    #
    # Get dimensions of ND-array
    #
    # axis      Axis to get dimension along. Default blank for all.
    
    method shape {{axis ""}} {
        if {$axis eq ""} {
            return [my GetShape]
        }
        ::ndlist::ValidateAxis $myRank $axis
        lindex [my GetShape] $axis
    }
    
    # $object size --
    #
    # Get size of ND-array
    
    method size {} {
        ::ndlist::nsize $myRank $myValue
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
        my SetValue [::ndlist::ninsert $myRank $myValue $index $sublist $axis]
    }
    
    # $object apply $command $arg ... --
    #
    # Apply command to values of ND-array, return value.
    #
    # command   Command prefix to apply
    # arg ...   Additional arguments to append to command
    
    method apply {command args} {
        tailcall ::ndlist::napply $myRank $command $myValue {*}$args
    }
     
    # $object reduce $command <$axis> $arg ... --
    #
    # Apply command to axis of ND-array, return value.
    #
    # command   Command prefix to apply
    # arg ...   Additional arguments to append to command
    # axis      Axis to reduce along. Default 0.
    
    method reduce {command {axis 0} args} {
        ::ndlist::nreduce $myRank $command $myValue $axis {*}$args
    }
    
    # $object @ $i ... <$op $arg ...> --
    #
    # Index into the object
    #
    # Arguments:
    # i ...         Index arguments. Must match rank.
    # op arg ...    Index operators, explained below:
    #   = value             Value assignment.
    #   := expr             Expression assignment.
    #   --> varName         Create new object from range.
    #   | method arg ...    Temp object evaluation.
    #   & refName body      Evaluate body with range assigned to ref var.
    
    method @ {args} {
        # Get indices from input
        if {[llength $args] < $myRank} {
            return -code error "wrong # of indices: want $myRank"
        }
        set indices [lrange $args 0 $myRank-1]
        set args [lrange $args $myRank end]
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

    # my GetShape --
    #
    # Get the shape of the ND-list.
    
    method GetShape {} {
        ::ndlist::GetShape $myRank $myValue
    }
    
    # my GetIndexValue --
    #
    # Index into an ND-list object.
    #
    # Arguments:
    # indices       Index inputs
    
    method GetIndexValue {indices} {
        # Interpret input
        if {[llength $indices] != $myRank} {
            return -code error "wrong # of indices: want $myRank"
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
        if {[llength $indices] != $myRank} {
            return -code error "wrong # of indices: want $myRank"
        }
        # Validate input, and call nset.
        set rank [my GetIndexRank $indices]
        ::ndlist::nset myValue {*}$indices [::ndlist::ndlist $rank $value]
        return [self]
    }
    
    # my GetIndexRank $indices --
    #
    # Get rank of index input
    #
    # Arguments:
    # indices       Index inputs
    
    method GetIndexRank {indices} {
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
        if {[llength $indices] != $myRank} {
            return -code error "wrong # of indices: want $myRank"
        }
        # Get new rank and value.
        set value [my GetIndexValue $indices]
        tailcall [self class] new $varName $value
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
        if {[llength $indices] != $myRank} {
            return -code error "wrong # of indices: want $myRank"
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
# References must have matching rank or be scalar.
#
# Syntax:
# neval $body <$self> <$rankVar>
#
# Arguments:
# body          Tcl script, with @ref notation for object references.
# self          Object to refer to with "@.". Default blank.
# rankVar       Variable to store resulting rank in. Default blank.

# Example:
# [narray new x 1D] = {{hello world} {foo bar}}
# neval {string toupper @x}; # {{HELLO WORLD} {FOO BAR}}

proc ::ndlist::neval {body {self ""} {rankVar ""}} {
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
        # Get object rank and value for mapping.
        lappend refRanks [$object rank]
        lappend refValues [$object]
    }
    # Get rank of mapping
    if {$rankVar ne ""} {
        upvar 1 $rankVar rank
    }
    # Choose maximum reference rank
    set rank [expr {[llength $refRanks] == 0 ? 0 : [max $refRanks]}]
    
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
            # Not a scalar (rank > 0)
            lappend varMap ::ndlist::ref($refName.$index) $refValue
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
# nexpr $expr <$self> <$rankVar>
#
# Arguments:
# expr          Math expression, with @ref notation for object references.
# self          Object to refer to with "@.". Default blank.
# rankVar       Variable to store resulting rank in. Default blank.

# Example:
# narray new x {1.0 2.0 3.0}
# narray new y 5.0
# nexpr {@x + @y}; # {6.0 7.0 8.0}

proc ::ndlist::nexpr {expr {self ""} {rankVar ""}} {
    tailcall neval [list expr $expr] $self $rankVar
}
