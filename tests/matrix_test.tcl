# linalg_test.tcl
# Integer range

puts "Matrix (2D list) utilities"

test eye {
    # Generate identity matrix
} -body {
    set I [eye 3]
} -result {{1 0 0} {0 1 0} {0 0 1}}

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

test zip {} {zip {A B C} {1 2 3}} {{A 1} {B 2} {C 3}}
test zip3 {} {zip3 {Do Re Mi} {A B C} {1 2 3}} {{Do A 1} {Re B 2} {Mi C 3}}

test cartprod_2 {
    # Cartesian product of two vectors
} -body {
    cartprod {A B C} {1 2 3}    
} -result {{A 1} {A 2} {A 3} {B 1} {B 2} {B 3} {C 1} {C 2} {C 3}}

test cartprod_3 {
    # Cartesian product of three vectors
} -body {
    cartprod {1 2} {A B} {foo bar}
} -result {{1 A foo} {1 A bar} {1 B foo} {1 B bar} {2 A foo} {2 A bar} {2 B foo} {2 B bar}}