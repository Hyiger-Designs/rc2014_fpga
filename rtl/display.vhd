library IEEE;
use IEEE.std_logic_1164.all;

use work.user_types.all;

entity display is
	port(
		clk   : in  std_logic;
		nReset : in  std_logic;
		A     : in  std_logic_vector;
		D     : in  std_logic_vector;
		HEX   : out sseg
	);
end display;

architecture hex_display of display is
	constant D_BYTES : integer := D'length / 4 - 1; -- 1
	constant A_BYTES : integer := A'length / 4 - 1; -- 3
begin

	-- 2 hex digits
	data_disp : for i in D_BYTES downto 0 generate
		sseg_unit : entity work.hex_to_sseg
			port map(
				clk    => clk,
				nReset  => nReset,
				hex    => D(4 * (i + 1) - 1 downto 4 * i),
				dp     => '0',
				sseg_o => HEX(i)
			);
	end generate data_disp;

	-- 4 hex digits
	address_disp : for i in A_BYTES downto 0 generate
		sseg_unit : entity work.hex_to_sseg
			port map(
				clk    => clk,
				nReset  => nReset,
				hex    => A(4 * (i + 1) - 1 downto 4 * i),
				dp     => '0',
				sseg_o => HEX(i + 2)
			);
	end generate address_disp;

end hex_display;
