# tie
# untie

# Example class from https://www.tcl.tk/man/tcl8.6/TclCmd/class.html
oo::class create fruit {
    method eat {} {
        return yummy
    }
}

test tie_untie {
    # Basic tie/untie
} -body {
    set ::ndlist::tie_count 0
    set object [fruit new]
    tie a $object
    assert [trace info variable a] eq {{{write unset} {::ndlist::TieVarTrace 0}}}
    assert [trace info command $a] eq {{{rename delete} {::ndlist::TieObjTrace 0}}}
    untie a
    assert [trace info variable a] eq ""
    assert [trace info command $a] eq ""
    $a eat
} -result {yummy}

test retie {
    # Tying an object twice does nothing, but creates new tie traces
} -body {
    set ::ndlist::tie_count 0
    set object [fruit new]
    tie a $object
    tie a $object
    assert [trace info variable a] eq {{{write unset} {::ndlist::TieVarTrace 1}}}
    assert [trace info command $a] eq {{{rename delete} {::ndlist::TieObjTrace 1}}}
    $a eat
} -result {yummy}

test tie_unset {
    # Ensure that unsetting a variable destroys the object
} -body {
    set ::ndlist::tie_count 0
    set object [fruit new]
    tie a $object
    assert [trace info variable a] eq {{{write unset} {::ndlist::TieVarTrace 0}}}
    assert [trace info command $a] eq {{{rename delete} {::ndlist::TieObjTrace 0}}}
    unset a
    assert [trace info variable a] eq ""
    assert [info command $object] eq ""
}

test tie_write {
    # Ensure that writing to a variable destroys the object
} -body {
    set ::ndlist::tie_count 0
    set object [fruit new]
    tie a $object
    assert [trace info variable a] eq {{{write unset} {::ndlist::TieVarTrace 0}}}
    assert [trace info command $a] eq {{{rename delete} {::ndlist::TieObjTrace 0}}}
    set a 5
    assert [trace info variable a] eq ""
    assert [info command $object] eq ""
}

test tie_rename {
    # Ensure that renaming an object breaks the tie
} -body {
    set ::ndlist::tie_count 0
    set object [fruit new]
    tie a $object
    assert [trace info variable a] eq {{{write unset} {::ndlist::TieVarTrace 0}}}
    assert [trace info command $a] eq {{{rename delete} {::ndlist::TieObjTrace 0}}}
    rename $a foo
    # Note that the variable trace still exists.
    assert [trace info variable a] eq {{{write unset} {::ndlist::TieVarTrace 0}}}
    assert [trace info command foo] eq {}
    assert ![info exists ::ndlist::tie_object(0)]
    # Modifying the variable does nothing but clean up the trace.
    set a 5
    assert [trace info variable a] eq ""
    assert [info command foo] eq foo
}
rename foo ""

test tie_destroy {
    # Ensure that destroying an object breaks the tie
} -body {
    set ::ndlist::tie_count 0
    set object [fruit new]
    tie a $object
    assert [trace info variable a] eq {{{write unset} {::ndlist::TieVarTrace 0}}}
    assert [trace info command $a] eq {{{rename delete} {::ndlist::TieObjTrace 0}}}
    $a destroy
    # Note that the variable trace still exists.
    assert [trace info variable a] eq {{{write unset} {::ndlist::TieVarTrace 0}}}
    assert [info command $object] eq {}
    assert ![info exists ::ndlist::tie_object(0)]
    # Modifying the variable does nothing but clean up the trace.
    set a 5
    assert [trace info variable a] eq ""
    assert [info command $object] eq ""
}

test tie_multiple {
    # Have multiple ties on one object
} -body {
    set ::ndlist::tie_count 0
    set object [fruit new]
    tie a $object
    tie b $object
    assert [trace info variable a] eq {{{write unset} {::ndlist::TieVarTrace 0}}}
    assert [trace info variable b] eq {{{write unset} {::ndlist::TieVarTrace 1}}}
    assert [trace info command $a] eq {{{rename delete} {::ndlist::TieObjTrace 1}} {{rename delete} {::ndlist::TieObjTrace 0}}}
    set a 5; # destroys object
    assert [trace info variable a] eq ""
    # Variable trace still exists on b, but command does not exist
    assert [trace info variable b] eq {{{write unset} {::ndlist::TieVarTrace 1}}}
    assert [info command $b] eq ""
    set b 5; # removes trace on b
    assert [trace info variable a] eq ""
    assert [trace info variable b] eq ""
}

test tie_error1 {
    # Trying to tie to something that is not an object will return an error.
} -body {
    tie a 5
} -returnCodes {1} -result {"5" is not an object}

