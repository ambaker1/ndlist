package require tin 0.7.3
tin import assert from tin
tin import tcltest
set version 0.1
set config [dict create VERSION $version]
tin bake src build $config
tin bake doc/template/version.tin doc/template/version.tex $config

source build/ndlist.tcl 
namespace import ndlist::*

tin import flytrap

# Create identity matrix
for {set i 0} {$i < 3} {incr i} {
    nset I $i $i 1
}
assert {$I eq {{1 0 0} {0 1 0} {0 0 1}}}

# Matrix for testing (DO NOT CHANGE)
set testmat {{1 2 3} {4 5 6} {7 8 9}}

# Matrix access
assert {[nget $testmat : :] eq $testmat}
assert {[nget $testmat : 0] eq {1 4 7}}
assert {[nget $testmat : 0*] eq {1 4 7}}
assert {[nget $testmat : 0:1] eq {{1 2} {4 5} {7 8}}}
assert {[nget $testmat : 1:0] eq {{2 1} {5 4} {8 7}}}
assert {[nget $testmat 0 :] eq {{1 2 3}}}
assert {[nget $testmat 0 0] eq {1}}
assert {[nget $testmat 0 0*] eq {1}}
assert {[nget $testmat 0 0:1] eq {{1 2}}}
assert {[nget $testmat 0 1:0] eq {{2 1}}}
assert {[nget $testmat 0* :] eq {1 2 3}}
assert {[nget $testmat 0* 0] eq {1}}
assert {[nget $testmat 0* 0*] eq {1}}
assert {[nget $testmat 0* 0:1] eq {1 2}}
assert {[nget $testmat 0* 1:0] eq {2 1}}
assert {[nget $testmat 0:1 :] eq {{1 2 3} {4 5 6}}}
assert {[nget $testmat 0:1 0] eq {1 4}}
assert {[nget $testmat 0:1 0*] eq {1 4}}
assert {[nget $testmat 0:1 0:1] eq {{1 2} {4 5}}}
assert {[nget $testmat 0:1 1:0] eq {{2 1} {5 4}}}
assert {[nget $testmat 1:0 :] eq {{4 5 6} {1 2 3}}}
assert {[nget $testmat 1:0 0] eq {4 1}}
assert {[nget $testmat 1:0 0*] eq {4 1}}
assert {[nget $testmat 1:0 0:1] eq {{4 5} {1 2}}}
assert {[nget $testmat 1:0 1:0] eq {{5 4} {2 1}}}
assert {[nget $testmat 0:2:end :] eq {{1 2 3} {7 8 9}}}

