# stat.tcl
################################################################################
# Basic list statistics

# Copyright (C) 2023 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Define namespace
namespace eval ::ndlist {
    # Exported commands
    namespace export max min; # Extreme values
    namespace export sum product; # Sum or product
    namespace export mean median; # Average statistics
    namespace export stdev variance; # Variance statistics 
}

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
    return [expr {double([sum $list])/[llength $list]}]
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
# Sample or population standard deviation (sqrt of variance)
#
# Syntax:
# stdev $list <$pop>
# 
# Arguments:
# list      List of values (length > 0 or 1)
# pop       Whether to compute population standard deviation (default 0)

proc ::ndlist::stdev {list {pop 0}} {
    # Variance function checks list length 
    expr {sqrt([variance $list $pop])}
}

# variance -- 
#
# Sample or population variance
#
# Syntax:
# variance $list <$pop>
# 
# Arguments:
# list      List of values (length > 0 or 1)
# pop       Whether to compute population variance (default 0)

proc ::ndlist::variance {list {pop 0}} {
    # Check list length
    set n [llength $list]
    set pop [expr {bool($pop)}]
    if {$pop && $n == 0} {
        return -code error "population variance requires at least 1 value"
    }
    if {!$pop && $n < 2} {
        return -code error "sample variance requires at least 2 values"
    }
    # Perform variance calculation
    set mean [mean $list]
    set squares [lmap x $list {expr {($x - $mean)**2}}]
    return [expr {double([sum $squares])/($n + $pop - 1)}]
}
