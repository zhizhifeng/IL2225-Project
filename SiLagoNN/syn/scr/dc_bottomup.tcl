################################################################################
# Design Compiler bottom-up logic synthesis script
################################################################################
#
# This script is meant to be executed with the following directory structure
#
# project_top_folder
# |
# |- db: store output data like mapped designs or physical files like GDSII
# |
# |- phy: physical synthesis material (scripts, pins, etc)
# |
# |- rtl: contains rtl code for the design, it should also contain a
# |       hierarchy.txt file with the all the files that compose the design
# |
# |- syn: logic synthesis material (this script, SDC constraints, etc)
# |
# |- sim: simulation stuff like waveforms, reports, coverage etc.
# |
# |- tb: testbenches for the rtl code
# |
# |- exe: the directory where it should be executed. This keeps all the temp files
#         created by DC in that directory
#
#
# The standard way of executing the is from the project_top_folder
# with the following command
#
# $ dc_shell -f ../syn/dc_flat.tcl
################################################################################

#1. source setup file to extract global libraries
source ../syn/synopsys_dc.setup
#2. set the TOP_NAME of the design
set TOP_NAME silego

# Directories for output material
set REPORT_DIR  ../syn/rpt/task3;      # synthesis reports: timing, area, etc.
set OUT_DIR ../syn/db/task3;           # output files: netlist, sdf sdc etc.
set SOURCE_DIR ../rtl;           # rtl code that should be synthesised
set SYN_DIR ../syn;              # synthesis directory, synthesis scripts constraints etc.

