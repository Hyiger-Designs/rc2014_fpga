library IEEE;
use IEEE.std_logic_1164.all;

use work.user_types.all;

entity display is
	port(
		clk   : in  std_logic;
		reset : in  std_logic;
		A     : in  std_logic_vector;
		D     : in  std_logic_vector;
		HEX   : out sseg
	);
end display;

architecture hex_display of display is
	constant D_SIZE : integer := D'length / 4 - 1; -- 1
	constant A_SIZE : integer := A'length / 4 - 1; -- 3
begin
	data_disp : for i in D_SIZE downto 0 generate
		sseg_unit : entity work.hex_to_sseg
			port map(clk => clk, reset => reset, hex => D(4 * (i + 1) - 1 downto 4 * i), dp => '0', sseg_o => HEX(i));
	end generate data_disp;

	address_disp : for i in A_SIZE downto 0 generate
		sseg_unit : entity work.hex_to_sseg
			port map(clk => clk, reset => reset, hex => A(4 * (i + 1) - 1 downto 4 * i), dp => '0', sseg_o => HEX(i + 2));
	end generate address_disp;
end hex_display;
