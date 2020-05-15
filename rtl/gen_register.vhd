library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gen_register is
	generic(
		CLRBIT    : std_logic := '0'
	);
	port(
				clk        : in    std_logic;
				nRESET     : in    std_logic;	
				nENA     : in    std_logic;	
				
				D			: in   std_logic_vector;
				Q        : out   std_logic_vector
	);
end gen_register;

architecture rtl of gen_register is

begin

	process(clk,nRESET,nENA,D)
	begin
		if (nRESET = '0') then
			Q <= (others => CLRBIT);
		elsif (rising_edge(clk)) then
			if nENA = '0' then
				Q <= D;
			end if;
		end if;
	end process;

end;