# Vector (1D-list) tests

test range1 {
    # Basic range syntax
} -body {
    range 4 
} -result {0 1 2 3}

test range1_error {
    # Throw error for non-integer input
} -body {
    range 1.5
} -returnCodes {1} -result {expected integer but got "1.5"}

test range2 {
    # Second version of range syntax
} -body {
    range 0 4
} -result {0 1 2 3 4}

test range2_reverse {
    # Range, in reverse, with step size of 1
} -body {
    range 5 2
} -result {5 4 3 2}

test range3 {
    # Third version of range syntax
} -body {
    range 0 4 2
} -result {0 2 4}

test range3_reverse {
    # Reverse range
} -body {
    range 10 2 -3
} -result {10 7 4}

test find {
    # Find non-zero elements of a list
} -body {
    find {0 1 0 1 1 0}
} -result {1 3 4}

test find_null {
    # Return a blank list for no matches.
} -body {
    find {0 0 0}
} -result {}

test find_filter {
    # Filter with find and nget
} -body {
    set x {0.5 2.3 4.0 2.5 1.6 2.0 1.4 5.6}
    nget $x [find $x > 2]
} -result {2.3 4.0 2.5 5.6}

# List generation
test linspace {
    # Generate numbers between two points
} -body {
    linspace 5 0 1
} -result {0.0 0.25 0.5 0.75 1.0}

test linsteps {
    # Walk through target points
} -body {
    linsteps 0.25 0 1 0
} -result {0.0 0.25 0.5 0.75 1.0 0.75 0.5 0.25 0.0}

test linsteps_uneven {
    # Uneven steps
} -body {
    linsteps 0.3 0 1 0
} -result {0.0 0.3 0.6 0.8999999999999999 1.0 0.7 0.4 0.10000000000000009 0.0}

test linterp_mid {
    # Linear interpolation
} -body {
    linterp 0.5 {0 1} {-1 1}
} -result {0.0}

test linterp_start {
    # Linear interpolation
} -body {
    linterp 0 {0 1} {-1 1}
} -result {-1.0}

test linterp_end {
    # Linear interpolation
} -body {
    linterp 1 {0 1} {-1 1}
} -result {1.0}

test linterp_three {
    # Linear interpolation with more than two points
} -body {
    linterp 1.5 {0 1 2} {-1 1 4}
} -result {2.5}

test linterp_many_inputs {
    # Linear interpolation with more than two points
} -body {
    linterp 1.5 {0 1 2} {-1 1 4}
} -result {2.5}

test linterp_example {
    # Example from documentation
} -body {
    # Exact interpolation
    puts [linterp 2 {1 2 3} {4 5 6}]
    # Intermediate interpolation
    puts [linterp 8.2 {0 10 20} {2 -4 5}]
} -output {5.0
-2.92
}

test lapply {
    # Functional mapping of list
} -body {
    lapply expr {1 2 3} + 10
} -result {11 12 13}

test lapply2 {
    # Functional mapping over two lists
} -body {
    lapply2 {format "%s %s"} {hello goodbye} {world moon}
} -result {{hello world} {goodbye moon}}

test lapply2_error {
    # lapply2 requires same list length
} -body {
    lapply2 {format "%s %s"} {hello} {world moon}
} -returnCodes {1} -result {mismatched list lengths}

test lexpr {
    # Map a math command over a list
} -body {
    set a 10
    lexpr x {1 2 3} {$x + $a}
} -result {11 12 13}

test lop {
    # Map mathops over a list.
} -body {
    lop {1 2 3} + 10
} -result {11 12 13}

test lop2 {
    # Map mathops over two lists.
} -body {
    lop2 {1 2 3} + {2 3 2}
} -result {3 5 5}

test lop2_error {
    # lop2 requires same list length
} -body {
    lop2 {1 2 3} + 1
} -returnCodes {1} -result {mismatched list lengths}

test stats {
    # Test out every stats function
} -body {
    set a {-5 3 4 0}
    assert [max $a] == 4
    assert [min $a] == -5
    assert [sum $a] == 2
    assert [product $a] == 0
    assert [mean $a] == 0.5
    assert [median $a] == 1.5
    assert [stdev $a] == 4.041451884327381
    assert [variance $a] == 16.333333333333332
    assert [stdev $a 1] == 3.5
    assert [variance $a 1] == 12.25
} -result {}

test stat_errors {
    # Test out bounds of functions
} -body {
    set noArgs {}
    set oneArg {1}
    set twoArgs {1 2}
    # Normal stats 
    foreach func {max min sum product mean median} {
        assert [catch {$func $noArgs}]
        assert ![catch {$func $oneArg}]
        assert ![catch {$func $twoArgs}]
    }
    # Sample variance
    foreach func {stdev variance} {
        assert [catch {$func $noArgs}]
        assert [catch {$func $oneArg}]
        assert ![catch {$func $twoArgs}]
    }
    # Population variance
    foreach func {stdev variance} {
        assert [catch {$func $noArgs 1}]
        assert ![catch {$func $oneArg 1}]
        assert ![catch {$func $twoArgs 1}]
    }
}

test dot {
    # dot product
} -body {
    dot {1 2 3} {-2 -4 6}
} -result {8}

test cross {
    # cross product
} -body {
    cross {1 2 3} {-2 -4 6}
} -result {24 -12 0}

test norm {
    # Norm of vector (norm 2)
} -body {
    norm {-1 2 3}
} -result [expr {sqrt(14)}]

test norm1 {
    # Norm 1, sum of absolute values
} -body {
    norm {-1 2 3} 1
} -result {6}

test normInf {
    # Infinite norm, absolute maximum
} -body {
    norm {-1 2 3} Inf
} -result {3}

test norm4 {
    # Other norms
} -body {
    norm {-1 2 3} 4
} -result [expr {pow((-1)**4 + 2**4 + 3**4,0.25)}]

test vec_angle {
    # Get angle between two vectors
} -body {
    set a {1 0 0}
    set b {1 1 0}
    set theta [expr {acos([norm [cross $a $b]]/([norm $a]*[norm $b]))}]
    set pi [expr {2*asin(1.0)}]
    format %.1f [expr {$theta*180/$pi}]
} -result {45.0}
