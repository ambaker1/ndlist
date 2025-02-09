# N-Dimensional Lists (ndlist)
A pure Tcl implementation of arbitrary rank tensors.

Full documentation [here](https://raw.githubusercontent.com/ambaker1/ndlist/main/doc/ndlist.pdf).

## Installation
This package is a Tin package. 
Tin makes installing Tcl packages easy, and is available [here](https://github.com/ambaker1/Tin).

After installing Tin, simply run the following Tcl code to install and import the commands from the most recent version of "ndlist":
```tcl
package require tin 2.0
tin autoadd ndlist https://github.com/ambaker1/ndlist install.tcl
tin import ndlist
```
