#Script to get the specified pin from all the nets directly connected to an instance 

#This gets all the nets connected a specified instance, and subsequently filter out if the specified pin is connected to any of these nets.  

set inst instName
set pin pinName
get_pins -of_objects [get_nets -of_objects $inst] -leaf -filter "(ref_lib_pin_name==$pin)"
