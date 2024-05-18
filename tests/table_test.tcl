
test new_table1 {
    # Blank table (exists, but empty)
} -body {
    table new tblObj
    $tblObj
} -result {key}

test new_table2 {
    # Create a table with data
} -body {
    # Create test table (overwrite)
    table new tblObj {
        {key x y z}
        {1 3.44 7.11 8.67}
        {2 4.61 1.81 7.63}
        {3 8.25 7.56 3.84}
        {4 5.20 6.78 1.11}
        {5 3.26 9.92 4.56}
    }
    $tblObj
} -result {{key x y z} {1 3.44 7.11 8.67} {2 4.61 1.81 7.63} {3 8.25 7.56 3.84} {4 5.20 6.78 1.11} {5 3.26 9.92 4.56}}

test trim_table {
    # Use the "define" method to trim a table, and verify that it returns object
} -body {
    $tblObj --> tblCopy
    [[$tblCopy define keys {1 2}] define fields {x}]
} -result {{key x} {1 3.44} {2 4.61}}

test keyname {
    # Verify the default keyname
} -body {
    $tblObj keyname
} -result {key}

test keys_fields {
    # Get keys/fields
} -body {
    assert [$tblObj keys] eq {1 2 3 4 5}
    assert [$tblObj fields] eq {x y z}
} -result {}

test find {
    # Get key/field with row/column ID
} -body {
    assert [$tblObj find key 1] == 0
    assert [$tblObj find key 5] == 4
    assert [$tblObj find field x] == 0
    assert [$tblObj find field z] == 2
} -result {}

test rename_keys {
    # Rename keys 
} -body {
    $tblObj --> tblCopy
    $tblCopy rename keys [lmap key [$tblCopy keys] {string cat K $key}]
    $tblCopy keys
} -result {K1 K2 K3 K4 K5}

test rename_keys2 {
    # Rename subset of keys
} -body {
    $tblObj --> tblCopy
    $tblCopy rename keys [nget [$tblCopy keys] 0:2] {K1 K2 K3}
    assert [$tblCopy keys] eq {K1 K2 K3 4 5}
    $tblCopy search -all K*
} -result {K1 K2 K3}

test rename_fields {
    # Rename fields
} -body {
    $tblObj --> tblCopy
    $tblCopy rename fields {a b c}; # Renames all fields
    $tblCopy rename fields {c a} {C A}; # Selected fields
    $tblCopy fields
} -result {A b C}

test fedit_mkkey_remove {
    # Tests for fedit, mkkey and remove 
} -body {
    $tblObj --> tblCopy
    $tblCopy cset record_ID [$tblCopy expr {[string cat R @key]}]
    $tblCopy mkkey record_ID
    $tblCopy remove fields key
    assert [$tblCopy keys] eq {R1 R2 R3 R4 R5}
    assert [$tblCopy fields] eq {x y z}
    assert [$tblCopy values] eq [$tblObj values]
} -result {}

test clear_clean_wipe {
    # tests for clear, clean, and wipe
} -body {
    # clear, clean, and wipe
    $tblCopy define keyname foo
    $tblCopy clear
    assert [$tblCopy height] == 0
    assert [$tblCopy width] == 3
    $tblCopy clean
    assert [$tblCopy height] == 0
    assert [$tblCopy width] == 0
    assert [$tblCopy keyname] eq foo
    $tblCopy wipe
    assert [$tblCopy keyname] eq key
} -result {}

test exists {
    # Verify that the "exists" method works
} -body {
    assert [$tblObj exists key 3]
    assert [$tblObj exists key 6] == 0
    assert [$tblObj exists field y]
    assert [$tblObj exists field foo] == 0
    assert [$tblObj exists value 3 y]
    $tblObj --> tblCopy
    $tblCopy set 3 y ""
    assert [$tblCopy exists value 3 y] == 0
} -result {}

test get {
    # Access values in table
} -body {
    $tblObj get 2 x
} -result 4.61

test set {
    # Check that you can set values
} -body {
    $tblObj --> tblCopy
    $tblCopy set 2 x foo
    $tblCopy get 2 x
} -result foo

test filler {
    # Get filler value when value is missing
} -body {
    $tblObj --> tblCopy
    $tblCopy set 2 x ""; # delete
    assert ![$tblCopy exists value 2 x]
    assert [$tblCopy get 2 x] eq ""
    $tblCopy get 2 x 0.0; # with filler
} -result {0.0}

test rget {
    # Get row vector
} -body {
    $tblObj rget 2
} -result {4.61 1.81 7.63}

test rset_vector {
    # Set row with vector
} -body {
    $tblObj --> tblCopy
    $tblCopy rset 2 {foo bar foo}
    $tblCopy rget 2
} -result {foo bar foo}

test rset_delete {
    # Delete a row 
} -body {
    $tblCopy rset 2 ""
    assert [$tblCopy rget 2] eq {{} {} {}}
    $tblCopy exists value 2 x
} -result 0

