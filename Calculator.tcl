#Addition
proc addnumbers {a b} {
    return [expr $a+$b] 
    }

#Subtraction
proc subnumbers {a b} {
    return [expr $a-$b]
    }

#Multiplication
proc mulnumbers {a b} {
    return [expr $a*$b]  
    }

#Division
proc divnumbers {a b} {
    return [expr $a/$b]
    }

#Modulus
proc modnumbers {a b} {
  return [expr $a%$b]  
  } 

#Input-1
puts "Enter the first number"
gets stdin a

#Input-2
puts "Enter the second number"
gets stdin b

#called procedures
puts "The sum of two numbers is [addnumbers $a $b]"
puts "The difference between the two numbers is [subnumbers $a $b]"
puts "The product of the two numbers is [subnumbers $a $b]"
puts "The division of the two numbers is [divnumbers $a $b]"
puts "The modulo of the two numbers is [modnumbers $a $b]"
