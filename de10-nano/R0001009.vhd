library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY R0001009 IS
	PORT
	(
		a		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		clk		: IN STD_LOGIC;
		qspo		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END R0001009;

ARCHITECTURE RTL OF R0001009 IS
BEGIN
	rom64k : entity work.R0001009_NANO PORT MAP (
			address	 => a,
			clock	 => clk,
			q	 => qspo
		);
END RTL;
