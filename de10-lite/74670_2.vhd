-- Copyright (C) 2019  Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions 
-- and other software and tools, and any partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License 
-- Subscription Agreement, the Intel Quartus Prime License Agreement,
-- the Intel FPGA IP License Agreement, or other applicable license
-- agreement, including, without limitation, that your use is for
-- the sole purpose of programming logic devices manufactured by
-- Intel and sold by Intel or its authorized distributors.  Please
-- refer to the applicable agreement for further details, at
-- https://fpgasoftware.intel.com/eula.

-- PROGRAM		"Quartus Prime"
-- VERSION		"Version 19.1.0 Build 670 09/22/2019 SJ Lite Edition"
-- CREATED		"Wed Feb 19 18:13:30 2020"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY altera;
USE altera.maxplus2.all; 

LIBRARY work;

ENTITY 74670_2 IS 
PORT 
( 
	WA	:	IN	 STD_LOGIC;
	D1	:	IN	 STD_LOGIC;
	WB	:	IN	 STD_LOGIC;
	D2	:	IN	 STD_LOGIC;
	GRN	:	IN	 STD_LOGIC;
	D4	:	IN	 STD_LOGIC;
	D3	:	IN	 STD_LOGIC;
	RA	:	IN	 STD_LOGIC;
	RB	:	IN	 STD_LOGIC;
	GWN	:	IN	 STD_LOGIC;
	Q3	:	OUT	 STD_LOGIC;
	Q1	:	OUT	 STD_LOGIC;
	Q2	:	OUT	 STD_LOGIC
); 
END 74670_2;

ARCHITECTURE bdf_type OF 74670_2 IS 
BEGIN 

-- instantiate macrofunction 

b2v_inst6 : 74670
PORT MAP(WA => WA,
		 D1 => D1,
		 WB => WB,
		 D2 => D2,
		 GRN => GRN,
		 D4 => D4,
		 D3 => D3,
		 RA => RA,
		 RB => RB,
		 GWN => GWN,
		 Q3 => Q3,
		 Q1 => Q1,
		 Q2 => Q2);

END bdf_type; 