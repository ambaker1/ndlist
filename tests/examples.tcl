# Documentation examples

test {Installing and loading ``ndlist''} Example -body {
puts {}
package require tin
tin add -auto ndlist https://github.com/ambaker1/ndlist install.tcl
tin import ndlist
puts -nonewline {}
} -output {
}

test {Integer range generation} Example -body {
puts {}
puts [range 3]
puts [range 0 2]
puts [range 10 3 -2]
puts -nonewline {}
} -output {
0 1 2
0 1 2
10 8 6 4
}

test {Simpler for-loop} Example -body {
puts {}
foreach i [range 3] {
    puts $i
}
puts -nonewline {}
} -output {
0
1
2
}

test {Filtering a list} Example -body {
puts {}
set numbers [range 10]
set odds [lexpr x $numbers {$x % 2 ? $x : [continue]}]; # only odd numbers
puts $odds
puts -nonewline {}
} -output {
1 3 5 7 9
}

test {Linear interpolation} Example -body {
puts {}
puts [linterp 2 {1 2 3} {4 5 6}]
puts [linterp 8.2 {0 10 20} {2 -4 5}]
puts -nonewline {}
} -output {
5.0
-2.92
}

test {Linearly spaced vector generation} Example -body {
puts {}
puts [linspace 5 0 1]
puts -nonewline {}
} -output {
0.0 0.25 0.5 0.75 1.0
}

test {Intermediate value vector generation} Example -body {
puts {}
puts [linsteps 0.25 0 1 0]
puts -nonewline {}
} -output {
0.0 0.25 0.5 0.75 1.0 0.75 0.5 0.25 0.0
}

test {Applying a math function to a list} Example -body {
puts {}
# Add Tcl math functions to the current namespace path
namespace path [concat [namespace path] ::tcl::mathfunc]
puts [lapply abs {-5 1 2 -2}]
puts -nonewline {}
} -output {
5 1 2 2
}

test {Mapping over two lists} Example -body {
puts {}
lapply puts [lapply2 {format "%s %s"} {hello goodbye} {world moon}]
puts -nonewline {}
} -output {
hello world
goodbye moon
}

test {Adding two lists together} Example -body {
puts {}
puts [lop2 {1 2 3} + {2 3 2}]
puts -nonewline {}
} -output {
3 5 5
}

test {Adding three lists together} Example -body {
puts {}
set x {1 2 3}
set y {2 9 2}
set z {5 -2 0}
puts [lexpr xi $x yi $y zi $z {$xi + $yi + $zi}]
puts -nonewline {}
} -output {
8 9 5
}

test {List Statistics} Example -body {
puts {}
set list {-5 3 4 0}
foreach stat {max min sum product mean median variance stdev} {
    puts [list $stat [$stat $list]]
}
puts -nonewline {}
} -output {
max 4
min -5
sum 2
product 0
mean 0.5
median 1.5
variance 16.333333333333332
stdev 4.041451884327381
}

test {Dot and cross product} Example -body {
puts {}
set x {1 2 3}
set y {-2 -4 6}
puts [dot $x $y]
puts [cross $x $y]
puts -nonewline {}
} -output {
8
24 -12 0
}

test {Normalizing a vector} Example -body {
puts {}
set x {3 4}
set x [lop $x / [norm $x]]
puts $x
puts -nonewline {}
} -output {
0.6 0.8
}

test {Matrices and vectors} Example -body {
puts {}
set A {{2 5 1 3} {4 1 7 9} {6 8 3 2} {7 8 1 4}}
set B {9 3 0 -3}
set C {{3 7 -5 -2}}
puts -nonewline {}
} -output {
}

test {Generating an identity matrix} Example -body {
puts {}
puts [eye 3]
puts -nonewline {}
} -output {
{1 0 0} {0 1 0} {0 0 1}
}

test {Transposing a matrix} Example -body {
puts {}
puts [transpose {{1 2} {3 4}}]
puts -nonewline {}
} -output {
{1 3} {2 4}
}

