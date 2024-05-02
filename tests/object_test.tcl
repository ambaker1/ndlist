# Tests for object-oriented version vutil new.

tin import flytrap 

narray new 4D x = [nrand 5 5 5 5]

pause

$x @ 2*,4*,0:2:end,end-1*
$x @ 2*,4*,0:2:end,end-1* | := {$@ * 5}
$x @ 2*,4*,0:2:end,end-1* & value {lmap val $value {puts $val}}

ndnew 4D double x = {{1 2 3} {4 5 6}}
puts [$x shape]
ndnew 4D double y = {{{{1 2} {1 2}}}}
puts [$y shape]
puts [nexpr {$@x * $@y}]

foreach n {10 100 500} {
puts $n
ndnew 2D double x = [nrand $n $n]
set t1 [time {$x | := {$@ * 2}} 10]
set x [$x]
set t2 [time {nmap 2D xi $x {expr {$xi * 2}}} 10]
puts $t1
puts $t2
puts [expr {[lindex $t1 0] / [lindex $t2 0]}]
}
pause



ndnew 2D double x = {1 2 3}

$x := {$@ + 10}

ndnew 2D int i = [ones 3 3]
ndnew 2D int j = [ncat 2D [$i] [$i | := {$@ * 2}] 1]
puts [$i shape]
puts [$j shape]
puts [$j]
puts [$j @ {:,0:2}]
puts [$j @ {:,3:end}]
puts [nexpr {$@i + $@j}]

ndnew 2D double x = {1 2 3}
ndnew 2D double y = {{5 4 1 9 0 -2}}
puts [nexpr {$@x * $@y}]

ndnew 2D int i = [range 8]
[ndnew 2D int x = [ones 8 8]] := {$@ * $@i}
ndnew 2D int y = {{1 0}}
puts [join [nexpr {$@x(0:2:end,:) * $@y}] \n]

pause