assert {[nreplace $testmat : : ""] eq ""}
assert {[nreplace $testmat : : a] eq {{a a a} {a a a} {a a a}}}
assert {[nreplace $testmat : : {a b c}] eq {{a a a} {b b b} {c c c}}}
assert {[nreplace $testmat : : {{a b c}}] eq {{a b c} {a b c} {a b c}}}
assert {[nreplace $testmat : : {{a b c} {d e f} {g h i}}] eq {{a b c} {d e f} {g h i}}}
assert {[nreplace $testmat : 0 ""] eq {{2 3} {5 6} {8 9}}}
assert {[nreplace $testmat : 0 a] eq {{a 2 3} {a 5 6} {a 8 9}}}
assert {[nreplace $testmat : 0 {a b c}] eq {{a 2 3} {b 5 6} {c 8 9}}}
assert {[nreplace $testmat : 0* ""] eq {{2 3} {5 6} {8 9}}}
assert {[nreplace $testmat : 0* a] eq {{a 2 3} {a 5 6} {a 8 9}}}
assert {[nreplace $testmat : 0* {a b c}] eq {{a 2 3} {b 5 6} {c 8 9}}}
assert {[nreplace $testmat : 0:1 ""] eq {3 6 9}}
assert {[nreplace $testmat : 0:1 a] eq {{a a 3} {a a 6} {a a 9}}}
assert {[nreplace $testmat : 0:1 {a b c}] eq {{a a 3} {b b 6} {c c 9}}}
assert {[nreplace $testmat : 0:1 {{a b}}] eq {{a b 3} {a b 6} {a b 9}}}
assert {[nreplace $testmat : 0:1 {{a b} {c d} {e f}}] eq {{a b 3} {c d 6} {e f 9}}}
assert {[nreplace $testmat : 1:0 ""] eq {3 6 9}}
assert {[nreplace $testmat : 1:0 a] eq {{a a 3} {a a 6} {a a 9}}}
assert {[nreplace $testmat : 1:0 {a b c}] eq {{a a 3} {b b 6} {c c 9}}}
assert {[nreplace $testmat : 1:0 {{a b}}] eq {{b a 3} {b a 6} {b a 9}}}
assert {[nreplace $testmat : 1:0 {{a b} {c d} {e f}}] eq {{b a 3} {d c 6} {f e 9}}}
assert {[nreplace $testmat 0 : ""] eq {{4 5 6} {7 8 9}}}
assert {[nreplace $testmat 0 : a] eq {{a a a} {4 5 6} {7 8 9}}}
assert {[nreplace $testmat 0 : {{a b c}}] eq {{a b c} {4 5 6} {7 8 9}}}
assert {[catch {nreplace $testmat 0 0 ""}] == 1}; # do not allow for non-axis deletion
assert {[nreplace $testmat 0 0 a] eq {{a 2 3} {4 5 6} {7 8 9}}}
assert {[nreplace $testmat 0 0* a] eq {{a 2 3} {4 5 6} {7 8 9}}}
assert {[nreplace $testmat 0 0:1 a] eq {{a a 3} {4 5 6} {7 8 9}}}
assert {[nreplace $testmat 0 0:1 {{a b}}] eq {{a b 3} {4 5 6} {7 8 9}}}
assert {[nreplace $testmat 0 1:0 a] eq {{a a 3} {4 5 6} {7 8 9}}}
assert {[nreplace $testmat 0 1:0 {{a b}}] eq {{b a 3} {4 5 6} {7 8 9}}}
assert {[nreplace $testmat 0* : ""] eq {{4 5 6} {7 8 9}}}
assert {[nreplace $testmat 0* : a] eq {{a a a} {4 5 6} {7 8 9}}}
assert {[nreplace $testmat 0* : {a b c}] eq {{a b c} {4 5 6} {7 8 9}}}
assert {[nreplace $testmat 0* 0 a] eq {{a 2 3} {4 5 6} {7 8 9}}}
assert {[nreplace $testmat 0* 0* {hello world}] eq {{{hello world} 2 3} {4 5 6} {7 8 9}}}
assert {[nreplace $testmat 0* 0:1 a] eq {{a a 3} {4 5 6} {7 8 9}}}
assert {[nreplace $testmat 0* 0:1 {a b}] eq {{a b 3} {4 5 6} {7 8 9}}}
assert {[nreplace $testmat 0* 1:0 a] eq {{a a 3} {4 5 6} {7 8 9}}}
assert {[nreplace $testmat 0* 1:0 {a b}] eq {{b a 3} {4 5 6} {7 8 9}}}
assert {[nreplace $testmat 0:1 : ""] eq {{7 8 9}}}
assert {[nreplace $testmat 0:1 : a] eq {{a a a} {a a a} {7 8 9}}}
assert {[nreplace $testmat 0:1 : {{a b c}}] eq {{a b c} {a b c} {7 8 9}}}
assert {[nreplace $testmat 0:1 : {a b}] eq {{a a a} {b b b} {7 8 9}}}
assert {[nreplace $testmat 0:1 : {{a b c} {d e f}}] eq {{a b c} {d e f} {7 8 9}}}
assert {[nreplace $testmat 0:1 0 a] eq {{a 2 3} {a 5 6} {7 8 9}}}
assert {[nreplace $testmat 0:1 0 {a b}] eq {{a 2 3} {b 5 6} {7 8 9}}}
assert {[nreplace $testmat 0:1 0* a] eq {{a 2 3} {a 5 6} {7 8 9}}}
assert {[nreplace $testmat 0:1 0* {{hello world} {foo bar}}] eq {{{hello world} 2 3} {{foo bar} 5 6} {7 8 9}}}
assert {[nreplace $testmat 0:1 0:1 a] eq {{a a 3} {a a 6} {7 8 9}}}
assert {[nreplace $testmat 0:1 0:1 {a b}] eq {{a a 3} {b b 6} {7 8 9}}}
assert {[nreplace $testmat 0:1 0:1 {{a b}}] eq {{a b 3} {a b 6} {7 8 9}}}
assert {[nreplace $testmat 0:1 0:1 {{a b} {c d}}] eq {{a b 3} {c d 6} {7 8 9}}}
assert {[nreplace $testmat 0:1 1:0 a] eq {{a a 3} {a a 6} {7 8 9}}}
assert {[nreplace $testmat 0:1 1:0 {a b}] eq {{a a 3} {b b 6} {7 8 9}}}
assert {[nreplace $testmat 0:1 1:0 {{a b}}] eq {{b a 3} {b a 6} {7 8 9}}}
assert {[nreplace $testmat 0:1 1:0 {{a b} {c d}}] eq {{b a 3} {d c 6} {7 8 9}}}
assert {[nreplace $testmat 1:0 : ""] eq {{7 8 9}}}
assert {[nreplace $testmat 1:0 : a] eq {{a a a} {a a a} {7 8 9}}}
assert {[nreplace $testmat 1:0 : {{a b c}}] eq {{a b c} {a b c} {7 8 9}}}
assert {[nreplace $testmat 1:0 : {a b}] eq {{b b b} {a a a} {7 8 9}}}
assert {[nreplace $testmat 1:0 : {{a b c} {d e f}}] eq {{d e f} {a b c} {7 8 9}}}
assert {[nreplace $testmat 1:0 0 a] eq {{a 2 3} {a 5 6} {7 8 9}}}
assert {[nreplace $testmat 1:0 0 {a b}] eq {{b 2 3} {a 5 6} {7 8 9}}}
assert {[nreplace $testmat 1:0 0* a] eq {{a 2 3} {a 5 6} {7 8 9}}}
assert {[nreplace $testmat 1:0 0* {{hello world} {foo bar}}] eq {{{foo bar} 2 3} {{hello world} 5 6} {7 8 9}}}
assert {[nreplace $testmat 1:0 0:1 a] eq {{a a 3} {a a 6} {7 8 9}}}
assert {[nreplace $testmat 1:0 0:1 {a b}] eq {{b b 3} {a a 6} {7 8 9}}}
assert {[nreplace $testmat 1:0 0:1 {{a b}}] eq {{a b 3} {a b 6} {7 8 9}}}
assert {[nreplace $testmat 1:0 0:1 {{a b} {c d}}] eq {{c d 3} {a b 6} {7 8 9}}}
assert {[nreplace $testmat 1:0 1:0 a] eq {{a a 3} {a a 6} {7 8 9}}}
assert {[nreplace $testmat 1:0 1:0 {a b}] eq {{b b 3} {a a 6} {7 8 9}}}
assert {[nreplace $testmat 1:0 1:0 {{a b}}] eq {{b a 3} {b a 6} {7 8 9}}}
assert {[nreplace $testmat 1:0 1:0 {{a b} {c d}}] eq {{d c 3} {b a 6} {7 8 9}}}


