package require tin 1.0
tin import assert from tin
tin import tcltest
set version 0.3
set config ""
dict set config VERSION $version
tin bake src build $config
tin bake doc/template/version.tin doc/template/version.tex $config

# Import ndlist
source build/ndlist.tcl 
namespace import ndlist::*
tin import flytrap
# Source all test files
source tests/vector_test.tcl
source tests/matrix_test.tcl
source tests/tensor_test.tcl

# Check number of failed tests
set nFailed $::tcltest::numTests(Failed)

# Clean up and report on tests
cleanupTests

# If tests failed, return error
if {$nFailed > 0} {
    error "$nFailed tests failed"
}
# Tests passed, copy build files to main folder and install
file copy -force {*}[glob -directory build *] [pwd]

exec tclsh install.tcl

# Verify installation
tin forget ndlist
tin clear
tin import ndlist -exact $version
