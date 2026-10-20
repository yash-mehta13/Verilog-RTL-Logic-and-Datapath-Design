# Quartus Prime Lite 20.1 project creation TEMPLATE (not executed in this repository).
# Usage (after filling the variables from your board manual):
#   quartus_sh -t fpga/create_project.template.tcl
# Nothing below is a guess: DEVICE and pin assignments must come from your board documentation.
set PROJECT   half_adder_de10
set TOP       fpga_half_adder_top
set DEVICE    "<DEVICE_PART_NUMBER_FROM_BOARD_MANUAL>"

project_new $PROJECT -overwrite
set_global_assignment -name FAMILY   "<DEVICE_FAMILY_FROM_BOARD_MANUAL>"
set_global_assignment -name DEVICE   $DEVICE
set_global_assignment -name TOP_LEVEL_ENTITY $TOP
set_global_assignment -name VERILOG_FILE ../rtl/arithmetic/half_adder.v
set_global_assignment -name VERILOG_FILE ../rtl/fpga/fpga_half_adder_top.v
# Pin assignments: add one line per signal after filling fpga/pin_assignments.template.csv, e.g.
#   set_location_assignment <PIN_xx> -to sw[0]
project_close