# nexpr stuff
assert {[nexpr 1D x {1 2 3} {-$x}] eq {-1 -2 -3}}
# Filter a column out
assert {[nexpr 2D x $testmat {[j] == 2 ? [continue] : $x}] eq [nreplace $testmat : 2 ""]}
# Flip signs
assert {[nexpr 2D x $testmat {$x*([i]%2 + [j]%2 == 1?-1:1)}] eq {{1 -2 3} {-4 5 -6} {7 -8 9}}}
# Truncation
assert {[nexpr 1D x $testmat {[i] > 0 ? [break] : $x}] eq {{1 2 3}}}
# Basic operations
assert {[nexpr 2D x $testmat {-$x}] eq {{-1 -2 -3} {-4 -5 -6} {-7 -8 -9}}}

assert {[nexpr 2D x $testmat {$x / 2.0}] eq {{0.5 1.0 1.5} {2.0 2.5 3.0} {3.5 4.0 4.5}}}
assert {[nexpr 2D x $testmat y {.1 .2 .3} {$x + $y}] eq {{1.1 2.1 3.1} {4.2 5.2 6.2} {7.3 8.3 9.3}}}
assert {[nexpr 2D x $testmat y {{.1 .2 .3}} {$x + $y}] eq {{1.1 2.2 3.3} {4.1 5.2 6.3} {7.1 8.2 9.3}}}
assert {[nexpr 2D x $testmat y {{.1 .2 .3} {.4 .5 .6} {.7 .8 .9}} {$x + $y}] eq {{1.1 2.2 3.3} {4.4 5.5 6.6} {7.7 8.8 9.9}}}

assert {[nexpr 2D x $testmat {double($x)}] eq {{1.0 2.0 3.0} {4.0 5.0 6.0} {7.0 8.0 9.0}}}
assert {[nmap 1D x {1 2 3} {format %.2f $x}] eq {1.00 2.00 3.00}}
set cutoff 3
assert {[nexpr 1D x {1 2 3 4 5 6} {$x > $cutoff ? [continue] : $x}] eq {1 2 3}}

set a {{1 2} {3 4} {5 6}}
nset a {1 0} : [nget $a {0 1} :]
assert {$a eq {{3 4} {1 2} {5 6}}}

# Higher dimension stuff
assert {[nrepeat 2 2 2 0] eq {{{0 0} {0 0}} {{0 0} {0 0}}}}
set a ""
assert {[nset a 1 1 1 foo] eq {{{0 0} {0 0}} {{0 0} {0 foo}}}}; # fills with zeros
set ::ndlist::filler bar; # custom filler
set a ""
assert {[nset a 1 1 1 foo] eq {{{bar bar} {bar bar}} {{bar bar} {bar foo}}}}; # fills with bar
set ::ndlist::filler 0; # reset to default

ndlist 3D a ""
$a @ 1 1 1 = foo
assert {[$a] eq {{{0 0} {0 0}} {{0 0} {0 foo}}}}

matrix a [nrepeat 2 2 1]
set b $a
nexpr {@a*2.0} --> a
assert {![info object isa object $b]}
assert {[$a] eq {{2.0 2.0} {2.0 2.0}}}

nexpr {@a + 2} --> a

$ndobj += 5
$ndobj := {@ndobj + 5}


$ndobj := {@ndobj + 5}

nop 2D $ndlist $op <$value>
nop $ndobj $op <$value>

