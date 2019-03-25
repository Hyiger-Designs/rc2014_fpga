transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/richa/gitrepo/RC2014_fpga/de10-lite/db {C:/Users/richa/gitrepo/RC2014_fpga/de10-lite/db/clocks_altpll.v}
vcom -93 -work work {C:/Users/richa/gitrepo/RC2014_fpga/rtl/decoder_3x8.vhd}
vcom -93 -work work {C:/Users/richa/gitrepo/RC2014_fpga/rtl/T80/T80_Reg.vhd}
vcom -93 -work work {C:/Users/richa/gitrepo/RC2014_fpga/rtl/T80/T80_Pack.vhd}
vcom -93 -work work {C:/Users/richa/gitrepo/RC2014_fpga/rtl/T80/T80_MCode.vhd}
vcom -93 -work work {C:/Users/richa/gitrepo/RC2014_fpga/rtl/T80/T80_ALU.vhd}
vcom -93 -work work {C:/Users/richa/gitrepo/RC2014_fpga/rtl/single_port_ram.vhd}
vcom -93 -work work {C:/Users/richa/gitrepo/RC2014_fpga/rtl/acia6850.vhd}
vcom -93 -work work {C:/Users/richa/gitrepo/RC2014_fpga/rtl/sd_controller.vhd}
vcom -93 -work work {C:/Users/richa/gitrepo/RC2014_fpga/de10-lite/CPM_BASIC_LITE.vhd}
vcom -93 -work work {C:/Users/richa/gitrepo/RC2014_fpga/de10-lite/clocks.vhd}
vcom -93 -work work {C:/Users/richa/gitrepo/RC2014_fpga/de10-lite/CPM_BASIC.vhd}
vcom -93 -work work {C:/Users/richa/gitrepo/RC2014_fpga/rtl/ROM_Page_Select.vhd}
vcom -93 -work work {C:/Users/richa/gitrepo/RC2014_fpga/rtl/T80/T80s.vhd}
vcom -93 -work work {C:/Users/richa/gitrepo/RC2014_fpga/rtl/T80/T80.vhd}
vcom -93 -work work {C:/Users/richa/gitrepo/RC2014_fpga/rtl/RC2014_fpga.vhd}

vcom -93 -work work {C:/Users/richa/gitrepo/RC2014_fpga/de10-lite/../test/RC2014_TB.vhd}
vcom -93 -work work {C:/Users/richa/gitrepo/RC2014_fpga/de10-lite/../test/AsyncLog.vhd}
vcom -93 -work work {C:/Users/richa/gitrepo/RC2014_fpga/de10-lite/../test/AsyncStim.vhd}
vcom -93 -work work {C:/Users/richa/gitrepo/RC2014_fpga/de10-lite/../test/StimLog.vhd}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L fiftyfivenm -L rtl_work -L work -voptargs="+acc"  RC2014_TB

add wave *
view structure
view signals
run -all
