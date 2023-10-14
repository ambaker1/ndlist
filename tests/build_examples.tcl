# Builds the example test file
# Called from main directory.

# Define proc to read example body
proc GetLstListing {fid} {
    set line [gets $fid]
    if {$line ne "\\begin{lstlisting}"} {
        return -code error "no lstlisting found"
    }
    set lines ""
    while {[set line [gets $fid]] ne "\\end{lstlisting}"} {
        lappend lines $line
    }
    return $lines
}

# Find examples in file
set examples ""
set fid [open doc/ndlist.tex r]
while {![eof $fid]} {
    # Look for example
    set line [gets $fid]
    if {[string range $line 0 14] ne "\\begin{example}"} {
        continue
    }
    # Example found, with name $name
    set name [string range $line 16 end-1]
    # Get example body
    set body [GetLstListing $fid]
    # Check for output
    set line [gets $fid]
    if {$line eq "\\tcblower"} {
        set output [GetLstListing $fid]
    } else {
        set output ""
    }
    # Add to examples 
    dict set examples $name body $body
    dict set examples $name output $output
}
close $fid

# Write examples file
set fid [open tests/examples.tcl w]
puts $fid "# Documentation examples"
set count 1
dict for {name data} $examples {
    puts $fid "\ntest {Example $count} {$name} -body \{"
    puts $fid "puts {}"; # For first line of output
    foreach line [dict get $data body] {
        puts $fid $line
    }
    puts $fid "puts -nonewline {}"; # For result of example
    puts $fid "\} -output \{"
    foreach line [dict get $data output] {
        puts $fid $line
    }
    puts $fid "\}"
    incr count
}
close $fid
