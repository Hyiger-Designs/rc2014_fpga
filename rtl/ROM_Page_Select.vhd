library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ROM_Page_Select is
	port(
		clk         : in  std_logic;
		page_select : in  std_logic_vector(2 downto 0);
		nPage       : in  std_logic;
		A           : in  std_logic_vector(15 downto 0);
		D           : out std_logic_vector(7 downto 0);
		nCS         : out std_logic;
		page_LED		: out std_logic_vector(7 downto 0)
	);
end entity ROM_Page_Select;

architecture RTL of ROM_Page_Select is
	signal ADDR : std_logic_vector(15 downto 0);
	signal nPage_LED : std_logic_vector(7 downto 0);
begin
	ADDR <= page_select & A(12 downto 0);

	rom64k : entity work.R0001009
		port map(
			clock   => clk,
			address => ADDR(15 downto 0),
			q       => D
		);

	nCS <= '0' when A(15 downto 13) = "000" and nPage = '0' else '1';

		led_select : entity work.decoder_3x8
		port map(
			i => page_select,
			y => nPage_LED
		);

	page_LED <= not nPage_LED when nPage = '0' else (others => '0');
end architecture RTL;
