library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CPM_BASIC is
	port(
			a    : in  std_logic_vector(12 downto 0);
			clk  : in  std_logic;
			qspo : out std_logic_vector(7 downto 0)
	);
end entity CPM_BASIC;

architecture RTL of CPM_BASIC is
	
begin
	rom8k : entity work.CPM_BASIC_NANO 
	port map (
		clock => clk,
		address => a,
		q => qspo
	);

end architecture RTL;