test GC1 {
    # Test example of GarbageCollector superclass
} -body {
    oo::class create veggie {
        superclass ::ndlist::GarbageCollector
        variable veggieType veggieCount
        constructor {refName type count} {
            set veggieType $type
            set veggieCount $count
            next $refName
        }
        method eat {} {
            puts "yum!"
            incr veggieCount -1
        }
        method type {} {
            return $veggieType
        }
        method count {} {
            return $veggieCount
        }
    }
    veggie new x beans 10
    $x eat
    assert {[$x type] eq "beans"}
    $x --> y
    assert {[$y count] == 9}
    unset x
    assert {[llength [info class instances ::veggie]] == 1}
    assert {[$y type] eq "beans"}
    $y --> x
    $y --> x; # deletes previous x
    assert {[llength [info class instances ::veggie]] == 2}
    $y eat; # reduces count of $y to 8, doesn't affect x
    $x count
} -result {9}

test GarbageCollector {
    # Testing features of the GarbageCollector
} -body {
    # Create class that is subclass of ::ndlist::GarbageCollector
    oo::class create count {
        superclass ::ndlist::GarbageCollector
        variable i
        constructor {refName value} {
            set i $value
            next $refName
        }
        method value {} {
            return $i
        }
        method incr {{value 1}} {
            incr i $value
        }
    }
    # Create procedure that returns a "count" object
    proc addup {list} {
        count new sum 0
        foreach value $list {
            $sum incr $value
        }
        untie sum
        return $sum
    }
    # Get sum, and store in "total"
    tie total [addup {1 2 3 4}]
    [addup {1 2 3 4}] --> total
    llength [info class instances count]
} -result {2}

test ValueContainer {
    # ValueContainer basic test
} -body {
    ::ndlist::ValueContainer new x
    $x = 10
    $x
} -result {10}

test SelfRef {
    # Use alias $. for current object.
} -body {
    ::ndlist::ValueContainer new x 5
    assert [$x | := {[$.] + 10}] == 15
    assert [$x | := {[lrepeat [$.] foo]}] eq {foo foo foo foo foo}
}

test Uplevel {
    # ValueContainer Uplevel test
} -body {
    ::ndlist::ValueContainer new x
    $x = 1
    $x := {[[$. := {[$.] + 1}]] + 1}; # Nested call
    $x
} -result {3}

test Pipe {
    # ValueContainer temporary object test
} -body {
    ::ndlist::ValueContainer new x 5.0
    [$x --> y] = [$x | := {[$.] ** 2}]
    list [$x] [$y]
} -result {5.0 25.0}

test RefEval_1 {
    # Reference evaluation
} -body {
    ::ndlist::ValueContainer new x 5
    $x & ref {incr ref}
    assert ![info exists ref]
    $x
} -result {6}

test RefEval_2 {
    # Delete object
} -body {
    ::ndlist::ValueContainer new x 5
    $x & ref {unset ref}
    info object isa object $x
} -result {0}

test RefEval_3 {
    # Return value of body
} -body {
    ::ndlist::ValueContainer new x {1 2 3 4}
    $x & ref {llength $ref}
} -result {4}

# Run examples from Documentation
test doc_examples {
    # Documentation examples, (note, not automatically built from docs)
} -body {
puts ""
puts "Variable-object ties"
oo::class create foo {
    method sayhello {} {
        puts {hello world}
    }
}
tie a [foo create bar]
set b $a; # object alias
$a sayhello
$b sayhello
unset a; # destroys object
catch {$b sayhello} result; # throws error
puts $result

puts "Simple value container class"
oo::class create value {
    superclass ::ndlist::GarbageCollector
    variable myValue
    method set {value} {set myValue $value}
    method value {} {return $myValue}
}
[value new x] --> y; # create x, and copy to y.
$y set {hello world}; # modify $y
unset x; # destroys $x
puts [$y value]

puts "Simple container"
::ndlist::ValueContainer new x
$x = {hello world}
puts [$x]

puts "Modifying a container object"
[::ndlist::ValueContainer new x] = 5.0
$x := {[$.] + 5}
puts [$x]

puts "Advanced methods"
[::ndlist::ValueContainer new x] = {1 2 3}
# Use ampersand method to use commands that take variable name as input
$x & ref {
    lappend ref 4
}
puts [$x | = {hello world}]; # operates on temp object
puts [$x]
} -output {
Variable-object ties
hello world
hello world
invalid command name "::bar"
Simple value container class
hello world
Simple container
hello world
Modifying a container object
10.0
Advanced methods
hello world
1 2 3 4
} -errorOutput {}
