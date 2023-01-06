# The-Power-of-TCL
This article explains the basics of using the Timing Tcl Scripting Commands. 
These commands can be used in combination with each other to report and query database objects based on specified criteria.

|Report               |                                                                                    |
|-----------------    |------------------------------------------------------------------------------------|
|1. FP_report.tcl     | Script to report the endpoint, the startpoint and slack of top 1000 failing paths  |
|2. RSC_report.tcl    |To get a list of the register sinks for a clock                                     |
|3. instance_pin.tcl  | To return all the instance pins that are used in the path                          |
|4. slack.tcl         | Script to report slack and difference between clock arrival time at launch and capture clocks|  
|5. reg_reg_logic.tcl | Script to report logics between reg-to-reg. This script can be modified for different path groups|
|6. Fanin_out.tcl     | Script to get the intermediate logic between fanout cone of one instance to fanin cone of another instance|
|7. worst_slack.tcl   | Script to report worst slack for all clock group|
|8. comb_level.tcl    | Script to find the number of logic levels (combinational) in a timing path or group of timing paths|
|9. cell_delay.tcl    |cript to report cell delays above/below a specified value|
|10. pin.tcl          |Script to get the specified pin from all the nets directly connected to an instance |
