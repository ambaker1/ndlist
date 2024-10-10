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

test {Example 19} {Getting shape and size of an ND-list} -body {
puts {}
set x {{1 2 3} {4 5 6}}
puts [nshape 2D $x]
puts [nsize 2D $x]
puts -nonewline {}
} -output {
2 3
6
}

test {Example 20} {Generate ND-list filled with one value} -body {
puts {}
puts [nfull foo 3 2]; # 3x2 matrix filled with "foo"
puts [nfull 0 2 2 2]; # 2x2x2 tensor filled with zeros
puts -nonewline {}
} -output {
{foo foo} {foo foo} {foo foo}
{{0 0} {0 0}} {{0 0} {0 0}}
}

test {Example 21} {Generate random matrix} -body {
puts {}
expr {srand(0)}; # resets the random number seed (for the example)
puts [nrand 1 2]; # 1x2 matrix filled with random numbers
puts -nonewline {}
} -output {
{0.013469574513598146 0.3831388500440581}
}

test {Example 22} {Repeat elements of a matrix} -body {
puts {}
puts [nrepeat {{1 2} {3 4}} 1 2]
puts -nonewline {}
} -output {
{1 2 1 2} {3 4 3 4}
}

test {Example 23} {Expand an ND-list to new dimensions} -body {
puts {}
puts [nexpand {1 2 3} -1 2]
puts [nexpand {{1 2}} 2 4]
puts -nonewline {}
} -output {
{1 1} {2 2} {3 3}
{1 2 1 2} {1 2 1 2}
}

test {Example 24} {Padding an ND-list with zeros} -body {
puts {}
set a {{1 2 3} {4 5 6} {7 8 9}}
puts [npad $a 0 2 1]
puts -nonewline {}
} -output {
{1 2 3 0} {4 5 6 0} {7 8 9 0} {0 0 0 0} {0 0 0 0}
}

test {Example 25} {Extending an ND-list to a new shape with a filler value} -body {
puts {}
set a {hello hi hey howdy}
puts [nextend $a world -1 2]
puts -nonewline {}
} -output {
{hello world} {hi world} {hey world} {howdy world}
}

test {Example 26} {Reshape a matrix to a 3D tensor} -body {
puts {}
set x [nflatten 2D {{1 2 3 4} {5 6 7 8}}]
puts [nreshape $x 2 2 2]
puts -nonewline {}
} -output {
{{1 2} {3 4}} {{5 6} {7 8}}
}

test {Example 27} {Reshape a vector to a matrix} -body {
puts {}
puts [nreshape {1 2 3 4 5 6} 2 3]
puts -nonewline {}
} -output {
{1 2 3} {4 5 6}
}

