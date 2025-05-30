# Benchmark tests for nexpr
# Algorithm is linear, O(n), and approximately 1 microsecond per element for larger arrays.

source ../ndlist.tcl
namespace import ndlist::*

puts "Rank 1 array"
set times [list {Time (microseconds}]
set sizes [list {Array size}]
for {set n 1} {$n <= 20} {incr n} {
    set size [expr {2**$n}]
    puts "Array size $size"
    set x [nfull 1 $size]
    set y [nfull 2 $size]
    nexpr {@x + @y}
    set msg [time {nexpr {@x + @y} 100}]
    puts $msg
    lappend times [lindex $msg 0]
    lappend sizes $size
}
writeMatrix rank1_times.csv [zip $sizes $times]

puts "Rank 2 array"
set times [list {Time (microseconds}]
set sizes [list {Array size}]
for {set n 2} {$n <= 20} {incr n} {
    set size [expr {2**$n}]
    set shape [list 2 [expr {$size/2}]]
    puts "Array size $size"
    set x [nfull 1 $shape]
    set y [nfull 2 $shape]
    nexpr {@x + @y}
    set msg [time {nexpr {@x + @y} 100}]
    puts $msg
    lappend times [lindex $msg 0]
    lappend sizes $size
}
writeMatrix rank2_times.csv [zip $sizes $times]

puts "Rank 3 array"
set times [list {Time (microseconds}]
set sizes [list {Array size}]
for {set n 3} {$n <= 20} {incr n} {
    set size [expr {2**$n}]
    set shape [list 2 2 [expr {$size/4}]]
    puts "Array size $size"
    set x [nfull 1 $shape]
    set y [nfull 2 $shape]
    nexpr {@x + @y}
    set msg [time {nexpr {@x + @y} 100}]
    puts $msg
    lappend times [lindex $msg 0]
    lappend sizes $size
}
writeMatrix rank3_times.csv [zip $sizes $times]
