source ../target.tcl

# Start from synthesized checkpoint
open_checkpoint ${ABS_TOP}/build/synth/${TOP}.dcp

# Read constraints (clocks, I/O, etc.)
if {[string trim ${CONSTRAINTS}] ne ""} {
  read_xdc ${CONSTRAINTS}
}

opt_design -directive ExploreWithRemap

place_design -directive ExtraTimingOpt

write_checkpoint -force ${TOP}_placed.dcp
report_utilization          -file post_place_utilization.rpt
report_timing_summary -warn_on_violation -file post_place_timing_summary.rpt

phys_opt_design -directive AggressiveExplore

route_design -directive AggressiveExplore

phys_opt_design -directive AggressiveExplore
phys_opt_design -directive AggressiveFanoutOpt
route_design -directive AggressiveExplore

phys_opt_design -directive AggressiveExplore
route_design -directive NoTimingRelaxation

phys_opt_design -directive AggressiveExplore
phys_opt_design -directive AggressiveFanoutOpt
route_design -directive MoreGlobalIterations

phys_opt_design -critical_pin_opt -routing_opt
route_design -directive AggressiveExplore

write_checkpoint -force ${TOP}_routed_srl_critpin.dcp
report_timing_summary -warn_on_violation -file post_route_srl_critpin_timing_summary.rpt

write_checkpoint -force ${TOP}_routed.dcp
write_verilog    -force post_route.v
write_xdc        -force post_route.xdc
report_drc       -file post_route_drc.rpt
report_timing_summary -warn_on_violation -file post_route_timing_summary.rpt

write_bitstream -force ${TOP}.bit
