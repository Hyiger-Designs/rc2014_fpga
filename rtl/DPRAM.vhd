library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- A generic asynchronous dual port RAM with write enable
entity DPRAM is
	port(
		nWR_Ena : in  std_logic;
		RA      : in  std_logic_vector;
		WA      : in  std_logic_vector;
		D       : in  std_logic_vector;
		Q       : out std_logic_vector
	);
end DPRAM;

architecture arch of DPRAM is

	constant SIZE : integer := (2**RA'length) - 1;

	subtype word is std_logic_vector(D'range);
	type RegisterEntry is array (0 to SIZE) of word;

	signal mem : RegisterEntry;
	
begin

	process(D, mem, nWR_Ena, RA, WA)
	begin
		if (nWR_Ena = '0') then
			mem(to_integer(unsigned(WA))) <= D;
		end if;

		Q <= mem(to_integer(unsigned(RA)));
	end process;

end arch;
