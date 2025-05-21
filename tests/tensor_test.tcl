# Tensor (ND-list) tests

# Matrix for testing (DO NOT CHANGE)
set testmat {{1 2 3} {4 5 6} {7 8 9}}

# ndims/nshape/nsize 
################################################################################
# ndlist

test ndims {
    # Automatically determine dimensions of a matrix
} -body {
    ndims $testmat
} -result 2

test ndims_error {
    # Throws error if ragged.
} -body {
    ndims {1 {2 3}} 2
} -returnCodes {1} -result {not a valid 2D-list}

# nshape
test nshape {
    # Assert that nshape works
} -body {
    nshape {{1 2} {3 4} {5 6}}
} -result {3 2}

# Blanks must be contained within a list, unless if entire ndlist is blank.
test nshape_blank0 {} -body {nshape "" 2} -result {0 0}
test nshape_blank1 {} -body {nshape {{}} 2} -returnCodes {1} -result {null dimension along non-zero axis}
test nshape_blank2 {} {nshape {{{}}} 2} {1 1}

# nsize
test nsize0D {
    # No size for scalars
} -body {
    nsize foo
} -result {}

test nsize1D {
    # Same as llength
} -body {
    nsize {foo bar}
} -result {2}

test nsize2D {
    # Product of rows/columns
} -body {
    nsize {{1 2} {3 4} {5 6}}
} -result {6}

test nsize3D {
    # Product of all dimensions
} -body {
    nsize {{{1 2} {3 4} {5 6}} {{1 2} {3 4} {5 6}}}
} -result {12}

# nrepeat/nreshape/nexpand
################################################################################

# nfull
test nfull {
    # Create a tensor filled with a value.
} -body {
    nfull 0.0 1 2 3
} -result {{{0.0 0.0 0.0} {0.0 0.0 0.0}}}

test nrand0 {
    # Random number generator function (no args)
} -body {
    expr {srand(0)}
    nrand
} -result {0.013469574513598146}

test nrand1 {
    # list of random numbers
} -body {
    expr {srand(0)}
    nrand 2
} -result {0.013469574513598146 0.3831388500440581}

test nrand_2 {
    # matrix of random numbers
} -body {
    expr {srand(0)}
    nrand 1 2
} -result {{0.013469574513598146 0.3831388500440581}}

# nreshape
test nreshape1 {
    # Check that nreshape works for matrices
} -body {
    nreshape {1 2 3 4 5 6} 2 3
} -result {{1 2 3} {4 5 6}}

test nreshape_error {
    # incompatible length error
} -body {
    nreshape {1 2 3 4 5 6} 3 3
} -returnCodes {1} -result {incompatible dimensions}

test nreshape_error2 {
    # incompatible length error (dynamic)
} -body {
    nreshape {1 2 3 4 5 6} 4 *
} -returnCodes {1} -result {incompatible dimensions}

test nreshape2 {
    # Check that nreshape works for higher dimensions
} -body {
    nreshape {1 2 3 4 5 6 7 8} 2 2 2
} -result {{{1 2} {3 4}} {{5 6} {7 8}}}

test nreshape_error3 {
    # too many dynamic axes (higher dimensions too)
} -body {
    nreshape {1 2 3 4 5 6 7 8 9} 3 * *
} -returnCodes {1} -result {can only make one axis dynamic}

test nrepeat {
    # Repeat along a dimension
} -body {
    nrepeat {{1 2} {3 4}} 1 2
} -result {{1 2 1 2} {3 4 3 4}}

test nrepeat0 {} {nrepeat {{1 2} {3 4}}} {{1 2} {3 4}}
test nrepeat1 {} {nrepeat {{1 2} {3 4}} 2} {{1 2} {3 4} {1 2} {3 4}}
test nrepeat3 {} {nrepeat {{1 2} {3 4}} 3 1 2} {{{1 1} {2 2}} {{3 3} {4 4}} {{1 1} {2 2}} {{3 3} {4 4}} {{1 1} {2 2}} {{3 3} {4 4}}}
test nrepeat_blank1 {} {nrepeat {} 2 2} {}
test nrepeat_blank2 {} {nrepeat {{}} 2 2} {{} {}}
test nrepeat_blank2 {} {nrepeat {{{}}} 2 2} {{{} {}} {{} {}}}

