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

ENTITY 74139_1 IS 
PORT 
( 
	A1	:	IN	 STD_LOGIC;
	A2	:	IN	 STD_LOGIC;
	B1	:	IN	 STD_LOGIC;
	B2	:	IN	 STD_LOGIC;
	G1N	:	IN	 STD_LOGIC;
	G2N	:	IN	 STD_LOGIC;
	Y10N	:	OUT	 STD_LOGIC;
	Y20N	:	OUT	 STD_LOGIC;
	Y11N	:	OUT	 STD_LOGIC;
	Y21N	:	OUT	 STD_LOGIC
); 
END 74139_1;

ARCHITECTURE bdf_type OF 74139_1 IS 
BEGIN 

-- instantiate macrofunction 

b2v_inst4 : 74139
PORT MAP(A1 => A1,
		 A2 => A2,
		 B1 => B1,
		 B2 => B2,
		 G1N => G1N,
		 G2N => G2N,
		 Y10N => Y10N,
		 Y20N => Y20N,
		 Y11N => Y11N,
		 Y21N => Y21N);

END bdf_type; 