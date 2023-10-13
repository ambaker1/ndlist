# ltools.tcl
################################################################################
# List utilities 

# Copyright (C) 2023 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Define namespace and exported commands
namespace eval ::ndlist {
    namespace export range find; # List indexing utilities
    namespace export linspace linsteps linterp; # List generation
    namespace export lapply lapply2 lop lop2 lexpr; # Functional mapping
}

# range --
#
# Utility to generate integer range for indexing lists.
# 
# range $n
# range $start $stop <$step>
#
# Arguments:
# n         Number of integers
# start     Start of resultant range.
# stop      End limit of resultant range.
# step      Step size. Default 1 or -1, depending on direction.

proc ::ndlist::range {args} {
    # Switch for arity
    if {[llength $args] == 1} {
        # range $n
        return [lsearch -all [lrepeat [lindex $args 0] {}] *]
    } elseif {[llength $args] == 0 || [llength $args] > 3} {
        return -code error "wrong # args: should be\
                \"range n\", \"range start stop\", or \"range start stop step\""
    } 
    # General case (stepped range)
    # range $start $stop <$step>
    lassign $args start stop step
    # Auto-step
    if {$step eq ""} {
        set step [expr {$stop > $start ? 1 : -1}]
    }
    # Validate integer input
    foreach value [list $start $stop $step] {
        if {![string is integer -strict $value]} {
            return -code error "expected integer but got \"$value\""
        }
    }
    # Avoid dividing by zero
    if {$step == 0} {
        return
    }
    # Get range length
    set n [expr {($stop - $start)/$step + 1}]
    # Basic cases
    if {$n <= 0} {
        return
    }
    if {$n == 1} {
        return $start
    }
    # General case (generate list)
    set i [expr {$start - $step}]
    lmap x [lrepeat $n {}] {incr i $step}
}

# find --
#
# Get list of all non-zero elements for indexing lists.
# Converts list to boolean, then performs lsearch to get all indices.
#
# Syntax:
# find $list <$op $value>
#
# Arguments:
# list          List to search for non-zero elements.
# op            Comparison operator. Default !=
# value         Value to compare with. Default 0

proc ::ndlist::find {list args} {
    # Switch for arity and interpret input
    if {[llength $args] == 0} {
        # find $list
        set op !=
        set value 0
    } elseif {[llength $args] == 2} {
        # find $list $op $value
        lassign $args op value
        # Check comparison operator
        if {$op ni {!= == <= >= < > eq ne in ni}} {
            return -code error "expected comparison operator, got \"$op\""
        }
    } else {
        return -code error "wrong # args: should be\
                \"find list ?op value?\""
    }
    # Perform search.
    lsearch -exact -all [lop $list $op $value] 1
}

# linspace --
#
# Generate equally spaced list with specific number of points
#
# Syntax:
# linspace $n $start $stop
#
# Arguments:
# n         Number of points
# start     First number 
# stop      Last number

proc ::ndlist::linspace {n start stop} {
    set start [expr {double($start)}]
    set stop [expr {double($stop)}]
    set gap [expr {$stop - $start}]
    set values ""
    for {set i 0} {$i < $n} {incr i} {
        lappend values [expr {$start + $gap*$i/($n - 1.0)}]
    }
    return $values
}

# linsteps --
# 
# Generate list that walks between targets, with a maximum step size.
#
# Syntax:
# linsteps $stepSize $start $target ...
# 
# Arguments:
# stepSize      Magnitude of step size (must be > 0.0)
# start         Starting value
# target ...    Targets to walk through

proc ::ndlist::linsteps {stepSize start args} {
    # Interpret inputs and coerce into double (throws error if not double)
    set stepSize [expr {double($stepSize)}]
    if {$stepSize <= 0.0} {
        return -code error "Step size must be > 0.0"
    }
    set start [expr {double($start)}]
    set targets [lmap target $args {expr {double($target)}}]
    # Initialize with start
    set values [list $start]
    # Loop through targets
    foreach target $targets {
        set gap [expr {$target - $start}]
        # Skip for duplicates
        if {$gap == 0} {
            continue
        }
        # Calculate step value and number of steps
        set step [expr {$gap > 0 ? $stepSize : -$stepSize}]; 
        set n [expr {int($gap/$step)}]
        for {set i 1} {$i <= $n} {incr i} {
            lappend values [expr {$start + $i*$step}]
        }
        # For the case where it doesn't go all the way
        if {[lindex $values end] != $target} {
            lappend values $target
        }
        # Reset for next target (if any)
        set start $target
    }
    return $values
}

