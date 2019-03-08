library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity clock_div is
	port(
		i_clk         : in  std_logic;
		i_rst         : in  std_logic;
		i_clk_divider : in  std_logic_vector(3 downto 0);
		o_clk         : out std_logic);
end clock_div;

architecture rtl of clock_div is
	signal r_clk_counter      : unsigned(3 downto 0);
	signal r_clk_divider      : unsigned(3 downto 0);
	signal r_clk_divider_half : unsigned(3 downto 0);
begin
	p_clk_divider : process(i_rst, i_clk)
	begin
		if (i_rst = '0') then
			r_clk_counter      <= (others => '0');
			r_clk_divider      <= (others => '0');
			r_clk_divider_half <= (others => '0');
			o_clk              <= '0';
		elsif (rising_edge(i_clk)) then
			r_clk_divider      <= unsigned(i_clk_divider) - 1;
			r_clk_divider_half <= unsigned('0' & i_clk_divider(3 downto 1)); -- half
			if (r_clk_counter < r_clk_divider_half) then
				r_clk_counter <= r_clk_counter + 1;
				o_clk         <= '0';
			elsif (r_clk_counter = r_clk_divider) then
				r_clk_counter <= (others => '0');
				o_clk         <= '1';
			else
				r_clk_counter <= r_clk_counter + 1;
				o_clk         <= '1';
			end if;
		end if;
	end process p_clk_divider;
end rtl;
