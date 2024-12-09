BASE_DIR="/home/yurunc/Documents/IL2225_project/SiLagoNN"

source ../phy/scr/global_variables_hrchy.tcl
source ../phy/scr/design_variables.tcl

cd $BASE_DIR/task6
innovus -stylus -no_gui -batch -files ../phy/scr/create_partitions.tcl -log "../log/create_partitions_${TIMESTAMP}.log ../log/create_partitions_${TIMESTAMP}.cmd ../log/create_partitions_${TIMESTAMP}.logv"

# run pnr_partition.sh
$BASE_DIR/phy/scr/pnr_partition.sh

#run pnr_top.tcl
cd $BASE_DIR/task6
innovus -stylus -no_gui -batch -files ../phy/scr/pnr_top.tcl -log "../log/pnr_top_${TIMESTAMP}.log ../log/pnr_top_${TIMESTAMP}.cmd ../log/pnr_top_${TIMESTAMP}.logv"

#run assemble_design.tcl
cd $BASE_DIR/task6
innovus -stylus -no_gui -batch -files ../phy/scr/assemble_design.tcl -log "../log/assemble_design_${TIMESTAMP}.log ../log/assemble_design_${TIMESTAMP}.cmd ../log/assemble_design_${TIMESTAMP}.logv"