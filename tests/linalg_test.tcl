# linalg_test.tcl
# Integer range

puts "Linear algebra utilities"

test eye {
    # Generate identity matrix
} -body {
    set I [eye 3]
} -result {{1 0 0} {0 1 0} {0 0 1}}

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