#define the process
proc nth_pass {n} {
    #3. import the global variables for the process
    global SOURCE_DIR SYN_DIR OUT_DIR TOP_NAME REPORT_DIR

    set prev_n [expr {$n - 1}]
    exec rm -rf ${OUT_DIR}/pass${n}
    exec mkdir -p ${OUT_DIR}/pass${n}
    remove_design -all
    
    #4. Anayze the files in ${SOURCE_DIR}/pkg_hierarchy.txt. These files only contain variable definitions so you don't need to elaborate them
    set hierarchy_files [split [read [open ${SOURCE_DIR}/pkg_hierarchy.txt r]] "\n"]
    foreach filename [lrange ${hierarchy_files} 0 end-1] {
        analyze -format vhdl -lib WORK "${SOURCE_DIR}/${filename}"
    }
    
    #Next we will compile divider_pipe first, ${SOURCE_DIR}/mtrf/DPU/divider_pipe.vhd. As the divider is a big structure We would like to import constraints in the next pass over divider pipe
    #5. analyze divider_pipe
    analyze -format vhdl -lib WORK "${SOURCE_DIR}/mtrf/DPU/divider_pipe.vhd"
    #6. elaborate divider_pipe
    elaborate divider_pipe
    #7. set the current design to divider_pipe
    current_design divider_pipe
    #8. link
    link
    #9. uniquify
    uniquify
    #10 source the top constraints file
    source ${SYN_DIR}/constraints.sdc
    if  {$n > 1} {
        #11. source constraints of divider pipe from previous pass
        source ${OUT_DIR}/pass${prev_n}/divider_pipe.wscr
    }
    #11. compile
    compile
    # compile -map_effort high -incremental
    
    # We will compile the "silego" entity, which is identical for all the tiles. We will also import its constraints for the next pass.
    #12. analyze silego, use silego_hierarchy.
    set hierarchy_files [split [read [open ${SOURCE_DIR}/silego_hierarchy.txt r]] "\n"]
    foreach filename [lrange ${hierarchy_files} 0 end-1] {
        analyze -format vhdl -lib WORK "${SOURCE_DIR}/${filename}"
    }
    #13. elaborate silego
    elaborate silego
    #14. set the current design to silego
    current_design silego
    #15. link
    link
    #16. uniquify
    uniquify
    #17. source the top constraints file
    source ${SYN_DIR}/constraints.sdc
    if {$n > 1} {
        #18. source the silego constraints file from the previous pass
        source ${OUT_DIR}/pass${prev_n}/silego.wscr
    }
    #19. set dont touch attribute for divider_pipe
    dont_touch divider_pipe true
    #20. compile
    compile
    # compile -map_effort high -incremental

    #21. analyze Silago_top
    analyze -format vhdl -lib WORK "${SOURCE_DIR}/mtrf/Silago_top.vhd"
    #22. elaborate Silago_top
    elaborate Silago_top
    #23. set current design to Silago_top
    current_design Silago_top
    #24. link
    link
    #25. uniquify
    uniquify
    #26. source the top constraints
    source ${SYN_DIR}/constraints.sdc
    #27. set dont touch for silego and divider pipe
    dont_touch silego true
    dont_touch divider_pipe true
    #28. compile
    compile
    # compile -map_effort high -incremental

    # Repeat 21. to 28. for the remaining unique tile designs: Silago_bot, Silago_top_left_corner, Silago_top_right_corner, Silago_bot_left_corner, Silago_bot_right_corner
    foreach tile {Silago_bot Silago_top_left_corner Silago_top_right_corner Silago_bot_left_corner Silago_bot_right_corner} {
        #21. analyze $tile
        analyze -format vhdl -lib WORK "${SOURCE_DIR}/mtrf/${tile}.vhd"
        #22. elaborate $tile
        elaborate $tile
        #23. set current design to $tile
        current_design $tile
        #24. link
        link
        #25. uniquify
        uniquify
        #26. source the top constraints
        source ${SYN_DIR}/constraints.sdc
        #27. set dont touch for silego and divider pipe
        dont_touch silego true
        dont_touch divider_pipe true
        #28. compile
        compile
        # compile -map_effort high -incremental
    }
    
    #29. analyze drra_wrapper
    analyze -format vhdl -lib WORK "${SOURCE_DIR}/mtrf/drra_wrapper.vhd"
    #30. elaborate drra_wrapper
    elaborate drra_wrapper
    #31. set current design to drra_wrapper
    current_design drra_wrapper

    link

    #32. set dont touch for divider pipe and ALL tiles
    dont_touch divider_pipe true
    foreach tile {Silago_bot Silago_top_left_corner Silago_top_right_corner Silago_bot_left_corner Silago_bot_right_corner} {
        dont_touch $tile true
    }
    #33. source constraints
    source ${SYN_DIR}/constraints.sdc
    #34. report timing of drra wrapper in the current pass
    report_timing
    #35. write_ddc from the current pass
    write_file -format ddc -output ${OUT_DIR}/pass${n}/drra_wrapper.ddc

    #36. characterize constraints of silego and divider_pipe
    characterize -constraint {Silago_top_inst_1_0/SILEGO_cell \
    Silago_top_inst_1_0/SILEGO_cell/MTRF_cell/dpu_gen/U_NACU_0/U_divider}

    current_design silego
    write_script > ${OUT_DIR}/pass${n}/silego.wscr
    current_design divider_pipe
    write_script > ${OUT_DIR}/pass${n}/divider_pipe.wscr
}

#EXECUTE N PASSES OF THE ABOVE FUNCTION. DECIDE ON A REASONABLE N.
for {set i 1} {$i <= 2} {incr i} {
    nth_pass $i
}

#37. Set current design to drra_wrapper 
current_design drra_wrapper
#38. Report the final timing, power, area.
report_area > ${REPORT_DIR}/${TOP_NAME}_area.txt
report_timing > ${REPORT_DIR}/${TOP_NAME}_timing.txt
report_power > ${REPORT_DIR}/${TOP_NAME}_power.txt
report_cell > ${REPORT_DIR}/${TOP_NAME}_cell.txt

#39. Write the netlist, ddc, sdc and sdf.
write_file -hierarchy -format ddc -output ${OUT_DIR}/${TOP_NAME}.ddc
write_file -hierarchy -format verilog -output ${OUT_DIR}/${TOP_NAME}.v
write_sdf ${OUT_DIR}/${TOP_NAME}.sdf
