
test file_io {
    # Write to file and read back the result
} -body {
    # Export data to file (creates or overwrites the file)
    writeFile tests/example.txt "hello world"
    # Import the contents of the file (requires that the file exists)
    readFile tests/example.txt
} -result {hello world}
file delete tests/example.txt

test binary_io {
    # fconfigure feature of readFile
} -body {
    # Binary files
    # Example modified from example on tcl wiki written by Mac Cody and Jeff David
    # https://wiki.tcl-lang.org/page/Working+with+binary+data
    set outBinData [binary format s2Sa6B8 {100 -2} 100 foobar 01000001]
    writeFile -translation binary tests/binfile.bin $outBinData
    set inBinData [readFile -translation binary tests/binfile.bin]
    assert [binary scan $inBinData s2Sa6B8 val1 val2 val3 val4] == 4
    list $val1 $val2 $val3 $val4
} -result {{100 -2} 100 foobar 01000001}
file delete tests/binfile.bin

# Validate basic conversions
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
# Read CSV from file
set csv1 [readFile $csvDir/comma_in_quotes.csv]
set csv2 [readFile $csvDir/empty.csv]
set csv3 [readFile $csvDir/empty_crlf.csv]
set csv4 [readFile $csvDir/escaped_quotes.csv]
set csv5 [readFile $csvDir/json.csv]
set csv6 [readFile $csvDir/newlines.csv]
set csv7 [readFile $csvDir/quotes_and_newlines.csv]
set csv8 [readFile $csvDir/simple.csv]
set csv9 [readFile $csvDir/simple_crlf.csv]
set csv10 [readFile $csvDir/utf8.csv]
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

# Delete database if it exists
if {[file exists tests/test.db]} {
    file delete tests/test.db
}

test sql_not_loaded1 {
    # If sqlite3 is not loaded, an error message will occur
} -body {
    readTable foo bar
} -returnCodes 1 -result {package sqlite3 3.45.2 is not present}

test sql_not_loaded2 {
    # If sqlite3 is not loaded, an error message will occur
} -body {
    writeTable foo bar "hello world"
} -returnCodes 1 -result {package sqlite3 3.45.2 is not present}

package require sqlite3 3.45.2

test sql {
    # Write a matrix to SQL
} -body {
    set myMatrix {
    {first last address city zip} 
    {John Doe {120 any st.} {Anytown, WW} 08123}
    {Jane Doe {123 Main St.} {Somewhere, ZZ} 12345}
    }
    sqlite3 db tests/test.db
    writeTable db People1 $myMatrix
    readTable db People1
} -result {{first last address city zip} {John Doe {120 any st.} {Anytown, WW} 08123} {Jane Doe {123 Main St.} {Somewhere, ZZ} 12345}}

test sql_null {
    # Write a matrix to SQL with nulls
} -body {
    set myMatrix {
    {ID first last address city zip} 
    {1 John Doe {120 any st.} {Anytown, WW} 08123}
    {2 Jane Doe {123 Main St.} {Somewhere, ZZ} 12345}
    {3 {} {} {} {} 54321}
    }
    sqlite3 db tests/test.db
    writeTable db People2 $myMatrix
    readTable db People2
} -result {{ID first last address city zip} {1 John Doe {120 any st.} {Anytown, WW} 08123} {2 Jane Doe {123 Main St.} {Somewhere, ZZ} 12345} {3 {} {} {} {} 54321}}

test sql_tablenamespaces {
    # Write a matrix to SQL with a name with spaces
} -body {
    set myMatrix {
    {ID first last address city zip} 
    {1 John Doe {120 any st.} {Anytown, WW} 08123}
    {2 Jane Doe {123 Main St.} {Somewhere, ZZ} 12345}
    }
    sqlite3 db tests/test.db
    writeTable db {People 3} $myMatrix
    readTable db {People 3}
} -result {{ID first last address city zip} {1 John Doe {120 any st.} {Anytown, WW} 08123} {2 Jane Doe {123 Main St.} {Somewhere, ZZ} 12345}}

test sql_database {
    # Testing the sqldatabase read/write functions
} -body {
    readDatabase db t
    assert [lsort [array names t]] eq [lsort {People1 People2 {People 3}}]
    $t(People 3) set 2 last Dot
    writeDatabase db t
    readTable db {People 3}
} -result {{ID first last address city zip} {1 John Doe {120 any st.} {Anytown, WW} 08123} {2 Jane Dot {123 Main St.} {Somewhere, ZZ} 12345}}

# Clean up sqlite test database
db close
file delete tests/test.db

