# scalar.tcl
################################################################################
# Primative datatypes (wraps mathfunc commands with defaults)

# Copyright (C) 2023 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" for information on usage, redistribution, and for a 
# DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Define namespace and exported commands
namespace eval ::ndlist {
    namespace export bool int float
}

# bool --
#
# Validates a boolean value, by calling ::tcl::mathfunc::bool
#
# Syntax:
# bool <$value>
#
# Arguments:
# value         Valid Tcl boolean, default 0

proc ::ndlist::bool {{value 0}} {
    ::tcl::mathfunc::bool $value
}

# int --
# 
# Validates an integer value, by calling ::tcl::mathfunc::int
#
# Syntax:
# int <$value>
#
# Arguments:
# value         Valid integer, default 0

proc ::ndlist::int {{value 0}} {
    ::tcl::mathfunc::int $value
}

# float --
#
# Validates a floating point number, by calling ::tcl::mathfunc::double
#
# Syntax:
# float <$value>
#
# Arguments:
# value         Number to convert to float, default 0.0

proc ::ndlist::float {{value 0.0}} {
    ::tcl::mathfunc::double $value
}
