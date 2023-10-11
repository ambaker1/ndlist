# linalg_test.tcl
# Integer range

puts "Linear algebra utilities"

test ones {
    # Generate nd list of ones
} -body {
    ones 2 3
} -result {{1 1 1} {1 1 1}}

test zeros {
    # Generate nd list of zeros
} -body {
    zeros 2 3
} -result {{0 0 0} {0 0 0}}

test rand0 {
    # Random number generator function (no args)
} -body {
    expr {srand(0)}
    rand
} -result {0.013469574513598146}

test rand1 {
    # list of random numbers
} -body {
    expr {srand(0)}
    rand 2
} -result {0.013469574513598146 0.3831388500440581}

test rand_2 {
    # matrix of random numbers
} -body {
    expr {srand(0)}
    rand 1 2
} -result {{0.013469574513598146 0.3831388500440581}}

test eye {
    # Generate identity matrix
} -body {
    set I [eye 3]
} -result {{1 0 0} {0 1 0} {0 0 1}}

test dot {
    # dot product
} -body {
    dot {1 2 3} {-2 -4 3}
} -result {-1}

test cross {
    # cross product
} -body {
    cross {1 2 3} {-2 -4 3}
} -result {18 -9 0}

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

test matmul {
    # Larger matrix multiplication
} -body {
    matmul {{2 5 1 3} {4 1 7 9} {6 8 3 2} {7 8 1 4}} {9 3 0 -3}
} -result {24 12 72 75}

test matmul_eye {
    # Verify that multiplying by identity matrix gives you the same result.
} -body {
    matmul [eye 3] {1.0 2.0 3.0}
} -result {1.0 2.0 3.0}

test matmul_error {
    # Incompatible inner dimensions
} -body {
    matmul [eye 3] {{1 2 3}}
} -returnCodes {1} -result {incompatible matrix dimensions}

test matmul_dot {
    # Multiply a row vector times a column vector
} -body {
    matmul {{1 2 3}} {-2 -4 3}
} -result [dot {1 2 3} {-2 -4 3}]

test transpose {
    # Transpose a matrix
} -body {
    transpose {{1 2 3} {4 5 6} {7 8 9}}
} -result {{1 4 7} {2 5 8} {3 6 9}}

test transpose_column {
    # Transpose a column vector
} -body {
    transpose {1 2 3}
} -result {{1 2 3}}

test transpose_row {
    # Transpose a column vector
} -body {
    transpose {{1 2 3}}
} -result {1 2 3}

test transpose_scalar {
    # Transpose a scalar
} -body {
    transpose {1}
} -result {1}