test rset_scalar {
    # Set to a scalar
} -body {
    $tblCopy rset 2 foo
    $tblCopy rget 2
} -result {foo foo foo}

test cget {
    # Get a column vector
} -body {   
    $tblObj cget x
} -result {3.44 4.61 8.25 5.20 3.26}

test cset_vector {
    # Set column with vector
} -body {
    $tblObj --> tblCopy
    $tblCopy cset x {foo bar foo bar foo}
    $tblCopy cget x
} -result {foo bar foo bar foo}

test cset_delete {
    # Delete column
} -body {
    $tblCopy cset x ""
    assert [$tblCopy cget x] eq {{} {} {} {} {}}
    assert [$tblCopy exists value 2 x] == 0
} -result {}

test cset_scalar {
    # Set column to scalar
} -body {
$tblCopy cset x foo
assert [$tblCopy cget x] eq {foo foo foo foo foo}
} -result {}

test height_width {
    # Get height and width
} -body {
    # height
    assert [$tblObj height] == 5
    # width
    assert [$tblObj width] == 3
} -result {}

test add_with {
    # Add fields and edit through "with"
} -body {
    set a 20.0; # external variable in "with" and "fedit"
    $tblObj --> tblCopy
    $tblCopy add fields q
    $tblCopy with {
        set q [expr {$x*2 + $a}]; # modify field value
    }
    $tblCopy cget q 
} -result {26.88 29.22 36.5 30.4 26.52}

test add_sort {
    # Add keys and sort
} -body {
    # Add keys, and sort keys
    $tblCopy add keys 0 7 12 3 8 2 1
    assert [$tblCopy keys] eq {1 2 3 4 5 0 7 12 8}
    $tblCopy sort -integer 
    assert [$tblCopy keys] eq {0 1 2 3 4 5 7 8 12}
} -result {}


test move_swap {
    # Move and swap rows, back to original location
} -body {
    $tblObj --> tblCopy
    $tblCopy move key 1 end-1
    assert [$tblCopy keys] eq {2 3 4 1 5}
    $tblCopy swap keys 1 5
    assert [$tblCopy keys] eq {2 3 4 5 1}
    $tblCopy move key [lindex [$tblCopy keys] end] 0
    assert [$tblCopy] eq [$tblObj]
    
    $tblCopy move field x end
    assert [$tblCopy fields] eq {y z x}
    $tblCopy move field z end
    assert [$tblCopy fields] eq {y x z}
    $tblCopy swap fields x y
    assert [$tblCopy fields] eq {x y z}
    assert [$tblCopy] eq [$tblObj]
} -result {}

test insert {
    # Insert keys/fields
} -body {
    $tblCopy insert keys 2 foo bar
    assert [$tblCopy keys] eq {1 2 foo bar 3 4 5}
    $tblCopy insert fields end foo bar; # to append, use "add"
    assert [$tblCopy fields] eq {x y foo bar z}
    assert [catch {$tblCopy insert fields 0 foo}]; # cannot insert existing field
    assert [catch {$tblCopy insert fields 0 bah bah}]; # Cannot have duplicates
} -result {}

test expr {
    # Validate field expressions
} -body {
    # Expr and fedit
    $tblObj --> tblCopy
    assert [$tblCopy expr {@x*2 + $a}] eq {26.88 29.22 36.5 30.4 26.52}
    $tblCopy cset q [$tblCopy expr {@x*2 + $a}]
    assert [$tblCopy cget q] eq {26.88 29.22 36.5 30.4 26.52}
    # Access to key values in "expr"
    assert [$tblCopy expr {@key}] eq [$tblCopy keys]
} -result {}

test query {
    # Query keys matching a field expression
} -body {
    $tblObj query {@x > 3.0 && @y > 7.0}
} -result {1 3 5}

test search_sort {
    # Searching and sorting
} -body {
    $tblObj --> tblCopy
    assert [$tblCopy search -real x 8.25] == 3; # returns first matching key
    $tblCopy sort -real x; # sorts in-place
    assert [$tblCopy keys] eq {5 1 2 4 3}
    assert [$tblCopy cget x] eq {3.26 3.44 4.61 5.20 8.25}
    assert [$tblCopy search -sorted -bisect -real x 5.0] == 2
} -result {}

test merge {
    # Create a new table, and merge the data into a copy of test table
} -body {
    table new newTable
    $tblObj --> tblCopy
    $newTable set 1 x 5.00 q 6.34
    $tblCopy merge $newTable
    $newTable destroy; # clean up
    $tblCopy
} -result {{key x y z q} {1 5.00 7.11 8.67 6.34} {2 4.61 1.81 7.63 {}} {3 8.25 7.56 3.84 {}} {4 5.20 6.78 1.11 {}} {5 3.26 9.92 4.56 {}}}

tin import flytrap
pause