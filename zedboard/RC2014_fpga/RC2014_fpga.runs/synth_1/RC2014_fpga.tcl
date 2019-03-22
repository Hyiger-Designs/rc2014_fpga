# 
# Synthesis run script generated by Vivado
# 

set TIME_start [clock seconds] 
proc create_report { reportName command } {
  set status "."
  append status $reportName ".fail"
  if { [file exists $status] } {
    eval file delete [glob $status]
  }
  send_msg_id runtcl-4 info "Executing : $command"
  set retval [eval catch { $command } msg]
  if { $retval != 0 } {
    set fp [open $status w]
    close $fp
    send_msg_id runtcl-5 warning "$msg"
  }
}
create_project -in_memory -part xc7z020clg484-1

set_param project.singleFileAddWarning.threshold 0
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_msg_config -source 4 -id {IP_Flow 19-2162} -severity warning -new_severity info
set_property webtalk.parent_dir C:/Users/richa/gitrepo/RC2014_fpga/zedboard/RC2014_fpga/RC2014_fpga.cache/wt [current_project]
set_property parent.project_path C:/Users/richa/gitrepo/RC2014_fpga/zedboard/RC2014_fpga/RC2014_fpga.xpr [current_project]
set_property XPM_LIBRARIES XPM_MEMORY [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language VHDL [current_project]
set_property board_part em.avnet.com:zed:part0:1.4 [current_project]
set_property ip_output_repo c:/Users/richa/gitrepo/RC2014_fpga/zedboard/RC2014_fpga/RC2014_fpga.cache/ip [current_project]
set_property ip_cache_permissions {read write} [current_project]
add_files c:/Users/richa/gitrepo/RC2014_fpga/roms/CPM_BASIC.coe
add_files c:/Users/richa/gitrepo/RC2014_fpga/roms/SCMonitor-v100-S3-SCS3-32k-ROM.coe
add_files c:/Users/richa/gitrepo/RC2014_fpga/roms/R0001009.coe
read_vhdl -library xil_defaultlib {
  C:/Users/richa/gitrepo/RC2014_fpga/rtl/frac20.vhd
  C:/Users/richa/gitrepo/RC2014_fpga/rtl/T80/T80_Pack.vhd
  C:/Users/richa/gitrepo/RC2014_fpga/rtl/T80/T80s.vhd
  C:/Users/richa/gitrepo/RC2014_fpga/rtl/single_port_ram.vhd
  C:/Users/richa/gitrepo/RC2014_fpga/rtl/decoder_3x8.vhd
  C:/Users/richa/gitrepo/RC2014_fpga/rtl/ROM_Page_Select.vhd
  C:/Users/richa/gitrepo/RC2014_fpga/rtl/acia6850.vhd
  C:/Users/richa/gitrepo/RC2014_fpga/rtl/T80/T80.vhd
  C:/Users/richa/gitrepo/RC2014_fpga/rtl/T80/T80_ALU.vhd
  C:/Users/richa/gitrepo/RC2014_fpga/rtl/T80/T80_MCode.vhd
  C:/Users/richa/gitrepo/RC2014_fpga/rtl/T80/T80_Reg.vhd
  C:/Users/richa/gitrepo/RC2014_fpga/rtl/RC2014_fpga.vhd
}
read_ip -quiet c:/Users/richa/gitrepo/RC2014_fpga/zedboard/RC2014_fpga/RC2014_fpga.srcs/sources_1/ip/CPM_BASIC/CPM_BASIC.xci
set_property used_in_implementation false [get_files -all c:/Users/richa/gitrepo/RC2014_fpga/zedboard/RC2014_fpga/RC2014_fpga.srcs/sources_1/ip/CPM_BASIC/CPM_BASIC_ooc.xdc]

read_ip -quiet c:/Users/richa/gitrepo/RC2014_fpga/zedboard/RC2014_fpga/RC2014_fpga.srcs/sources_1/ip/SCM_V100_S3_SCS3_32K/SCM_V100_S3_SCS3_32K.xci
set_property used_in_implementation false [get_files -all c:/Users/richa/gitrepo/RC2014_fpga/zedboard/RC2014_fpga/RC2014_fpga.srcs/sources_1/ip/SCM_V100_S3_SCS3_32K/SCM_V100_S3_SCS3_32K_ooc.xdc]

read_ip -quiet c:/Users/richa/gitrepo/RC2014_fpga/zedboard/RC2014_fpga/RC2014_fpga.srcs/sources_1/ip/R0001009/R0001009.xci
set_property used_in_implementation false [get_files -all c:/Users/richa/gitrepo/RC2014_fpga/zedboard/RC2014_fpga/RC2014_fpga.srcs/sources_1/ip/R0001009/R0001009_ooc.xdc]

# Mark all dcp files as not used in implementation to prevent them from being
# stitched into the results of this synthesis run. Any black boxes in the
# design are intentionally left as such for best results. Dcp files will be
# stitched into the design at a later time, either when this synthesis run is
# opened, or when it is stitched into a dependent implementation run.
foreach dcp [get_files -quiet -all -filter file_type=="Design\ Checkpoint"] {
  set_property used_in_implementation false $dcp
}
read_xdc C:/Users/richa/gitrepo/RC2014_fpga/zedboard/RC2014_fpga/RC2014_fpga.srcs/constrs_1/new/RC2014_fpga.xdc
set_property used_in_implementation false [get_files C:/Users/richa/gitrepo/RC2014_fpga/zedboard/RC2014_fpga/RC2014_fpga.srcs/constrs_1/new/RC2014_fpga.xdc]

read_xdc dont_touch.xdc
set_property used_in_implementation false [get_files dont_touch.xdc]
set_param ips.enableIPCacheLiteLoad 1
close [open __synthesis_is_running__ w]

synth_design -top RC2014_fpga -part xc7z020clg484-1


# disable binary constraint mode for synth run checkpoints
set_param constraints.enableBinaryConstraints false
write_checkpoint -force -noxdef RC2014_fpga.dcp
create_report "synth_1_synth_report_utilization_0" "report_utilization -file RC2014_fpga_utilization_synth.rpt -pb RC2014_fpga_utilization_synth.pb"
file delete __synthesis_is_running__
close [open __synthesis_is_complete__ w]
