# Define the to_bits procedure
proc to_bits {a} {
    # Check if the input value is within the valid range 0-15
    if {($a < 0) || ($a > 15)} {
        puts "Warning: Input value $a is outside the valid range of 0-15"
        return
    }
    
    # Extract individual bits
    set b0 [expr {$a & 1}]
    set b1 [expr {($a >> 1) & 1}]
    set b2 [expr {($a >> 2) & 1}]
    set b3 [expr {($a >> 3) & 1}]
    
    # Concatenate bits to form the binary representation
    set b "$b3$b2$b1$b0"
    
    # Print the result in binary format
    puts "${b}b"
}

# Example usage
#to_bits 9
