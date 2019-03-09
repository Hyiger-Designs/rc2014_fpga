library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Replicates a 74X138 
entity decoder_3x8 is
	Port(i : in  std_logic_vector(2 downto 0);
	     y : out std_logic_vector(7 downto 0));
end decoder_3x8;

architecture rtl of decoder_3x8 is
begin
	process(i)
	begin
		case i is
			when "000"  => y <= "11111110";
			when "001"  => y <= "11111101";
			when "010"  => y <= "11111011";
			when "011"  => y <= "11110111";
			when "100"  => y <= "11101111";
			when "101"  => y <= "11011111";
			when "110"  => y <= "10111111";
			when "111"  => y <= "01111111";
			when others => y <= "11111111";
		end case;
	end process;
end rtl;