test {Example 28} {Index Notation} -body {
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

test {Example 29} {ND-list access} -body {
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

test {Example 30} {Replace range with a single value} -body {
puts {}
puts [nreplace [range 10] 0:2:end 0]
puts -nonewline {}
} -output {
0 1 0 3 0 5 0 7 0 9
}

test {Example 31} {Swapping matrix rows} -body {
puts {}
set a {{1 2 3} {4 5 6} {7 8 9}}
nset a {1 0} : [nget $a {0 1} :]; # Swap rows and columns (modify by reference)
puts $a
puts -nonewline {}
} -output {
{4 5 6} {1 2 3} {7 8 9}
}

test {Example 32} {Filtering a list by removing elements} -body {
puts {}
set x [range 10]
puts [nremove $x [find $x > 4]]
puts -nonewline {}
} -output {
0 1 2 3 4
}

test {Example 33} {Deleting a column from a matrix} -body {
puts {}
set a {{1 2 3} {4 5 6} {7 8 9}}
puts [nremove $a 2 1]
puts -nonewline {}
} -output {
{1 2} {4 5} {7 8}
}

test {Example 34} {Inserting a column into a matrix} -body {
puts {}
narray new matrix 2 {{1 2} {3 4} {5 6}}
$matrix insert 1 {A B C} 1
puts [$matrix]
puts -nonewline {}
} -output {
{1 A 2} {3 B 4} {5 C 6}
}

test {Example 35} {Concatenate tensors} -body {
puts {}
set x [nreshape {1 2 3 4 5 6 7 8 9} 3 3 1]
set y [nreshape {A B C D E F G H I} 3 3 1]
puts [ncat 3D $x $y 2]
puts -nonewline {}
} -output {
{{1 A} {2 B} {3 C}} {{4 D} {5 E} {6 F}} {{7 G} {8 H} {9 I}}
}

test {Example 36} {Changing tensor axes} -body {
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

test {Example 37} {Chained functional mapping over a matrix} -body {
puts {}
napply 2D puts [napply 2D {format %.2f} [napply 2D expr {{1 2} {3 4}} + 1]]
puts -nonewline {}
} -output {
2.00
3.00
4.00
5.00
}

test {Example 38} {Format columns of a matrix} -body {
puts {}
set data {{1 2 3} {4 5 6} {7 8 9}}
set formats {{%.1f %.2f %.3f}}
puts [napply2 2D format $formats $data]
puts -nonewline {}
} -output {
{1.0 2.00 3.000} {4.0 5.00 6.000} {7.0 8.00 9.000}
}

test {Example 39} {Matrix row and column statistics} -body {
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

test {Example 40} {Expand and map over matrices} -body {
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

test {Example 41} {Finding index tuples that match criteria} -body {
puts {}
set x {{1 2 3} {4 5 6} {7 8 9}}
set indices {}
nmap 2D xi $x {
    if {$xi > 4} {
        lappend indices [list [i] [j]]
    }
}
puts $indices
puts -nonewline {}
} -output {
{1 1} {1 2} {2 0} {2 1} {2 2}
}

test {Example 42} {Creating ND-arrays} -body {
puts {}
# Create new ND-arrays
narray new x 2D {{1 2 3} {4 5 6} {7 8 9}}
narray new y 1D {hello world}
# Print rank and value of ND-arrays
puts "[$x rank], [$x]"
puts "[$y rank], [$y]"
puts -nonewline {}
} -output {
2, {1 2 3} {4 5 6} {7 8 9}
1, hello world
}

test {Example 43} {Accessing portions of an ND-array} -body {
puts {}
narray new x 2D {{1 2 3} {4 5 6} {7 8 9}}
puts [$x @ 0 2]
puts [$x @ 0:end-1 {0 2}]
puts -nonewline {}
} -output {
3
{1 3} {4 6}
}

test {Example 44} {Copying a portion of an ND-array} -body {
puts {}
narray new x 2 {{1 2 3} {4 5 6}}
$x @ 0* : --> y; # Row vector (flattened to 1D)
puts "[$y rank], [$y]"
puts -nonewline {}
} -output {
1, 1 2 3
}

test {Example 45} {Get distance between elements in a vector} -body {
puts {}
narray new x 1D {1 2 4 7 11 16}
puts [nexpr {$.x(1:end) - $.x(0:end-1)}]
puts -nonewline {}
} -output {
1 2 3 4 5
}

test {Example 46} {Outer product of two vectors} -body {
puts {}
narray new x 2D {1 2 3}
narray new y 2D {{4 5 6}}
puts [nexpr {$.x * $.y}]
puts -nonewline {}
} -output {
{4 5 6} {8 10 12} {12 15 18}
}

test {Example 47} {Element-wise modification of a vector} -body {
puts {}
# Create blank vectors and assign values
[narray new x 1D] = {1 2 3}
[narray new y 1D] = {10 20 30}
# Add one to each element
puts [[$x := {$. + 1}]]
# Double the last element
puts [[$x @ end := {$. * 2}]]
# Element-wise addition of vectors
puts [[$x := {$. + $.y}]]
puts -nonewline {}
} -output {
2 3 4
2 3 8
12 23 38
}

test {Example 48} {Removing elements from a vector} -body {
puts {}
narray new vector 1 {1 2 3 4 5 6 7 8}
# Remove all odd numbers
$vector remove [find [nexpr {$.vector % 2}]]
puts [$vector]
puts -nonewline {}
} -output {
2 4 6 8
}

test {Example 49} {Map a command over a list} -body {
puts {}
narray new text 1 {The quick brown fox jumps over the lazy dog}
puts [$text apply {string length}]; # Print the length of each word
puts -nonewline {}
} -output {
3 5 5 3 5 4 3 4 3
}

test {Example 50} {Get column statistics of a matrix} -body {
puts {}
narray new matrix 2 {{1 2 3} {4 5 6} {7 8 9}}
# Convert to double-precision floating point
$matrix = [$matrix apply ::tcl::mathfunc::double]
# Get maximum and minimum of each column
puts [$matrix reduce max]
puts [$matrix reduce min]
puts -nonewline {}
} -output {
7.0 8.0 9.0
1.0 2.0 3.0
}

test {Example 51} {Temporary object value} -body {
puts {}
# Create a matrix
narray new x 2 {{1 2 3} {4 5 6}}
# Print value with first row doubled.
puts [$x | @ 0* : := {$. * 2}]
# Source object was not modified
puts [$x]
puts -nonewline {}
} -output {
{2 4 6} {4 5 6}
{1 2 3} {4 5 6}
}

test {Example 52} {Appending a vector} -body {
puts {}
# Create a 1D list
narray new x 1 {1 2 3}
# Append the list
$x & ref {lappend ref 4 5 6}
puts [$x]
# Append a subset of the list
$x @ end* & ref {lappend ref 7 8 9}
puts [$x]
puts -nonewline {}
} -output {
1 2 3 4 5 6
1 2 3 4 5 {6 7 8 9}
}

test {Example 53} {Creating and accessing a table} -body {
puts {}
table new tableObj {{key A B} {1 foo bar} {2 hello world}}
puts [$tableObj]
puts -nonewline {}
} -output {
{key A B} {1 foo bar} {2 hello world}
}

test {Example 54} {Cleaning the table} -body {
puts {}
table new tableObj
$tableObj = {
    {key x y z}
    {1 {} foo bar}
    {2 {} hello world}
    {3 {} {} {}}
}
puts [$tableObj]
# Remove keys and fields with no data
$tableObj clean
puts [$tableObj]
# Remove all keys and data, keep fields
$tableObj clear
puts [$tableObj]
# Reset table 
$tableObj wipe
puts [$tableObj]
puts -nonewline {}
} -output {
{key x y z} {1 {} foo bar} {2 {} hello world} {3 {} {} {}}
{key y z} {1 foo bar} {2 hello world}
{key y z}
key
}

test {Example 55} {Access table components} -body {
puts {}
table new tableObj
$tableObj = {
    {key A B}
    {1 foo bar}
    {2 hello world}
}
puts [$tableObj]
puts [$tableObj keyname]
puts [$tableObj keys]
puts [$tableObj fields]
puts [$tableObj values]
puts -nonewline {}
} -output {
{key A B} {1 foo bar} {2 hello world}
key
1 2
A B
{foo bar} {hello world}
}

test {Example 56} {Accessing table data and dimensions} -body {
puts {}
table new tableObj {{key A B} {1 foo bar} {2 hello world} {3 {} {}}}
puts [$tableObj dict]
puts [$tableObj height]
puts [$tableObj width]
puts -nonewline {}
} -output {
1 {A foo B bar} 2 {A hello B world} 3 {}
3
2
}

test {Example 57} {Find column index of a field} -body {
puts {}
table new tableObj {
    {name x y z}
    {bob 1 2 3}
    {sue 3 2 1}
}
puts [$tableObj exists field z]
puts [$tableObj find field z]
puts -nonewline {}
} -output {
1
2
}

test {Example 58} {Getting and setting values in a table} -body {
puts {}
table new tableObj
# Set multiple values at once
$tableObj set 1 x 2.0 y 3.0 z 6.5
# Access values in the table
puts [$tableObj get 1 x]
puts [$tableObj get 1 y]
puts -nonewline {}
} -output {
2.0
3.0
}

test {Example 59} {Setting entire rows/columns} -body {
puts {}
table new tableObj {{key A B}}
$tableObj rset 1 {1 2}
$tableObj rset 2 {4 5}
$tableObj rset 3 {7 8}
$tableObj cset C {3 6 9}
puts [$tableObj]
puts -nonewline {}
} -output {
{key A B C} {1 1 2 3} {2 4 5 6} {3 7 8 9}
}

test {Example 60} {Matrix entry and access} -body {
puts {}
table new T
$T mset {1 2 3 4} {A B} 0.0; # Initialize as zero
$T mset {1 2 3} A {1.0 2.0 3.0}; # Set subset of table
puts [$T mget [$T keys] [$T fields]]; # Same as [$T values]
puts -nonewline {}
} -output {
{1.0 0.0} {2.0 0.0} {3.0 0.0} {0.0 0.0}
}

test {Example 61} {Iterating over a table, accessing and modifying field values} -body {
puts {}
table new parameters {{key x y z}}
$parameters set 1 x 1.0 y 2.0
$parameters set 2 x 3.0 y 4.0
$parameters with {
    set z [expr {$x + $y}]
}
puts [$parameters cget z]
puts -nonewline {}
} -output {
3.0 7.0
}

test {Example 62} {Math operation over table columns} -body {
puts {}
table new myTable
$myTable set 1 x 1.0 
$myTable set 2 x 2.0
$myTable set 3 x 3.0
set a 20.0
puts [$myTable expr {@x*2 + $a}]
puts -nonewline {}
} -output {
22.0 24.0 26.0
}

test {Example 63} {Getting data that meets a criteria} -body {
puts {}
# Create blank table with keyname "StudentID"
table new classData StudentID
$classData set 1 name bob {height (cm)} 175 {weight (kg)} 60
$classData set 2 name frank {height (cm)} 180 {weight (kg)} 75
$classData set 3 name sue {height (cm)} 165 {weight (kg)} 55
$classData set 4 name sally {height (cm)} 150 {weight (kg)} 50
# Subset of data where height is greater than 160
puts [$classData mget [$classData query {@{height (cm)} > 160}] {name {height (cm)}}]
puts -nonewline {}
} -output {
{bob 175} {frank 180} {sue 165}
}

test {Example 64} {Accessing and modifying table columns} -body {
puts {}
table new myTable
$myTable define keys {1 2 3}
$myTable @ x = {1.0 2.0 3.0}
set a 20.0
$myTable @ y := {@x*2 + $a}
puts [$myTable @ y]
puts -nonewline {}
} -output {
22.0 24.0 26.0
}

test {Example 65} {Searching and sorting} -body {
puts {}
# Use zip command to make a one-column table
table new data [zip {key 1 2 3 4 5} {x 3.0 2.3 5.0 2.0 1.8}]
# Find key corresponding to x value of 5
puts [$data search -exact -real x 5]
# Sort the table, and print list of keys and values
$data sort -real x
puts [zip [$data keys] [$data cget x]]
puts -nonewline {}
} -output {
3
{5 1.8} {4 2.0} {2 2.3} {1 3.0} {3 5.0}
}

test {Example 66} {Merging data from other tables} -body {
puts {}
table new table1 {{key A B} {1 foo bar} {2 hello world}}
table new table2 {{key B} {1 foo} {2 there}}
$table1 merge $table2
puts [$table1]
puts -nonewline {}
} -output {
{key A B} {1 foo foo} {2 hello there}
}

test {Example 67} {Re-keying a table} -body {
puts {}
table new tableObj {{ID A B C} {1 1 2 3} {2 4 5 6} {3 7 8 9}}
$tableObj mkkey A
puts [$tableObj]
puts -nonewline {}
} -output {
{A B C ID} {1 2 3 1} {4 5 6 2} {7 8 9 3}
}

test {Example 68} {Renaming fields} -body {
puts {}
table new tableObj {{key A B C} {1 1 2 3}}
$tableObj rename fields {x y z}
puts [$tableObj]
puts -nonewline {}
} -output {
{key x y z} {1 1 2 3}
}

test {Example 69} {Swapping table rows} -body {
puts {}
table new tableObj
$tableObj define keys {1 2 3 4}
$tableObj cset A {2.0 4.0 8.0 16.0}
$tableObj swap keys 1 4
puts [$tableObj]
puts -nonewline {}
} -output {
{key A} {4 16.0} {2 4.0} {3 8.0} {1 2.0}
}

test {Example 70} {File import/export} -body {
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

test {Example 71} {Data conversions} -body {
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
