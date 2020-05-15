library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity single_step_tb is
end;

architecture bench of single_step_tb is

	component single_step
		PORT(
			clk     : in  std_logic;
			reset   : in  std_logic;
			step_pb : in  STD_LOGIC;
			nM1     : in  STD_LOGIC;
			mode_sw : in  STD_LOGIC;
			nWait   : out STD_LOGIC
		);
	end component;

	signal clk     : std_logic;
	signal reset   : std_logic;
	signal step_pb : std_logic;
	signal nM1     : std_logic;
	signal mode_sw : std_logic;
	signal nWait   : std_logic;

	constant clock_period : time := 10 ns;
	signal stop_the_clock : boolean;

begin

	uut : ENTITY work.single_step
		PORT MAP(
			clk     => clk,
			reset   => reset,
			step_pb => step_pb,
			nM1     => nM1,
			mode_sw => mode_sw,
			nWait   => nWait
		);

	stimulus : process
	begin
		reset   <= '1';
		step_pb <= '0';
		nM1     <= '0';
		mode_sw <= '1';
		--nWait   <= '1';

		-- Reset for 3 clock cycles
		reset <= '1', '0' after clock_period * 2;
		wait for clock_period * 2;

		nM1 <= '1', '0' after clock_period * 2;
		wait for clock_period * 2;

		step_pb <= '1', '0' after clock_period * 2;
		wait for clock_period * 8;

		--nM1 <= '1', '0' after clock_period;
		--wait for clock_period * 4;

		stop_the_clock <= true;
		wait;

	end process;

	clocking : process
	begin
		while not stop_the_clock loop
			clk <= '0', '1' after clock_period / 2;
			wait for clock_period;
		end loop;
		wait;
	end process;

end;
