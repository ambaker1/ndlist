# matrix.tcl
################################################################################
# Utilities for matrices (2D lists)

# Copyright (C) 2025 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Define namespace and exported commands
namespace eval ::ndlist {
    namespace export stack augment block; # Combine matrices
    namespace export transpose eye matmul outerprod kronprod; # Linear algebra
    namespace export zip zip3 cartprod; # Iteration tools
    namespace export mat2txt txt2mat mat2csv csv2mat; # Data conversions
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
    set x [lrepeat $n [lrepeat $n 0]]
    foreach i [range $n] {
        lset x $i $i 1
    }
    return $x
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

# Datatype conversions
################################################################################

# Conform2Matrix --
#
# Expand rows to have the same length (and trims trailing newline)
# Pads short rows with blanks.
#
# Syntax:
# Conform2Matrix $matrix 
#
# Arguments:
# matrix        Nested list to conform into a matrix.

proc ::ndlist::Conform2Matrix {matrix} {
    # Trim trailing newline.
    if {[llength [lindex $matrix end]] == 0} {
        set matrix [lrange $matrix 0 end-1]
    }
    # Get number of columns
    set m 0
    foreach row $matrix {
        if {[llength $row] > $m} {
            set m [llength $row]
        }
    }
    # Expand matrix if needed.
    lmap row $matrix {
        if {[llength $row] < $m} {
            lappend row {*}[lrepeat [expr {$m-[llength $row]}] {}]
        }
        set row
    }
}

# mat2txt --
#
# Convert from matrix to space-delimited text. 
# Note that rows are Tcl lists.
#
# Syntax:
# mat2txt $matrix
#
# Arguments:
# matrix:       Matrix value

proc ::ndlist::mat2txt {matrix} {
    join [Conform2Matrix $matrix] \n
}

# txt2mat --
#
# Convert from space-delimited text to matrix
# Newlines can be escaped inside curly braces
# Ignores blank lines
#
# Syntax:
# txt2mat $text
#
# Arguments:
# text:     Text to convert.

proc ::ndlist::txt2mat {text} {
    set matrix ""
    set row ""
    foreach line [split $text \n] {
        # Add to row, and handle escaped newlines
        append row $line
        if {[string is list $row]} {
            lappend matrix $row
            set row ""
        } else {
            append row \n
        }
    }
    # Validate and return matrix
    return [Conform2Matrix $matrix]
}

# mat2csv --
#
# Convert from matrix to comma-separated values
#
# Arguments:
# matrix:       Matrix to convert

proc ::ndlist::mat2csv {matrix} {
    set csvLines ""
    # Validate matrix and loop through rows
    foreach row [Conform2Matrix $matrix] {
        set csvRow ""
        foreach val $row {
            # Perform escaping if required
            if {[string match "*\[\",\r\n\]*" $val]} {
                set val "\"[string map [list \" \"\"] $val]\""
            }
            lappend csvRow $val
        }
        lappend csvLines [join $csvRow ,]
    }
    return [join $csvLines \n]
}

# csv2mat --
#
# Convert from comma-separated values to matrix
# Ignores blank lines
#
# Syntax:
# csv2mat $csv
#
# Arguments:
# csv:          CSV string to convert

proc ::ndlist::csv2mat {csv} {
    # Initialize variables
    set matrix ""; # Output matrix
    set csvRow ""; # CSV-formatted row of data
    set val ""; # Value in matrix row
    
    # Split csv by newline and loop through lines
    foreach line [split $csv \n] {
        append csvRow $line
        # Check for escaped newline condition
        if {[regexp -all "\"" $csvRow] % 2} {
            # Odd number of quotes
            append csvRow \n
            continue
        }
        # Split csv row by comma and loop through items, creating matrix row
        set row ""; # Matrix row of data
        foreach item [split $csvRow ,] {
            append val $item
            # Check for escaped comma condition
            if {[regexp -all "\"" $val] % 2} {
                # Odd number of quotes
                append val ,
                continue
            }
            # Check if escaped (commas, newlines, or quotes)
            if {[regexp "\"" $val]} {
                # Remove outer escaping quotes
                set val [string range $val 1 end-1]
                # Check for escaped quotes
                if {[regexp "\"" $val]} {
                    # Replace with normal quotes
                    set val [regsub -all "\"\"" $val "\""]
                }
            }
            # Add to row
            lappend row $val
            # Clear val
            set val ""
        }
        # Add to matrix
        lappend matrix $row
        # Clear csv row
        set csvRow ""
    }
    # Validate and return matrix
    return [Conform2Matrix $matrix]
}
