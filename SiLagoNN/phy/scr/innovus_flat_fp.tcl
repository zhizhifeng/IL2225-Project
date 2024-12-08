#1. source global variables
source ../phy/scr/global_variables.tcl
#2. source read_design
source ../phy/scr/read_design.tcl

source ../phy/scr/design_variables.tcl

source ../phy/scr/floorplan.tcl

source ../phy/scr/powerplan.tcl

#3. place
place_design
#4. clock
ccopt_design
#5. route
assign_io_pins
route_design
#6. write design
write_db ../phy/db/task5/${TOP_NAME}.dat
#7. write_netlist
write_netlist ../phy/db/task5/${TOP_NAME}.v