# linterp --
# 
# Simple linear interpolation, assuming ascending order on xList
#
# Syntax:
# linterp $x $xList $yList
#
# Arguments:
# x         x value to query
# xList     x points (must be strictly increasing)
# yList     y points (same length as xList)

proc ::ndlist::linterp {x xList yList} {
    # Error check size of input
    if {[llength $xList] != [llength $yList]} {
        return -code error "mismatched list lengths"
    }
    # Check bounds
    if {$x < [lindex $xList 0]} {
        return -code error "out of range: below min"
    }
    if {$x > [lindex $xList end]} {
        return -code error "out of range: above max"
    }
    # Perform search
    set i [lsearch -sorted -real -bisect $xList $x]
    # Get bounding points
    set x1 [lindex $xList $i]
    set y1 [lindex $yList $i]
    set x2 [lindex $xList $i+1]
    set y2 [lindex $yList $i+1]
    # Edge cases
    if {$x == $x1} {
        return [expr {double($y1)}]
    }
    if {$x == $x2} {
        return [expr {double($y2)}]
    }
    # Straight-line interpolation
    set r [expr {double($x-$x1)/($x2-$x1)}]
    return [expr {$r*($y2-$y1)+$y1}]
}

# lapply --
#
# Apply a simple command over one list.
#
# Syntax:
# lapply $command $list $arg ...
#
# Arguments:
# command       Command to map over list
# list          List to map over
# arg ...       Additional arguments

proc ::ndlist::lapply {command list args} {
    lmap value $list {
        uplevel 1 [linsert $command end $value {*}$args]
    }
}

# lapply2 --
#
# Apply a simple command over two lists.
#
# Syntax:
# lapply2 $command $list1 $list2 $arg ...
#
# Arguments:
# command       Command to map over list
# list          List to map over
# arg ...       Additional arguments

proc ::ndlist::lapply2 {command list1 list2 args} {
    if {[llength $list1] != [llength $list2]} {
        return -code error "mismatched list lengths"
    }
    lmap value1 $list1 value2 $list2 {
        uplevel 1 [linsert $command end $value1 $value2 {*}$args]
    }
}

# lop --
#
# Math operations over a list, using lmap.
#
# Syntax:
# lop $list $op $arg ...
#
# Arguments:
# list          List to map over
# op            Math operator (see ::tcl::mathop namespace)
# arg ...       Additional arguments

proc ::ndlist::lop {list op args} {
    lmap value $list {
        ::tcl::mathop::$op $value {*}$args
    }
}

# lop2 --
#
# Math operations over two lists, using lmap.
# List lengths must be equal.
#
# Syntax:
# lop2 $list1 $op $list2 $arg ...
#
# Arguments:
# list1 list2   Lists to map over
# op            Math operator (see ::tcl::mathop namespace)
# arg ...       Additional arguments

proc ::ndlist::lop2 {list1 op list2 args} {
    if {[llength $list1] != [llength $list2]} {
        return -code error "mismatched list lengths"
    }
    lmap value1 $list1 value2 $list2 {
        ::tcl::mathop::$op $value1 $value2 {*}$args
    }
}

# lexpr --
#
# lmap, but with expr. Follows all rules of lmap.
#
# Syntax:
# lexpr $varList $list <$varList $list ...> $expr
#
# Arguments:
# varName ...   List(s) of variables to map with
# list ...      List(s) to map over.
# expr          Tcl math expression to evaluate.

proc ::ndlist::lexpr {args} {
    # Check arity
    if {[llength $args] == 1 || [llength $args] % 2 == 0} {
        return -code error "wrong # args: should be\
                \"lexpr varList list ?varList list ...? expr"
    }
    # Interpret input
    set varMap [lrange $args 0 end-1]
    set expr [lindex $args end]
    # Call modified lmap
    tailcall lmap {*}$varMap [list expr $expr]
}
