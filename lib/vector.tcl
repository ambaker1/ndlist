# vector.tcl
################################################################################
# Utilities for vectors (1D lists)

# Copyright (C) 2025 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Define namespace and exported commands
namespace eval ::ndlist {
    namespace export range find; # List indexing utilities
    namespace export linspace linsteps linterp; # List generation
    namespace export lapply lapply2; # Functional mapping
    namespace export max min sum product mean median stdev pstdev; # Stats
    namespace export dot cross norm; # Vector algebra
}

# List indexing
################################################################################

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
    lsearch -exact -integer -all [lapply ::tcl::mathop::$op $list $value] 1
}

# List generation
################################################################################

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
# linsteps $stepSize $targets
# 
# Arguments:
# stepSize      Magnitude of step size (must be > 0.0)
# target        Targets to walk through (length > 0)

proc ::ndlist::linsteps {stepSize targets} {
    # Interpret inputs and coerce into double (throws error if not double)
    set stepSize [expr {double($stepSize)}]
    if {$stepSize <= 0.0} {
        return -code error "Step size must be > 0.0"
    }
    if {[llength $targets] == 0} {
        return -code error "target list must be at least length 1"
    }
    set targets [lmap target $targets {expr {double($target)}}]
    set targets [lassign $targets start]
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
    expr {$r*($y2-$y1)+$y1}
}

# Functional mapping
################################################################################

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

# List statistics
################################################################################

# max --
# 
# Maximum value
#
# Syntax:
# max $list
# 
# Arguments:
# list          List of values (length > 0)

proc ::ndlist::max {list} {
    if {[llength $list] == 0} {
        return -code error "max requires at least one value"
    }
    foreach value [lassign $list max] {
        if {![string is double -strict $value]} {
            return -code error "expected number but got \"$value\""
        }
        if {$value > $max} {
            set max $value
        }
    }
    return $max
}

# min --
# 
# Minimum value 
#
# Syntax:
# min $list
# 
# Arguments:
# list          List of values (length > 0)

proc ::ndlist::min {list} {
    if {[llength $list] == 0} {
        return -code error "min requires at least one value"
    }
    foreach value [lassign $list min] {
        if {![string is double -strict $value]} {
            return -code error "expected number but got \"$value\""
        }
        if {$value < $min} {
            set min $value
        }
    }
    return $min
}

# sum --
# 
# Sum of values
#
# Syntax:
# sum $list
# 
# Arguments:
# list          List of values (length > 0)

proc ::ndlist::sum {list} {
    if {[llength $list] == 0} {
        return -code error "sum requires at least one value"
    }
    foreach value [lassign $list sum] {
        set sum [expr {$sum + $value}]
    }
    return $sum
}

# product --
# 
# Product of values
#
# Syntax:
# product $list
# 
# Arguments:
# list          List of values (length > 0)

proc ::ndlist::product {list} {
    if {[llength $list] == 0} {
        return -code error "product requires at least one value"
    }
    foreach value [lassign $list product] {
        set product [expr {$product * $value}]
    }
    return $product
}

# mean --
# 
# Mean value
#
# Syntax:
# mean $list
# 
# Arguments:
# list         List of values (length > 0)

proc ::ndlist::mean {list} {
    if {[llength $list] == 0} {
        return -code error "mean requires at least one value"
    }
    expr {double([sum $list])/[llength $list]}
}

# median --
# 
# Median value (sorts, then takes middle values)
#
# Syntax:
# median $list
# 
# Arguments:
# list          List of values (length > 0)

proc ::ndlist::median {list} {
    set n [llength $list]
    if {$n == 0} {
        return -code error "median requires at least one value"
    }
    set sorted [lsort -real $list]
    if {$n%2 == 1} {
        set i [expr {($n-1)/2}]
        set median [lindex $sorted $i]
    } else {
        set i [expr {$n/2}]
        set j [expr {$n/2 - 1}]
        set median [expr {([lindex $sorted $i] + [lindex $sorted $j])/2.0}]
    }; # end if
    return $median
}

# stdev -- 
#
# Sample standard deviation
#
# Syntax:
# stdev $list
# 
# Arguments:
# list      List of values (length > 1)

proc ::ndlist::stdev {list} {
    if {[llength $list] < 2} {
        return -code error "stdev requires at least two values"
    }
    # Variance function checks list length 
    expr {sqrt([Variance $list 0])}
}

# pstdev -- 
#
# Population standard deviation
#
# Syntax:
# pstdev $list
# 
# Arguments:
# list      List of values (length > 0)

proc ::ndlist::pstdev {list} {
    if {[llength $list] == 0} {
        return -code error "pstdev requires at least one value"
    }
    # Variance function checks list length 
    expr {sqrt([Variance $list 1])}
}

# Variance -- 
#
# Sample or population variance
#
# Syntax:
# Variance $list $pop
# 
# Arguments:
# list      List of values (length > 0 or 1)
# pop       Whether to compute population variance.

proc ::ndlist::Variance {list pop} {
    # Check list length
    set n [llength $list]
    set pop [expr {bool($pop)}]
    # Perform variance calculation
    set mean [mean $list]
    set squares [lmap x $list {expr {($x - $mean)**2}}]
    expr {double([sum $squares])/($n + $pop - 1)}
}

# Vector algebra
################################################################################

# dot --
#
# Dot product of two vectors.
#
# Syntax:
# dot $a $b
#
# Arguments:
# a b           Vectors, same length (length > 0)

proc ::ndlist::dot {a b} {
    # Check dimensions
    if {[llength $a] != [llength $b]} {
        return -code error "incompatible vector lengths"
    }
    sum [lmap ai $a bi $b {expr {$ai * $bi}}]
}

# cross --
# 
# Cross product of two 3D vectors
#
# Syntax:
# cross $a $b
#
# Arguments:
# a b        Vectors, length 3

proc ::ndlist::cross {a b} {
    # Check dimensions
    if {[llength $a] != 3 || [llength $b] != 3} {
        return -code error "cross-product only defined for 3D vectors"
    }
    lassign $a a1 a2 a3
    lassign $b b1 b2 b3
    set c1 [expr {$a2*$b3 - $a3*$b2}]
    set c2 [expr {$a3*$b1 - $a1*$b3}]
    set c3 [expr {$a1*$b2 - $a2*$b1}]
    list $c1 $c2 $c3
}

# norm --
# 
# Norm of vector (returns double)
#
# Arguments:
# vector        Vector
# p             Norm type. Default 2 (euclidean distance).

proc ::ndlist::norm {vector {p 2}} {
    switch $p {
        1 { # Sum of absolute values
            sum [lmap value $vector {expr {abs($value)}}]
        }
        2 { # Euclidean (use hypot function to avoid overflow)
            set norm 0.0
            foreach value $vector {
                set norm [expr {hypot($value,$norm)}]
            }
            return $norm
        }
        Inf { # Absolute maximum of the vector
            max [lmap value $vector {expr {abs($value)}}]
        }
        default { # Arbitrary integer norm
            if {![string is integer -strict $p] || $p <= 0} {
                return -code error "p must be integer > 0"
            }
            expr {pow([sum [lmap x $vector {expr {$x ** $p}}]],1.0/$p)}
        }
    }
}
