
# Matrix for testing (DO NOT CHANGE)
set testmat {{1 2 3} {4 5 6} {7 8 9}}

# ndlist/nrepeat/nexpand
################################################################################
puts "Creating ND lists"
test ndlist {
    # Create an ndlist (validates)
} -body {
    assert [ndlist 2D $testmat] eq $testmat
    catch {ndlist 2D {1 {2 3}}}
} -result {1}

# nrepeat
test nrepeat {
    # Assert that nrepeat works
} -body {
    nrepeat 0 1 2 3
} -result {{{0 0 0} {0 0 0}}}

# nexpand
test nexpand {
    # Expand an existing ndlist to new dimensions (copies existing data)
} -body {
    nexpand {1 2 3} 3 2
} -result {{1 1} {2 2} {3 3}}

# nshape/nsize 
################################################################################
puts "Getting shape/size of ND lists"
# nshape
test nshape {
    # Assert that nshape works
} -body {
    nshape 2D {{1 2} {3 4} {5 6}}
} -result {3 2}

# nsize
test nsize {
    # Assert that nsize works
} -body {
    nsize 2D {{1 2} {3 4} {5 6}}
} -result {6}

# nget/nset/nreplace (ndlist access/modification)
################################################################################
puts "Accessing/modifying ND lists"

# nget
test nget {
    # Test out all combinations of nget for a matrix
} -body {
    assert {[nget $testmat : :] eq $testmat}
    assert {[nget $testmat : 0] eq {1 4 7}}
    assert {[nget $testmat : 0*] eq {1 4 7}}
    assert {[nget $testmat : 0:1] eq {{1 2} {4 5} {7 8}}}
    assert {[nget $testmat : 1:0] eq {{2 1} {5 4} {8 7}}}
    assert {[nget $testmat 0 :] eq {{1 2 3}}}
    assert {[nget $testmat 0 0] eq {1}}
    assert {[nget $testmat 0 0*] eq {1}}
    assert {[nget $testmat 0 0:1] eq {{1 2}}}
    assert {[nget $testmat 0 1:0] eq {{2 1}}}
    assert {[nget $testmat 0* :] eq {1 2 3}}
    assert {[nget $testmat 0* 0] eq {1}}
    assert {[nget $testmat 0* 0*] eq {1}}
    assert {[nget $testmat 0* 0:1] eq {1 2}}
    assert {[nget $testmat 0* 1:0] eq {2 1}}
    assert {[nget $testmat 0:1 :] eq {{1 2 3} {4 5 6}}}
    assert {[nget $testmat 0:1 0] eq {1 4}}
    assert {[nget $testmat 0:1 0*] eq {1 4}}
    assert {[nget $testmat 0:1 0:1] eq {{1 2} {4 5}}}
    assert {[nget $testmat 0:1 1:0] eq {{2 1} {5 4}}}
    assert {[nget $testmat 1:0 :] eq {{4 5 6} {1 2 3}}}
    assert {[nget $testmat 1:0 0] eq {4 1}}
    assert {[nget $testmat 1:0 0*] eq {4 1}}
    assert {[nget $testmat 1:0 0:1] eq {{4 5} {1 2}}}
    assert {[nget $testmat 1:0 1:0] eq {{5 4} {2 1}}}
    assert {[nget $testmat 0:2:end :] eq {{1 2 3} {7 8 9}}}
} -result {}


