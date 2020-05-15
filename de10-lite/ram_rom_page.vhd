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

LIBRARY work;

ENTITY ram_rom_page IS 
	PORT
	(
		nIORQ :  IN  STD_LOGIC;
		nM1 :  IN  STD_LOGIC;
		nMREQ :  IN  STD_LOGIC;
		nWR :  IN  STD_LOGIC;
		nRST :  IN  STD_LOGIC;
		A :  IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		D :  IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		ROM_CE :  OUT  STD_LOGIC;
		RAM_CE :  OUT  STD_LOGIC;
		page :  OUT  STD_LOGIC_VECTOR(4 DOWNTO 0)
	);
END ram_rom_page;

ARCHITECTURE bdf_type OF ram_rom_page IS 

ATTRIBUTE black_box : BOOLEAN;
ATTRIBUTE noopt : BOOLEAN;

COMPONENT \74138_3\
	PORT(A : IN STD_LOGIC;
		 B : IN STD_LOGIC;
		 G1 : IN STD_LOGIC;
		 C : IN STD_LOGIC;
		 G2AN : IN STD_LOGIC;
		 G2BN : IN STD_LOGIC;
		 Y7N : OUT STD_LOGIC);
END COMPONENT;
ATTRIBUTE black_box OF \74138_3\: COMPONENT IS true;
ATTRIBUTE noopt OF \74138_3\: COMPONENT IS true;

COMPONENT \74139_1\
	PORT(A1 : IN STD_LOGIC;
		 A2 : IN STD_LOGIC;
		 B1 : IN STD_LOGIC;
		 B2 : IN STD_LOGIC;
		 G1N : IN STD_LOGIC;
		 G2N : IN STD_LOGIC;
		 Y10N : OUT STD_LOGIC;
		 Y20N : OUT STD_LOGIC;
		 Y11N : OUT STD_LOGIC;
		 Y21N : OUT STD_LOGIC);
END COMPONENT;
ATTRIBUTE black_box OF \74139_1\: COMPONENT IS true;
ATTRIBUTE noopt OF \74139_1\: COMPONENT IS true;

COMPONENT \74670_0\
	PORT(WA : IN STD_LOGIC;
		 D1 : IN STD_LOGIC;
		 WB : IN STD_LOGIC;
		 D2 : IN STD_LOGIC;
		 GRN : IN STD_LOGIC;
		 D4 : IN STD_LOGIC;
		 D3 : IN STD_LOGIC;
		 RA : IN STD_LOGIC;
		 RB : IN STD_LOGIC;
		 GWN : IN STD_LOGIC;
		 Q3 : OUT STD_LOGIC;
		 Q4 : OUT STD_LOGIC;
		 Q1 : OUT STD_LOGIC;
		 Q2 : OUT STD_LOGIC);
END COMPONENT;
ATTRIBUTE black_box OF \74670_0\: COMPONENT IS true;
ATTRIBUTE noopt OF \74670_0\: COMPONENT IS true;

COMPONENT \74670_2\
	PORT(WA : IN STD_LOGIC;
		 D1 : IN STD_LOGIC;
		 WB : IN STD_LOGIC;
		 D2 : IN STD_LOGIC;
		 GRN : IN STD_LOGIC;
		 D4 : IN STD_LOGIC;
		 D3 : IN STD_LOGIC;
		 RA : IN STD_LOGIC;
		 RB : IN STD_LOGIC;
		 GWN : IN STD_LOGIC;
		 Q3 : OUT STD_LOGIC;
		 Q1 : OUT STD_LOGIC;
		 Q2 : OUT STD_LOGIC);
END COMPONENT;
ATTRIBUTE black_box OF \74670_2\: COMPONENT IS true;
ATTRIBUTE noopt OF \74670_2\: COMPONENT IS true;

SIGNAL	ADRSEL :  STD_LOGIC;
SIGNAL	MA19 :  STD_LOGIC;
SIGNAL	MA20 :  STD_LOGIC;
SIGNAL	nPAGE_EN :  STD_LOGIC;
SIGNAL	page_ALTERA_SYNTHESIZED :  STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL	Page_EN :  STD_LOGIC;
SIGNAL	PAGE_WR :  STD_LOGIC;
SIGNAL	PGEN_WR :  STD_LOGIC;


BEGIN 



nPAGE_EN <= NOT(Page_EN);



b2v_inst2 : 74670_0
PORT MAP(WA => A(0),
		 D1 => D(0),
		 WB => A(1),
		 D2 => D(1),
		 GRN => nPAGE_EN,
		 D4 => D(3),
		 D3 => D(2),
		 RA => A(14),
		 RB => A(15),
		 GWN => PAGE_WR,
		 Q3 => page_ALTERA_SYNTHESIZED(2),
		 Q4 => page_ALTERA_SYNTHESIZED(3),
		 Q1 => page_ALTERA_SYNTHESIZED(0),
		 Q2 => page_ALTERA_SYNTHESIZED(1));


b2v_inst4 : 74139_1
PORT MAP(A1 => MA19,
		 A2 => A(2),
		 B1 => MA20,
		 B2 => ADRSEL,
		 G1N => nMREQ,
		 G2N => nWR,
		 Y10N => ROM_CE,
		 Y20N => PAGE_WR,
		 Y11N => RAM_CE,
		 Y21N => PGEN_WR);


b2v_inst6 : 74670_2
PORT MAP(WA => A(0),
		 D1 => D(4),
		 WB => A(1),
		 D2 => D(5),
		 GRN => nPAGE_EN,
		 D4 => D(7),
		 D3 => D(6),
		 RA => A(14),
		 RB => A(15),
		 GWN => PAGE_WR,
		 Q3 => MA20,
		 Q1 => page_ALTERA_SYNTHESIZED(4),
		 Q2 => MA19);


b2v_IO_ADDR : 74138_3
PORT MAP(A => A(4),
		 B => A(5),
		 G1 => nIORQ,
		 C => A(6),
		 G2AN => A(7),
		 G2BN => nM1,
		 Y7N => ADRSEL);


PROCESS(PGEN_WR,nRST)
BEGIN
IF (nRST = '0') THEN
	Page_EN <= '0';
ELSIF (RISING_EDGE(PGEN_WR)) THEN
	Page_EN <= D(0);
END IF;
END PROCESS;

page <= page_ALTERA_SYNTHESIZED;

END bdf_type;