package require tin 1.0
tin import assert from tin
tin import tcltest
set version 0.1
set vutil_version 1.1
set config [dict create VERSION $version VUTIL_VERSION $vutil_version]
tin bake src build $config
tin bake doc/template/version.tin doc/template/version.tex $config

source build/ndlist.tcl 
namespace import ndlist::*

tin import flytrap

# Matrix for testing (DO NOT CHANGE)
set testmat {{1 2 3} {4 5 6} {7 8 9}}

# ndlist 
################################################################################
puts "Expanding ragged list"
test nrepeat {
    # Assert that nrepeat works
} -body {
    ndlist 2D {1 {2 3}}
} -result {{1 0} {2 3}}

# nrepeat
################################################################################
puts "Creating ndlist value..."
test nrepeat {
    # Assert that nrepeat works
} -body {
    nrepeat {1 2 3} 0 
} -result {{{0 0 0} {0 0 0}}}

# nrange
################################################################################
puts "Creating nrange"
test nrange {
    # Generate range of integers
} -body {
assert [nrange 3] eq [nrange 0 2]
assert [nrange 10 3 -2] eq {10 8 6 4}
assert [nrange 4] eq {0 1 2 3}
assert [nrange 0 4] eq {0 1 2 3 4}
assert [nrange 0 4 2] eq {0 2 4}
} -result {}

# nshape/nsize 
################################################################################
puts "Getting shape/size of ndlists"
test nshape {
    # Assert that nshape works
} -body {
    nshape 2D {{1 2} {3 4} {5 6}}
} -result {3 2}

test nsize {
    # Assert that nsize works
} -body {
    nsize 2D {{1 2} {3 4} {5 6}}
} -result {6}

# nflatten/nreshape
################################################################################

puts "Flattening/reshaping ndlists..."

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

test nreshape1 {
    # Check that nreshape works for matrices
} -body {
    nreshape 1D {1 2 3 4 5 6} {2 3}
} -result {{1 2 3} {4 5 6}}

test nreshape2 {
    # Check that nreshape works for higher dimensions
} -body {
    nreshape 1D {1 2 3 4 5 6 7 8} {2 2 2}
} -result {{{1 2} {3 4}} {{5 6} {7 8}}}


# ntranspose
################################################################################

puts "Transposing ndlists ..."

test ntranspose0D {
    # Transpose scalar returns self
} -body {
    ntranspose 0D {hello world}
} -result {hello world}

test ntranspose1D {
    # Transpose vector just returns self
} -body {
    ntranspose 1D {hello world}
} -result {hello world}

test ntranspose2D_default {
    # Flip rows/columns
} -body {
    ntranspose 2D {{1 2} {3 4}}
} -result {{1 3} {2 4}}

test ntranspose2D_11 {
    # Same axis, return self
} -body {
    ntranspose 2D {{1 2} {3 4}} 1 1
} -result {{1 2} {3 4}}

test ntranspose2D_10 {
    # Axis order flipped, still transpose
} -body {
    ntranspose 2D {{1 2} {3 4}} 1 0
} -result {{1 3} {2 4}}

test ntranspose3D_01 {
    # Just flip rows and columns
} -body {
    ntranspose 3D {{{1 2} {3 4}} {{5 6} {7 8}}}; # 2x2x2
} -result {{{1 2} {5 6}} {{3 4} {7 8}}}

test ntranspose3D_12 {
    # transpose inner matrices
} -body {
    ntranspose 3D {{{1 2} {3 4}} {{5 6} {7 8}}} 1 2; # 2x2x2
} -result {{{1 3} {2 4}} {{5 7} {6 8}}}

test ntranspose3D_02 {
    # transpose outer dimensions
} -body {
    ntranspose 3D {{{1 2} {3 4}} {{5 6} {7 8}}} 0 2; # 2x2x2
    # 0,0,0: 1 -> 0,0,0
    # 0,0,1: 2 -> 1,0,0
    # 0,1,0: 3 -> 0,1,0
    # 0,1,1: 4 -> 1,1,0
    # 1,0,0: 5 -> 0,0,1
    # 1,0,1: 6 -> 1,0,1
    # 1,1,0: 7 -> 0,1,1
    # 1,1,1: 7 -> 1,1,1
} -result {{{1 5} {3 7}} {{2 6} {4 8}}}