# nreplace
test nset-nreplace {
    # Check all combinations of nreplace 
} -body {
    assert {[nreplace $testmat : : ""] eq ""}
    assert {[nreplace $testmat : : a] eq {{a a a} {a a a} {a a a}}}
    assert {[nreplace $testmat : : {a b c}] eq {{a a a} {b b b} {c c c}}}
    assert {[nreplace $testmat : : {{a b c}}] eq {{a b c} {a b c} {a b c}}}
    assert {[nreplace $testmat : : {{a b c} {d e f} {g h i}}] eq {{a b c} {d e f} {g h i}}}
    assert {[nreplace $testmat : 0 ""] eq {{2 3} {5 6} {8 9}}}
    assert {[nreplace $testmat : 0 a] eq {{a 2 3} {a 5 6} {a 8 9}}}
    assert {[nreplace $testmat : 0 {a b c}] eq {{a 2 3} {b 5 6} {c 8 9}}}
    assert {[nreplace $testmat : 0* ""] eq {{2 3} {5 6} {8 9}}}
    assert {[nreplace $testmat : 0* a] eq {{a 2 3} {a 5 6} {a 8 9}}}
    assert {[nreplace $testmat : 0* {a b c}] eq {{a 2 3} {b 5 6} {c 8 9}}}
    assert {[nreplace $testmat : 0:1 ""] eq {3 6 9}}
    assert {[nreplace $testmat : 0:1 a] eq {{a a 3} {a a 6} {a a 9}}}
    assert {[nreplace $testmat : 0:1 {a b c}] eq {{a a 3} {b b 6} {c c 9}}}
    assert {[nreplace $testmat : 0:1 {{a b}}] eq {{a b 3} {a b 6} {a b 9}}}
    assert {[nreplace $testmat : 0:1 {{a b} {c d} {e f}}] eq {{a b 3} {c d 6} {e f 9}}}
    assert {[nreplace $testmat : 1:0 ""] eq {3 6 9}}
    assert {[nreplace $testmat : 1:0 a] eq {{a a 3} {a a 6} {a a 9}}}
    assert {[nreplace $testmat : 1:0 {a b c}] eq {{a a 3} {b b 6} {c c 9}}}
    assert {[nreplace $testmat : 1:0 {{a b}}] eq {{b a 3} {b a 6} {b a 9}}}
    assert {[nreplace $testmat : 1:0 {{a b} {c d} {e f}}] eq {{b a 3} {d c 6} {f e 9}}}
    assert {[nreplace $testmat 0 : ""] eq {{4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0 : a] eq {{a a a} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0 : {{a b c}}] eq {{a b c} {4 5 6} {7 8 9}}}
    assert {[catch {nreplace $testmat 0 0 ""}] == 1}; # do not allow for non-axis deletion
    assert {[nreplace $testmat 0 0 a] eq {{a 2 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0 0* a] eq {{a 2 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0 0:1 a] eq {{a a 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0 0:1 {{a b}}] eq {{a b 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0 1:0 a] eq {{a a 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0 1:0 {{a b}}] eq {{b a 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0* : ""] eq {{4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0* : a] eq {{a a a} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0* : {a b c}] eq {{a b c} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0* 0 a] eq {{a 2 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0* 0* {hello world}] eq {{{hello world} 2 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0* 0:1 a] eq {{a a 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0* 0:1 {a b}] eq {{a b 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0* 1:0 a] eq {{a a 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0* 1:0 {a b}] eq {{b a 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 : ""] eq {{7 8 9}}}
    assert {[nreplace $testmat 0:1 : a] eq {{a a a} {a a a} {7 8 9}}}
    assert {[nreplace $testmat 0:1 : {{a b c}}] eq {{a b c} {a b c} {7 8 9}}}
    assert {[nreplace $testmat 0:1 : {a b}] eq {{a a a} {b b b} {7 8 9}}}
    assert {[nreplace $testmat 0:1 : {{a b c} {d e f}}] eq {{a b c} {d e f} {7 8 9}}}
    assert {[nreplace $testmat 0:1 0 a] eq {{a 2 3} {a 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 0 {a b}] eq {{a 2 3} {b 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 0* a] eq {{a 2 3} {a 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 0* {{hello world} {foo bar}}] eq {{{hello world} 2 3} {{foo bar} 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 0:1 a] eq {{a a 3} {a a 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 0:1 {a b}] eq {{a a 3} {b b 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 0:1 {{a b}}] eq {{a b 3} {a b 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 0:1 {{a b} {c d}}] eq {{a b 3} {c d 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 1:0 a] eq {{a a 3} {a a 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 1:0 {a b}] eq {{a a 3} {b b 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 1:0 {{a b}}] eq {{b a 3} {b a 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 1:0 {{a b} {c d}}] eq {{b a 3} {d c 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 : ""] eq {{7 8 9}}}
    assert {[nreplace $testmat 1:0 : a] eq {{a a a} {a a a} {7 8 9}}}
    assert {[nreplace $testmat 1:0 : {{a b c}}] eq {{a b c} {a b c} {7 8 9}}}
    assert {[nreplace $testmat 1:0 : {a b}] eq {{b b b} {a a a} {7 8 9}}}
    assert {[nreplace $testmat 1:0 : {{a b c} {d e f}}] eq {{d e f} {a b c} {7 8 9}}}
    assert {[nreplace $testmat 1:0 0 a] eq {{a 2 3} {a 5 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 0 {a b}] eq {{b 2 3} {a 5 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 0* a] eq {{a 2 3} {a 5 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 0* {{hello world} {foo bar}}] eq {{{foo bar} 2 3} {{hello world} 5 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 0:1 a] eq {{a a 3} {a a 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 0:1 {a b}] eq {{b b 3} {a a 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 0:1 {{a b}}] eq {{a b 3} {a b 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 0:1 {{a b} {c d}}] eq {{c d 3} {a b 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 1:0 a] eq {{a a 3} {a a 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 1:0 {a b}] eq {{b b 3} {a a 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 1:0 {{a b}}] eq {{b a 3} {b a 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 1:0 {{a b} {c d}}] eq {{d c 3} {b a 6} {7 8 9}}}
}

# nset (just calls nreplace)
test nset_I_3D {
    # Create "Identity tensor"
} -body {
    set I [nrepeat 0 3 3 3]
    for {set i 0} {$i < 3} {incr i} {
        nset I $i $i $i 1
    }
    set I
} -result {{{1 0 0} {0 0 0} {0 0 0}} {{0 0 0} {0 1 0} {0 0 0}} {{0 0 0} {0 0 0} {0 0 1}}}

test nset2 {
    # Swap rows and columns (example)
} -body {
    set a {{1 2} {3 4} {5 6}}
    nset a {1 0} : [nget $a {0 1} :]
} -result {{3 4} {1 2} {5 6}}

# ninsert/nstack
################################################################################
puts "Combining ND lists"

# ninsert
test ninsert0D {
    # Error, cannot stack scalars.
} -body {
    ninsert 0D foo 0 bar
} -returnCodes {1} -result {axis out of range}

test ninsert1D {
    # Stack vectors (simple concat)
} -body {
    ninsert 1D {1 2 3} end {4 5 6} 0
} -result {1 2 3 4 5 6}

test ninsert2D_0 {
    # Create headers
} -body {
    ninsert 2D $testmat 0 {{A B C}}
} -result {{A B C} {1 2 3} {4 5 6} {7 8 9}}

test ninsert2D_1 {
    # Augment matrices (simple concat)
} -body {
    ninsert 2D {1 2 3} end {4 5 6} 1
} -result {{1 4} {2 5} {3 6}}

test ninsert3D_2 {
    # Test on tensors
} -body {
    set x [nreshape 1D {1 2 3 4 5 6 7 8 9} 3 3 1]; # Create tensor
    set y [nreshape 1D {A B C D E F G H I} 3 3 1]; # 
    ninsert 3D $x end $y 2
} -result {{{1 A} {2 B} {3 C}} {{4 D} {5 E} {6 F}} {{7 G} {8 H} {9 I}}}

# nstack
test nstack {
    # nstack is simply a special case of ninsert.
} -body {
    assert [ninsert 1D {1 2 3} end {4 5 6} 0] eq [nstack 1D {1 2 3} {4 5 6} 0]
    assert [ninsert 2D {1 2 3} end {4 5 6} 1] eq [nstack 2D {1 2 3} {4 5 6} 1]
    assert [ninsert 3D $x end $y 2] eq [nstack 3D $x $y 2]
} -result {}

# nflatten/nreshape/nswapaxes
################################################################################
puts "Manipulating ND lists"

# nflatten
test nflatten0D {
    # Turn scalar into vector
} -body {
    nflatten 0D {hello world}
} -result {{hello world}}

test nflatten1D {
    # Verify vector
} -body {
    nflatten 1D {hello world}
} -result {hello world}

test nflatten2D {
    # Flatten matrix to vector
} -body {
    nflatten 2D {{1 2} {3 4} {5 6}}
} -result {1 2 3 4 5 6}

test nflatten3D {
    # Flatten tensor to vector
} -body {
    nflatten 3D {{{1 2} {3 4}} {{5 6} {7 8}}}
} -result {1 2 3 4 5 6 7 8}

# nreshape
test nreshape1 {
    # Check that nreshape works for matrices
} -body {
    nreshape 1D {1 2 3 4 5 6} 2 3
} -result {{1 2 3} {4 5 6}}

test nreshape2 {
    # Check that nreshape works for higher dimensions
} -body {
    nreshape 1D {1 2 3 4 5 6 7 8} 2 2 2
} -result {{{1 2} {3 4}} {{5 6} {7 8}}}

# nswapaxes
test nswapaxes0D {
    # Error, no axes to swap
} -body {
    nswapaxes 0D {hello world} 0 0
} -returnCodes {1} -result {axes out of range}

test nswapaxes1D {
    # Transpose vector just returns self
} -body {
    nswapaxes 1D {hello world} 0 0
} -result {hello world}

test nswapaxes2D_01 {
    # Flip rows/columns
} -body {
    nswapaxes 2D {{1 2} {3 4}} 0 1
} -result {{1 3} {2 4}}

test nswapaxes2D_11 {
    # Same axis, return self
} -body {
    nswapaxes 2D {{1 2} {3 4}} 1 1
} -result {{1 2} {3 4}}

test nswapaxes2D_10 {
    # Axis order flipped, still transpose
} -body {
    nswapaxes 2D {{1 2} {3 4}} 1 0
} -result {{1 3} {2 4}}

test nswapaxes3D_01 {
    # Just flip rows and columns
} -body {
    nswapaxes 3D {{{1 2} {3 4}} {{5 6} {7 8}}} 0 1; # 2x2x2
} -result {{{1 2} {5 6}} {{3 4} {7 8}}}

test nswapaxes3D_12 {
    # transpose inner matrices
} -body {
    nswapaxes 3D {{{1 2} {3 4}} {{5 6} {7 8}}} 1 2; # 2x2x2
} -result {{{1 3} {2 4}} {{5 7} {6 8}}}

test nswapaxes3D_02 {
    # transpose outer dimensions
} -body {
    nswapaxes 3D {{{1 2} {3 4}} {{5 6} {7 8}}} 0 2; # 2x2x2
    # 0,0,0: 1 -> 0,0,0
    # 0,0,1: 2 -> 1,0,0
    # 0,1,0: 3 -> 0,1,0
    # 0,1,1: 4 -> 1,1,0
    # 1,0,0: 5 -> 0,0,1
    # 1,0,1: 6 -> 1,0,1
    # 1,1,0: 7 -> 0,1,1
    # 1,1,1: 7 -> 1,1,1
} -result {{{1 5} {3 7}} {{2 6} {4 8}}}

# napply/nreduce/nmap/nexpr/nop
################################################################################
puts "Mapping over ND lists"

# napply
test napply0D {
    # Map over a scalar (simple eval)
} -body {
    napply 0D expr 2 + 2
} -result {4}

test napply1D {
    # Map over a list
} -body {
    napply 1D lindex $testmat 0
} -result {1 4 7}

test napply2D {
    # Map over a matrix
} -body {
    napply 2D {format %.2f} $testmat
} -result {{1.00 2.00 3.00} {4.00 5.00 6.00} {7.00 8.00 9.00}}

# nreduce
test reduce0D_error {
    # Reduce a scalar (produces error)
} -body {
    catch {nreduce 0D max 5}
} -result {1}

test reduce1D_max {
    # Reduce a vector
} -body {
    nreduce 1D max {1 2 3 4 5}
} -result {5}

test reduce1D_sum {
    # Reduce a vector, with sum
} -body {
    nreduce 1D sum {1 2 3 4 5}
} -result {15}

test reduce1D_error {
    # Reduce a vector, along 1st dimension (returns error)
} -body {
    catch {nreduce 1D max {1 2 3 4 5} 1}
} -result {1}

test reduce2D_0 {
    # Reduce a matrix along row dimension
} -body {
    nreduce 2D max {{1 2} {3 4} {5 6} {7 8}}
} -result {7 8}

test reduce2D_1 {
    # Reduce a matrix along column dimension
} -body {
    nreduce 2D max {{1 2} {3 4} {5 6} {7 8}} 1
} -result {2 4 6 8}

# Tensor reductions (using a 2x3x4 tensor)
set myTensor {{{1 2 3 4} {5 6 7 8} {9 10 11 12}} {{13 14 15 16} {17 18 19 20} {21 22 23 24}}}

test reduce3D_0 {
    # Reduce a tensor along 0th dimension (result is 3x4)
} -body {
    nreduce 3D max $myTensor 0
} -result {{13 14 15 16} {17 18 19 20} {21 22 23 24}}

test reduce3D_1 {
    # Reduce a tensor along 1st dimension (result is 2x4)
} -body {
    nreduce 3D max $myTensor 1
} -result {{9 10 11 12} {21 22 23 24}}

test reduce3D_2 {
    # Reduce a tensor along 2nd dimension (result is 2x3)
} -body {
    nreduce 3D max $myTensor 2
} -result {{4 8 12} {16 20 24}}

# nmap
test nmap0 {
    # 0D is just a simple mapping.
} -body {
    nmap 0 x foo y bar {list $x $y}
} -result {foo bar}

test nmap1 {
    # 1D is a list mapping
} -body {
    nmap 1D x {1 2 3} {format %.2f $x}
} -result {1.00 2.00 3.00}

test nmap2 {
    # 2D is a list mapping
} -body {
    nmap 2D x $testmat {format %.2f $x}
} -result {{1.00 2.00 3.00} {4.00 5.00 6.00} {7.00 8.00 9.00}}

# nexpr
test nexpr {
    # nexpr is just a special case of nmap.
} -body {
    assert {[nexpr 1D x {1 2 3} {-$x}] eq {-1 -2 -3}}
    # Basic operations
    assert {[nexpr 2D x $testmat {-$x}] eq {{-1 -2 -3} {-4 -5 -6} {-7 -8 -9}}}
    assert {[nexpr 2D x $testmat {$x / 2.0}] eq {{0.5 1.0 1.5} {2.0 2.5 3.0} {3.5 4.0 4.5}}}
    assert {[nexpr 2D x $testmat y {.1 .2 .3} {$x + $y}] eq {{1.1 2.1 3.1} {4.2 5.2 6.2} {7.3 8.3 9.3}}}
    assert {[nexpr 2D x $testmat y {{.1 .2 .3}} {$x + $y}] eq {{1.1 2.2 3.3} {4.1 5.2 6.3} {7.1 8.2 9.3}}}
    assert {[nexpr 2D x $testmat y {{.1 .2 .3} {.4 .5 .6} {.7 .8 .9}} {$x + $y}] eq {{1.1 2.2 3.3} {4.4 5.5 6.6} {7.7 8.8 9.9}}}
    assert {[nexpr 2D x $testmat {double($x)}] eq {{1.0 2.0 3.0} {4.0 5.0 6.0} {7.0 8.0 9.0}}}
} -result {}

# nop
test nop0_multiple {
    # 0D is just a simple mathop
} -body {
    nop 0D 1 + 1 1
} -result {3}

test nop1_noargs {
    # Self-op (no additional arguments)
} -body {
nop 1D {1 2 3} -
} -result {-1 -2 -3}

test nop1_onearg {
    # Self-op (no additional arguments)
} -body {
    nop 1D {1 2 3} + 1
} -result {2 3 4}

test nop1_dot {
    # Self-op (no additional arguments)
} -body {
    nop 1D {1 2 3} .+ {3 2 1}
} -result {4 4 4}

test nop2 {
    # Test for higher dimensions
} -body {
    nop 2D {{1 2 3}} .+ {3 2 1}
} -result {{4 5 6} {3 4 5} {2 3 4}}

test nop_error {
    # Error for using .op incorrectly.
} -body {
    nop 1D {1 2 3} .+ {1 1 1} {5 3 9}
} -returnCodes {1} -result "wrong # args: should be \"nop nd ndlist1 .op ndlist2\""
