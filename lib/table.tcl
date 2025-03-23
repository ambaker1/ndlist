# table.tcl
################################################################################
# Tcl equivalent of SQLite tables

# Copyright (C) 2025 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Define namespace and exported commands
namespace eval ::ndlist {
    namespace export table
}

Table format: 
field column field column ...

brainstorming:
$table @ 0:end * | expr {@A + @B}

$table @ [$table where {@first eq "foo"}] last = "bar"

# A table is simply a matrix with the first row being fields.
# The fields must be unique, and an index map is created

$table = [nreplace [$table] : {1 2} [nget [$table] : {2 1}]]
$table fields

# Tables should be able to be modified in the same way as matrices, but with field names instead of column IDs.
# I need to totally reimagine how tables work in ndlist.

$t add 

# table --
#
# Object variable class for tables.
#
# Syntax:
# table new $varName <$matrix>
#
# Arguments:
# varName       Variable name for garbage collection
# matrix        Value of table (matrix representation)

::oo::class create ::ndlist::table {
    superclass ::ndlist::ValueContainer
    variable myValue
    
    # SetValue --
    # 
    # Verify that the input value is correct

    method SetValue {value} {
        # Ensure input is a dictionary
        if {[catch {dict size $value}]} {
            return -code error "table must be a valid Tcl dictionary"
        }
        # Ensure that values in dictionary are lists of same length
        set n ""
        dict for {field column} $value {
            if {![string is list $column]} {
                return -code error "columns must be valid Tcl lists"
            }
            if {$n eq ""} {
                set n [llength $column]
                continue
            }
            if {$n != [llength $column]} {
                return -code error "columns must all be same length"
            }
        }
        next $value
    }
    
    # $tblObj clear --
    #
    # Clear out all data in table (keeps fields)

    method clear {} {
        set myValue [dict map {field column} $myValue {set column ""}] 
        return [self]
    }
    
    # $tblObj clean --
    #
    # Clear entries and fields that have no data

    # method clean {} {
        # # Remove blank entries
        # set myValue [lmap row $myValue {
            # if {[my IsNull $row]} {
                # continue
            # }
            # set row
        # }]
        # # Remove blank fields
        # foreach field [my fields] {
            # if {[my IsNull [my @ : $field]]} {
                # my remove $field
            # }
        # }
        # # Return object name
        # return [self]
    # }
    
    # # my IsNull --
    # #
    # # Returns if a list is all blanks or not
    
    # method IsNull {list} {
        # set isNull 1
        # foreach value $list {
            # if {$value ne ""} {
                # set isNull 0
                # break
            # }
        # }
        # return $isNull
    # }

    # Table property access/modification
    ########################################################################

    # $tblObj fields --
    # 
    # Access table fields
    #
    # Syntax:
    # $tblObj fields <$pattern>
    #
    # Arguments:
    # pattern:          Optional glob pattern. Default "*"

    method fields {{pattern *}} {
        dict keys $myValue $pattern
    }
    
    # $tblObj exists --
    # 
    # Returns if a table field exists
    #
    # Syntax:
    # $tblObj exists $field
    #
    # Arguments:
    # field:            Name of field
    
    method exists {field} {
        dict exists $myValue $field
    }
    
    # $tblObj add --
    #
    # Add a field to the table
    
    method add {args} {
        foreach field $args {
            if {[my exists $field]} {
                continue
            }
            set i [my width]; # current size
            set myValue [::ndlist::npad $myValue {} 0 1]
            set myValue [::ndlist::nreplace $myValue 0 end $field]
            dict set fieldMap $field $i
        }
    }
    
    # $tblObj remove --
    #
    # Remove fields from the table
    
    method remove {args} {
        foreach field $args {
            if {![my exists $field]} {
                continue
            }
            set i [dict get $fieldMap $field]
            my SetValue [::ndlist::nremove $myValue $i 1]
        }
    }
    
    # my AssertFieldExists --
    #
    # Asserts that field exists
    #
    # Syntax:
    # my AssertFieldExists $field
    #
    # Arguments:
    # field:            Field to check
    
    method AssertFieldExists {field} {
        if {![dict exists $fieldMap $field]} {
            return -code error "field \"$field\" not in table"
        }
    }

    # $tblObj height --
    #
    # Number of entries

    method height {} {
        dict for {field column} $myValue {
            return [llength $column]
        }
    }

    # $tblObj width --
    #
    # Number of fields in table

    method width {} {
        llength [dict keys $myValue]
    }
    
    # Table entry
    ########################################################################
    
    # Table entry is tricky because I can't just rely on matrix indexing. The field stuff is complicated. I want there to only be a few functions. And I want the input/output to be in matrix format.
    
    $T set $fields $indices $values
    $T get $fields $indices 
    
    # Right now, the way that matrix indexing works, I can't index outside of the bounds of the size of the matrix. So I can't expand it. This is a problem, I want to be able to add more entries to the matrix.
    
    # Should 
    
    
    
    $t set : 
    
    $t @ : {{hello there}}
    
    $t set 2* A $value B $value
    
    $t lappend A foo B bar
    $t lappend 
    $t lappend 
    
    $t get {1 2} A B 
    
    

    # $tblObj set --
    #
    # Set values in a table
    #
    # Syntax:
    # $tblObj set $indices $field $values ...
    #
    # Arguments:
    # fields:       field to modify
    # indices:      indices of column to modify (":" for all)
    # sublist:      replacement values (uses nreplace)

    method set {indices args} {
        set myCopy $myValue
        dict for {field values} $args {
            my AssertFieldExists $field
            set column [dict get $myValue $field]
            ::ndlist::nset column $indices $values
            dict set myCopy $field $column
        }
        my SetValue $myCopy
        return [self]
    }
    
    # $tblObj get --
    # 
    # Get column values from a table
    #
    # Syntax:
    # $tblObj get $indices $field
    #
    # Arguments:
    # field:        field to get
    # indices:      indices of column to get (":" for all)

    method get {indices field} {
        my AssertFieldExists $field
        return [::ndlist::nget [dict get $myValue $field] $indices]
    }
    
    # $tblObj rset --
    #
    # Set values, row-wise, in a table
    #
    # Syntax:
    # $tblObj rset $fields $indices
    #
    # Arguments:
    # field:        field to get
    # indices:      indices of column to get (":" for all)
    
    $table @ field : = foo
    
    $table set A [$table where {@A > 3}] 
    
    # $tblObj rset --
    #
    # Set row values in table
    
    # $tblObj rset $index $field $value $field $value 
    
    # $tblObj lappend --
    # 
    # Append a row to the table.
    
    method append {args} {
        set myValue [::ndlist::npad $myValue {} 1 0]
        if {[catch {my set end {*}$args} result]} {
            set myValue [::ndlist::nremove $myValue end]
            return -code error $result
        }
        return $result
    }
    
    # $tblObj get --
    # 
    # Get a single value from a table
    # If a key/field pairing does not exist, returns blank.
    # Return error if a key or field does not exist
    #
    # Syntax:
    # $tblObj get $row $field
    #
    # Arguments:
    # row:          row index (1 to height)
    # field:        field to query

    method get {row field} {
        # Check for valid row input
        if {![string is integer -strict $row]} {
            return -code error "row ID must be integer"
        }
        if {$row < 1 || $row > [my height]} {
            return -code error "row ID out of range"
        }
        # Assert if field exists
        my AssertFieldExists $field
        # Return value in table
        return [lindex $myValue $row [dict get $fieldMap $field]]
    }
    
    # $tblObj expr --
    #
    # Perform a field expression, return list of values
    # 
    # Arguments:
    # fieldExpr:    Tcl expression, but with @ symbol for fields

    method expr {fieldExpr} {
        # Get list of fields in fieldExpr
        set exp {@\w+|@{(\\\{|\\\}|[^\\}{]|\\\\)*}}
        set map ""
        foreach {match submatch} [regexp -inline -all $exp $fieldExpr] {
            lappend map [join [string range $match 1 end]] ""
        }
        set fields [dict keys $map]
        
        # Check validity of fields in field expression
        foreach field $fields {
            my AssertFieldExists $field
        }
        
        # Now, we know that the fields are valid, and we will loop through 
        # the rows and get values according to the field expression
        set values ""
        foreach entry [lrange $myValue 1 end] {
            # Perform regular expression substitution
            set subExpr $fieldExpr
            set valid 1
            foreach field $fields {
                set value [lindex $entry [dict get $fieldMap $field]]
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
        }; # end foreach key
        
        # Return values created by field expression
        return $values
    }
    
    
    
    
    # $tblObj where --
    #
    # Get row IDs where a field expression is true
    #
    # Arguments:
    # expr:         Field expression that results in a boolean value

    method where {expr} {
        ::ndlist::find [concat 0 [uplevel 1 [list [self] expr $expr]]]
    }
	
	# $tblObj @ --
    # 
    # Field access and modification
    #
    # Syntax:
    # $tblObj @ $rows $field <= $column | := $expr>
    #
    # Arguments:
    # index:        row indices
    # field:        field to query or modify
    # filler:       filler for missing values (default "")
    # column:       List of values (length must match height, or be scalar)
    # expr:    		Tcl expression, but with @ symbol for fields
	
	method @ {index field args} {
		# Check arity
		if {[llength $args] > 2} {
			return -code error 
					"wrong # args: want \"[self] @ field ?op arg?\""
		}
		# Access
		# $tblObj @ $field <$filler>
		if {[llength $args] <= 1} {
			tailcall my cget $field {*}$args
		}
		# Modification
		lassign $args op arg
		switch $op {
			= { # $tblObj @ $field = $column
				tailcall my cset $field $arg
			}
			:= { # $tblObj @ $field := $expr
				tailcall my cset $field [uplevel 1 [list [self] expr $arg]]
			}
			default {
				return -code error "unknown operator \"$op\""
			}
		}
	}
	export @

    # $tblObj search --
    #
    # Find key or keys that match a specific criteria, using lsearch.
    # 
    # Arguments:
    # args:         Selected lsearch options. 
    #                   Use -- to signal end of options.         
    # field:        Field to search in. If omitted, will search in keys.
    # value:        Value to search for.

    method search {args} {
        # Interpret arguments
        set options ""
        set remArgs ""
        set optionCheck 1
        foreach arg $args {
            if {$optionCheck} {
                # Check valid options
                if {$arg in {
                    -exact
                    -glob
                    -regexp
                    -sorted
                    -all
                    -not
                    -ascii
                    -dictionary
                    -integer
                    -nocase
                    -real
                    -decreasing
                    -increasing
                    -bisect
                }} then {
                    lappend options $arg
                    continue
                } else {
                    set optionCheck 0
                    if {$arg eq {--}} {
                        continue
                    }
                }; # end check option arg
            }; # end if checking for options
            lappend remArgs $arg
        }; # end foreach arg
        
        # Process value and field arguments
        switch [llength $remArgs] {
            1 { # Search keys
                set value [lindex $remArgs 0]
            }
            2 { # Search a column
                lassign $remArgs field value
            }
            default {
                return -code error "wrong # args: should be\
                        \"[self] search ?-option value ...? field pattern\""
            }
        }; # end switch arity of remaining

        # Handle key search case
        if {![info exists field]} {
            # Filter by keys 
            set keyset [lsearch {*}$options -inline $keys $value]
        } else {
            # Filter by field values
            if {![my exists field $field]} {
                return -code error "field \"$field\" not found in table"
            }
            
            # Check whether to include blanks or not
            set includeBlanks [expr {
                ![catch {lsearch {*}$options {{}} $value} result] 
                && $result == 0
            }]
            
            # Get search list
            set searchList [lmap key $keys {
                if {[dict exists $datamap $key $field]} {
                    list $key [dict get $datamap $key $field]
                } elseif {$includeBlanks} {
                    list $key {}
                } else {
                    continue
                }
            }]; # end lmap key
            # Get matches and corresponding keys
            set matchList [lsearch {*}$options -index 1 -inline \
                    $searchList $value]
            if {{-all} in $options} {
                set keyset [lsearch -all -inline -subindices -index 0 \
                        $matchList *]
            } else {
                set keyset [lrange $matchList 0 0]
            }
        }
        # Return keyset or individual key if not -all
        if {{-all} in $options} {
            return $keyset
        } else {
            return [lindex $keyset 0]
        }
    }

    # $tblObj sort --
    # 
    # Sort a table, using lsort
    #
    # Arguments:
    # options:      Selected lsort options. Use -- to signal end of options.
    # args:         Fields to sort by

    method sort {args} {
        # Interpret arguments
        set options ""
        set fieldset ""
        set optionCheck 1
        foreach arg $args {
            if {$optionCheck} {
                # Check valid options
                if {$arg in {
                    -ascii
                    -dictionary
                    -integer
                    -real
                    -increasing
                    -decreasing
                    -nocase
                }} then {
                    lappend options $arg
                    continue
                } else {
                    set optionCheck 0
                    if {$arg eq "--"} {
                        continue
                    }
                }
            }
            lappend fieldset $arg
        }

        # Switch for sort type (keys vs fields)
        if {[llength $fieldset] == 0} {
            # Sort by keys
            set keys [lsort {*}$options $keys]
        } else {
            # Sort by field values
            foreach field $fieldset {
                # Check validity of field
                if {![my exists field $field]} {
                    return -code error "field \"$field\" not found in table"
                }
                
                # Get column and blanks
                set cdict ""; # Column dictionary for existing values
                set blanks ""; # Keys for blank values
                foreach key $keys {
                    if {[my exists value $key $field]} {
                        dict set cdict $key [dict get $datamap $key $field]
                    } else {
                        lappend blanks $key
                    }
                }
                
                # Sort valid keys by values, and then add blanks
                set keys [concat [dict keys [lsort -stride 2 -index 1 \
                        {*}$options $cdict]] $blanks]
            }; # end foreach field
        }; # end if number of fields
        
        # Update key map
        set i 0
        foreach key $keys {
            dict set keymap $key $i
            incr i
        }
        # Return object name
        return [self]
    }

    # $tblObj with --
    # 
    # Loops through table (row-wise), using dict with on the table data.
    # Missing data is represented by blanks. Setting a field to blank or 
    # unsetting the variable will unset the data.

    # Syntax:
    # $tblObj with $body 
    # Example:
    #
    # Arguments:
    # body:         Body to evaluate

    # new table T {key {x y}}
    # $T cset y {1 2 3}
    # $T with {set x [expr {$y + 2}]}

    method with {body} {
        variable temp; # Temporary variable for dict with loop
        foreach key $keys {
            # Establish keyname variable (not upvar, cannot modify)
            uplevel 1 [list set $keyname $key]
            # Create temporary row dict with blanks
            set temp [dict get $datamap $key]
            foreach field $fields {
                if {![dict exists $temp $field]} {
                    dict set temp $field ""
                }
            }
            # Evaluate body, using dict with
            uplevel 1 [list dict with [self namespace]::temp $body]
            # Filter out blanks
            dict set datamap $key [dict filter $temp value ?*]
        }
        # Return object name
        return [self]
    }

    # $tblObj merge --
    # 
    # Add table data from other tables, merging the data. 
    # Keynames must be consistent to merge.
    #
    # $tblObj merge $object ...
    # 
    # Arguments:
    # object ...    Tables to merge into main table

    method merge {args} {
        # Check compatibility
        foreach tblObj $args {
            # Check that the reference is pointing to a valid object.
            if {![info object isa object $tblObj]} {
                return -code error "\"$tblObj\" is not an object"
            }
            if {![info object isa typeof $tblObj ::ndlist::table]} {
                return -code error "\"$tblObj\" is not a table object"
            }
            # Verify that tables are compatible
            if {$keyname ne [$tblObj keyname]} {
                return -code error "cannot merge tables - keyname conflict"
            }
        }
        # Merge input tables
        foreach tblObj $args {
            # Add keys and fields
            my add keys {*}[$tblObj keys]
            my add fields {*}[$tblObj fields]
            # Merge data
            dict for {key rowmap} [$tblObj dict] {
                my set $key {*}$rowmap
            }
        }
        # Return object name
        return [self]
    }

}; # end class definition