test {Multiplying a matrix} Example -body {
puts {}
puts [matmul {{2 5 1 3} {4 1 7 9} {6 8 3 2} {7 8 1 4}} {9 3 0 -3}]
puts -nonewline {}
} -output {
24 12 72 75
}

test {Zipping lists} Example -body {
puts {}
puts [zip {A B C} {1 2 3}]
puts [zip3 {Do Re Mi} {A B C} {1 2 3}]
puts -nonewline {}
} -output {
{A 1} {B 2} {C 3}
{Do A 1} {Re B 2} {Mi C 3}
}

test {Cartesian product} Example -body {
puts {}
puts [cartprod {A B C} {1 2 3}]
puts -nonewline {}
} -output {
{A 1} {A 2} {A 3} {B 1} {B 2} {B 3} {C 1} {C 2} {C 3}
}

test {Getting shape and size of an ND-list} Example -body {
puts {}
set A [ndlist 2D {{1 2 3} {4 5 6}}]
puts [nshape 2D $A]
puts [nsize 2D $A]
puts -nonewline {}
} -output {
2 3
6
}

test {Generate ND-list filled with one value} Example -body {
puts {}
puts [nfull foo 3 2]; # 3x2 matrix filled with "foo"
puts [nfull 0 2 2 2]; # 2x2x2 tensor filled with zeros
puts -nonewline {}
} -output {
{foo foo} {foo foo} {foo foo}
{{0 0} {0 0}} {{0 0} {0 0}}
}

test {Generate random matrix} Example -body {
puts {}
expr {srand(0)}; # resets the random number seed (for the example)
puts [nrand 1 2]; # 1x2 matrix filled with random numbers
puts -nonewline {}
} -output {
{0.013469574513598146 0.3831388500440581}
}

test {Repeat elements of a matrix} Example -body {
puts {}
puts [nrepeat {{1 2} {3 4}} 1 2]
puts -nonewline {}
} -output {
{1 2 1 2} {3 4 3 4}
}

test {Expand an ND-list to new dimensions} Example -body {
puts {}
puts [nexpand {1 2 3} 3 2]
puts [nexpand {{1 2}} 2 4]
puts -nonewline {}
} -output {
{1 1} {2 2} {3 3}
{1 2 1 2} {1 2 1 2}
}

test {Reshape a vector to a matrix} Example -body {
puts {}
puts [nreshape {1 2 3 4 5 6} 2 3]
puts -nonewline {}
} -output {
{1 2 3} {4 5 6}
}

test {Reshape a matrix to a 3D tensor} Example -body {
puts {}
set x [nflatten 2D {{1 2 3 4} {5 6 7 8}}]
puts [nreshape $x 2 2 2]
puts -nonewline {}
} -output {
{{1 2} {3 4}} {{5 6} {7 8}}
}

test {Index Notation} Example -body {
puts {}
set n 10
puts [::ndlist::ParseIndex $n *]
puts [::ndlist::ParseIndex $n 1:8]
puts [::ndlist::ParseIndex $n 0:2:6]
puts [::ndlist::ParseIndex $n {0 5 end-1}]
puts [::ndlist::ParseIndex $n end.]
puts -nonewline {}
} -output {
A {}
R {1 8}
L {0 2 4 6}
L {0 5 8}
S 9
}

test {ND-list access} Example -body {
puts {}
set A {{1 2 3} {4 5 6} {7 8 9}}
puts [nget $A 0 *]; # get row matrix
puts [nget $A 0. *]; # flatten row matrix to a vector
puts [nget $A 0:1 0:1]; # get matrix subset
puts [nget $A end:0 end:0]; # can have reverse ranges
puts [nget $A {0 0 0} 1.]; # can repeat indices
puts -nonewline {}
} -output {
{1 2 3}
1 2 3
{1 2} {4 5}
{9 8 7} {6 5 4} {3 2 1}
2 2 2
}

