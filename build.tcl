set tin_version 2.1
package require tin $tin_version
tin import assert from tin
tin import tcltest
set version 0.10.1
set config ""
dict set config VERSION $version
dict set config TIN_VERSION $tin_version

puts "Building from source files..."
tin bake src . $config
tin bake doc/template/version.tin doc/template/version.tex $config
source tests/build_examples.tcl

puts "Loading package ..."
source ndlist.tcl 
namespace import ndlist::*

# Source all test files
puts "Running all tests..."
source tests/vector_test.tcl
source tests/matrix_test.tcl
source tests/tensor_test.tcl
source tests/object_test.tcl
source tests/fileio_test.tcl
source tests/table_test.tcl
source tests/vutil_test.tcl
source tests/examples.tcl
file delete myDatabase.db; # from examples.tcl

# Check number of failed tests
set nFailed $::tcltest::numTests(Failed)

# Clean up and report on tests
cleanupTests

# If tests failed, return error
if {$nFailed > 0} {
    error "$nFailed tests failed"
}

puts "Tests passed, installing..."
exec tclsh install.tcl

# Verify installation
puts "Verifying installation..."
tin forget ndlist
tin clear
tin import ndlist -exact $version

puts "Installation Successful"
