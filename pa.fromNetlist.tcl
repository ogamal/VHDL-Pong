
# PlanAhead Launch Script for Post-Synthesis pin planning, created by Project Navigator

create_project -name retro_car -dir "/home/ogamal/nexys3/retro_car/planAhead_run_2" -part xc6slx16csg324-2
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "/home/ogamal/nexys3/retro_car/VgaTest.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {/home/ogamal/nexys3/retro_car} {ipcore_dir} }
add_files [list {ipcore_dir/block_ram.ncf}] -fileset [get_property constrset [current_run]]
set_param project.pinAheadLayout  yes
set_property target_constrs_file "VgaTest.ucf" [current_fileset -constrset]
add_files [list {VgaTest.ucf}] -fileset [get_property constrset [current_run]]
open_netlist_design
