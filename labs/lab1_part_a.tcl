set a 9

set b0 [expr {$a & 1}]
set b1 [expr {($a >> 1) & 1}]
set b2 [expr {($a >> 2) & 1}]
set b3 [expr {($a >> 3) & 1}]

set b "$b3$b2$b1$b0"

#set a 9 assigns the value 9 to the variable a.
#set b0 [expr {$a & 1}] extracts the least significant bit by performing a bitwise AND operation with 1.
#set b1 [expr {($a >> 1) & 1}] shifts the bits of a one position to the right and then performs a bitwise AND operation with 1 to extract the second least significant bit.
#set b2 [expr {($a >> 2) & 1}] shifts the bits of a two positions to the right and then performs a bitwise AND operation with 1 to extract the third least significant bit.
#set b3 [expr {($a >> 3) & 1}] shifts the bits of a three positions to the right and then performs a bitwise AND operation with 1 to extract the fourth least significant bit.
#set b "$b3$b2$b1$b0" concatenates the extracted bits in the correct order to form the binary representation of the number.
