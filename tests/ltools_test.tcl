
puts "List tools"

test range1 {
    # Basic range syntax
} -body {
    range 4 
} -result {0 1 2 3}

test range1_error {
    # Throw error for non-integer input
} -body {
    range 1.5
} -returnCodes {1} -result {n must be integer >= 0}

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
    find {1 0 0 1 0}
} -result {0 3}

test find_mixed {
    # Mixed real and ints
} -body {
    find {0.0 2.0 5 2 0 0 0.0 1}
} -result {1 2 3 7}

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

test lapply {
    # Functional mapping of list
} -body {
    lapply expr {1 2 3} + 10
} -result {11 12 13}

test lexpr {
    # Functional mapping of list
} -body {
    set a 10
    lexpr x {1 2 3} {$x + $a}
} -result {11 12 13}

test lop {
    # Map mathops over a list.
} -body {
    lop {1 2 3} + 10
} -result {11 12 13}

