# Matrix (2D-list) tests

test eye {
    # Generate identity matrix
} -body {
    set I [eye 3]
} -result {{1 0 0} {0 1 0} {0 0 1}}

test stack_augment {
    # Stack and augment matrices
} -body {
    assert [stack {1 2 3} {4 5 6} {7 8} 9] eq {1 2 3 4 5 6 7 8 9}
    assert [stack {{1 2 3} {4 5 6}} {{7 8 9}}] eq {{1 2 3} {4 5 6} {7 8 9}}
    assert [catch {stack {{1 2 3}} {{4 5}}}]
    assert [augment {1 2 3} {4 5 6}] eq {{1 4} {2 5} {3 6}}
    assert [augment {{1 2} {3 4}} {5 6} {7 8}] eq {{1 2 5 7} {3 4 6 8}}
    assert [catch {augment {1 2 3} {{4 5} {6 7}}}]
}

test block {
    # Combine a matrix of matrices
} -body {
    set A [nfull 1 {4 3}]
    set B [nfull 0 {4 2}]
    set C [nfull 0 {1 3}]
    set D [nfull 1 {1 2}]
    join [block [list [list $A $B] [list $C $D]]] \n
} -result {1 1 1 0 0
1 1 1 0 0
1 1 1 0 0
1 1 1 0 0
0 0 0 1 1}

test block_error {
    # Cannot combine if cannot stack/augment
} -body {
    block {{{{1 2} {3 4}}} {{1 2 3}}} 
} -returnCodes 1 -result {incompatible number of columns}

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
} -returnCodes {1} -result {incompatible inner matrix dimensions}

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

test outerprod {} {outerprod {0 1 2} {3 4}} {{0 0} {3 4} {6 8}}
test kronprod {} {kronprod {{1 1} {2 2}} {{1 2} {3 4}}} {{1 2 1 2} {3 4 3 4} {2 4 2 4} {6 8 6 8}}

# Validate basic data conversions
set mat {{A B C {} A} {1 2 3 4 5} {6 7 8 9 10}}
set tbl {A {1 6} B {2 7} C {3 8} {} {4 9} A {5 10}}
set txt {A B C {} A
1 2 3 4 5
6 7 8 9 10}
set csv {A,B,C,,A
1,2,3,4,5
6,7,8,9,10}

test base_conversions {
    # Validate all base conversions
} -body {
    assert [mat2txt $mat] eq $txt
    assert [txt2mat $txt] eq $mat 
    assert [mat2csv $mat] eq $csv
    assert [csv2mat $csv] eq $mat 
} -result {}

# Acid test for csv parser/writer
# Acid test files from https://github.com/maxogden/csv-spectrum
set csvDir "tests/csv_samples"
# Read CSV from file (without newline)
proc read_file {filename} {
    set fid [open $filename r]
    set data [read -nonewline $fid]
    close $fid
    return $data
}
set csv1 [read_file $csvDir/comma_in_quotes.csv]
set csv2 [read_file $csvDir/empty.csv]
set csv3 [read_file $csvDir/empty_crlf.csv]
set csv4 [read_file $csvDir/escaped_quotes.csv]
set csv5 [read_file $csvDir/json.csv]
set csv6 [read_file $csvDir/newlines.csv]
set csv7 [read_file $csvDir/quotes_and_newlines.csv]
set csv8 [read_file $csvDir/simple.csv]
set csv9 [read_file $csvDir/simple_crlf.csv]
set csv10 [read_file $csvDir/utf8.csv]
# Expected values
set mat1 {{first last address city zip} {John Doe {120 any st.} {Anytown, WW} 08123}}
set mat2 {{a b c} {1 {} {}} {2 3 4}}
set mat3 {{a b c} {1 {} {}} {2 3 4}}
set mat4 {{a b} {1 {ha "ha" ha}} {3 4}}
set mat5 {{key val} {1 {{"type": "Point", "coordinates": [102.0, 0.5]}}}}
set mat6 {{a b c} {1 2 3} {{Once upon 
a time} 5 6} {7 8 9}}
set mat7 {{a b} {1 {ha 
"ha" 
ha}} {3 4}}
set mat8 {{a b c} {1 2 3}}
set mat9 {{a b c} {1 2 3}}
set mat10 {{a b c} {1 2 3} {4 5 ʤ}}

test csvacidtest_parse {
    # Check csv parser
} -body {
    assert [csv2mat $csv1] eq $mat1
    assert [csv2mat $csv2] eq $mat2
    assert [csv2mat $csv3] eq $mat3
    assert [csv2mat $csv4] eq $mat4
    assert [csv2mat $csv5] eq $mat5
    assert [csv2mat $csv6] eq $mat6
    assert [csv2mat $csv7] eq $mat7
    assert [csv2mat $csv8] eq $mat8
    assert [csv2mat $csv9] eq $mat9
    assert [csv2mat $csv10] eq $mat10
} -result {}

test csvacidtest_write {
    # Verify csv writer
} -body {
    assert [mat2csv $mat1] eq $csv1
    # Note: this csv writer does not use "" for blanks.
    assert [mat2csv $mat2] eq [string map {{""} {}} $csv2]
    assert [mat2csv $mat3] eq [string map {{""} {}} $csv3]
    assert [mat2csv $mat4] eq $csv4
    assert [mat2csv $mat5] eq $csv5
    assert [mat2csv $mat6] eq $csv6
    assert [mat2csv $mat7] eq $csv7
    assert [mat2csv $mat8] eq $csv8
    assert [mat2csv $mat9] eq $csv9
    assert [mat2csv $mat10] eq $csv10
}