# nexpand
test nexpand {
    # Expand an ndlist
} -body {
    nexpand {1 2 3} 3 2
} -result {{1 1} {2 2} {3 3}}

test nexpand_3D {
    # Expand an ndlist to a tensor
} -body {
    nexpand {{1 2 3}} 3 3 2
} -result {{{1 1} {2 2} {3 3}} {{1 1} {2 2} {3 3}} {{1 1} {2 2} {3 3}}}

test nexpand_stride {
    # Expand a strided ndlist
} -body {
    nexpand {{1 2}} 2 4
} -result {{1 2 1 2} {1 2 1 2}}

test nexpand_-1 {
    # Use "-1" to say "same shape"
} -body {
    nexpand {{1 2}} -1 4
} -result {{1 2 1 2}}

test nexpand_error {
    # Cannot expand if dimensions don't match.
} -body {
    nexpand {1 2 3} 4 2
} -returnCodes {1} -result {incompatible dimensions}

test npad0 {
    # Padding an empty list just calls nfull
} -body {
    set a ""
    set a [npad $a 0 3 3]
} -result {{0 0 0} {0 0 0} {0 0 0}}

test npad1 {
    # Extend an ND list with values
} -body {
    set a [npad $a 1 1 1]
} -result {{0 0 0 1} {0 0 0 1} {0 0 0 1} {1 1 1 1}}

test npad2 {
    # Only extend along one axis (keep the other dimension the same)
} -body {
    set a [npad $a 2 1 0]
} -result {{0 0 0 1} {0 0 0 1} {0 0 0 1} {1 1 1 1} {2 2 2 2}}

# nextend 
test nextend0 {
    # Extending an empty list just calls nfull
} -body {
    set a ""
    set a [nextend $a 0 3 3]
} -result {{0 0 0} {0 0 0} {0 0 0}}

test nextend1 {
    # Extend an ND list with values
} -body {
    set a [nextend $a 1 4 4]
} -result {{0 0 0 1} {0 0 0 1} {0 0 0 1} {1 1 1 1}}

test nextend2 {
    # Only extend along one axis (keep the other dimension the same)
} -body {
    set a [nextend $a 2 5 -1]
} -result {{0 0 0 1} {0 0 0 1} {0 0 0 1} {1 1 1 1} {2 2 2 2}}

# nget/nset/nreplace (ndlist access/modification)
################################################################################

