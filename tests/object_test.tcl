
# Command   test?
# narray    Y
# nexpr     Y
# neval     Y

# Method    test?
# (blank)   Y
# -->       Y
# |         Y
# &         Y
# =         Y
# :=        Y
# @         Y
#   (blank) Y
#   -->     Y
#   |       Y
#   &       Y
#   =       Y
#   :=      Y
# rank      Y
# shape     Y
# size      Y
# remove    Y
# insert    Y
# apply     Y
# reduce    Y



test narray0D {
    # Create a scalar
} -body {
    narray new 0 x {hello world}
    assert [$x rank] == 0
    assert [$x shape] eq {}
    assert [$x size] eq {}
    $x
} -result {hello world}

test narray1D {
    # Create a vector
} -body {
    narray new 1 x {hello world}
    assert [$x rank] == 1
    assert [$x shape] eq 2
    assert [$x size] == 2
    assert [$x @ 0] eq {hello}
    assert [$x @ 1] eq {world}
    $x
} -result {hello world}

test narray2D {
    # Create a matrix
} -body {
    narray new 2 x {{1 2} {3 4} {5 6}}
    assert [$x rank] == 2
    assert [$x shape] eq {3 2}
    assert [$x size] == 6
    assert [$x @ 0 :] eq {{1 2}}
    assert [$x @ : 0] eq {1 3 5}
    $x
} -result {{1 2} {3 4} {5 6}}

test narray3D {
    # Tensor
} -body {
    narray new 3 x {{{1 2} {3 4}} {{5 6} {7 8}} {{9 10} {11 12}}}
    assert [$x rank] == 3
    assert [$x shape] eq {3 2 2}
    assert [$x size] == 12
    assert [$x @ 0 : 1] eq {{2 4}}
    assert [$x @ : 0 1] eq {2 6 10}
    $x
} -result {{{1 2} {3 4}} {{5 6} {7 8}} {{9 10} {11 12}}}

test neval {
    # nd-list mapping using references
} -body {
    narray new 2 x {{1 2 3} {4 5 6}}
    narray new 2 y {2 3}
    neval {string cat $@y $@x}
} -result {{21 22 23} {34 35 36}}

test nexpr {
    # Version of neval, but for math
} -body {
    narray new 2 x {{1 2 3} {4 5 6}}
    nexpr {$@x * 2.0}
} -result {{2.0 4.0 6.0} {8.0 10.0 12.0}}

test nexpr_advanced {
    # Use advanced features of nexpr
} -body {
    narray new 2 x {{1 2 3} {4 5 6}}
    narray new 1 y {0.1 0.2 0.3}
    narray new 1 z [nexpr {$@(1*,:) + $@y} $x rank]
    assert $rank == 1
    $z
} -result {4.1 5.2 6.3}

test nexpr_assignment {
    # Using the := operator
} -body {
    narray new 1 x {1 2 3}
    narray new 1 y {4 5 6}
    [narray new 1 z] := {$@x + $@y}
    $z
} -result {5 7 9}

test columnswap {
    # Swap columns in a matrix
} -body {
    narray new 2 x {{1 2 3} {4 5 6}}
    $x @ : {1 2} = [$x @ : {2 1}]
    $x
} -result {{1 3 2} {4 6 5}}

test nexpr_error1 {
    # Incompatible rank
} -body {
    narray new 2 x {1 2 3}
    narray new 1 y {1 2 3}
    catch {nexpr {$@x + $@y}}
} -result {1}

test nexpr_error2 {
    # Incompatible dimensions
} -body {
    narray new 1 x {1 2 3}
    narray new 1 y {1 2 3 4}
    catch {nexpr {$@x + $@y}}
} -result {1}

test index_methods {
    # Test all index methods
} -body {
    narray new 2 x {{1 2 3} {4 5 6}}
    # Basic indexing
    assert [$x @ 0 1] eq {2}
    # Assignment
    assert [$x @ 0 1 = 5] eq $x
    assert [$x @ 0 1] eq {5}
    # Pipe operator
    assert [$x @ 0 1 | = 10] eq {10}
    assert [$x @ 0 1] eq {5}
    # Reference operator
    assert [$x @ 0 1 & ref {incr ref}] eq {6}
    assert [$x @ 0 1] == 6
    # Copy operator
    $x @ 0 1 --> y
    assert [$y rank] == 2
    assert [$y shape] eq {1 1}
    assert [$y size] == 1
    # Math assignment operator
    assert [$x @ 0 1 := {$@ + 2.0}] eq $x
    assert [$x @ 0 1] eq {8.0}
    $x
} -result {{1 8.0 3} {4 5 6}}

test all_operators {
    # Test all operators (except index method)
} -body {
    narray new 2 x
    # Assignment
    $x = {{1 2 3} {4 5 6}}
    assert [$x] eq {{1 2 3} {4 5 6}}
    # Math Assignment
    $x := {double($@x)}
    assert [$x] eq {{1.0 2.0 3.0} {4.0 5.0 6.0}}
    # Copying
    $x --> y
    assert [$y] eq [$x]
    # Temporary object
    assert [$y | = {hello world}] eq {hello world}
    assert [$y] eq [$x]
    # Reference evaluation
    $y & ref {lappend ref {A B C}}
    assert [$y] eq {{1.0 2.0 3.0} {4.0 5.0 6.0} {A B C}}
} -result {}

# Other methods
test other_methods {
    # Test all other methods
} -body {
    narray new 2 x {{1 2 3} {4 5 6}}
    assert [[$x remove 1]] eq {{1 2 3}}
    assert [[$x insert 1 {{A B C}}]] eq {{1 2 3} {A B C}}
    narray new 2 y {{1 2 3} {4 5 6}}
    assert [$y apply ::tcl::mathfunc::double] eq {{1.0 2.0 3.0} {4.0 5.0 6.0}}
    assert [$y reduce max] eq {4 5 6}
    assert [$y reduce max 1] eq {3 6}
} -result {}
