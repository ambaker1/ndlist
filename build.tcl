package require tin 1.0
tin import assert from tin
tin import tcltest
set version 0.5
set config ""
dict set config VERSION $version

puts "Building from source files..."
tin bake src build $config
tin bake doc/template/version.tin doc/template/version.tex $config
source tests/build_examples.tcl

puts "Loading package from build folder..."
source build/ndlist.tcl 
namespace import ndlist::*

# Source all test files
puts "Running all tests..."
source tests/vector_test.tcl
source tests/matrix_test.tcl
source tests/tensor_test.tcl
source tests/examples.tcl

# Check number of failed tests
set nFailed $::tcltest::numTests(Failed)

# Clean up and report on tests
cleanupTests

# If tests failed, return error
if {$nFailed > 0} {
    error "$nFailed tests failed"
}

puts "Tests passed, installing..."
# Tests passed, copy build files to main folder and install
file copy -force {*}[glob -directory build *] [pwd]
exec tclsh install.tcl

# Verify installation
puts "Verifying installation..."
tin forget ndlist
tin clear
tin import ndlist -exact $version

# Build documentation
puts "Building documentation..."
cd doc
exec -ignorestderr pdflatex ndlist.tex
cd ..
