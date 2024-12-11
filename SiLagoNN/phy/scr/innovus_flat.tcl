#1. source global variables
source ../phy/scr/global_variables.tcl
#2. source read_design
source ../phy/scr/read_design.tcl

# specify the floorplan
create_floorplan -core_margins_by die -site core -core_density_size 1 0.7 10 10 10 10

source ../phy/scr/powerplan.tcl

#3. place
place_design
#4. clock
ccopt_design
#5. route
assign_io_pins
route_design
#6. write design
write_db ../phy/db/task4/${TOP_NAME}.dat
#7. write_netlist
write_netlist ../phy/db/task4/${TOP_NAME}.v
