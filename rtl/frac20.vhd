--------------------------------------------------------------------------------
-- File         : fracn20.vhd
-- Contains     : entity fracn20 (architecture rtl)
-- Author       : Allan Herriman
-- Date         : Tue Dec 24 2002
-- Version      : 2.0.0
-- Complain to  : fractional_divider@hotmail.com
-- License      : (read below)
--
-- This file contains synthesisable VHDL for a fixed ratio frequency divider.
--
-- The output frequency is a rational multiple of the input
-- frequency in the form:
--
--       (a + b)
-- ----------------------- * Fin
-- (a * n) + (b * (n + 1))
--
-- where a, b, and n are integers.
-- The dual modulus prescaler divides the input clock by n or (n+1).
-- The controller causes the prescaler to divide by n for a cycles of the
-- output, and divide by (n+1) for b cycles of the output.
-- The controller consists of a state machine that produces the best
-- interleaving of the a and b cycles,
-- which gives the minimum possible amount of jitter.
-- The peak to peak output jitter will be <= one period of the input clock.
--
-- Here is a block diagram:
--
--             +--------------+
--             | Dual modulus | 'prescaler_out'
-- 'clock'---->|  Prescaler   |------+--------->
--             | /n or /(n+1) |      |
--             +--------------+      |
--                    ^              |
--                    |       +------------+
--                    |       |            |
--                    +-------| Controller |
--          'modulus_control' |            |
--                            +------------+
--
--
--  The generics:
--      input_frequency     - set this to the input clock frequency in Hz
--      output_frequency    - set this to the desired output frequency in Hz
--      tolerance           - set this to the allowable relative tolerance
--                            on the output frequency.  The default value
--                            of 1.0e-7 should be adequate for most purposes.
--                            VHDL guarantees only about 15 digits of precision,
--                            so tolerances < 1e-15 don't make much sense.
--                            Don't make tolerance exactly zero, as
--                            floating point precision problems may cause an
--                            infinite loop.
--
-- Note: the output_50 output has a (nominally) 50% duty cycle.
-- This output will only be valid if output_frequency < 0.5 * input_frequency
--
-- Revisions:
--  2.0.0  Dec 24 2002   Initial revision.
--         (Starting at 2.0.0, to distinguish it from earlier VHDL-generating
--          Perl scripts.)
--
-- License:
--  This source code (and accompanying test bench and scripts) are released
--  under the terms of the BSD license.
--  http://www.opensource.org/licenses/bsd-license.html
--
--    Copyright (c) 2003, Allan Herriman
--    All rights reserved.
--
--    Redistribution and use in source and binary forms, with or without
--    modification, are permitted provided that the following conditions
--    are met:
--
--        Redistributions of source code must retain the above copyright
--        notice, this list of conditions and the following disclaimer.
--        Redistributions in binary form must reproduce the above copyright
--        notice, this list of conditions and the following disclaimer in
--        the documentation and/or other materials provided with the
--        distribution.
--        The name of Allan Herriman may not be used to endorse or promote
--        products derived from this software without specific prior
--        written permission.
--
--    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
--    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
--    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
--    A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
--    OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
--    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
--    LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
--    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
--    THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
--    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
--
--
-- BUGS:
--  This code is a straightforward translation of the perl script fracn09.pl
--  to VHDL.  Please see fracn09.pl for a list of bugs.
--  http://fractional_divider.tripod.com/fracn09.zip
--
-- Simulation Status:
--  It should work fine in any VHDL '93 or '00 LRM compliant simulator.
--  Seems to work fine in recent versions of Modelsim and Simili.
--  It wouldn't compile in Scirocco Version 2006.6-6.
--
-- Synthesis Status (Jan '03):
--  It should work find in any reasonable VHDL '93 or '00 synthesiser,
--  as only basic RTL code has been used.  (Some tools may object to
--  the assert statements though.  If this is the case, those statements
--  may be removed without changing the function of the code.)
--
--  Seems to work fine in:
--   -  LeonardoSpectrum 2002e build 16 (other versions may be ok, but
--      haven't been tested)
--   -  Synplify Pro 7.3.0 and later
--
--  Doesn't work in:
--   -  Synplify Pro prior to version 7.3.0
--   -  Any synthesis tool from Synopsys.
--   -  Any of the low cost, FPGA vendor supplied tools (e.g. XST, MAXPLUS2).
--
-- Common tool problems:
--   -  Can't handle VHDL '93 syntax.
--   -  Can't handle generics of type real.
--   -  They think that function f_prescaler_params contains an
--      infinite loop.
--   -  Fails an internal assertion.
--   -  Incorrect calculation of "longest static prefix" of signal stageout
--      causing multiple drivers.
--   -  Doesn't correctly interpret the LRM rules regarding initial values
--      on ports
--
--  If your particular toolset doesn't work with this code,
--  please consider instead using fracn09.pl available at
--  http://fractional_divider.tripod.com/
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity fracn20 is
	generic(
		input_frequency    : real;      -- := 1.0e6;    -- frequency of clock (Hz)
		output_frequency   : real;      -- := 32768.0;  -- desired frequency of output (Hz)
		tolerance          : real    := 1.0e-7;
		improve_duty_cycle : boolean := FALSE; -- TRUE uses a falling edge ff to make the output_50 duty cycle closer to 50%
		suppress_report    : boolean := TRUE
	);
	port(
		async_reset  : in  std_logic := '0'; -- active high reset
		clock        : in  std_logic;   -- input clock
		clock_enable : in  std_logic := '1'; -- active high clock enable
		output_50    : out std_logic;   -- output - approx 50% duty cycle
		output_pulse : out std_logic    -- output - high for single clock per cycle
	);
end entity fracn20;

architecture rtl of fracn20 is

	constant min_ratio     : real := (input_frequency / (output_frequency * (1.0 + tolerance)));
	constant max_ratio     : real := (input_frequency / (output_frequency * (1.0 - tolerance)));

	pure function max(x, y : integer) return integer is
	begin
		if x > y then
			return x;
		else
			return y;
		end if;
	end max;

	pure function floor_to_natural(x : real) return natural is
		variable result : natural;
	begin
		result := integer(x);
		if real(result) > x then
			result := result - 1;
		end if;
		return result;
	end floor_to_natural;

	pure function ceil_to_natural(x : real) return natural is
		variable result : natural;
	begin
		result := integer(x);
		if real(result) < x then
			result := result + 1;
		end if;
		return result;
	end ceil_to_natural;

	-- get the integer upper and lower bounds
	constant floor_max_ratio : positive := floor_to_natural(max_ratio);
	constant floor_min_ratio : positive := max(floor_to_natural(min_ratio), 1);
	constant ceil_min_ratio  : positive := ceil_to_natural(min_ratio);

	-- work out the frequency division needed in the dual modulus prescaler
	pure function choose_n return integer is
		variable n : positive;
	begin
		n := floor_min_ratio;

		-- check to see if a straight integer divider will do
		if floor_max_ratio >= ceil_min_ratio then
			--warning("Warning: a fractional-N divider is not needed.");
			if floor_max_ratio > ceil_min_ratio then
				--warning("  Integer dividers $ceil_min_ratio to $floor_max_ratio are ok.");
				n := floor_max_ratio;
			else
				--warning("  Integer divider $floor_max_ratio is ok.");
				n := floor_max_ratio;
			end if;
		end if;
		return n;
	end choose_n;

	-- prescaler divides by n, n+1
	constant n : positive := choose_n;

	type t_prescaler_params is record
		a              : natural;
		b              : natural;
		fout_achieved  : real;
		error_achieved : real;
	end record t_prescaler_params;

	-- Find smallest non-negative integers a and b such that
	--
	-- Fout           (a + b)
	-- ----  =  -----------------------
	--  Fin     (a * n) + (b * (n + 1))
	--
	-- (within the prescribed tolerance).
	--
	-- Note: I also tried a continued PFE based on Euclid's GCD algorithm.
	--  It used fewer iterations, but didn't always find the smallest
	--  a and b, so was rejected.
	pure function f_prescaler_params return t_prescaler_params is
		variable a              : natural;
		variable b              : natural;
		variable result         : t_prescaler_params;
		variable ratio          : real;
		variable dummy_count    : natural := 2_000_000_000;
		attribute syn_looplimit : integer; -- Needed for Synplify 7.3 to work
		attribute syn_looplimit of bigloop : label is 10_000_000;
	begin
		a := 1;                         -- number of /n cycles
		b := 0;                         -- number of /(n+1) cycles

		bigloop : while dummy_count > 0 loop -- test prevents spurious "infinite loop" errors from LeonardoSpectrum

			ratio := real(a * n + b * (n + 1)) / real(a + b);

			if ratio < min_ratio then
				-- too small
				b := b + 1;
				next;
			end if;
			if ratio > max_ratio then
				-- too big
				a := a + 1;
				next;
			end if;
			-- just right
			exit;
			dummy_count := dummy_count - 1; -- never executed
		end loop;

		result.a              := a;
		result.b              := b;
		result.fout_achieved  := input_frequency / ratio; -- Hz
		result.error_achieved := result.fout_achieved - output_frequency; -- Hz

		return result;
	end f_prescaler_params;

	constant prescaler_params : t_prescaler_params := f_prescaler_params;

	constant relative_error : real := prescaler_params.error_achieved / output_frequency;

	-- prescaler signals
	signal modulus_control  : std_logic;
	signal prescaler_count  : integer range 0 to n;
	signal prescaler_out    : std_logic;
	signal prescaler_out_50 : std_logic;
	signal duty_correction  : std_logic;

	-- controller signals and constants
	constant max_stages : positive := 20;

	type t_integer_array is array (natural range <>) of integer;

	type t_stage is record
		n : natural;                    -- this stage divides by n (or n+1)
		m : natural;                    -- Controls duty cycle of modulus control output from this stage.
		a : natural;                    -- This stage requires its modulus control input to be low for this number of cycles
		b : natural;                    -- This stage requires its modulus control input to be high for this number of cycles
		i : std_logic;                  -- Invert the output of this stage
	end record t_stage;

	type t_stage_array is array (natural range <>) of t_stage;

	pure function f_controller_params return t_stage_array is
		variable stage       : natural := 0;
		variable stage_array : t_stage_array(max_stages downto 0);
		variable n1          : natural;
		variable a1          : natural;
		variable b1          : natural;
		variable n2          : natural;
		variable m2          : natural;
		variable a2          : natural;
		variable b2          : natural;
		variable i2          : std_logic;
		variable determinant : integer;
	begin
		stage_array(stage).n := n;
		stage_array(stage).a := prescaler_params.a;
		stage_array(stage).b := prescaler_params.b;

		while (stage_array(stage).b > 1 and stage_array(stage).a > 1) loop
			n1                   := stage_array(stage).n;
			a1                   := stage_array(stage).a;
			b1                   := stage_array(stage).b;
			assert n1 >= 0 and a1 >= 0 and b1 >= 0;
			if a1 < b1 then
				i2          := '1';
				n2          := (a1 + b1) / a1;
				m2          := (a1 + b1 - 1) / a1;
				determinant := n2 - m2 + 1;
				assert determinant /= 0;
				a2          := (m2 * a1 - (n2 + 1 - m2) * b1) / determinant;
				b2          := ((1 - m2) * a1 + (n2 + 1 - m2) * b1) / determinant;
			else
				i2          := '0';
				n2          := (a1 + b1) / b1;
				m2          := (a1 + b1 - 1) / b1;
				determinant := (m2 - n2 - 1);
				assert determinant /= 0;
				a2          := ((n2 + 1 - m2) * a1 - m2 * b1) / determinant;
				b2          := ((m2 - n2 - 1) * a1 + (m2 - 1) * b1) / determinant;
			end if;
			stage                := stage + 1;
			stage_array(stage).n := n2;
			stage_array(stage).m := m2;
			stage_array(stage).a := a2;
			stage_array(stage).b := b2;
			stage_array(stage).i := i2;
		end loop;

		-- fill in the parameters for the last (non-fractional) stage
		stage                := stage + 1;
		stage_array(stage).n := stage_array(stage - 1).a + stage_array(stage - 1).b - 1;
		stage_array(stage).m := stage_array(stage - 1).a;
		stage_array(stage).i := '0';

		return stage_array(stage downto 0);

	end f_controller_params;

	constant stage_array : t_stage_array := f_controller_params;

	constant stages : natural := stage_array'high;

	signal count    : t_integer_array(stages downto 1);
	signal carry    : std_logic_vector(stages downto 0);
	signal stageout : std_logic_vector(stages + 1 downto 1) := (others => 'W'); -- initial value works around bug in Modelsim versions prior to 5.7b

	-- function to work out the modulus needed for each counter stage
	-- (otherwise each stage will be a 32 bit counter, which
	--  still gives the correct results, but is wasteful of logic)
	pure function makemod(x : natural) return integer is
		variable log      : integer := 0;
		variable my_count : integer := x;
	begin
		while my_count > 0 loop
			log      := log + 1;
			my_count := my_count / 2;
		end loop;
		return 2 ** log;
	end function makemod;

begin                                   -- architecture rtl

	-- print some of the constants, for debugging
	assert suppress_report
	report "n = " & integer'image(n) &
            " a = " & integer'image(prescaler_params.a) &
            " b = " & integer'image(prescaler_params.b) &
            " fout_achieved = " & real'image(prescaler_params.fout_achieved) &
            " error_achieved = " & real'image(prescaler_params.error_achieved) & " (Hz) " &
                                   real'image(relative_error) & " (rel)" &
            " stages = " & integer'image(stages)
	severity note;

	-- check some of the constants
	assert input_frequency > 0.0 severity failure;
	assert output_frequency > 0.0 severity failure;
	assert input_frequency >= output_frequency severity failure;
	assert tolerance < 1.0 and tolerance >= 0.0 severity failure;

	assert abs (relative_error) <= tolerance report "out of tolerance" severity error;

	--------------------------------------------------------------------------------
	-- Prescaler.  Divides by either n or n + 1
	-- depending on whether the signal "modulus_control" is '0' or '1'.
	-- Note: the "terminal count" is fixed, and the load value is
	-- varied, to give smaller, faster logic (?)
	--------------------------------------------------------------------------------
	prescaler : process(async_reset, clock)
	begin
		if async_reset = '1' then
			prescaler_count  <= 0;
			prescaler_out_50 <= '0';
		elsif rising_edge(clock) then
			if clock_enable = '1' then
				-- manage counter
				if prescaler_count < n then
					prescaler_count <= prescaler_count + 1;
				else
					if modulus_control = '0' then
						prescaler_count <= 1;
					else
						prescaler_count <= 0;
					end if;
				end if;
				-- decode counter
				if prescaler_count <= n / 2 then
					prescaler_out_50 <= '0';
				else
					prescaler_out_50 <= '1';
				end if;
			end if;
		end if;
	end process prescaler;

	decode_prescaler_out : if n > 1 generate
		decoder : process(async_reset, clock)
		begin
			if async_reset = '1' then
				prescaler_out <= '0';
			elsif rising_edge(clock) then
				if clock_enable = '1' then
					if prescaler_count < n then
						prescaler_out <= '0';
					else
						prescaler_out <= '1';
					end if;
				end if;
			end if;
		end process decoder;
	end generate decode_prescaler_out;

	no_decode_prescaler_out : if n <= 1 generate
		prescaler_out <= '0' when prescaler_count = 0 else '1';
	end generate no_decode_prescaler_out;

	output_pulse <= prescaler_out;

	--------------------------------------------------------------------------------
	-- Duty cycle improvement using falling edge flip flop.
	--------------------------------------------------------------------------------
	duty_cycle_improver : if improve_duty_cycle generate
		improver : process(async_reset, clock)
		begin
			if async_reset = '1' then
				duty_correction <= '0';
			elsif falling_edge(clock) then
				if clock_enable = '1' then
					duty_correction <= prescaler_out_50 and modulus_control;
				end if;
			end if;
		end process improver;

		output_50 <= duty_correction or prescaler_out_50;

	end generate duty_cycle_improver;

	no_duty_cycle_improver : if not improve_duty_cycle generate
		output_50 <= prescaler_out_50;
	end generate no_duty_cycle_improver;

	-- trash output_50 when it will not be useful
	trash_output_50 : if input_frequency <= 2.0 * output_frequency generate
		output_50 <= 'X';
	end generate trash_output_50;

	--------------------------------------------------------------------------------
	-- recursive controller
	-- The modulus control signal for the prescaler can be generated by another
	-- fractional-N divider, which in turn can have its modulus control signal
	-- generated by yet another fractional-N divider, and so on.
	-- We stop when we don't need another fractional-N divider, and can just use
	-- a fixed divider.
	-- The particular arrangement we use also produces the smallest possible jitter.
	-- The stagecount and stageout signals have been initialised to non-zero
	-- values to improve the jitter measurements during simulation.  This is not
	-- needed for synthesis, and these values should be set to zero if this
	-- improves synthesis results.
	--
	-- count will increment between 0 and stage_array(stage).n or
	--  1 and stage_array(stage).n,  depending on output of the next stage.
	--------------------------------------------------------------------------------
	controllers : for stage in 1 to stages generate
		constant countmask : natural := makemod(stage_array(stage).n);
	begin
		controller : process(async_reset, clock)
		begin
			if async_reset = '1' then
				count(stage)    <= stage_array(stage).n;
				carry(stage)    <= '0';
				stageout(stage) <= stage_array(stage).i;
			elsif rising_edge(clock) then
				if clock_enable = '1' then
					if carry(stage - 1) = '1' then
						if count(stage) < stage_array(stage).n then
							count(stage) <= (count(stage) + 1) mod countmask;
							carry(stage) <= '0';
						else
							if stageout(stage + 1) = '0' then
								count(stage) <= 1;
							else
								count(stage) <= 0;
							end if;
							carry(stage) <= '1';
						end if;
						if count(stage) < stage_array(stage).m then
							stageout(stage) <= stage_array(stage).i;
						else
							stageout(stage) <= not stage_array(stage).i;
						end if;
					else
						carry(stage) <= '0';
					end if;
				end if;
			end if;
		end process controller;
	end generate controllers;

	modulus_control <= stageout(1);

	carry(0) <= prescaler_out;

	stageout(stages + 1) <= '1';        -- last stage is a fixed modulus divider

end architecture rtl;                   -- of entity fracn20
--------------------------------------------------------------------------------
-- <EOF> fracn20.vhd
--------------------------------------------------------------------------------
