# Documentation examples

test {Example 1} {Integer range generation} -body {
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

test {Example 2} {Simpler for-loop} -body {
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

test {Example 3} {Filtering a list} -body {
puts {}
set x {0.5 2.3 4.0 2.5 1.6 2.0 1.4 5.6}
puts [nget $x [find $x > 2]]
puts -nonewline {}
} -output {
2.3 4.0 2.5 5.6
}

test {Example 4} {Linear interpolation} -body {
puts {}
puts [linterp 2 {1 2 3} {4 5 6}]
puts [linterp 8.2 {0 10 20} {2 -4 5}]
puts -nonewline {}
} -output {
5.0
-2.92
}

test {Example 5} {Linearly spaced vector generation} -body {
puts {}
puts [linspace 5 0 1]
puts -nonewline {}
} -output {
0.0 0.25 0.5 0.75 1.0
}

test {Example 6} {Intermediate value vector generation} -body {
puts {}
puts [linsteps 0.25 0 1 0]
puts -nonewline {}
} -output {
0.0 0.25 0.5 0.75 1.0 0.75 0.5 0.25 0.0
}

test {Example 7} {Applying a math function to a list} -body {
puts {}
# Add Tcl math functions to the current namespace path
namespace path [concat [namespace path] ::tcl::mathfunc]
puts [lapply abs {-5 1 2 -2}]
puts -nonewline {}
} -output {
5 1 2 2
}

test {Example 8} {Mapping over two lists} -body {
puts {}
lapply puts [lapply2 {format "%s %s"} {hello goodbye} {world moon}]
puts -nonewline {}
} -output {
hello world
goodbye moon
}

test {Example 9} {List Statistics} -body {
puts {}
set list {-5 3 4 0}
foreach stat {max min sum product mean median stdev pstdev} {
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
stdev 4.041451884327381
pstdev 3.5
}

test {Example 10} {Dot and cross product} -body {
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

test {Example 11} {Matrices and vectors} -body {
puts {}
# Define matrices, column vectors, and row vectors
set A {{2 5 1 3} {4 1 7 9} {6 8 3 2} {7 8 1 4}}
set B {9 3 0 -3}
set C {{3 7 -5 -2}}
# Print out matrices (join with newline to print out each row)
puts "A ="
puts [join $A \n]
puts "B ="
puts [join $B \n]
puts "C ="
puts [join $C \n]
puts -nonewline {}
} -output {
A =
2 5 1 3
4 1 7 9
6 8 3 2
7 8 1 4
B =
9
3
0
-3
C =
3 7 -5 -2
}

test {Example 12} {Generating standard matrices} -body {
puts {}
puts [zeros 2 3]
puts [ones 3 2]
puts [eye 3]
puts -nonewline {}
} -output {
{0 0 0} {0 0 0}
{1 1} {1 1} {1 1}
{1 0 0} {0 1 0} {0 0 1}
}

test {Example 13} {Combining matrices} -body {
puts {}
set A [stack {{1 2}} {{3 4}}]
set B [augment {1 2} {3 4}]
set C [block [list [list $A $B] [list $B $A]]]
puts $A
puts $B
puts [join $C \n]; # prints each row on a new line
puts -nonewline {}
} -output {
{1 2} {3 4}
{1 3} {2 4}
1 2 1 3
3 4 2 4
1 3 1 2
2 4 3 4
}

test {Example 14} {Transposing a matrix} -body {
puts {}
puts [transpose {{1 2} {3 4}}]
puts -nonewline {}
} -output {
{1 3} {2 4}
}

test {Example 15} {Multiplying a matrix} -body {
puts {}
puts [matmul {{2 5 1 3} {4 1 7 9} {6 8 3 2} {7 8 1 4}} {9 3 0 -3}]
puts -nonewline {}
} -output {
24 12 72 75
}

test {Example 16} {Outer product and Kronecker product} -body {
puts {}
set A [eye 3]
set B [outerprod {1 2} {3 4}]
set C [kronprod $A $B]
puts [join $C \n]; # prints out each row on a new line
puts -nonewline {}
} -output {
3 4 0 0 0 0
6 8 0 0 0 0
0 0 3 4 0 0
0 0 6 8 0 0
0 0 0 0 3 4
0 0 0 0 6 8
}

test {Example 17} {Zipping and unzipping lists} -body {
puts {}
# Zipping
set x [zip {A B C} {1 2 3}]
set y [zip3 {Do Re Mi} {A B C} {1 2 3}]
puts $x
puts $y
# Unzipping (using transpose)
puts [transpose $x]
puts -nonewline {}
} -output {
{A 1} {B 2} {C 3}
{Do A 1} {Re B 2} {Mi C 3}
{A B C} {1 2 3}
}

test {Example 18} {Cartesian product} -body {
puts {}
puts [cartprod {A B C} {1 2 3}]
puts -nonewline {}
} -output {
{A 1} {A 2} {A 3} {B 1} {B 2} {B 3} {C 1} {C 2} {C 3}
}

test {Example 19} {Rank of an ND-list} -body {
puts {}
set x {1}
set y {1 2 {hello world}}; # note that this is not a valid 2D list
set z {{1 2 3} {4 5 6}}
puts [ndims $x]; # 0
puts [ndims $y]; # 1
puts [ndims $z]; # 2
puts [ndims_multiple [list $x $y $z]]; # 1
puts -nonewline {}
} -output {
0
1
2
1
}

test {Example 20} {Getting shape and size of an ND-list} -body {
puts {}
set x {{1 2 3} {4 5 6}}
puts [nshape $x]
puts [nsize $x]
puts -nonewline {}
} -output {
2 3
6
}

test {Example 21} {Generate ND-list filled with one value} -body {
puts {}
puts [nfull foo 3 2]; # 3x2 matrix filled with "foo"
puts [nfull 0 2 2 2]; # 2x2x2 tensor filled with zeros
puts -nonewline {}
} -output {
{foo foo} {foo foo} {foo foo}
{{0 0} {0 0}} {{0 0} {0 0}}
}

test {Example 22} {Generate random matrix} -body {
puts {}
expr {srand(0)}; # resets the random number seed (for the example)
puts [nrand 1 2]; # 1x2 matrix filled with random numbers
puts -nonewline {}
} -output {
{0.013469574513598146 0.3831388500440581}
}

test {Example 23} {Repeat elements of a matrix} -body {
puts {}
puts [nrepeat {{1 2} {3 4}} 1 2]
puts -nonewline {}
} -output {
{1 2 1 2} {3 4 3 4}
}

test {Example 24} {Expand an ND-list to new dimensions} -body {
puts {}
puts [nexpand {1 2 3} -1 2]
puts [nexpand {{1 2}} 2 4]
puts -nonewline {}
} -output {
{1 1} {2 2} {3 3}
{1 2 1 2} {1 2 1 2}
}

test {Example 25} {Padding an ND-list with zeros} -body {
puts {}
set a {{1 2 3} {4 5 6} {7 8 9}}
puts [npad $a 0 2 1]
puts -nonewline {}
} -output {
{1 2 3 0} {4 5 6 0} {7 8 9 0} {0 0 0 0} {0 0 0 0}
}

test {Example 26} {Extending an ND-list to a new shape with a filler value} -body {
puts {}
set a {hello hi hey howdy}
puts [nextend $a world -1 2]
puts -nonewline {}
} -output {
{hello world} {hi world} {hey world} {howdy world}
}

test {Example 27} {Reshape a matrix to a 3D tensor} -body {
puts {}
set x [nflatten {{1 2 3 4} {5 6 7 8}}]
puts [nreshape $x 2 2 2]
puts -nonewline {}
} -output {
{{1 2} {3 4}} {{5 6} {7 8}}
}

test {Example 28} {Reshape a vector to a matrix with three columns} -body {
puts {}
puts [nreshape {1 2 3 4 5 6} * 3]
puts -nonewline {}
} -output {
{1 2 3} {4 5 6}
}

test {Example 29} {Index Notation} -body {
puts {}
set n 10
puts [::ndlist::ParseIndex $n :]
puts [::ndlist::ParseIndex $n 1:8]
puts [::ndlist::ParseIndex $n 0:2:6]
puts [::ndlist::ParseIndex $n {0 5 end-1}]
puts [::ndlist::ParseIndex $n end*]
puts -nonewline {}
} -output {
A {}
R {1 8}
L {0 2 4 6}
L {0 5 8}
S 9
}

test {Example 30} {ND-list access} -body {
puts {}
set A {{1 2 3} {4 5 6} {7 8 9}}
puts [nget $A 0 :]; # get row matrix
puts [nget $A 0* :]; # flatten row matrix to a vector
puts [nget $A 0:1 0:1]; # get matrix subset
puts [nget $A end:0 end:0]; # can have reverse ranges
puts [nget $A {0 0 0} 1*]; # can repeat indices
puts -nonewline {}
} -output {
{1 2 3}
1 2 3
{1 2} {4 5}
{9 8 7} {6 5 4} {3 2 1}
2 2 2
}

test {Example 31} {Replace range with a single value} -body {
puts {}
puts [nreplace [range 10] 0:2:end 0]
puts -nonewline {}
} -output {
0 1 0 3 0 5 0 7 0 9
}

test {Example 32} {Swapping matrix rows} -body {
puts {}
set a {{1 2 3} {4 5 6} {7 8 9}}
nset a {1 0} : [nget $a {0 1} :]; # Swap rows and columns (modify by reference)
puts $a
puts -nonewline {}
} -output {
{4 5 6} {1 2 3} {7 8 9}
}

test {Example 33} {Filtering a list by removing elements} -body {
puts {}
set x [range 10]
puts [nremove $x [find $x > 4]]
puts -nonewline {}
} -output {
0 1 2 3 4
}

test {Example 34} {Deleting a column from a matrix} -body {
puts {}
set a {{1 2 3} {4 5 6} {7 8 9}}
puts [nremove $a 2 1]
puts -nonewline {}
} -output {
{1 2} {4 5} {7 8}
}

test {Example 35} {Inserting a column into a matrix} -body {
puts {}
set matrix {{1 2} {3 4} {5 6}}
set column {A B C}
puts [ninsert $matrix 1 $column 1 2]
puts -nonewline {}
} -output {
{1 A 2} {3 B 4} {5 C 6}
}

test {Example 36} {Concatenate tensors} -body {
puts {}
set x [nreshape {1 2 3 4 5 6 7 8 9} 3 3 1]
set y [nreshape {A B C D E F G H I} 3 3 1]
puts [ncat $x $y 2 3]
puts -nonewline {}
} -output {
{{1 A} {2 B} {3 C}} {{4 D} {5 E} {6 F}} {{7 G} {8 H} {9 I}}
}

test {Example 37} {Changing tensor axes} -body {
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

test {Example 38} {Chained functional mapping over a matrix} -body {
puts {}
napply puts [napply {format %.2f} [napply expr {{1 2} {3 4}} {+ 1}]]
puts -nonewline {}
} -output {
2.00
3.00
4.00
5.00
}

test {Example 39} {Format columns of a matrix} -body {
puts {}
set data {{1 2 3} {4 5 6} {7 8 9}}
set formats {{%.1f %.2f %.3f}}
puts [napply2 format $formats $data]
puts -nonewline {}
} -output {
{1.0 2.00 3.000} {4.0 5.00 6.000} {7.0 8.00 9.000}
}

test {Example 40} {Matrix row and column statistics} -body {
puts {}
set x {{1 2} {3 4} {5 6} {7 8}}
puts [nreduce max $x]; # max of each column
puts [nreduce max $x 1]; # max of each row
puts [nreduce sum $x]; # sum of each column
puts [nreduce sum $x 1]; # sum of each row
puts -nonewline {}
} -output {
7 8
2 4 6 8
16 20
3 7 11 15
}

test {Example 41} {Expand and map over matrices} -body {
puts {}
set phrases [nmap 2 greeting {{hello goodbye}} subject {world moon} {
    list $greeting $subject
}]
napply puts $phrases {} 2 
puts -nonewline {}
} -output {
hello world
goodbye world
hello moon
goodbye moon
}

test {Example 42} {Finding index tuples that match criteria} -body {
puts {}
set x {{1 2 3} {4 5 6} {7 8 9}}
set indices {}
nmap xi $x {
    if {$xi > 4} {
        lappend indices [list [i] [j]]
    }
}
puts $indices
puts -nonewline {}
} -output {
{1 1} {1 2} {2 0} {2 1} {2 2}
}

test {Example 43} {File import/export} -body {
puts {}
# Export matrix to file (converts to csv)
writeMatrix example.csv {{foo bar} {hello world}}
# Read CSV file
puts [readFile example.csv]
puts [readMatrix example.csv]; # converts from csv to matrix
file delete example.csv
puts -nonewline {}
} -output {
foo,bar
hello,world
{foo bar} {hello world}
}

test {Example 44} {Data conversions} -body {
puts {}
set matrix {{A B C} {{hello world} foo,bar {"hi"}}}
puts {TXT format:}
puts [mat2txt $matrix]
puts {CSV format:}
puts [mat2csv $matrix]
puts -nonewline {}
} -output {
TXT format:
A B C
{hello world} foo,bar {"hi"}
CSV format:
A,B,C
hello world,"foo,bar","""hi"""
}
