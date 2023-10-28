# Tests for object-oriented version vutil new.

ndnew 2D double x = {1 2 3}
tin import flytrap 
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
