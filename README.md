# N-Dimensional Lists (ndlist)
Utilities for accessing, modifying and manipulating N-Dimensional lists in Tcl.

Also adds the "ndlist" object variable type, using the type framework provided by the [vutil](https://github.com/ambaker1/vutil) package.

Full documentation [here](https://raw.githubusercontent.com/ambaker1/ndlist/main/doc/ndlist.pdf).

## Installation
This package is a Tin package. 
Tin makes installing Tcl packages easy, and is available [here](https://github.com/ambaker1/Tin).

After installing Tin, simply run the following Tcl code to install the most recent version of "ndlist":
```tcl
package require tin
tin add -auto ndlist https://github.com/ambaker1/ndlist install.tcl
tin install ndlist
```