# ninsert
################################################################################

puts "Combining ndlists ..."

test ninsert1 {
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

test nstack3D_2 {
    # Test on tensors
} -body {
    set x [nreshape 1D {1 2 3 4 5 6 7 8 9} {3 3 1}]; # Create tensor
    set y [nreshape 1D {A B C D E F G H I} {3 3 1}]; # 
    ninsert 3D $x end $y 2
} -result {{{1 A} {2 B} {3 C}} {{4 D} {5 E} {6 F}} {{7 G} {8 H} {9 I}}}

# nget/nset/nreplace (ndlist access/modification)
################################################################################
puts "Accessing/modififying ndlists"

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

# nset --
test nset_I_2D {
    # Check that nset works on a non-existent matrix (and grows the matrix)
    # (nset just calls nreplace)
} -body {
    if {[info exists I]} {unset I}
    for {set i 0} {$i < 3} {incr i} {
        nset I $i $i 1
    }
    set I
} -result {{1 0 0} {0 1 0} {0 0 1}}

test nset_I_3D {
    # Create "Identity tensor"
} -body {
    if {[info exists I]} {unset I}
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

test nset_filler {
    # Test out custom filler
} -body {
    assert $::ndlist::filler eq 0
    set a ""
    set ::ndlist::filler bar; # custom filler
    nset a 1 1 1 foo
} -result {{{bar bar} {bar bar}} {{bar bar} {bar foo}}}
set ::ndlist::filler 0; # reset to default



# nop 
test nop1 {
    # Verify that nop works
} -body {
    assert [nop 1D {1 2 3} + 3] eq {4 5 6}
    assert [nop 1D {1 2 3} -] eq {-1 -2 -3}
    assert [nop 2D $testmat > 4] eq {{0 0 0} {0 1 1} {1 1 1}}
    nop 2D $testmat * 2.0
} -result {{2.0 4.0 6.0} {8.0 10.0 12.0} {14.0 16.0 18.0}}

test nop2 {
    # Nopping all over and back again
} -body {
    nop 2D [nop 2D [nop 2D $testmat + 5] - 2] - 3
} -result $testmat

# nmap
test nmap {
    # nmap for basic functional mapping
} -body {
    nmap 1D x {1 2 3} {format %.2f $x}
} -result {1.00 2.00 3.00}

# i/j/k
test nmap_test {
    # Various tests
} -body {
    assert {[nmap 1D x {1 2 3} {expr {-$x}}] eq {-1 -2 -3}}
    # Filter a column out
    assert {[nmap 2D x $testmat {expr {[j] == 2 ? [continue] : $x}}] eq [nreplace $testmat : 2 ""]}
    # Flip signs
    assert {[nmap 2D x $testmat {expr {$x*([i]%2 + [j]%2 == 1?-1:1)}}] eq {{1 -2 3} {-4 5 -6} {7 -8 9}}}
    # Truncation
    assert {[nmap 1D x $testmat {expr {[i] > 0 ? [break] : $x}}] eq {{1 2 3}}}
    # Basic operations
    assert {[nmap 2D x $testmat {expr {-$x}}] eq {{-1 -2 -3} {-4 -5 -6} {-7 -8 -9}}}

    assert {[nmap 2D x $testmat {expr {$x / 2.0}}] eq {{0.5 1.0 1.5} {2.0 2.5 3.0} {3.5 4.0 4.5}}}
    assert {[nmap 2D x $testmat y {.1 .2 .3} {expr {$x + $y}}] eq {{1.1 2.1 3.1} {4.2 5.2 6.2} {7.3 8.3 9.3}}}
    assert {[nmap 2D x $testmat y {{.1 .2 .3}} {expr {$x + $y}}] eq {{1.1 2.2 3.3} {4.1 5.2 6.3} {7.1 8.2 9.3}}}
    assert {[nmap 2D x $testmat y {{.1 .2 .3} {.4 .5 .6} {.7 .8 .9}} {expr {$x + $y}}] eq {{1.1 2.2 3.3} {4.4 5.5 6.6} {7.7 8.8 9.9}}}

    assert {[nmap 2D x $testmat {expr {double($x)}}] eq {{1.0 2.0 3.0} {4.0 5.0 6.0} {7.0 8.0 9.0}}}
    set cutoff 3
    assert {[nmap 1D x {1 2 3 4 5 6} {expr {$x > $cutoff ? [continue] : $x}}] eq {1 2 3}}
} -result {}

# ndlist/matrix/vector/scalar
################################################################################
puts "Creating ndlist objects..."

test ndlist {
    # Create ndlist object
} -body {
    ::ndlist::ndobj new x 3D [nrepeat {1 2 3} 0.0]
    $x info
} -result {exists 1 ndims 3 shape {1 2 3} type ndlist value {{{0.0 0.0 0.0} {0.0 0.0 0.0}}}}

test tensor {
    # Create tensor object (shorthand for ndlist new)
} -body {
    tensor y 3D [nrepeat {1 2 3} 0.0]
    assert {[$x info] eq [$y info]}
} -result {}

test matrix {
    # Create ndlist object
} -body {
    matrix x $testmat
    $x info
} -result [list exists 1 ndims 2 shape {3 3} type ndlist value $testmat]

test vector {
    # Create vector
} -body {
    vector x {1 2 3}
    $x info
} -result {exists 1 ndims 1 shape 3 type ndlist value {1 2 3}}

test scalar {
    # Create scalar
} -body {
    scalar x 5.0
    $x info
} -result {exists 1 ndims 0 shape {} type ndlist value 5.0}



# neval/nexpr
################################################################################

test neval {
    # neval 
} -body {
    neval {string length $@.} 2D {{hello world} {foo bar}}
} -result {{5 5} {3 3}}

test nexpr_1 {
    # nexpr and misc tests
} -body {
    matrix a [nrepeat {2 2} 1]
    set b $a
    nexpr {$@a*2.0} --> a
    assert {![info object isa object $b]}; # garbage collection
    $a
} -result {{2.0 2.0} {2.0 2.0}}

test nexpr_2 {
    # use ndobjects
} -body {
    matrix x $testmat
    scalar y 5.0
    set code [catch {nexpr {$@x + $@y}} result]; # incompatible dimensionality
    list $code $result
} -result {1 {incompatible dimensionality}}

test nexpr_2 {
    # resolve error, and change ndims
} -body {
    $y ndims 2
    nexpr {$@x + $@y}
} -result {{6.0 7.0 8.0} {9.0 10.0 11.0} {12.0 13.0 14.0}} 

# NDOBJ METHODS
################################################################################
# @ <- --> = .= := ::=

# ndims/shape/size
################################################################################

test ndobj_ndims {
    # Check dimensionality of ndobj
} -body {
    matrix x $testmat
    $x ndims
} -result {2}

test ndobj_shape {
    # Check that shape is correct
} -body {
    tensor x 3D [nrepeat {3 2 1} foo]
    assert [$x shape 0] == 3
    assert [$x shape 1] == 2
    assert [$x shape 2] == 1
    $x shape
} -result {3 2 1}

test ndobj_size {
    # Check size
} -body {$x size} -result 6

# flatten/reshape
################################################################################

test ndobj_flatten {
    # Flatten an ND list
} -body {
    matrix x $testmat
    $x flatten
    $x info
} -result {exists 1 ndims 1 shape 9 type ndlist value {1 2 3 4 5 6 7 8 9}}

test ndobj_reshape {
    # Reshape an ND list 
} -body {
    matrix x {{1 2} {3 4} {5 6}}
    $x reshape {2 3}
    $x
} -result {{1 2 3} {4 5 6}}

# transpose/insert
################################################################################

test ndobj_transpose {
    # Transpose an ndobj
} -body {
    [$x transpose]
} -result {{1 4} {2 5} {3 6}}

test ndobj_insert {
    # Insert a column to an ND list
} -body {
    [$x insert 1 {A B C} 1]
} -result {{1 A 4} {2 B 5} {3 C 6}}

# = assignment
################################################################################

test ndobj_assign_and_copy {
    # Assign value
} -body {
    [[matrix x] = $testmat]
} -result $testmat

# --> copying
################################################################################

test ndobj_copy {
    # copy object
} -body {
    [$x --> y]
} -result $testmat

# .= assignment
################################################################################

test ndobj_nop {
    # Verify that self-op method works, and is equivalent to nexpr
} -body {
    $x .= {* 2.0}
    $x .= {+ 5}
    $x .= {- 1.5}
    $x .= {/ 2}
    assert [$x] == [nexpr {((($@y * 2.0) + 5) - 1.5) / 2}]
} -result {}

# := assignment
################################################################################

test ndobj_nexpr {
    # Verify that assigment operators work
} -body {
    [$x := {$@y + 5.0}]
} -result {{6.0 7.0 8.0} {9.0 10.0 11.0} {12.0 13.0 14.0}} 

# ::= assignment
################################################################################

test ndobj_neval {
    # Use ::= assigment operator
} -body {
    $x ::= {format %.2f $@.}
    $x
} -result {{6.00 7.00 8.00} {9.00 10.00 11.00} {12.00 13.00 14.00}} 

# <- assignment
################################################################################

test ndobj_objassignment {
    # Assign an object directly
} -body {
    matrix y
    [$y <- $x]
} -result {{6.00 7.00 8.00} {9.00 10.00 11.00} {12.00 13.00 14.00}} 

# @ indexing
################################################################################

test ndobj_index {
    # Verify that indexing works
} -body {
    matrix x $testmat
    $x @ 0:2:end :
} -result {{1 2 3} {7 8 9}}

test ndobj_at_replacement {
    # Verify that replacement works
} -body {
    $x --> y
    [$y @ 0* 1:0 = a]
} -result {{a a 3} {4 5 6} {7 8 9}}

test ndobj_at_deletion {
    # Verify that removal works
} -body {
    $x --> y
    [$y @ : 0 = ""]
} -result {{2 3} {5 6} {8 9}}

test ndobj_at_newobj {
    # Verify that you can create new ndobj from range
} -body {
    $x @ 0:2:end : --> y
    $y
} -result {{1 2 3} {7 8 9}}

test ndobj_at_setobj {
    # Verify that you can modify portion with another object
} -body {
    scalar z 5.0
    $x --> y
    $y @ 0* 1* <- $z
    $y @ 0* 1*
} -result 5.0

test ndobj_at_selfop {
    # Verify that self-op index methods work, and are equivalent to nexpr
} -body {
    $x --> y
    $y @ : 0 --> z
    $y @ : 0 .= {* 2.0}
    $y @ : 0 .= {+ 5}
    $y @ : 0 .= {- 1.5}
    $y @ : 0 .= {/ 2}
    assert [$y @ : 0] == [nexpr {((($@z * 2.0) + 5) - 1.5) / 2}]
} -result {}

test ndobj_selfexpr {
    # Ensure that you can run nexpr on portion of ndobj
} -body {
    $x --> y
    $y @ : 0 --> z
    $y @ : 0 := {((($@. * 2.0) + 5) - 1.5) / 2}
    assert [$y @ : 0] == [nexpr {((($@z * 2.0) + 5) - 1.5) / 2}]
}

test ndobj_selfeval {
    # Ensure that neval works on portion of range
} -body {
    $x --> y
    [$y @ 0 : ::= {format %.2f $@.}]
} -result {{1.00 2.00 3.00} {4 5 6} {7 8 9}}


# Check number of failed tests
set nFailed $::tcltest::numTests(Failed)

# Clean up and report on tests
cleanupTests

# If tests failed, return error
if {$nFailed > 0} {
    error "$nFailed tests failed"
}
# Tests passed, copy build files to main folder and install
file copy -force {*}[glob -directory build *] [pwd]

exec tclsh install.tcl

# Verify installation
tin forget ndlist
tin clear
tin import ndlist -exact $version
