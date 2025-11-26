# scripts/impl.tcl (timing-focused version for Vivado 2021.1 / 7-series)

source ../target.tcl

# Start from synthesized checkpoint
open_checkpoint ${ABS_TOP}/build/synth/${TOP}.dcp

# Read constraints (clocks, I/O, etc.)
if {[string trim ${CONSTRAINTS}] ne ""} {
  read_xdc ${CONSTRAINTS}
}

#------------------------------------------------------------
# 1) Logical optimization – bias toward timing
#------------------------------------------------------------
# ExploreWithRemap does more aggressive restructuring and remapping
# to reduce logic depth, at the cost of area/runtime.
opt_design -directive ExploreWithRemap

#------------------------------------------------------------
# 2) Placement – higher effort for timing QoR
#------------------------------------------------------------
place_design -directive ExtraTimingOpt

# Save placed checkpoint & basic reports
write_checkpoint -force ${TOP}_placed.dcp
report_utilization          -file post_place_utilization.rpt
report_timing_summary -warn_on_violation -file post_place_timing_summary.rpt

#------------------------------------------------------------
# 3) Post-place physical optimization – fix long nets, fanout
#------------------------------------------------------------
phys_opt_design -directive AggressiveExplore

#------------------------------------------------------------
# 4) Routing – timing-driven, higher effort
#------------------------------------------------------------
route_design -directive Explore

#------------------------------------------------------------
# 5) Optional post-route phys_opt to squeeze extra slack
#    (no -post_route switch in 2021.1; just call it again)
#------------------------------------------------------------
phys_opt_design -directive AggressiveExplore

#------------------------------------------------------------
# 6) Final checkpoint, reports, and bitstream
#------------------------------------------------------------
write_checkpoint -force ${TOP}_routed.dcp
write_verilog    -force post_route.v
write_xdc        -force post_route.xdc
report_drc       -file post_route_drc.rpt
report_timing_summary -warn_on_violation -file post_route_timing_summary.rpt

write_bitstream -force ${TOP}.bit
