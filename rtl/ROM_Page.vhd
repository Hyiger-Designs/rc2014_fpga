library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ROM_Page is
	generic(page_port : integer := 16#38#);

	port(
		nWR    : in  std_logic;
		nReset : in  std_logic;
		A      : in  std_logic_vector(15 downto 0);
		nPage  : out std_logic
	);
end ROM_Page;

architecture rtl of ROM_Page is
begin
	process(nReset, nWR)
	begin
		if (nReset = '0') then
			nPage <= '0';
		elsif (rising_edge(nWR)) then
			if A(7 downto 0) = std_logic_vector(to_unsigned(page_port, A'length)) then
				nPage <= '1';
			end if;
		end if;
	end process;
end;
