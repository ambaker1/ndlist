# matrix.tcl
################################################################################
# Utilities for matrices (2D lists)

# Copyright (C) 2023 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Define namespace and exported commands
namespace eval ::ndlist {
    namespace export eye matmul transpose; # Matrix algebra
    namespace export zip zip3 cartprod; # Iteration tools (e.g. tuples)
}

# eye --
# 
# Generate an identity matrix of specified size
#
# Syntax:
# eye $n
# 
# Arguments:
# n             Size of matrix (nxn)

proc ::ndlist::eye {n} {
    set x [nfull 0 $n $n]
    foreach i [range $n] {
        lset x $i $i 1
    }
    return $x
}

# transpose --
# 
# Transpose a matrix
# Similar to math::linearalgebra::transpose and lsearch example on Tcl wiki
# written by MJ (https://wiki.tcl-lang.org/page/Transposing+a+matrix)
# 
# Arguments:
# matrix:           Matrix to transpose

proc ::ndlist::transpose {matrix} {
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

# matmul --
#
# Multiplies two matrices. Inner dimensions must agree.
# Similar to math::linearalgebra::matmul. 
# Returns a nxm matrix, by computing the dot-product of rows and columns
# 
# Syntax:
# matmul $A $B
#
# Arguments:
# A B           Matrices, matching inner dimensions (e.g. nxq and qxm)

proc ::ndlist::matmul {A B} {
    # Check dimensions
    if {[llength [lindex $A 0]] != [llength $B]} {
        return -code error "incompatible matrix dimensions"
    }
    # Transpose B matrix for easy multiplication
    set BT [transpose $B]
    # Perform dot-product of all rows and columns
    lmap rowA $A {
        lmap colB $BT {
            dot $rowA $colB
        }
    }
}

# zip --
#
# Zip vectors (equal length) into a tuple list
#
# Syntax:
# zip $a $b ...
#
# Arguments:
# a b       Vectors (equal length)

proc ::ndlist::zip {a b} {
    if {[llength $a] != [llength $b]} {
        return -code error "mismatched list lengths"
    }
    lmap ai $a bi $b {
        list $ai $bi
    }
}

# zip3 --
#
# Zip three vectors (equal length) into a triple
#
# Syntax:
# zip3 $a $b $c
#
# Arguments:
# a b c     Vectors (equal length)

proc ::ndlist::zip3 {a b c} {
    if {[llength $a] != [llength $b] || [llength $a] != [llength $c]} {
        return -code error "mismatched list lengths"
    }
    lmap ai $a bi $b ci $c {
        list $ai $bi $ci
    }
}

# cartprod --
# 
# Cartesian product of multiple vectors (can have duplicates)
# Returns a list of all combinations
# Modified from "cartesianNaryProduct", accessed on 12/15/2021 at 
# https://rosettacode.org/wiki/Cartesian_product_of_two_or_more_lists
#
# Syntax:
# cartprod $arg ...
#
# Arguments:
# arg ...       Vectors to take "cartesian product" of

proc ::ndlist::cartprod {args} {
    foreach vector [lassign $args matrix] { 
        set newMatrix {}
        foreach row $matrix {
            foreach value $vector {
                lappend newMatrix [linsert $row end $value]
            }
        }
        set matrix $newMatrix
    }
    return $matrix
}
