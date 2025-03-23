package require tin
tin import ndlist 0.10.1

proc texpr {tableValue expr} {
    # Get list of fields in expr
    set exp {@\w+|@{(\\\{|\\\}|[^\\}{]|\\\\)*}}
    set map ""
    foreach {match submatch} [regexp -inline -all $exp $expr] {
        lappend map [join [string range $match 1 end]] ""
    }
    set fields [dict keys $map]
    
    # Check validity of fields in field expression
    set subTable ""
    foreach field $fields {
        if {![dict exists $tableValue $field]} {
            return -code error "field \"$field\" does not exist"
        }
        dict set subTable $field [dict get $tableValue $field]
    }
    # Get height of table
    dict for {field column} $tableValue {
        set n [llength $column]
        break
    }
    # Loop through table
    set values ""
    for {set i 0} {$i < $n} {incr i} {
        # Perform regular expression substitution
        set subExpr $expr
        set valid 1
        foreach field $fields {
            set value [lindex [dict get $tableValue $field] $i]
            if {$value eq ""} {
                # No data here. Skip.
                set valid 0
                break
            }
            set subExpr [regsub $exp $subExpr "{$value}"]
        }; # end foreach fieldmap pair
        if {$valid} {
            # Only add data if all required fields exist.
            lappend values [uplevel 1 [list expr $subExpr]]
        } else {
            lappend values ""
        }; # end if valid
    }

    # Return values created by field expression
    return $values
}

# tsize --
proc TableHeight {table} {
    dict for {field column} $tableValue {return [llength $column]}
}

proc AssertFields {table args} {
    foreach field $args {
        if {![dict exists $table $field]} {
            return -code error "field \"$field\" not in table"
        }
    }
}

proc tsize {tableValue} {
    dict for {field column} $tableValue {
        return [list [llength $column] [llength [dict keys $tableValue]]]
    }
}

# # tget -- 
# #
# # Get a subset of a table, given fields and indices.

# proc tget {table fields index} {
    # if {$fields eq "*"} {
        # set fields [dict keys $table]
    # } else {
        # AssertFields $table {*}$fields
    # }
    # set subTable ""
    # foreach field $fields {
        # set column [dict get $table $field] 
        # dict set subTable $field [::ndlist::nget $column $index]
    # }
    # return $subTable
# }

set subset [tcreate $fields [tget $otherTable $fields $index]]

# My brain is fried

proc tcreate {fields values} {
    
}

# tget -- 
#
# Get values from a table, given fields and indices.

proc tget {table fields index} {
    if {$fields eq "*"} {
        set fields [dict keys $table]
    } else {
        AssertFields $table {*}$fields
    }
    set subTable ""
    foreach field $fields {
        set column [dict get $table $field] 
        dict set subTable $field [::ndlist::nget $column $index]
    }
    return $subTable
}

# trep --
# 
# Replace a portion of the table with values from a new table

proc trep {table fields index subTable} {
    if {$fields eq "*"} {
        set fields [dict keys $table]
    } else {
        AssertFields $table {*}$fields
    }
    
}

proc tbl2mat {table} {
    set header [::ndlist::transpose [dict keys $table]]
    set rows [::ndlist::transpose [dict values $table]]
    return [::ndlist::stack $header $rows]
}

proc mat2tbl {matrix} {
    set fields [lindex $matrix 0]
    set columns [::ndlist::transpose [lrange $matrix 1 end]]
    set table ""
    foreach field $fields column $columns {
        dict set table $field $column
    }
    return $table
}

treplace {A {1 2 3} B {4 5 6}} 0:1 {A {0 1}}



puts [mat2tbl {{A B C} {1 2 3} {4 5 6} {7 8 9}}]

proc treplace {tableValue fields index values} {
    
}


# treplace $table 1:end {foo bar} {{hello there}}


set table {A {1 2 3} B {4 {} 6} C {10 9 8}}
puts [tbl2mat $table]
puts [texpr $table {(@A + @B)*@C}]

puts [texpr [tget $table * {0 end}] {@A + @B}]

