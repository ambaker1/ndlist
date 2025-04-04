# table.tcl
################################################################################
# Constant-time tabular data format, using TclOO and Tcl dictionaries.

# Copyright (C) 2025 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Define namespace and exported commands
namespace eval ::ndlist {
    namespace export table
}

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
    # Additional variables used in all methods
    variable keyname keys keymap fields fieldmap datamap

    # SetValue --
    # 
    # Set value of table from matrix representation.

    method SetValue {matrix} {
        # Null case (wipe the table)
        if {$matrix eq ""} {
            my wipe
            return [self]
        }
        # Validate input before setting value.
        set matrix [::ndlist::ndlist 2 $matrix]; # verifies that it is a matrix
        # Check uniqueness of keyname/fields
        set header [lindex $matrix 0]
        if {![my IsUniqueList $header]} {
            return -code error "invalid input: duplicates in header"
        }
        # Check uniqueness of keys
        set firstcolumn [lmap row [lrange $matrix 1 end] {lindex $row 0}]
        if {![my IsUniqueList $firstcolumn]} {
            return -code error "invalid input: duplicates in first column"
        }
        # Define table
        my wipe
        my define keyname [lindex $header 0]
        my define fields [lrange $header 1 end]
        my define keys $firstcolumn
        foreach row [lrange $matrix 1 end] key [my keys] {
            foreach value [lrange $row 1 end] field [my fields] {
                my set $key $field $value
            }
        }
        return [self]
    }

    # GetValue --
    #
    # Gets matrix representation of table.

    method GetValue {} {
        set matrix [list [linsert $fields 0 $keyname]]
        foreach key $keys {
            set row $key
            foreach field $fields {
                lappend row [my get $key $field]
            }
            lappend matrix $row
        }
        return $matrix
    }

    # my IsUniqueList --
    #
    # Private method for checking uniqueness of key/field inputs.
    #
    # Syntax:
    # my IsUniqueList $list
    #
    # Arguments:
    # list:             List to check for uniqueness

    method IsUniqueList {list} {
        set map ""
        foreach item $list {
            if {[dict exists $map $item]} {
                return 0
            }
            dict set map $item ""
        }
        return 1
    }
    
    # $tblObj wipe --
    #
    # Reset table entirely to defaults

    method wipe {} {
        my clear
        set fields ""; # Ordered list of fields
        set fieldmap ""; # Dictionary of fields and indices
        set keyname key; # Name of keys (first column name)
        return [self]
    }

    # $tblObj clear --
    #
    # Clear out all data in table (keeps keyname and fields/fieldmap)

    method clear {} {
        set datamap ""; # Double-nested dictionary of table data
        set keys ""; # Ordered list of keys
        set keymap ""; # dictionary of keys and indices
        return [self]
    }

    # Table property access/modification
    ########################################################################

    # $tblObj keyname --
    # 
    # Access keyname of table.
    #
    # Syntax:
    # $tblObj keyname

    method keyname {} {
        return $keyname
    }

    # $tblObj keys --
    # 
    # Access table keys
    #
    # Syntax:
    # $tblObj keys <$pattern>

    method keys {{pattern *}} {
        if {$pattern eq "*"} {
            return $keys
        }
        lsearch -inline -all $keys $pattern
    }

    # $tblObj fields --
    # 
    # Access table fields
    #
    # Syntax:
    # $tblObj fields <$pattern>
    #
    # Arguments:
    # pattern:          Optional glob pattern

    method fields {{pattern *}} {
        if {$pattern eq "*"} {
            return $fields
        }
        lsearch -inline -all $fields $pattern
    }
    
    # $tblObj values --
    # 
    # Access matrix of values (excluding the header and first column)
    #
    # Arguments:
    # filler:           Filler for missing values. Default blank.
    
    method values {{filler ""}} {
        lmap key $keys {
            my rget $key $filler
        }
    }
    
    # $tblObj dict --
    #
    # Get raw table dict (double-nested dictionary, first level keys)
    
    method dict {} {
        return $datamap
    }

    # $tblObj height --
    #
    # Number of keys in table

    method height {} {
        llength $keys
    }

    # $tblObj width --
    #
    # Number of fields in table

    method width {} {
        llength $fields
    }

    # $tblObj exists --
    #
    # Check if key/field or key/field pairing exists, using hashmaps
    #
    # Syntax:
    # $tblObj exists key $key
    # $tblObj exists field $field
    # $tblObj exists value $key $field
    # 
    # Arguments:
    # key:          Key to look up
    # field:        Field to look up

    method exists {type args} {
        switch $type {
            key { # $tblObj exists key $key
                if {[llength $args] != 1} {
                    return -code error "wrong # args: should be\
                            \"[self] exists key name\""
                }
                return [dict exists $keymap [lindex $args 0]]
            }
            field { # $tblObj exists field $field
                if {[llength $args] != 1} {
                    return -code error "wrong # args: should be\
                            \"[self] exists field name\""
                }
                return [dict exists $fieldmap [lindex $args 0]]
            }
            value { # $tblObj exists value $key $field
                if {[llength $args] != 2} {
                    return -code error "wrong # args: should be\
                            \"[self] exists value key field\""
                }
                return [dict exists $datamap {*}$args]
            }
            default {
                return -code error "unknown option \"$type\": want\
                        \"key\", \"field\" or \"value\""
            }
        }; # end switch type
    }

    # $tblObj find --
    #
    # Find index of key/field.
    #
    # Syntax:
    # $tblObj find key $key
    # $tblObj find field $field
    #
    # Arguments:
    # key/field:        Key/field to look up

    method find {type value} {
        switch $type {
            key { # $tblObj find key $key
                set key $value
                if {[my exists key $key]} {
                    return [dict get $keymap $key]
                } else {
                    return -code error "key \"$key\" not found in table"
                }
            }
            field { # $tblObj find field $field
                set field $value
                if {[my exists field $field]} {
                    return [dict get $fieldmap $field]
                } else {
                    return -code error "field \"$field\" not found in table"
                }
            }
            default {
                return -code error "unknown option \"$type\": want\
                        \"key\" or \"field\""
            }
        }
    }

    # Table entry
    ########################################################################

    # $tblObj set --
    #
    # Set single values in a table (single or dictionary form)
    # Allows for multiple value inputs for record-style entry
    #
    # Syntax:
    # $tblObj set $key $field $value ...
    #
    # Arguments:
    # key:          Row key
    # field:        Column field(s)
    # value:        Value(s) to set

    method set {key args} {
        # Check arity
        if {[llength $args] % 2} {
            # Default syntax
            return -code error "wrong # args: should be \"[self] set key field\
                    value ?field value ...?\""
        }
        # Add keys and fields
        my add keys $key
        my add fields {*}[dict keys $args]
        # Add data
        dict for {field value} $args {
            # Handle blanks
            if {$value eq ""} {
                dict unset datamap $key $field
            } else {
                dict set datamap $key $field $value
            }; # end if blank
        }
        # Return self
        return [self]
    }
    
    # $tblObj rset --
    #
    # Set entire row
    #
    # Syntax:
    # $tblObj rset $key $row
    #
    # Arguments:
    # key:          Key associated with row
    # row:          List of values (length must match table width, or be scalar)

    method rset {key row} {
        # Get input and target dimensions and check for error
        set m0 [my width]
        set m1 [llength $row]
        if {$m1 == 0} {
            set type blank
        } elseif {$m1 == 1} {
            set value [lindex $row 0]
            if {$value eq ""} {
                set type blank
            } else {
                set type scalar
            }
        } elseif {$m1 == $m0} {
            set type values
        } else {
            return -code error "inconsistent number of fields/columns"
        }
        
        # Add key
        my add keys $key
        
        # Switch for input type (blank, scalar, or values)
        switch $type {
            blank {
                dict set datamap $key ""
            }
            scalar {
                foreach field $fields {
                    dict set datamap $key $field $value
                }; # end foreach field
            }
            values {
                foreach value $row field $fields {
                    # Handle blanks
                    if {$value eq ""} {
                        dict unset datamap $key $field
                    } else {
                        dict set datamap $key $field $value
                    }; # end if blank
                }; # end foreach value/field
            }
        }; # end switch input type
        # Return object name
        return [self]
    }

    # $tblObj cset --
    #
    # Set entire column
    #
    # Syntax:
    # $tblObj cset $field $column
    # 
    # Arguments:
    # field:        Field associated with column
    # column:       List of values (length must match height, or be scalar)

    method cset {field column} {
        # Get source and input dimensions and get input type
        set n0 [my height]
        set n1 [llength $column]
        if {$n1 == 0} {
            set type blank
        } elseif {$n1 == 1} {
            set value [lindex $column 0]
            if {$value eq ""} {
                set type blank
            } else {
                set type scalar
            }
        } elseif {$n1 == $n0} {
            set type values
        } else {
            return -code error "inconsistent number of keys/rows"
        }
        
        # Add to field list
        my add fields $field
        
        # Switch for input type (blank, scalar, or column)
        switch $type {
            blank {
                foreach key $keys {
                    dict unset datamap $key $field
                }; # end foreach value/field
            }
            scalar {
                foreach key $keys {
                    dict set datamap $key $field $value
                }; # end foreach key
            }
            values {
                foreach value $column key $keys {
                    # Handle blanks
                    if {$value eq ""} {
                        dict unset datamap $key $field
                    } else {
                        dict set datamap $key $field $value
                    }; # end if blank
                }; # end foreach value/field
            }
        }; # end switch input type
        # Return object name
        return [self]
    }
    
    # $tblObj mset --
    #
    # Set range of table
    #
    # Syntax:
    # $tblObj mset $keys $fields $matrix
    #
    # Arguments:
    # keys:         Keys associated with rows
    # field:        Fields associated with columns
    # matrix:       Matrix of values (dimensions must match table or be scalar)

    method mset {keyset fieldset matrix} {
        # Get source and input dimensions and get input type
        set n0 [llength $keyset]
        set m0 [llength $fieldset]
        set n1 [llength $matrix]
        set m1 [llength [lindex $matrix 0]]
        if {$n1 == 0 && $m1 == 0} {
            set type blank
        } elseif {$n1 == 1 && $m1 == 1} {
            set value [lindex $matrix 0 0]
            if {$value eq ""} {
                set type blank
            } else {
                set type scalar
            }
        } elseif {$n1 == $n0 && $m1 == $m0} {
            set type values
        } else {
            return -code error "input must be 0x0, 1x1 or ${n0}x${m0}"
        }
     
        # Add to key/field lists
        my add keys {*}$keyset
        my add fields {*}$fieldset
        
        # Switch for input type (blank, scalar, or matrix)
        switch $type {
            blank {
                foreach key $keyset {
                    foreach field $fieldset {
                        dict unset datamap $key $field
                    }; # end foreach value/field
                }; # end foreach row/key
            }
            scalar {
                foreach key $keyset {
                    foreach field $fieldset {
                        dict set datamap $key $field $value
                    }; # end foreach value/field
                }; # end foreach row/key
            }
            values {
                foreach row $matrix key $keyset {
                    foreach value $row field $fieldset {
                        # Handle blanks
                        if {$value eq ""} {
                            dict unset datamap $key $field
                        } else {
                            dict set datamap $key $field $value
                        }; # end if blank
                    }; # end foreach value/field
                }; # end foreach row/key
            }
        }; # end switch input type
        # Return object name
        return [self]
    }
	
	# $tblObj @ --
    # 
    # Field access and modification
    #
    # Syntax:
    # $tblObj @ $field <$filler> <= $column | := $expr>
    #
    # Arguments:
    # field:        field to query or modify
    # filler:       filler for missing values (default "")
    # column:       List of values (length must match height, or be scalar)
    # expr:    		Tcl expression, but with @ symbol for fields
	
	method @ {field args} {
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
    
    # Table access
    ########################################################################

    # $tblObj get --
    # 
    # Get a value from a table
    # If a key/field pairing does not exist, returns blank.
    # Return error if a key or field does not exist
    #
    # Syntax:
    # $tblObj get $key $field <$filler>
    #
    # Arguments:
    # key:          key to query
    # field:        field to query
    # filler:       filler for missing values (default "")

    method get {key field {filler ""}} {
        # Check if key-field pairing exists
        if {![my exists key $key]} {
            return -code error "key \"$key\" not found in table"
        }
        if {![my exists field $field]} {
            return -code error "field \"$field\" not found in table"
        }
        # Return value or blank if does not exist
        if {[my exists value $key $field]} {
            return [dict get $datamap $key $field]
        } else {
            return $filler
        } 
    }
    
    # $tblObj rget --
    #
    # Get a list of row values
    #
    # Syntax:
    # $tblObj rget $key <$filler>
    #
    # Arguments:
    # key:          key to query
    # filler:       filler for missing values (default "")

    method rget {key {filler ""}} {
        lmap field $fields {
            my get $key $field $filler
        }
    }

    # $tblObj cget --
    #
    # Get a list of column values
    #
    # Syntax:
    # $tblObj cget $field <$filler>
    #
    # Arguments:
    # field:        field to query
    # filler:       filler for missing values (default "")

    method cget {field {filler ""}} {
        # Loop through all keys, and return vector
        lmap key $keys {
            my get $key $field $filler
        }
    }
    
    # $tblObj mget --
    #
    # Get a matrix of table values 
    #
    # Syntax:
    # $tblObj mget $keys $fields <$filler>
    #
    # Arguments:
    # keys:         Keys to query
    # fields:       Fields to query
    # filler:       filler for missing values (default "")

    method mget {keyset fieldset {filler ""}} {
        # Loop through keys and fields and return matrix
        lmap key $keyset {
            lmap field $fieldset {
                my get $key $field $filler
            }
        }
    }

    # $tblObj expr --
    #
    # Perform a field expression, return list of values
    # 
    # Arguments:
    # fieldExpr:    Tcl expression, but with @ symbol for fields

    method expr {fieldExpr {filler ""}} {
        # Get mapping of fields in fieldExpr
        set exp {@\w+|@{(\\\{|\\\}|[^\\}{]|\\\\)*}}
        set fieldMap ""
        foreach {match submatch} [regexp -inline -all $exp $fieldExpr] {
            lappend fieldMap [join [string range $match 1 end]] $match
        }
        
        # Check validity of fields in field expression
        dict for {field match} $fieldMap {
            if {![dict exists $fieldmap $field] && $field ne $keyname} {
                return -code error "field \"$field\" not found in table"
            }
        }
        
        # Now, we know that the fields are valid, and we will loop through 
        # the list of keys, and use "catch"
        # Get values according to field expression
        set values ""
        foreach key $keys {
            # Perform regular expression substitution
            set subExpr $fieldExpr
            set valid 1
            foreach {field match} $fieldMap {
                if {![my exists value $key $field]} {
                    if {$field eq $keyname} {
                        set subExpr [regsub $exp $subExpr "{$key}"]
                        continue
                    }
                    # No data for this key/field combo. Skip.
                    set valid 0
                    break
                }
                set subExpr [regsub $exp $subExpr "{[my get $key $field]}"]
            }; # end foreach fieldmap pair
            if {$valid} {
                # Only add data if all required fields exist.
                lappend values [uplevel 1 [list expr $subExpr]]
            } else {
                lappend values $filler
            }; # end if valid
        }; # end foreach key
        
        # Return values created by field expression
        return $values
    }

    # $tblObj query --
    #
    # Get keys that match a specific criteria from field expression
    #
    # Arguments:
    # expr:         Field expression that results in a boolean value

    method query {expr} {
        return [lmap bool [uplevel 1 [list [self] expr $expr]] key $keys {
            if {$bool} {
                set key
            } else {
                continue
            }
        }]
    }

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

    # Table manipulation
    ########################################################################

    # $tblObj define --
    # 
    # Define keys/fields. Filters table and adds any new keys/fields.
    # 
    # Syntax:
    # $tblObj define keyname $keyname
    # $tblObj define keys $keys
    # $tblObj define fields $fields
    # 
    # Arguments:
    # keyname           Keyname (field for keys)
    # keys/fields:      List of keys/fields for table. Must be unique.

    method define {type value} {
        switch $type {
            keyname { #tblObj define keyname $keyname
                if {[my exists field $value]} {
                    return -code error "cannot set keyname, found in fields"
                }
                set keyname $value
            }
            keys { # $tblObj define keys $keys
                # Check uniqueness
                if {![my IsUniqueList $value]} {
                    return -code error "keys must be unique"
                }
                # Redefine keys
                set keys ""
                set keymap ""
                my add keys {*}$value
                # Filter data
                dict for {key rowmap} $datamap {
                    if {![my exists key $key]} {
                        dict unset datamap $key
                    }
                }
            }
            fields { # $tblObj define fields $fields
                # Check uniqueness
                if {![my IsUniqueList $value]} {
                    return -code error "fields must be unique"
                }
                # Redefine fields
                set fields ""
                set fieldmap ""
                my add fields {*}$value
                # Filter data
                dict for {key rowmap} $datamap {
                    dict for {field value} $rowmap {
                        if {![my exists field $field]} {
                            dict unset datamap $key $field
                        }
                    }
                }
            }
            default {
                return -code error "unknown option \"$type\": \
                        want \"keys\" or \"fields\""
            }
        }; # end switch
        # Return self
        return [self]
    }

    # $tblObj add --
    #
    # Add keys/fields to the table, appending to end, in "dict set" fashion.
    # Blank keys/fields are not allowed.
    # Field must not conflict with keyname
    # Duplicates may be entered with no penalty.
    #
    # Syntax:
    # $tblObj add keys $key ...
    # $tblObj add fields $field ...
    # 
    # Arguments:
    # key ...       Keys to add
    # field ...     Fields to add

    method add {option args} {
        switch $option {
            keys { # $tblObj add keys $key ...
                foreach key $args {
                    # Ensure that input is valid
                    if {$key eq ""} {
                        return -code error "key cannot be blank"
                    }
                    # Check if key is new
                    if {![dict exists $keymap $key]} {
                        dict set keymap $key [my height]
                        lappend keys $key
                    }
                    # Ensure that data entries exist
                    if {![dict exists $datamap $key]} {
                        dict set datamap $key ""
                    }
                }
            }
            fields { # $tblObj add fields $field ...
                foreach field $args {
                    if {$field eq $keyname} {
                        return -code error "field cannot be keyname"
                    }
                    if {$field eq ""} {
                        return -code error "field cannot be blank"
                    }
                    # Check if field is new
                    if {![dict exists $fieldmap $field]} {
                        dict set fieldmap $field [my width]
                        lappend fields $field
                    }
                }
            }
            default {
                return -code error "unknown option \"$option\".\
                        want \"keys\" or \"fields\""
            }
        } 
        # Return object name
        return [self]
    }

    # $tblObj remove --
    #
    # Remove keys/fields if they exist. Handles duplicates just fine.
    #
    # Syntax:
    # $tblObj remove keys $key ...
    # $tblObj remove fields $field ...
    #
    # Arguments:
    # key ...       Keys to remove
    # field ...     Fields to remove

    method remove {type args} {
        switch $type {
            keys {
                # Get keys to remove in order of index
                set imap ""
                foreach key $args {
                    if {![my exists key $key]} {
                        continue
                    }
                    dict set imap $key [my find key $key]
                }
                # Switch for number of keys to remove
                if {[dict size $imap] == 0} {
                    return
                } elseif {[dict size $imap] > 1} {
                    set imap [lsort -integer -stride 2 -index 1 $imap]
                }

                # Remove from keys and data (k-trick for performance)
                set count 0; # Count of removed values
                dict for {key i} $imap {
                    incr i -$count; # Adjust for removed elements
                    set keys [lreplace $keys[set keys ""] $i $i]
                    dict unset keymap $key
                    dict unset datamap $key
                    incr count
                }
                
                # Update keymap
                set i [lindex $imap 1]; # minimum removed i
                foreach key [lrange $keys $i end] {
                    dict set keymap $key $i
                    incr i
                }
            }
            fields {
                # Get fields to remove in order of index
                set jmap ""
                foreach field $args {
                    if {![my exists field $field]} {
                        continue
                    }
                    dict set jmap $field [my find field $field]
                }
                
                # Switch for number of keys to remove
                if {[dict size $jmap] == 0} {
                    return
                } elseif {[dict size $jmap] > 1} {
                    set jmap [lsort -integer -stride 2 -index 1 $jmap]
                }   
                
                # Remove from fields and data (k-trick for performance)
                set count 0; # Count of removed values
                dict for {field j} $jmap {
                    incr j -$count; # Adjust for removed elements
                    set fields [lreplace $fields[set fields ""] $j $j]
                    dict unset fieldmap $field
                    dict for {key rowmap} $datamap {
                        dict unset datamap $key $field
                    }
                    incr count
                }
                
                # Update fieldmap
                set j [lindex $jmap 1]; # minimum removed j
                foreach field [lrange $fields $j end] {
                    dict set fieldmap $field $j
                    incr j
                }
            }
            default {
                return -code error "unknown option \"$option\".\
                        want \"keys\" or \"fields\""
            }
        }
        return
    }

    # $tblObj insert --
    # 
    # Insert keys/fields (must be unique, and no duplicates)
    #
    # Syntax:
    # $tblObj insert keys $index $key ...
    # $tblObj insert fields $index $field ...
    #
    # Arguments:
    # index:        Row or column ID to insert at
    # key ...       Keys to insert
    # field ...     Fields to insert

    method insert {type index args} {
        switch $type {
            keys {
                # Ensure input keys are unique and new
                if {![my IsUniqueList $args]} {
                    return -code error "cannot have duplicate key inputs"
                }
                foreach key $args {
                    if {[my exists key $key]} {
                        return -code error "key \"$key\" already exists"
                    }
                }
                # Convert index input to integer
                set i [::ndlist::Index2Integer [my height] $index]
                # Insert keys (using k-trick for performance)
                set keys [linsert $keys[set keys ""] $i {*}$args]
                # Update indices in key map
                foreach key [lrange $keys $i end] {
                    dict set keymap $key $i
                    incr i
                }
                # Ensure that entries in data exist
                foreach key $args {
                    if {![dict exists $datamap $key]} {
                        dict set datamap $key ""
                    }
                }
            }
            fields {
                # Ensure input fields are unique and new
                if {![my IsUniqueList $args]} {
                    return -code error "cannot have duplicate field inputs"
                }
                foreach field $args {
                    if {[my exists field $field]} {
                        return -code error "field \"$field\" already exists"
                    }
                }
                # Convert index input to integer
                set j [::ndlist::Index2Integer [my width] $index]
                # Insert fields (using k-trick for performance)
                set fields [linsert $fields[set fields ""] $j {*}$args]
                # Update indices in field map
                foreach field [lrange $fields $j end] {
                    dict set fieldmap $field $j
                    incr j
                }
            }
            default {
                return -code error "unknown option \"$option\".\
                        want \"keys\" or \"fields\""
            }
        }
        return
    }
      
    # $tblObj rename --
    #
    # Rename keys or fields in table
    #
    # Syntax:
    # $tblObj rename keys <$old> $new
    # $tblObj rename fields <$old> $new
    #
    # Arguments:
    # old:          List of old keys/fields. Default existing keys/fields
    # new:          List of new keys/fields

    method rename {type args} {
        # Check type
        if {$type ni {keys fields}} {
            return -code error "unknown option \"$option\".\
                        want \"keys\" or \"fields\""
        }
        # Switch for arity
        if {[llength $args] == 1} {
            switch $type {
                keys {set old $keys}
                fields {set old $fields}
            }
            set new [lindex $args 0]
            if {![my IsUniqueList $new]} {
                return -code error "new $type must be unique"
            }
        } elseif {[llength $args] == 2} {
            lassign $args old new
            if {![my IsUniqueList $old] || ![my IsUniqueList $new]} {
                return -code error "old and new $type must be unique"
            }
        } else {
            return -code error "wrong # args: want \"[self] $type ?old? new\""
        }
        # Check lengths
        if {[llength $old] != [llength $new]} {
            return -code error "old and new $type must match in length"
        }
        switch $type {
            keys {
                # Get old rows (checks for error)
                set rows [lmap key $old {my rget $key}]
                
                # Update key list and map (requires two loops, incase of 
                # intersection between old and new lists)
                set iList ""
                foreach oldKey $old newKey $new {
                    set i [my find key $oldKey]
                    lappend iList $i
                    lset keys $i $newKey
                    dict unset keymap $oldKey
                    dict unset datamap $oldKey
                }
                foreach newKey $new i $iList row $rows {
                    dict set keymap $newKey $i; # update in-place
                    my rset $newKey $row; # Re-add row
                }
            }
            fields {
                # Get old columns (checks for error)
                set columns [lmap field $old {my cget $field}]
                
                # Update field list and map (requires two loops, incase of 
                # intersection between old and new lists)
                set jList ""
                foreach oldField $old newField $new {
                    set j [my find field $oldField]
                    lappend jList $j
                    lset fields $j $newField
                    dict unset fieldmap $oldField
                    dict for {key rowmap} $datamap {
                        dict unset datamap $key $oldField
                    }
                }
                foreach newField $new j $jList column $columns {
                    dict set fieldmap $newField $j; # update in-place
                    my cset $newField $column; # Re-add column
                }
            }
        }
        # Return object name
        return [self]
    }     

    # $tblObj mkkey --
    # 
    # Make a field the key. Data loss may occur.
    #
    # Syntax:
    # $tblObj mkkey $field
    # 
    # Arguments:
    # field:            Field to swap with key.

    method mkkey {field} {
        # Check validity of transfer
        if {[my exists field $keyname]} {
            return -code error "keyname conflict with fields"
        }
        if {![my exists field $field]} {
            return -code error "field \"$field\" not found in table"
        }
        # Make changes to a table copy
        my --> tblCopy
        $tblCopy remove fields $field; # Remove field (also removes data)
        $tblCopy define keyname $field; # Redefine keyname
        $tblCopy rename keys [my cget $field]; # Rename keys
        $tblCopy cset $keyname $keys; # Add field for original keys
        # Redefine current table
        my = [$tblCopy]
        # Return object name
        return [self]
    }

    # $tblObj move --
    #
    # Move row or column. Calls "MoveRow" and "MoveColumn"
    #
    # Syntax:
    # $tblObj move key $key $index
    # $tblObj move field $field $index
    #
    # Arguments:
    # key       Key of row to move
    # field     Field of column to move
    # index     Row or column ID to move to.

    method move {type args} {
        switch $type {
            key {
                my MoveRow {*}$args
            }
            field {
                my MoveColumn {*}$args
            }
            default {
                return -code error "unknown option \"$type\": \
                        should be \"key\" or \"field\"."
            }
        }
        # Return object name
        return [self]
    }

    # my MoveRow --
    #
    # Move row to a specific row index
    #
    # Syntax:
    # my MoveRow $key $i
    # 
    # Arguments:
    # key:      Key to move
    # i:        Row index to move to.

    method MoveRow {key i} {
        # Get initial and final row indices
        set i1 [my find key $key]
        set i2 [::ndlist::Index2Integer [my height] $i]
        # Switch for move type
        if {$i1 < $i2} {
            # Target index is beyond source
            set keys [concat [lrange $keys 0 $i1-1] \
                    [lrange $keys $i1+1 $i2] [list $key] \
                    [lrange $keys $i2+1 end]]
            set i $i1
        } elseif {$i1 > $i2} {
            # Target index is below source
            set keys [concat [lrange $keys 0 $i2-1] [list $key] \
                    [lrange $keys $i2 $i1-1] [lrange $keys $i1+1 end]]
            set i $i2
        } else {
            # Trivial case
            return
        }
        # Update keymap
        foreach key [lrange $keys $i end] {
            dict set keymap $key $i
            incr i
        }
    }

    # my MoveColumn --
    #
    # Move column to a specific column index
    #
    # Syntax:
    # my MoveColumn $field $j
    # 
    # Arguments:
    # field:    Field to move
    # j:        Column index to move to.

    method MoveColumn {field j} {
        # Get source index, checking validity of field
        set j1 [my find field $field]
        set j2 [::ndlist::Index2Integer [my width] $j]
        # Switch for move type
        if {$j1 < $j2} {
            # Target index is beyond source
            set fields [concat [lrange $fields 0 $j1-1] \
                    [lrange $fields $j1+1 $j2] [list $field] \
                    [lrange $fields $j2+1 end]]
            set j $j1
        } elseif {$j1 > $j2} {
            # Target index is below source
            set fields [concat [lrange $fields 0 $j2-1] [list $field] \
                    [lrange $fields $j2 $j1-1] [lrange $fields $j1+1 end]]
            set j $j2
        } else {
            # Trivial case
            return
        }
        # Update fieldmap
        foreach field [lrange $fields $j end] {
            dict set fieldmap $field $j
            incr j
        }
    }

    # $tblObj swap --
    #
    # Swap rows/columns. Calls "SwapRows" and "SwapColumns"
    #
    # Syntax:
    # $tblObj swap keys $key1 $key2 
    # $tblObj swap fields $field1 $field2 
    #
    # Arguments:
    # key1 key2:        Keys to swap
    # field1 field2:    Fields to swap

    method swap {type args} {
        switch $type {
            keys {
                my SwapRows {*}$args
            }
            fields {
                my SwapColumns {*}$args
            }
            default {
                return -code error "unknown option \"$type\": \
                        should be \"keys\" or \"fields\"."
            }
        }
        # Return object name
        return [self]
    }

    # my SwapRows --
    #
    # Swap rows
    #
    # Syntax:
    # my SwapRows $key1 $key2
    #
    # Arguments:
    # key1:         Key to swap with key2
    # key2:         Key to swap with key1

    method SwapRows {key1 key2} {
        # Check existence of keys
        foreach key [list $key1 $key2] {
            if {![dict exists $keymap $key]} {
                return -code error "key \"$key\" not found in table"
            }
        }
        # Get row IDs
        set i1 [dict get $keymap $key1]
        set i2 [dict get $keymap $key2]
        # Update key list and map
        lset keys $i2 $key1
        lset keys $i1 $key2
        dict set keymap $key1 $i2
        dict set keymap $key2 $i1
        # Return object name
        return [self]
    }

    # my SwapColumns --
    #
    # Swap columns
    #
    # Syntax:
    # my SwapColumns $field1 $field2
    #
    # Arguments:
    # field1:       Field to swap with field2
    # field2:       Field to swap with field1

    method SwapColumns {field1 field2} {
        # Check existence of fields
        foreach field [list $field1 $field2] {
            if {![dict exists $fieldmap $field]} {
                return -code error "field \"$field\" not found in table"
            }
        }
        # Get column IDs
        set j1 [dict get $fieldmap $field1]
        set j2 [dict get $fieldmap $field2]
        # Update field list and map
        lset fields $j2 $field1
        lset fields $j1 $field2
        dict set fieldmap $field1 $j2
        dict set fieldmap $field2 $j1
        # Return object name
        return [self]
    }

    # $tblObj clean --
    #
    # Clear keys and fields that don't exist in data

    method clean {} {
        # Remove blank keys
        my remove keys {*}[lmap key $keys {
            if {[dict size [dict get $datamap $key]]} {
                continue
            }
            set key
        }]
        # Remove blank fields
        my remove fields {*}[lmap field $fields {
            set isBlank 1
            dict for {key rowmap} $datamap {
                if {[dict exists $rowmap $field]} {
                    set isBlank 0
                    break
                }
            }
            if {!$isBlank} {
                continue
            }
            set field
        }]
        # Return object name
        return [self]
    }
}; # end class definition


