package require tin
tin import ndlist

puts "Create nested ND list with one value"
puts [nrepeat {1 2 3} 0]

puts "Expand ragged ND list"
puts [ndlist 2D {1 {2 3}}]

puts "ND list access"
set A {{1 2 3} {4 5 6} {7 8 9}}
puts [nget $A 0 :]
puts [nget $A 0* :]; # can "flatten" row
puts [nget $A 0:1 1]
puts [nget $A end:0 end:0]; # can have reverse ranges
puts [nget $A {0 0 0} 1*]; # can repeat indices

puts "Swapping rows in a matrix"
# ND List Value Modification
set a {{1 2} {3 4} {5 6}}
puts [nreplace $a : 1 ""]; # Delete a column (modify in-place)
nset a {1 0} : [nget $a {0 1} :]; # Swap rows and columns (modify by reference)
puts $a

puts "Element-wise operations"
# Using ND list values
puts [nop 1D {1 2 3} -]
puts [nop 1D {1 2 3} + 1]
# Using ND list objects
matrix x {{1 2 3} {4 5 6}}
[$x .= {>= 3}] print

puts "ND list mapping"
set testmat {{1 2 3} {4 5 6} {7 8 9}}
# Checkerboard sign pattern
puts [nmap 2D x $testmat {expr {
    $x*([i]%2 + [j]%2 == 1?-1:1)
}}]
# Simple formatting
puts [nmap 2D x $testmat {format %.2f $x}]

puts "Create ND list object"
matrix x {{1 2 3} {4 5 6} {7 8 9}}
puts [$x info]

puts "ND list object methods"
matrix X {{1 2} {3 4}}
$X ::= {format %0.2f $@.}; # Format values
$X print
$X --> Y; # Copy object
$Y .= {+ 1}; # Perform math operation
$Y print

puts "ND list object access/manipulation"
# Access ND List Objects
matrix X {{1 2} {3 4}}
puts [$X @ : 1]; # get column value
$X @ 1* : --> Y; # create row vector (1D list)
$Y @ end .= {* 2}; # double last element of Y
puts [$Y info]

puts "Element-wise expressions"
matrix x {{1 2} {3 4} {5 6}}
matrix y 5.0
puts [nexpr {$@x + $@y}]

puts "Self-operation, using index access commands"
matrix x [nrepeat {2 3} 1]
[$x := {$@. * [i]}] print

puts "Shape and size"
set x {{1 2} {3 4} {5 6}}
puts [nshape 2D $x]
puts [nsize 2D $x]
# Convert scalar ND list object to matrix
scalar x 5.0
$x ndims 2
puts [$x shape]

puts "Flatten and reshape ND lists"
vector x [nflatten 2D {{1 2 3 4} {5 6 7 8}}]
[$x reshape {2 2 2}] print

puts "Transposing a matrix"
puts [ntranspose 2D {{1 2} {3 4}}]

puts "Swapping axes of a tensor"
tensor x 3D {{{1 2} {3 4}} {{5 6} {7 8}}}
[$x transpose 0 2] print

puts "Inserting rows and columns in a matrix"
# Insert row
puts [ninsert 2D {{1 2 3} {4 5 6} {7 8 9}} 0 {{A B C}}]
# Insert column
matrix x {1 2 3}
$x insert end {4 5 6} 1
$x print

puts "Stack tensors"
set x [nreshape 1D {1 2 3 4 5 6 7 8 9} {3 3 1}]
set y [nreshape 1D {A B C D E F G H I} {3 3 1}]
puts [ninsert 3D $x end $y 2]

puts "Creating an identity matrix"
set I ""
for {set i 0} {$i < 3} {incr i} {
    nset I $i $i 1
}
set I [nfill 2D $I 0]
puts $I

puts "Integer range generator"
puts [range 3]
puts [range 0 2]
puts [range 10 3 -2]
# Alternative for-loop
foreach i [range 5] {
    puts $i
}