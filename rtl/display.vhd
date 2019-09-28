library IEEE;
use IEEE.std_logic_1164.all;

use work.user_types.all;

entity display is 
	port (
		clk          : in std_logic; 
		reset        : in std_logic; 
		A            : in std_logic_vector(15 downto 0); 
		D            : in std_logic_vector(7 downto 0);
		HEX : out sseg
	);
end display;

architecture hex_display of display is	
begin
	data_disp: for i in 0 to D'length / 4 - 1 generate
		sseg_unit : entity work.hex_to_sseg
			port map(clk => clk, reset => reset, hex => D(4 * (i + 1) - 1 downto 4 * i), dp => '0', sseg_o => HEX(i));
	end generate data_disp;
	
	address_disp: for i in 0 to A'length / 4 - 1 generate
		sseg_unit : entity work.hex_to_sseg
			port map(clk => clk, reset => reset, hex => A(4 * (i + 1) - 1 downto 4 * i), dp => '0', sseg_o => HEX(i+2));
	end generate address_disp;
end hex_display;