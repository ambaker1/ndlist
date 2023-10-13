# linalg.tcl
################################################################################
# Basic linear algebra routines
# Adapted from similar routines in math::linearalgebra package

# Copyright (C) 2023 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Define namespace and exported commands
namespace eval ::ndlist {
    namespace export dot cross norm; # Vector algebra
    namespace export eye matmul transpose; # Matrix algebra
}

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
    return [list $c1 $c2 $c3]
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
            return [sum [lexpr value $vector {abs($value)}]]
        }
        2 { # Euclidean (use hypot function to avoid overflow)
            set norm 0.0
            foreach value $vector {
                set norm [expr {hypot($value,$norm)}]
            }
            return $norm
        }
        Inf { # Absolute maximum of the vector
            return [max [lexpr value $vector {abs($value)}]]
        }
        default { # Arbitrary integer norm
            if {![string is integer -strict $p] || $p <= 0} {
                return -code error "p must be integer > 0"
            }
            return [expr {pow([sum [lop $vector ** $p]],1.0/$p)}]
        }
    }
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
# Adapted from math::linearalgebra::transpose and lsearch example on Tcl wiki
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
# Multiplies two matrices. Must agree in dimension.
# Returns a nxm matrix, by computing the dot-product of rows and columns
# 
# Syntax:
# matmul $A $B
#
# Arguments:
# A B           Matrices, matching inner dimensions

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
