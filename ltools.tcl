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
# Utility to generate integer range, great for use with foreach or lmap.
# 
# range $n
# range $start $stop
# range $start $stop $step
#
# Arguments:
# n         Number of integers
# start     Start of resultant range.
# stop      End limit of resultant range.
# step      Step size. Default 1 or -1, depending on direction.

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
    # Compute range
    # Avoid divide by zero
    if {$step == 0} {
        return ""
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
# Get indices of all non-zero elements
#
# Syntax:
# find $list
#
# Arguments:
# list          List to search for non-zero elements.

proc ::ndlist::find {list} {
    set i 0
    set indices ""
    foreach value $list {
        if {$value != 0} {
            lappend indices $i
        }
        incr i
    }
    return $indices
}

# linspace --
#
# Generate equally spaced list with specific number of points
#
# Syntax:
# linspace $n $x1 $x2
#
# Arguments:
# n         Number of points
# x1        First number 
# x2        Last number

proc ::ndlist::linspace {n x1 x2} {
    set x1 [expr {double($x1)}]
    set x2 [expr {double($x2)}]
    set gap [expr {$x2 - $x1}]
    set values ""
    for {set i 0} {$i < $n} {incr i} {
        lappend values [expr {$x1 + $gap*$i/($n - 1.0)}]
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
# Simple linear interpolation, assuming ascending order on list xp
#
# Syntax:
# linterp $xq $xp $yp
#
# Arguments:
# xq            x value to query
# xp            x points (must be strictly increasing)
# yp            y points (same length as xp)

proc ::ndlist::linterp {xq xp yp} {
    # Error check size of input
    if {[llength $xp] != [llength $yp]} {
        return -code error "xp and yp must be same size"
    }
    # Check bounds
    if {$xq < [lindex $xp 0]} {
        return -code error "xq value $x below bounds of xp"
    }
    if {$xq > [lindex $xp end]} {
        return -code error "xq value $x above bounds of xp"
    }
    # Perform search
    set i [lsearch -sorted -real -bisect $xp $xq]
    # Get bounding points
    set x1 [lindex $xp $i]
    set y1 [lindex $yp $i]
    set x2 [lindex $xp $i+1]
    set y2 [lindex $yp $i+1]
    # Edge cases
    if {$xq == $x1} {
        return [expr {double($y1)}]
    }
    if {$xq == $x2} {
        return [expr {double($y2)}]
    }
    # Straight-line interpolation
    set r [expr {double($xq-$x1)/($x2-$x1)}]
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
        eval [linsert $command end $value {*}$args]
    }
}

# lapply2 --
#
# Apply a simple command over multiple lists.
#
# Syntax:
# lapply $command $list1 $list2 $arg ...
#
# Arguments:
# command       Command to map over list
# list          List to map over
# arg ...       Additional arguments

proc ::ndlist::lapply2 {command list1 list2 args} {
    lmap value1 $list1 value2 $list2 {
        eval [linsert $command end $value1 $value2 {*}$args]
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
# Math operations over multiple lists, using lmap.
#
# Syntax:
# lop $list1 $op $list2 $arg ...
#
# Arguments:
# list1 list2   Lists to map over
# op            Math operator (see ::tcl::mathop namespace)
# arg ...       Additional arguments

proc ::ndlist::lop2 {list1 op list2 args} {
    lmap value1 $list1 value2 $list2 {
        ::tcl::mathop::$op $value1 $value2 {*}$args
    }
}

# lexpr --
#
# lmap, but with expr.
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