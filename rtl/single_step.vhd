LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY work;

ENTITY single_step IS
	PORT(
		clk     : in  std_logic;
		reset   : in  std_logic;
		step_pb : in  STD_LOGIC;
		nM1     : in  STD_LOGIC;
		mode_sw : in  STD_LOGIC;
		nWait   : out STD_LOGIC
	);
END single_step;

ARCHITECTURE rtl OF single_step IS
	signal D        : STD_LOGIC;
	signal mode     : STD_LOGIC;
	signal m1_pulse : STD_LOGIC;
	signal S        : STD_LOGIC;
	signal step     : STD_LOGIC;
BEGIN

	D <= '1';
	S <= '1';

	mode <= mode_sw;
	
	m1_pulse_gen : entity work.pulse_generator
		port map(
			clk   => clk,
			reset => reset,
			trig  => nM1,
			pulse => m1_pulse
		);

	PROCESS(step_pb, m1_pulse, S)
	BEGIN
		IF (m1_pulse = '0') THEN
			step <= '0';
		ELSIF (S = '0') THEN
			step <= '1';
		ELSIF (RISING_EDGE(step_pb)) THEN
			step <= D;
		END IF;
	END PROCESS;
	
	nWait <= NOT (mode AND not step);


END rtl;