test {Swapping rows in a matrix} Example -body {
puts {}
# ND-list Value Modification
set a {{1 2} {3 4} {5 6}}
nset a {1 0} * [nget $a {0 1} *]; # Swap rows and columns (modify by reference)
puts $a
puts -nonewline {}
} -output {
{3 4} {1 2} {5 6}
}

test {Deleting a column from a matrix} Example -body {
puts {}
set a {{1 2 3} {4 5 6} {7 8 9}}
puts [nremove $a 2 1]; # Delete column 2
puts -nonewline {}
} -output {
{1 2} {4 5} {7 8}
}

test {Removing list elements that satisfy criteria} Example -body {
puts {}
set x [range 10]
puts [nremove $x [find $x > 4]]
puts -nonewline {}
} -output {
0 1 2 3 4
}

test {Inserting a column into a matrix} Example -body {
puts {}
set matrix {{1 2} {3 4} {5 6}}
set column {A B C}
puts [ninsert 2D $matrix 1 $column 1]
puts -nonewline {}
} -output {
{1 A 2} {3 B 4} {5 C 6}
}

test {Concatenate tensors} Example -body {
puts {}
set x [nreshape {1 2 3 4 5 6 7 8 9} 3 3 1]
set y [nreshape {A B C D E F G H I} 3 3 1]
puts [nstack 3D $x $y 2]
puts -nonewline {}
} -output {
{{1 A} {2 B} {3 C}} {{4 D} {5 E} {6 F}} {{7 G} {8 H} {9 I}}
}

test {Changing tensor axes} Example -body {
puts {}
set x {{{1 2} {3 4}} {{5 6} {7 8}}}
set y [nswapaxes $x 0 2]
set z [nmoveaxis $x 0 2]
puts [lindex $x 0 0 1]
puts [lindex $y 1 0 0]
puts [lindex $z 0 1 0]
puts -nonewline {}
} -output {
2
2
2
}

test {Chained functional mapping over a matrix} Example -body {
puts {}
napply 2D puts [napply 2D {format %.2f} [napply 2D expr {{1 2} {3 4}} + 1]]
puts -nonewline {}
} -output {
2.00
3.00
4.00
5.00
}

test {Element-wise operations} Example -body {
puts {}
puts [nop 1D {1 2 3} + 1]
puts [nop 2D {{1 2 3} {4 5 6}} > 2]
puts -nonewline {}
} -output {
2 3 4
{0 0 1} {1 1 1}
}

test {Format columns of a matrix} Example -body {
puts {}
set data {{1 2 3} {4 5 6} {7 8 9}}
set formats {{%.1f %.2f %.3f}}
puts [napply2 2D format $formats $data]
puts -nonewline {}
} -output {
{1.0 2.00 3.000} {4.0 5.00 6.000} {7.0 8.00 9.000}
}

test {Adding matrices together} Example -body {
puts {}
set A {{1 2} {3 4}}
set B {{4 9} {3 1}}
puts [nop2 2D $A + $B]
puts -nonewline {}
} -output {
{5 11} {6 5}
}

test {Matrix row and column statistics} Example -body {
puts {}
set x {{1 2} {3 4} {5 6} {7 8}}
puts [nreduce 2D max $x]; # max of each column
puts [nreduce 2D max $x 1]; # max of each row
puts [nreduce 2D sum $x]; # sum of each column
puts [nreduce 2D sum $x 1]; # sum of each row
puts -nonewline {}
} -output {
7 8
2 4 6 8
16 20
3 7 11 15
}

test {Expand and map over matrices} Example -body {
puts {}
set phrases [nmap 2D greeting {{hello goodbye}} subject {world moon} {
    list $greeting $subject
}]
napply 2D puts $phrases
puts -nonewline {}
} -output {
hello world
goodbye world
hello moon
goodbye moon
}

test {Adding two matrices together, element-wise} Example -body {
puts {}
set x {{1 2} {3 4}}
set y {{4 1} {3 9}}
set z [nexpr 2D xi $x yi $y {$xi + $yi}]
puts $z
puts -nonewline {}
} -output {
{5 3} {6 13}
}
