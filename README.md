# N-Dimensional Lists (ndlist)
Vectors, matrices, and arbitrary dimensional tensors (ND-lists) in pure Tcl

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

Here are just a few of the things you can do with "ndlist":

```tcl
# Difference between elements in a vector
set x {1 2 4 7 11 16}
puts [nexpr {@x(1:end) - @x(0:end-1)}]; # 1 2 3 4 5
```

```tcl
# Swapping matrix rows
set a {{1 2 3} {4 5 6} {7 8 9}}
nset a {1 0} : [nget $a {0 1} :]
puts $a; # {4 5 6} {1 2 3} {7 8 9}
```

```tcl
# Changing tensor axes
set x {{{1 2} {3 4}} {{5 6} {7 8}}}
set y [nswapaxes $x 0 2]
set z [nmoveaxis $x 0 2]
puts [lindex $x 0 0 1]; # 2
puts [lindex $y 1 0 0]; # 2
puts [lindex $z 0 1 0]; # 2
```

## Documentation

Full documentation with examples [here](https://raw.githubusercontent.com/ambaker1/ndlist/main/doc/ndlist.pdf).

