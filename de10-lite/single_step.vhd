LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY single_step IS 
	PORT
	(
		clk	: in std_logic;
		reset : in std_logic;
		step :  IN  STD_LOGIC;
		nM1  :  IN  STD_LOGIC;
		mode :  IN  STD_LOGIC;
		nWait :  OUT  STD_LOGIC
	);
END single_step;

ARCHITECTURE rtl OF single_step IS 
	SIGNAL nTrigger :  STD_LOGIC := '1';
	signal nPulse : std_logic := '0';
	signal m1 : std_logic;
BEGIN 

	m1 <= not nM1;
	
	pulse: entity work.pulse_generator
		port map(
			clk => clk,
			reset => reset,
			trig => nM1,
			pulse => nPulse
		);
		
	PROCESS(step, nPulse)
	BEGIN
		IF (nPulse = '0') THEN
			nTrigger <= '1';
		ELSIF (RISING_EDGE(step)) THEN
			nTrigger <= '0';
		END IF;
	END PROCESS;

	nWait <= nTrigger NAND mode;

END rtl;
