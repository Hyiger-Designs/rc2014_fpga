library ieee;
use ieee.std_logic_1164.all;

-- Convert a 4-bit value into a single HEX digit
entity hex_to_sseg is
	port(
		clk    : in  std_logic;
		nReset : in  std_logic;
		hex    : in  std_logic_vector(3 downto 0);
		dp     : in  std_logic;
		sseg_o : out std_logic_vector(7 downto 0)
	);
end hex_to_sseg;

architecture arch of hex_to_sseg is
	signal sseg : std_logic_vector(7 downto 0);
begin

	disp : entity work.gen_register
		generic map(CLRBIT => '1')
		port map(
			clk    => clk,
			nRESET => nRESET,
			nENA   => '0',			
			D		 => sseg,
			Q      => sseg_o
		);
		
--	process(clk, reset)
--	begin
--		if (reset = '1') then
--			sseg_o <= (others => '1');
--		elsif rising_edge(clk) then
--			sseg_o <= sseg;
--		end if;
--	end process;

	with hex select sseg(6 downto 0) <=
		"1000000" when "0000",          -- 0
		"1111001" when "0001",          -- 1 	
		"0100100" when "0010",	
		"0110000" when "0011",	
		"0011001" when "0100",	
		"0010010" when "0101",	
		"0000010" when "0110",	
		"1111000" when "0111",	
		"0000000" when "1000",	
		"0011000" when "1001",	
		"0001000" when "1010",	
		"0000011" when "1011",	
		"1000110" when "1100",	
		"0100001" when "1101",	
		"0000110" when "1110",	
		"0001110" when "1111";          -- F

	-- decimal point
	sseg(7) <= not dp;
end arch;
