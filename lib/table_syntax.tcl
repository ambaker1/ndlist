table new $varName <$value>

# Old methods
$table rename
$table merge
$table sort
$table @
$table exists
$table mkkey
$table find
$table height
$table cget
$table with
$table set
$table insert
$table remove
$table rset
$table expr
$table get
$table values
$table width
$table add
$table mset
$table rget
$table keyname
$table clean
$table swap
$table define
$table keys
$table dict
$table mget
$table wipe
$table search
$table query
$table move
$table cset
$table clear
$table fields

# New syntax

# I want to have a lot less methods for the table class. It should be dead simple.
# It is a dictionary, so I can just leave the rest to manipulating dictionaries.
dict get [$table] $field

$table rename $field $newField
$table sort
$table @ $field <= $column | := $expr>
$table exists $field
$table height
$table cget $field
$table with $body
$table set $i $field $value $field $value ...
$table remove $field ...
$table add $field ...
$table rset
$table expr
$table get $i $field
$table width
$table mset $indices $fields $values
$table rget $i
$table clean
$table define
$table keys
$table dict
$table mget
$table wipe
$table search
$table query
$table move
$table cset
$table clear
$table fields

# Basic modification
$table set $i $field $value ...; # can use end+1
$table get $i $field
$table rget $i
$table rset $i $row; # can use end+1
$table cget $field
$table cset $field $column
$table mget $indices $fields $values; # uses nget
$table mset $indices $fields $values; # uses nset
$table expr $expr; # column-wise operation
$table @ $field <= $values | := $expr>

texpr $table $expr



# Adding new data
$table rget 

# I am completely redoing the table data structure. Like, from scratch. 
# most of it is completely unusable now. I am changing how it is stored.
