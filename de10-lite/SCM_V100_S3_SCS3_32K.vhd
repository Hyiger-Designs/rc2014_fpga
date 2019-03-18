
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY SCM_V100_S3_SCS3_32K IS
	PORT
	(
		addra		: IN STD_LOGIC_VECTOR (14 DOWNTO 0);
		clka		: IN STD_LOGIC;
		douta		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END SCM_V100_S3_SCS3_32K;

ARCHITECTURE RTL OF scm_v100_s3_scs3_32k IS
BEGIN
	rom32k : entity work.SCM_V100_S3_SCS3_32K_LITE PORT MAP (
			address	 => addra,
			clock	 => clka,
			q	 => douta
		);
END RTL;
