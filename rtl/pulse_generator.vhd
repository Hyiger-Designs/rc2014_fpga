library IEEE;
use IEEE.std_logic_1164.all;

entity pulse_generator is
	port (
		CLK : in std_ulogic;
		RESET : in std_ulogic;
		TRIG : in std_ulogic;
		PULSE : out std_ulogic
	);
end pulse_generator;

architecture STATE_MACHINE of pulse_generator is

	type PULSEGEN_STATE_TYPE is (IDLE, GEN_PULSE_A, GEN_PULSE_B,END_PULSE, RETRIGGER); 
	signal CURRENT_STATE, NEXT_STATE: PULSEGEN_STATE_TYPE;
	signal COUNT : integer range 0 to 31;
	
	constant WIDTH : integer range 0 to 31 := 4;
	
	begin
	
	STATE_MACH_PROC : process (CURRENT_STATE, TRIG, COUNT)
	begin
		case CURRENT_STATE is 
			when IDLE => if TRIG='1' then
					NEXT_STATE <= GEN_PULSE_A;
				end if;
				
			when GEN_PULSE_A => if COUNT = WIDTH then
					NEXT_STATE <= END_PULSE;
				elsif TRIG='0' then
					NEXT_STATE <= GEN_PULSE_B;
				end if;
				
			when END_PULSE => if TRIG ='1' then
					NEXT_STATE <= IDLE;
				end if;
				
			when GEN_PULSE_B => if TRIG = '1' then
					NEXT_STATE <= RETRIGGER;
				elsif COUNT=WIDTH then
					NEXT_STATE <= IDLE;
				end if;
				
			when RETRIGGER => NEXT_STATE <= GEN_PULSE_A;
			
			when OTHERS => NEXT_STATE <= NEXT_STATE;
			
		end case;
	end process STATE_MACH_PROC;
	
	PULSE_PROC : process (CLK, RESET) 
	begin
		if RESET = '1' then
			PULSE <= '0';
			COUNT <= 0;
			CURRENT_STATE <= IDLE;
		elsif rising_edge(clk) then 
			CURRENT_STATE <= NEXT_STATE;
			case NEXT_STATE is
			
				when IDLE => PULSE <= '0';
					COUNT <= 0;
					
				when GEN_PULSE_A => PULSE <= '1';
					COUNT <= COUNT + 1;
					
				when END_PULSE => PULSE <= '0';
					COUNT <= 0;
					
				when GEN_PULSE_B => PULSE <= '1';
					COUNT <= COUNT + 1;
					
				when RETRIGGER => COUNT <= 0;
				
				when OTHERS => COUNT <= COUNT;
				
			end case;
		end if;
	end process PULSE_PROC;
	
end STATE_MACHINE;