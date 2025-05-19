# N-Dimensional Lists (ndlist)
Vectors, Matrices, Tables and Tensors


## Installation
This package is a Tin package. 
Tin makes installing Tcl packages easy, and is available [here](https://github.com/ambaker1/Tin).

After installing Tin, simply run the following Tcl code to install and import the commands from the most recent version of "ndlist":
```tcl
package require tin 2.1
tin autoadd ndlist https://github.com/ambaker1/ndlist install.tcl
tin import ndlist
```

## Examples
The ndlist package has support for vectors, matrices, tables, and higher-dimensional tensors.

Below are just a few examples of what is possible with ndlist. 

```tcl
# Get distance between elements in a vector
narray new x {1 2 4 7 11 16}
puts [nexpr {@x(1:end) - @x(0:end-1)}]; # 1 2 3 4 5
```

```tcl
# Element-wise multiplication of column and row matrices
narray new x {1 2 3}
narray new y {{4 5 6}}
puts [nexpr {@x * @y}]; # {4 5 6} {8 10 12} {12 15 18}
```

```tcl
# Multi-dimensional mapping of Tcl nested lists
set x {{1 2 3} {4 5 6} {7 8 9}}
set indices {}
nmap xi $x {
    if {$xi > 4} {
        lappend indices [list [i] [j]]
    }
}
puts $indices; # {1 1} {1 2} {2 0} {2 1} {2 2}
```

```tcl
# Tabular data structure
table new myTable
$myTable define keys {1 2 3}
$myTable @ x = {1.0 2.0 3.0}
set a 20.0
$myTable @ y := {@x*2 + $a}
puts [$myTable @ y]; # 22.0 24.0 26.0
```

## Documentation

Full documentation with examples [here](https://raw.githubusercontent.com/ambaker1/ndlist/main/doc/ndlist.pdf).

