library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity single_port_ram is
	port(
		clock   : in  std_logic;
		we      : in  std_logic;
		address : in  std_logic_vector;
		data    : in  std_logic_vector;
		q       : out std_logic_vector
	);
end entity single_port_ram;

architecture RTL of single_port_ram is

	type ram_type is array (0 to (2**address'length) - 1) of std_logic_vector(data'range);
	signal ram          : ram_type;
	signal read_address : std_logic_vector(address'range);

begin

	RamProc : process(clock) is
	begin
		if rising_edge(clock) then
			if we = '1' then
				ram(to_integer(unsigned(address))) <= data;
			end if;
			read_address <= address;
		end if;
	end process RamProc;

	q <= ram(to_integer(unsigned(read_address)));

end architecture RTL;
