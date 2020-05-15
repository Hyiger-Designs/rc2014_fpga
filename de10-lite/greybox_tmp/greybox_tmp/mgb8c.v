//altecc_encoder CBX_SINGLE_OUTPUT_FILE="ON" INTENDED_DEVICE_FAMILY=""MAX 10"" lpm_pipeline=0 width_codeword=72 width_dataword=64 data q
//VERSION_BEGIN 19.1 cbx_mgl 2019:09:22:11:02:15:SJ cbx_stratixii 2019:09:22:11:00:28:SJ cbx_util_mgl 2019:09:22:11:00:28:SJ  VERSION_END
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463



// Copyright (C) 2019  Intel Corporation. All rights reserved.
//  Your use of Intel Corporation's design tools, logic functions 
//  and other software and tools, and any partner logic 
//  functions, and any output files from any of the foregoing 
//  (including device programming or simulation files), and any 
//  associated documentation or information are expressly subject 
//  to the terms and conditions of the Intel Program License 
//  Subscription Agreement, the Intel Quartus Prime License Agreement,
//  the Intel FPGA IP License Agreement, or other applicable license
//  agreement, including, without limitation, that your use is for
//  the sole purpose of programming logic devices manufactured by
//  Intel and sold by Intel or its authorized distributors.  Please
//  refer to the applicable agreement for further details, at
//  https://fpgasoftware.intel.com/eula.



//synthesis_resources = altecc_encoder 1 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
module  mgb8c
	( 
	data,
	q) /* synthesis synthesis_clearbox=1 */;
	input   [63:0]  data;
	output   [71:0]  q;

	wire  [71:0]   wire_mgl_prim1_q;

	altecc_encoder   mgl_prim1
	( 
	.data(data),
	.q(wire_mgl_prim1_q));
	defparam
		mgl_prim1.intended_device_family = ""MAX 10"",
		mgl_prim1.lpm_pipeline = 0,
		mgl_prim1.width_codeword = 72,
		mgl_prim1.width_dataword = 64;
	assign
		q = wire_mgl_prim1_q;
endmodule //mgb8c
//VALID FILE