test ParseIndex {
    # Test index parser
} -body {
    set n 10
    # All indices
    assert [::ndlist::ParseIndex $n :] eq {A {}}
    assert [::ndlist::ParseIndex $n 0:end] eq {A {}}
    assert [::ndlist::ParseIndex $n 0:1:end] eq {A {}}
    # Range of indices
    assert [::ndlist::ParseIndex $n 1:8] eq {R {1 8}}
    assert [::ndlist::ParseIndex $n 1:1:8] eq {R {1 8}}
    assert [::ndlist::ParseIndex $n end:4] eq {R {9 4}}
    assert [::ndlist::ParseIndex $n end:-1:4] eq {R {9 4}}
    assert [catch {::ndlist::ParseIndex $n 0:end+1}]
    assert [catch {::ndlist::ParseIndex $n end+1:0}]
    # Stepped range of indices (list)
    assert [::ndlist::ParseIndex $n 0:2:6] eq {L {0 2 4 6}}
    assert [::ndlist::ParseIndex $n 6:-2:0] eq {L {6 4 2 0}}
    assert [catch {::ndlist::ParseIndex $n 0:2:10}]
    assert [catch {::ndlist::ParseIndex $n 10:2:0}]
    # List of indices 
    assert [::ndlist::ParseIndex $n {0 end end-1}] eq {L {0 9 8}}
    assert [::ndlist::ParseIndex $n {-1 -2 5+2}] eq {L {9 8 7}}
    assert [::ndlist::ParseIndex $n {end-3}] eq {L 6}
    assert [catch {::ndlist::ParseIndex $n {0 1 2 10}}]
    # Single index
    assert [::ndlist::ParseIndex $n end*] eq {S 9}
    assert [catch {::ndlist::ParseIndex $n {end+1*}}]
} 

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
    assert {[nreplace $testmat : : a]                               eq {{a a a} {a a a} {a a a}}}
    assert {[nreplace $testmat : : {a b c}]                         eq {{a a a} {b b b} {c c c}}}
    assert {[nreplace $testmat : : {{a b c}}]                       eq {{a b c} {a b c} {a b c}}}
    assert {[nreplace $testmat : : {{a b c} {d e f} {g h i}}]       eq {{a b c} {d e f} {g h i}}}
    assert {[nreplace $testmat : 0 a]                               eq {{a 2 3} {a 5 6} {a 8 9}}}
    assert {[nreplace $testmat : 0 {a b c}]                         eq {{a 2 3} {b 5 6} {c 8 9}}}
    assert {[nreplace $testmat : 0* a]                              eq {{a 2 3} {a 5 6} {a 8 9}}}
    assert {[nreplace $testmat : 0* {a b c}]                        eq {{a 2 3} {b 5 6} {c 8 9}}}
    assert {[nreplace $testmat : 0:1 a]                             eq {{a a 3} {a a 6} {a a 9}}}
    assert {[nreplace $testmat : 0:1 {a b c}]                       eq {{a a 3} {b b 6} {c c 9}}}
    assert {[nreplace $testmat : 0:1 {{a b}}]                       eq {{a b 3} {a b 6} {a b 9}}}
    assert {[nreplace $testmat : 0:1 {{a b} {c d} {e f}}]           eq {{a b 3} {c d 6} {e f 9}}}
    assert {[nreplace $testmat : 1:0 a]                             eq {{a a 3} {a a 6} {a a 9}}}
    assert {[nreplace $testmat : 1:0 {a b c}]                       eq {{a a 3} {b b 6} {c c 9}}}
    assert {[nreplace $testmat : 1:0 {{a b}}]                       eq {{b a 3} {b a 6} {b a 9}}}
    assert {[nreplace $testmat : 1:0 {{a b} {c d} {e f}}]           eq {{b a 3} {d c 6} {f e 9}}}
    assert {[nreplace $testmat 0 : a]                               eq {{a a a} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0 : {{a b c}}]                       eq {{a b c} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0 0 a]                               eq {{a 2 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0 0* a]                              eq {{a 2 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0 0:1 a]                             eq {{a a 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0 0:1 {{a b}}]                       eq {{a b 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0 1:0 a]                             eq {{a a 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0 1:0 {{a b}}]                       eq {{b a 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0* : a]                              eq {{a a a} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0* : {a b c}]                        eq {{a b c} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0* 0 a]                              eq {{a 2 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0* 0* {hello world}]                 eq {{{hello world} 2 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0* 0:1 a]                            eq {{a a 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0* 0:1 {a b}]                        eq {{a b 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0* 1:0 a]                            eq {{a a 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0* 1:0 {a b}]                        eq {{b a 3} {4 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 : a]                             eq {{a a a} {a a a} {7 8 9}}}
    assert {[nreplace $testmat 0:1 : {{a b c}}]                     eq {{a b c} {a b c} {7 8 9}}}
    assert {[nreplace $testmat 0:1 : {a b}]                         eq {{a a a} {b b b} {7 8 9}}}
    assert {[nreplace $testmat 0:1 : {{a b c} {d e f}}]             eq {{a b c} {d e f} {7 8 9}}}
    assert {[nreplace $testmat 0:1 0 a]                             eq {{a 2 3} {a 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 0 {a b}]                         eq {{a 2 3} {b 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 0* a]                            eq {{a 2 3} {a 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 0* {{hello world} {foo bar}}]    eq {{{hello world} 2 3} {{foo bar} 5 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 0:1 a]                           eq {{a a 3} {a a 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 0:1 {a b}]                       eq {{a a 3} {b b 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 0:1 {{a b}}]                     eq {{a b 3} {a b 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 0:1 {{a b} {c d}}]               eq {{a b 3} {c d 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 1:0 a]                           eq {{a a 3} {a a 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 1:0 {a b}]                       eq {{a a 3} {b b 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 1:0 {{a b}}]                     eq {{b a 3} {b a 6} {7 8 9}}}
    assert {[nreplace $testmat 0:1 1:0 {{a b} {c d}}]               eq {{b a 3} {d c 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 : a]                             eq {{a a a} {a a a} {7 8 9}}}
    assert {[nreplace $testmat 1:0 : {{a b c}}]                     eq {{a b c} {a b c} {7 8 9}}}
    assert {[nreplace $testmat 1:0 : {a b}]                         eq {{b b b} {a a a} {7 8 9}}}
    assert {[nreplace $testmat 1:0 : {{a b c} {d e f}}]             eq {{d e f} {a b c} {7 8 9}}}
    assert {[nreplace $testmat 1:0 0 a]                             eq {{a 2 3} {a 5 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 0 {a b}]                         eq {{b 2 3} {a 5 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 0* a]                            eq {{a 2 3} {a 5 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 0* {{hello world} {foo bar}}]    eq {{{foo bar} 2 3} {{hello world} 5 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 0:1 a]                           eq {{a a 3} {a a 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 0:1 {a b}]                       eq {{b b 3} {a a 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 0:1 {{a b}}]                     eq {{a b 3} {a b 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 0:1 {{a b} {c d}}]               eq {{c d 3} {a b 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 1:0 a]                           eq {{a a 3} {a a 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 1:0 {a b}]                       eq {{b b 3} {a a 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 1:0 {{a b}}]                     eq {{b a 3} {b a 6} {7 8 9}}}
    assert {[nreplace $testmat 1:0 1:0 {{a b} {c d}}]               eq {{d c 3} {b a 6} {7 8 9}}}
}

test nreplace_blank {
    # Behavior of blank replacement.
} -body {
    assert [nreplace $testmat ""]               eq ""
    assert [nreplace $testmat : ""]             eq ""
    assert [nreplace $testmat : : ""]           eq ""
    assert [nreplace $testmat 0 : ""]           eq {{4 5 6} {7 8 9}}
    assert [nreplace $testmat 0* : ""]          eq {{4 5 6} {7 8 9}}
    assert [nreplace $testmat 0:1 : ""]         eq {{7 8 9}}
    assert [nreplace $testmat 1:0 : ""]         eq {{7 8 9}}
    assert [nreplace $testmat : 0 ""]           eq {{2 3} {5 6} {8 9}}
    assert [nreplace $testmat : 0* ""]          eq {{2 3} {5 6} {8 9}}
    assert [nreplace $testmat : 0:1 ""]         eq {3 6 9}
    assert [nreplace $testmat : 1:0 ""]         eq {3 6 9}
    # Replacing with blanks (not deleting)
    assert [nreplace $testmat 0* 0* ""]         eq {{{} 2 3} {4 5 6} {7 8 9}}
    assert [nreplace $testmat : {{}}]           eq {{} {} {}}
    assert [nreplace $testmat : 0:end-1 {{{}}}] eq {{{} {} 3} {{} {} 6} {{} {} 9}}
}

test nremove {
    # Remove portions of an ndlist
} -body {
    # Default axis is 0
    assert [nremove $testmat :]         eq ""
    assert [nremove $testmat : 1]       eq ""
    assert [nremove $testmat 0]         eq {{4 5 6} {7 8 9}}
    assert [nremove $testmat 0*]        eq {{4 5 6} {7 8 9}}
    assert [nremove $testmat 0:1]       eq {{7 8 9}}
    assert [nremove $testmat 1:0]       eq {{7 8 9}}
    assert [nremove $testmat 0 1]       eq {{2 3} {5 6} {8 9}}
    assert [nremove $testmat 0* 1]      eq {{2 3} {5 6} {8 9}}
    assert [nremove $testmat 0:1 1]     eq {3 6 9}
    assert [nremove $testmat 1:0 1]     eq {3 6 9}
}

# Various tests for 3D tensors 
set x {{{1 2 3} {4 5 6}} {{7 8 9} {10 11 12}}}
test nget3 {} {nget $x : : :} $x
test nget3 {} {nget $x 0 : :} {{{1 2 3} {4 5 6}}}
test nget3 {} {nget $x 0 : 0:1} {{{1 2} {4 5}}}
test nget3 {} {nget $x 0 1* 0:1} {{4 5}}
test nget3 {} {nget $x 0* : 2} {3 6}
test nreplace3 {} {nreplace $x : : : 0}             {{{0 0 0} {0 0 0}} {{0 0 0} {0 0 0}}}
test nreplace3 {} {nreplace $x : : 0:1 0}           {{{0 0 3} {0 0 6}} {{0 0 9} {0 0 12}}}
test nreplace3 {} {nreplace $x : : {0 2} 0}         {{{0 2 0} {0 5 0}} {{0 8 0} {0 11 0}}}
test nreplace3 {} {nreplace $x : : 2* {{{}}}}       {{{1 2 {}} {4 5 {}}} {{7 8 {}} {10 11 {}}}}
test nreplace3 {} {nreplace $x 0* 0:end 0:1 {a b}}  {{{a a 3} {b b 6}} {{7 8 9} {10 11 12}}}
test nreplace3 {} {nreplace $x : : 0 ""}            {{{2 3} {5 6}} {{8 9} {11 12}}}
test nreplace3 {} {nremove $x 0 2}                  {{{2 3} {5 6}} {{8 9} {11 12}}}

# nset (just calls nreplace)
test nset2 {
    # Swap rows and columns (example)
} -body {
    set a {{1 2} {3 4} {5 6}}
    nset a {1 0} : [nget $a {0 1} :]
} -result {{3 4} {1 2} {5 6}}

test nset_I_3D {
    # Create "Identity tensor"
} -body {
    set I [nfull 0 3 3 3]
    for {set i 0} {$i < 3} {incr i} {
        nset I $i $i $i 1
    }
    set I
} -result {{{1 0 0} {0 0 0} {0 0 0}} {{0 0 0} {0 1 0} {0 0 0}} {{0 0 0} {0 0 0} {0 0 1}}}

# ninsert/ncat
################################################################################

# ninsert
test ninsert0D {
    # Error, cannot stack scalars.
} -body {
    ninsert foo 0 bar
} -returnCodes {1} -result {axis out of range}

test ninsert1D {
    # Stack vectors (simple concat)
} -body {
    ninsert {1 2 3} end {4 5 6} 0
} -result {1 2 3 4 5 6}

test ninsert1D_2 {
    # Insert before end.
} -body {
    ninsert {1 2 3} 2 {4 5 6} 0
} -result {1 2 4 5 6 3}

test ninsert2D_0 {
    # Create headers
} -body {
    ninsert $testmat 0 {{A B C}}
} -result {{A B C} {1 2 3} {4 5 6} {7 8 9}}

test ninsert2D_1 {
    # Augment matrices (simple concat)
} -body {
    ninsert {1 2 3} end {4 5 6} 1 2
} -result {{1 4} {2 5} {3 6}}

test ninsert3D_2 {
    # Test on tensors
} -body {
    set x [nreshape {1 2 3 4 5 6 7 8 9} 3 3 1]; # Create tensor
    set y [nreshape {A B C D E F G H I} 3 3 1]; # 
    ninsert $x end $y 2 3 
} -result {{{1 A} {2 B} {3 C}} {{4 D} {5 E} {6 F}} {{7 G} {8 H} {9 I}}}

# ncat
test ncat {
    # ncat is simply a special case of ninsert.
} -body {
    assert [ninsert {1 2 3} end {4 5 6} 0] eq [ncat {1 2 3} {4 5 6} 0]
    assert [ninsert {1 2 3} end {4 5 6} 1 2] eq [ncat {1 2 3} {4 5 6} 1 2]
    assert [ninsert $x end $y 2 3] eq [ncat $x $y 2 3]
} -result {}

# nflatten/nswapaxes
################################################################################

# nflatten
test nflatten0D {
    # Turn scalar into vector
} -body {
    nflatten {hello world} 0
} -result {{hello world}}

test nflatten1D {
    # Verify vector
} -body {
    nflatten {hello world} 1
} -result {hello world}

test nflatten2D {
    # Flatten matrix to vector
} -body {
    nflatten {{1 2} {3 4} {5 6}}
} -result {1 2 3 4 5 6}

test nflatten3D {
    # Flatten tensor to vector
} -body {
    nflatten {{{1 2} {3 4}} {{5 6} {7 8}}}
} -result {1 2 3 4 5 6 7 8}

# nswapaxes
test nswapaxes_error {
    # Error, axes must be positive
} -body {
    nswapaxes {hello world} -1 0
} -returnCodes {1} -result {axis out of range}

test nswapaxes_error {
    # Transpose vector just returns self
} -body {
    nswapaxes {hello world} 0 0
} -result {hello world}

test nswapaxes_01 {
    # Flip rows/columns
} -body {
    nswapaxes {{1 2} {3 4}} 0 1
} -result {{1 3} {2 4}}

test nswapaxes_11 {
    # Same axis, return self
} -body {
    nswapaxes {{1 2} {3 4}} 1 1
} -result {{1 2} {3 4}}

test nswapaxes_10 {
    # Axis order flipped, still transpose
} -body {
    nswapaxes {{1 2} {3 4}} 1 0
} -result {{1 3} {2 4}}

test nswapaxes_01 {
    # Just flip rows and columns
} -body {
    nswapaxes {{{1 2} {3 4}} {{5 6} {7 8}}} 0 1; # 2x2x2
} -result {{{1 2} {5 6}} {{3 4} {7 8}}}

test nswapaxes_12 {
    # transpose inner matrices
} -body {
    nswapaxes {{{1 2} {3 4}} {{5 6} {7 8}}} 1 2; # 2x2x2
} -result {{{1 3} {2 4}} {{5 7} {6 8}}}

test nswapaxes_02 {
    # transpose outer dimensions
} -body {
    nswapaxes {{{1 2} {3 4}} {{5 6} {7 8}}} 0 2; # 2x2x2
    # i,j,k -> k,j,i
    # 0,0,0: 1 -> 0,0,0
    # 0,0,1: 2 -> 1,0,0
    # 0,1,0: 3 -> 0,1,0
    # 0,1,1: 4 -> 1,1,0
    # 1,0,0: 5 -> 0,0,1
    # 1,0,1: 6 -> 1,0,1
    # 1,1,0: 7 -> 0,1,1
    # 1,1,1: 8 -> 1,1,1
} -result {{{1 5} {3 7}} {{2 6} {4 8}}}

test nmoveaxis_ftb {
    # Move an axis (front to back)
} -body {
    nmoveaxis {{{1 2} {3 4}} {{5 6} {7 8}}} 0 2
    # i,j,k -> j,k,i
    # 0,0,0: 1 -> 0,0,0
    # 0,0,1: 2 -> 0,1,0
    # 0,1,0: 3 -> 1,0,0
    # 0,1,1: 4 -> 1,1,0
    # 1,0,0: 5 -> 0,0,1
    # 1,0,1: 6 -> 0,1,1
    # 1,1,0: 7 -> 1,0,1
    # 1,1,1: 8 -> 1,1,1
} -result {{{1 5} {2 6}} {{3 7} {4 8}}}

test nmoveaxis_btf {
    # Move an axis
} -body {
    nmoveaxis {{{1 2} {3 4}} {{5 6} {7 8}}} 2 0
    # i,j,k: ? -> k,i,j
    # 0,0,0: 1 -> 0,0,0
    # 0,0,1: 2 -> 1,0,0
    # 0,1,0: 3 -> 0,0,1
    # 0,1,1: 4 -> 1,0,1
    # 1,0,0: 5 -> 0,1,0
    # 1,0,1: 6 -> 1,1,0
    # 1,1,0: 7 -> 0,1,1
    # 1,1,1: 8 -> 1,1,1
} -result {{{1 3} {5 7}} {{2 4} {6 8}}}

test npermute {
    # Reorder axes, and show agreement with nswapaxes and nmoveaxis
} -body {
    # Verify with 4D tensor
    set x [nrand 10 10 10 10]
    set y1 [npermute $x 3 2 0 1]; # Reversed order
    # i j k l; # swap 3 and 0
    # l j k i; # move 1 to 3
    # l k i j
    set y2 [nmoveaxis [nswapaxes $x 0 3] 1 3]
    assert $y1 eq $y2
    # Perform same axis swap as example nmoveaxis_btf
    npermute {{{1 2} {3 4}} {{5 6} {7 8}}} 2 0 1; # Same as move 2 0
} -result {{{1 3} {5 7}} {{2 4} {6 8}}}

test npermute5 {
    # Permute a 5D tensor
} -body {
    set x [nrand 10 10 10 10 10]
    set y1 [npermute $x 4 3 0 2 1]
    # 0 1 2 3 4; # swap 0 and 4
    # 4 1 2 3 0; # swap 1 and 3
    # 4 3 2 1 0; # swap 2 and 3
    # 4 3 1 2 0; # swap 2 and 4
    # 4 3 0 2 1;
    set y2 [nswapaxes [nswapaxes [nswapaxes [nswapaxes $x 0 4] 1 3] 2 3] 2 4]
    assert $y1 eq $y2
}

# napply/nreduce/nmap
################################################################################

# napply
test napply0D {
    # Map over a scalar (simple eval)
} -body {
    napply expr 2 {+ 2}
} -result {4}

test napply1D {
    # Map over a list
} -body {
    napply lindex $testmat 0 1
} -result {1 4 7}

test napply2D {
    # Map over a matrix
} -body {
    napply {format %.2f} $testmat
} -result {{1.00 2.00 3.00} {4.00 5.00 6.00} {7.00 8.00 9.00}}

# nreduce
test reduce0D_error {
    # Reduce a scalar (produces error)
} -body {
    catch {nreduce max 5 {} 0}
} -result {1}

test reduce1D_max {
    # Reduce a vector
} -body {
    nreduce max {1 2 3 4 5}
} -result {5}

test reduce1D_sum {
    # Reduce a vector, with sum
} -body {
    nreduce sum {1 2 3 4 5}
} -result {15}

test reduce1D_error {
    # Reduce a vector, along 1st dimension (returns error)
} -body {
    catch {nreduce max {1 2 3 4 5} 1}
} -result {1}

test reduce2D_0 {
    # Reduce a matrix along row dimension
} -body {
    nreduce max {{1 2} {3 4} {5 6} {7 8}}
} -result {7 8}

test reduce2D_1 {
    # Reduce a matrix along column dimension
} -body {
    nreduce max {{1 2} {3 4} {5 6} {7 8}} 1
} -result {2 4 6 8}

# Tensor reductions (using a 2x3x4 tensor)
set myTensor {{{1 2 3 4} {5 6 7 8} {9 10 11 12}} {{13 14 15 16} {17 18 19 20} {21 22 23 24}}}

test reduce3D_0 {
    # Reduce a tensor along 0th dimension (result is 3x4)
} -body {
    nreduce max $myTensor 0
} -result {{13 14 15 16} {17 18 19 20} {21 22 23 24}}

test reduce3D_1 {
    # Reduce a tensor along 1st dimension (result is 2x4)
} -body {
    nreduce max $myTensor 1
} -result {{9 10 11 12} {21 22 23 24}}

test reduce3D_2 {
    # Reduce a tensor along 2nd dimension (result is 2x3)
} -body {
    nreduce max $myTensor 2
} -result {{4 8 12} {16 20 24}}

# nmap
test nmap0 {
    # 0D is just a simple mapping.
} -body {
    nmap x foo y bar {list $x $y}
} -result {foo bar}

test nmap1 {
    # 1D is a list mapping
} -body {
    nmap x {1 2 3} {format %.2f $x}
} -result {1.00 2.00 3.00}

test nmap2 {
    # 2D is a matrix mapping
} -body {
    nmap x $testmat {format %.2f $x}
} -result {{1.00 2.00 3.00} {4.00 5.00 6.00} {7.00 8.00 9.00}}

# nmap
test nmap_expr {
    # using expr
} -body {
    assert {[nmap x {1 2 3} {expr {-$x}}] eq {-1 -2 -3}}
    # Basic operations
    assert {[nmap x $testmat {expr {-$x}}] eq {{-1 -2 -3} {-4 -5 -6} {-7 -8 -9}}}
    assert {[nmap x $testmat {expr {$x / 2.0}}] eq {{0.5 1.0 1.5} {2.0 2.5 3.0} {3.5 4.0 4.5}}}
    assert {[nmap x $testmat y {.1 .2 .3} {expr {$x + $y}}] eq {{1.1 2.1 3.1} {4.2 5.2 6.2} {7.3 8.3 9.3}}}
    assert {[nmap x $testmat y {{.1 .2 .3}} {expr {$x + $y}}] eq {{1.1 2.2 3.3} {4.1 5.2 6.3} {7.1 8.2 9.3}}}
    assert {[nmap x $testmat y {{.1 .2 .3} {.4 .5 .6} {.7 .8 .9}} {expr {$x + $y}}] eq {{1.1 2.2 3.3} {4.4 5.5 6.6} {7.7 8.8 9.9}}}
    assert {[nmap x $testmat {expr {double($x)}}] eq {{1.0 2.0 3.0} {4.0 5.0 6.0} {7.0 8.0 9.0}}}
} -result {}

test nmap_index2 {
    # Test out indices
} -body {
    nmap x $testmat {expr {$x*([i]%2 + [j]%2 == 1?-1:1)}}
} -result {{1 -2 3} {-4 5 -6} {7 -8 9}}

test nmap_index3 {
    # Test out all features.
} -body {
    set y ""
    lappend y ""
    nmap x [nfull {} 2 3 2] {
        lappend y [list [i -1] [i] [j] [k]]
    }
    lappend y ""
    join $y \n
} -result {
0 0 0 0
1 0 0 1
2 0 1 0
3 0 1 1
4 0 2 0
5 0 2 1
6 1 0 0
7 1 0 1
8 1 1 0
9 1 1 1
10 1 2 0
11 1 2 1
}

test nmap_index_nested {
   # Verify that the nmap indices can be nested.
} -body {
    nmap 1 x {{1 2} {1 2 3} {1 2 3 4}} {
        list [i] [nmap 1 xi $x {expr {[i] * $xi}}]
    }
} -result {{0 {0 2}} {1 {0 2 6}} {2 {0 2 6 12}}}

test nmap_index_blank {
    # Verify that the index is reset, even if error occurs.
} -body {
    assert $::ndlist::map_index eq ""
    assert $::ndlist::map_shape eq ""
    catch {nmap 1 x {1 2 3} {expr 1/0}}
    assert $::ndlist::map_index eq ""
    assert $::ndlist::map_shape eq ""
} -result {}
