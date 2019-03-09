library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ROM_select is
	generic(
		rom : natural := 0              -- 0 = SCM, 1 - CPM/Basic
	);
	port(
		clk   : in  std_logic;
		nPage : in  std_logic;
		A     : in  std_logic_vector(15 downto 0);
		D     : out std_logic_vector(7 downto 0);
		nCS   : out std_logic
	);
end ROM_select;

architecture rtl of ROM_select is
begin
	scm : if rom = 0 generate
		rom32k : entity work.SCM_V100_S3_SCS3_32K
			port map(
				clock   => clk,
				address => A(14 downto 0),
				q       => D
			);
		nCS <= '0' when A(15) = '0' and nPage = '0' else '1';
	end generate scm;

	cpm_basic : if rom = 1 generate
		rom16k : entity work.CPM_BASIC
			port map(
				clock   => clk,
				address => A(13 downto 0),
				q       => D
			);

		nCS <= '0' when A(15 downto 14) = "00" and nPage = '0' else '1';
	end generate cpm_basic;

	K0000000 : if rom = 2 generate
		rom8k : entity work.K0000000
			port map(
				clock   => clk,
				address => A(12 downto 0),
				q       => D
			);

		nCS <= '0' when A(15 downto 13) = "000" and nPage = '0' else '1';
	end generate K0000000;
end rtl;
