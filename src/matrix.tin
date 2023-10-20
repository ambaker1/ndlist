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
    namespace export zeros ones eye; # Generate matrices
    namespace export stack augment block; # Combine matrices
    namespace export transpose matmul outerprod kronprod; # Linear algebra
    namespace export zip zip3 cartprod; # Iteration tools
}

# zeros --
# 
# Generate a matrix filled with zeros.
#
# Syntax:
# zeros $n $m
# 
# Arguments:
# n             Number of rows
# m             Number of columns

proc ::ndlist::zeros {n m} {
    if {$m == 0} {return}
    lrepeat $n [lrepeat $m 0]
}

# ones --
#
# Generate a matrix filled with ones.
#
# Syntax:
# ones $n $m
# 
# Arguments:
# n             Number of rows
# m             Number of columns

proc ::ndlist::ones {n m} {
    if {$m == 0} {return}
    lrepeat $n [lrepeat $m 1]
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
    set x [zeros $n $n]
    foreach i [range $n] {
        lset x $i $i 1
    }
    return $x
}

# stack --
# 
# Combines matrices (row-wise)
#
# Syntax:
# stack $mat1 $mat2 ...
# 
# Arguments:
# $mat1 $mat2 ...       Arbitrary number of matrices

proc ::ndlist::stack {args} {
    set Matrix [lindex $args 0]
    set M [llength [lindex $Matrix 0]]
    foreach matrix [lrange $args 1 end] {
        set m [llength [lindex $matrix 0]]
        if {$m != $M} {
            return -code error "incompatible number of columns"
        }
        set Matrix [concat $Matrix $matrix]
    }
    return $Matrix
}

# augment --
# 
# Combines matrices (column-wise)
#
# Syntax:
# augment $mat1 $mat2 ...
# 
# Arguments:
# mat1 mat2 ...         Arbitrary number of matrices

proc ::ndlist::augment {args} {
    set Matrix [lindex $args 0]
    set N [llength $Matrix]
    foreach matrix [lrange $args 1 end] {
        set n [llength $matrix]
        if {$n != $N} {
            return -code error "incompatible number of rows"
        }
        set Matrix [lmap Row $Matrix row $matrix {concat $Row $row}]
    }
    return $Matrix
}

# block --
#
# Combine a matrix of matrices
#
# Syntax:
# block $matrices
#
# Arguments:
# matrices          Matrix of matrices

proc ::ndlist::block {matrices} {
    stack {*}[lmap row $matrices {augment {*}$row}]
}

# transpose --
# 
# Transpose a matrix
# Similar to math::linearalgebra::transpose and lsearch example on Tcl wiki
# written by MJ (https://wiki.tcl-lang.org/page/Transposing+a+matrix)
#
# Syntax:
# transpose $matrix
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
        return -code error "incompatible inner matrix dimensions"
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

# outerprod --
#
# Outer product of two vectors
# [ a1 a2 ] x [ b1 b2 b3 ] = [ a1b1 a1b2 a1b3 ]
#                            [ a2b1 a2b2 a2b3 ]
# Syntax: 
# outerprod $a $b
#
# Arguments:
# a b       Vectors (equal length) to take outer product of.

proc ::ndlist::outerprod {a b} {
    matmul $a [list $b]
}

# kronprod --
#
# Kronecker product of two matrices (vector spaces)
# Example:
# 
# [ a11 a12 ]                   [ a11b11 a11b12 a12b11 a12b12]
# [ a21 a22 ] (x) [ b11 b12 ] = [ a21b11 a21b12 a22b11 a22b12]
#
# Syntax: 
# kronprod $A $B
#
# Arguments:
# A B       Vector spaces to take Kronecker product of.

proc ::ndlist::kronprod {A B} {
    block [lmap rowA $A {lmap valueA $rowA {lmap rowB $B {lmap valueB $rowB {
        expr {$valueA * $valueB}
    }}}}]
}

# zip --
#
# Zip vectors (equal length) into a tuple list
# To unzip, use lassign and transpose.
# lassign [transpose $tuples] a b
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
# To unzip, use lassign and transpose.
# lassign [transpose $triples] a b c
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
