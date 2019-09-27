library IEEE;
use IEEE.std_logic_1164.all;

entity display is 
	port (
		clk          : in std_logic; 
		reset        : in std_logic; 
		A            : in std_logic_vector(15 downto 0); 
		D            : in std_logic_vector(7 downto 0);
		HEX0         : out   std_logic_vector(7 downto 0);
		HEX1         : out   std_logic_vector(7 downto 0);
		HEX2         : out   std_logic_vector(7 downto 0);
		HEX3         : out   std_logic_vector(7 downto 0);
		HEX4         : out   std_logic_vector(7 downto 0);
		HEX5         : out   std_logic_vector(7 downto 0)	
	);
end display;

architecture hex_display of display is	
begin
	sseg_unit_0 : entity work.hex_to_sseg
		port map(clk => clk, reset => reset, hex => D(3 downto 0), dp => '0', sseg_o => HEX0);
	sseg_unit_1 : entity work.hex_to_sseg
		port map(clk => clk, reset => reset, hex => D(7 downto 4), dp => '0', sseg_o => HEX1);

	sseg_unit_2 : entity work.hex_to_sseg
		port map(clk => clk, reset => reset, hex => A(3 downto 0), dp => '0', sseg_o => HEX2);
	sseg_unit_3 : entity work.hex_to_sseg
		port map(clk => clk, reset => reset, hex => A(7 downto 4), dp => '0', sseg_o => HEX3);
	sseg_unit_4 : entity work.hex_to_sseg
		port map(clk => clk, reset => reset, hex => A(11 downto 8), dp => '0', sseg_o => HEX4);
	sseg_unit_5 : entity work.hex_to_sseg
		port map(clk => clk, reset => reset, hex => A(15 downto 12), dp => '0', sseg_o => HEX5);
end hex_display;