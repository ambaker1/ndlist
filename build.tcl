set tin_version 2.1
package require tin $tin_version
tin import assert from tin
tin import tcltest
tin add flytrap 1.2 https://github.com/ambaker1/flytrap v1.2 install.tcl
tin import flytrap -exact 1.2
set version 0.11
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


set x {1 2 3}
set y {{1 2} {3 4} {5 6}}
set z 20.0
puts [::ndlist::nexpr2 {@x + 2*@y + @z}]
pause

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
