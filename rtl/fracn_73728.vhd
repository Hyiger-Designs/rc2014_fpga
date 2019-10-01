--------------------------------------------------------------------------------
-- File         : fracn_73728.vhd (machine generated)
-- Contains     : entity fracn_73728 (architecture rtl)
-- Author       : ./fracn09.pl  (version 0.09)
-- Command Line : ./fracn09.pl -e fracn_73728 50000000 7372800
-- Date         : Tue Oct  1 01:10:51 2019
-- Complain to  : fractional_divider@hotmail.com
--
-- This machine generated VHDL file contains a fixed ratio frequency divider.
-- Different styles of dividers can be selected by generics or parameters.
--
--  use_phase_accumulator = TRUE   selects a "classic" phase accumulator
--                                 frequency divider
--
--  use_phase_accumulator = FALSE  selects a frequency divider made up of
--                                 a dual modulus prescaler and a controller
--                                 In this case, the generics "minimum_jitter"
--                                 and "use_recursive_controller"
--                                 control size / jitter tradeoffs in
--                                 the controller.
--
-- The phase accumulator style divider has a regular structure (in the sense
-- that it doesn't change much if the ratio is changed - which is good for
-- floorplanning) and it is quite easy to understand.
-- The output frequency is a rational multiple of the input frequency in
-- the form:
--
--       c
-- --------------- * Fin
-- (2 ** num_bits)
--
-- where c and num_bits are integers.
-- The hardware consists of a constant adder, so it will be simple to
-- make it work at high speed.
-- The output jitter will generally be equal to or just less than one
-- cycle of the input clock.
-- Here is a block diagram:
-- 
-- 'clock'-----------------------+
--                               |
--             +-------+    +----------+
-- Constant--->|       |    |          |
-- 'c'         | Adder |--->| Register |-+-->'phase'
--          +->|       |    |          | |
--          |  +-------+    +----------+ |
--          |                            |
--          +----------------------------+
--
-- The MSB of the 'phase' signal has approximately a 50% duty cycle, and
-- is retimed (in another ff not shown) and used as the 'output_50' output.
-- The carry output of the adder will be high once every output cycle,
-- and is registered (in another ff not shown) and used as the
-- 'output_pulse' output.
--
--
-- The dual modulus prescaler divider is somewhat harder to understand, but
-- it may result in less hardware, and it may enable the exact ratio to
-- be produced.
-- In this case, the output frequency is a rational multiple of the input
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
-- Depending on how these a and b cycles are mixed up, the output
-- jitter will vary.
-- There are a number of ways to make the controller.
-- If the generic use_recursive_controller is TRUE, the controller consists
-- of a state machine that produces the best interleaving of the a and b cycles,
-- which gives about the same jitter as the phase accumulator.
-- If use_recursive_controller is FALSE, the controller consists of a counter
-- and a lookup table to interleave the a and b cycles.
-- There are more tradeoffs: if the generic minimum_jitter is FALSE, the lookup
-- table bunches all the a cycles together, and all the b cycles together.
-- This results in simple hardware, but may produce lots of jitter.
-- If the generic minimum_jitter is TRUE, the lookup table produces the best
-- interleaving of the a and b cycles, but it may result in an excessively
-- large case statement.
-- (It will usually be possible to come up with a much better
-- controller design by hand, but the details vary so much with
-- the choice of frequencies that it is hard to generalise this
-- into a simple script.)
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
-- For a given set of input to output frequency ratio and tolerance,
-- the only way to work out which type of divider is better is
-- to try them!  Generally, the phase accumulator is better for
-- loose tolerances (> 10ppm), and the dual modulus prescaler is
-- better if the ratio must be exact, but this depends on the ratio.
--
-- Frequency Parameters:
-- Input Frequency: 50000000 Hz.
-- Desired Output Frequency: 7372800 Hz.
-- Requested Relative Frequency Error Bounds (+/-) : 1e-07 (0.1 ppm)
--
-- Frequency Results (use_phase_accumulator = FALSE) :
--  Achieved Output Frequency: 7372800.43650252 Hz.
--  Achieved Relative Frequency Error: 5.92044438639682e-08 (0.0592044438639682 ppm)
--  Achieved Frequency Error: 0.436502523720264 Hz.
--
-- Frequency Results (use_phase_accumulator = TRUE) :
--  Achieved Output Frequency: 7372799.51572418 Hz.
--  Achieved Relative Frequency Error: -6.56841115819083e-08 (-0.0656841115819083 ppm)
--  Achieved Frequency Error: -0.484275817871094 Hz.
--
-- Output Jitter Parameters (use_phase_accumulator = FALSE) :
--  The fundamental frequency is 6820.3519301596 Hz.
--  The amplitude is 3.6895467160037e-06 seconds p-p (minimum_jitter = FALSE).
--  The amplitude is 1.99814986123962e-08 seconds p-p (minimum_jitter = TRUE).
--
-- Output Jitter Parameters (use_phase_accumulator = TRUE) :
--  The fundamental frequency is 2.98023223876953 Hz.
--  The amplitude is 2e-08 seconds p-p (approx).
--
-- Design Parameters (use_phase_accumulator = FALSE) :
--  Approx 17 flip flops (3 in prescaler, 12 in controller and 2 retimes).
--  The recursive controller uses approx 25 flip flops.
--  The Dual-Modulus Prescaler uses ratios /6,/7
--  The Output consists of 236 cycles of 6 input clocks,
--  and 845 cycles of 7 input clocks.
--  There are 1081 output clocks for every 7331 input clocks.
--
-- Design Parameters (use_phase_accumulator = TRUE) :
--  Approx 26 flip flops (24 in accumulator and 2 retimes)
--  There are 2473901 output clocks for every 16777216 input clocks.
--
-- Divider summary :
--
-- Approx Approx    Relative  Approx    
--  ff    Virtex    Frequency Jitter    Divider
-- count  Slices    Error     (seconds) (generic parameters)
--
--  26    tbd       -6.6e-08  2e-08     use_phase_accumulator
--  29    tbd       -6.6e-08  1e-08     use_phase_accumulator improve_duty_cycle
--  30    tbd       5.9e-08   2e-08     use_recursive_controller
--  31    tbd       5.9e-08   2e-08     use_recursive_controller improve_duty_cycle
--  17    tbd       5.9e-08   2e-08     minimum_jitter
--  18    tbd       5.9e-08   2e-08     minimum_jitter improve_duty_cycle
--  17    tbd       5.9e-08   3.7e-06   (none)
--  18    tbd       5.9e-08   3.7e-06   (none) improve_duty_cycle
--
-- Warnings:
--  none
--
-- Do not fix bugs by hand editing this file - fix the Perl source instead!
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fracn_73728 is
    generic (
        use_phase_accumulator : boolean := FALSE;
            -- TRUE uses classic NCO design.
            -- FALSE uses prescaler / controller design
        use_recursive_controller  : boolean := TRUE;
        minimum_jitter        : boolean := FALSE;
            -- TRUE may use more hardware, but has lowest jitter
            -- (only applies when use_phase_accumulator is FALSE)
        improve_duty_cycle    : boolean := TRUE
            -- TRUE uses a falling edge ff to make the output duty cycle closer to 50%
    );
    port (
        async_reset       : in  std_logic := '0';   -- active high reset
        clock             : in  std_logic;          -- 50000000 Hz input clock
        clock_enable      : in  std_logic := '1';   -- active high clock enable
        output_50         : out std_logic;  -- 7372800 Hz output - approx 50% duty cycle
        output_pulse      : out std_logic   -- 7372800 Hz output - high for single clock per cycle
    );
end fracn_73728;

architecture rtl of fracn_73728 is

    -- definitions for prescaler / controller design
    constant n              : positive := 6;    -- prescaler divides by n or n + 1
    constant a              : positive := 236;  -- this many counts of 6
    constant b              : natural  := 845;  -- this many counts of 7
    signal modulus_control  : std_logic;
    signal prescaler_count  : integer range 0 to n;
    signal controller_count : integer range 0 to a + b - 1;
    signal prescaler_out    : std_logic;
    signal prescaler_out_50 : std_logic;
    signal duty_correction  : std_logic;
    -- definitions for recursive controller design
    constant n1             : natural  := 4;    -- prescaler #1 divides by n1 or n1 + 1
    constant m1             : positive := 4;    -- determines output duty cycle for prescaler #1
    constant n2             : natural  := 2;    -- prescaler #2 divides by n2 or n2 + 1
    constant m2             : positive := 2;    -- determines output duty cycle for prescaler #2
    constant n3             : natural  := 2;    -- prescaler #3 divides by n3 or n3 + 1
    constant m3             : positive := 2;    -- determines output duty cycle for prescaler #3
    constant n4             : natural  := 2;    -- prescaler #4 divides by n4 or n4 + 1
    constant m4             : positive := 2;    -- determines output duty cycle for prescaler #4
    constant n5             : natural  := 2;    -- prescaler #5 divides by n5 or n5 + 1
    constant m5             : positive := 2;    -- determines output duty cycle for prescaler #5
    constant n6             : natural  := 6;    -- prescaler #6 divides by n6 or n6 + 1
    constant m6             : positive := 6;    -- determines output duty cycle for prescaler #6
    signal stage1_count     : integer range 0 to n1;
    signal stage2_count     : integer range 0 to n2;
    signal stage3_count     : integer range 0 to n3;
    signal stage4_count     : integer range 0 to n4;
    signal stage5_count     : integer range 0 to n5;
    signal stage6_count     : integer range 0 to n6;
    signal stage1_out       : std_logic;
    signal stage2_out       : std_logic;
    signal stage3_out       : std_logic;
    signal stage4_out       : std_logic;
    signal stage5_out       : std_logic;
    signal stage6_out       : std_logic;
    signal stage1_carry     : std_logic;
    signal stage2_carry     : std_logic;
    signal stage3_carry     : std_logic;
    signal stage4_carry     : std_logic;
    signal stage5_carry     : std_logic;

    -- definitions for phase accumulator design
    constant num_bits       : positive := 24;   -- size of phase accumulator
    constant c              : unsigned(num_bits - 1 downto 0) := to_unsigned(2473901, num_bits);
    signal phase            : unsigned(num_bits downto 0);  -- MSB is carry output from adder

    -- definitions for phase accumulator design with improved duty cycle
    signal carry            : std_logic;
    signal d_carry          : std_logic;
    signal late             : std_logic;
    signal msb              : std_logic;
    signal d_msb_1          : std_logic;
    signal d_msb_2_neg      : std_logic;
    signal phase_diff       : unsigned(num_bits downto 0);

begin -- rtl

--------------------------------------------------------------------------------
-- Standard Phase accumulator.
-- Adds c to phase each clock.
-- phase(num_bits) is actually the registered carry output.
--------------------------------------------------------------------------------
gen_phase_accumulator : if use_phase_accumulator and not improve_duty_cycle generate
    phase_accumulator : process (async_reset, clock)
    begin
        if (async_reset = '1') then
            phase <= (others => '0');
            output_50 <= '0';
        elsif (rising_edge(clock)) then
            if (clock_enable = '1') then
                phase <= ('0' & phase(num_bits - 1 downto 0)) + ('0' & c);
                output_50 <= phase(num_bits - 1);
            end if;
        end if;
    end process phase_accumulator;

    output_pulse <= phase(num_bits);

end generate gen_phase_accumulator;

--------------------------------------------------------------------------------
-- Phase accumulator with lower jitter (on output_50) and improved duty cycle.
--------------------------------------------------------------------------------
gen_other_phase_accumulator : if use_phase_accumulator and improve_duty_cycle generate
    phase_accumulator : process (async_reset, clock)
        variable new_phase : unsigned(num_bits - 1 downto 0);
    begin
        if (async_reset = '1') then
            phase <= (others => '0');
            output_pulse <= '0';
            carry <= '0';
            d_carry <= '0';
            late <= '0';
            msb <= '0';
            d_msb_1 <= '0';
        elsif (rising_edge(clock)) then
            if (clock_enable = '1') then
                new_phase := ('0' & phase(num_bits - 2 downto 0)) + c;
                phase(num_bits - 2 downto 0) <= new_phase(num_bits - 2 downto 0);
                carry <= new_phase(num_bits - 1);
                if (carry = '1') then
                    msb <= not msb; -- toggle msb
                end if;
                output_pulse <= msb and carry;
                d_carry <= carry;
                d_msb_1 <= msb and not (d_carry and late);
                if (carry = '1') then
                    late <= phase_diff(num_bits);
                end if;
            end if;
        end if;
    end process phase_accumulator;

    phase_diff <= (phase(num_bits - 2 downto 0) & '0') - ('0' & c);

    output_50 <= d_msb_1 or d_msb_2_neg;

    neg_edge : process (async_reset, clock)
    begin
        if (async_reset = '1') then
            d_msb_2_neg <= '0';
        elsif (falling_edge(clock)) then
            if (clock_enable = '1') then
                d_msb_2_neg <= msb xor (d_carry and not (not late and not msb));
            end if;
        end if;
    end process neg_edge;

    assert c(num_bits - 1) = '0' severity failure; 

end generate gen_other_phase_accumulator;

--------------------------------------------------------------------------------
-- Prescaler.  Divides by either 6 or 7
-- depending on whether the signal "modulus_control" is '0' or '1'.
-- Note: the "terminal count" is fixed, and the load value is
-- varied, to give smaller, faster logic (?)
--------------------------------------------------------------------------------
gen_prescaler : if not use_phase_accumulator generate
    prescaler : process (async_reset, clock)
    begin
        if (async_reset = '1') then
            prescaler_count  <= 0;
            prescaler_out    <= '0';
            prescaler_out_50 <= '0';
        elsif (rising_edge(clock)) then
            if (clock_enable = '1') then
                -- manage counter
                if (prescaler_count < n) then
                    prescaler_count <= prescaler_count + 1;
                else
                    if (modulus_control = '0') then
                        prescaler_count <= 1;
                    else
                        prescaler_count <= 0;
                    end if;
                end if;
                -- decode counter
                if (prescaler_count < n) then
                    prescaler_out <= '0';
                else
                    prescaler_out <= '1';
                end if;
                if (prescaler_count <= n/2) then
                    prescaler_out_50 <= '0';
                else
                    prescaler_out_50 <= '1';
                end if;
            end if;
        end if;
    end process prescaler;

    output_pulse <= prescaler_out;

end generate gen_prescaler;

--------------------------------------------------------------------------------
-- Duty cycle improvement using falling edge flip flop.
--------------------------------------------------------------------------------
duty_cycle_improver : if improve_duty_cycle and not use_phase_accumulator generate
    improver : process (async_reset, clock)
    begin
        if (async_reset = '1') then
            duty_correction <= '0';
        elsif (falling_edge(clock)) then
            if (clock_enable = '1') then
                duty_correction <= prescaler_out_50 and modulus_control;
            end if;
        end if;
    end process improver;

    output_50 <= duty_correction or prescaler_out_50;

end generate duty_cycle_improver;

no_duty_cycle_improver : if not improve_duty_cycle and not use_phase_accumulator generate
    output_50 <= prescaler_out_50;
end generate no_duty_cycle_improver;

--------------------------------------------------------------------------------
-- Controller.
-- Wobbles the signal "modulus_control" to cause the prescaler
-- to divide by the correct ratio (in the long term).
-- Modulus_control must be '0' for 236 counts of prescaler_out,
-- and '1' for 845 counts (out of a total of 1081 counts).
-- The simple way to do this is to just have modulus_control '0' for
-- all 236 counts, then '1' for 845 counts, but this may result in severe jitter.
-- The jitter can be reduced (at some hardware cost) by interleaving
-- the '0' and '1' counts.
-- This behaviour can be controlled by the generic parameter "minimum_jitter".
-- Note that there are many hardware / jitter tradeoffs.
-- Best results may require human intervention!
--------------------------------------------------------------------------------
high_jitter_controller : if not minimum_jitter and not use_phase_accumulator and not use_recursive_controller generate
    controller : process (async_reset, clock)
    begin
        if (async_reset = '1') then
            modulus_control <= '0';
            controller_count <= 0;
        elsif (rising_edge(clock)) then
            if (clock_enable = '1') then
                if (prescaler_out = '1') then
                    -- manage counter
                    if (controller_count < a + b - 1) then
                        controller_count <= controller_count + 1;
                    else
                        controller_count <= 0;
                    end if;
                    -- decode counter
                    if (controller_count < a) then
                        modulus_control <= '0';
                    else
                        modulus_control <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process controller;
end generate high_jitter_controller;

low_jitter_controller : if minimum_jitter and not use_phase_accumulator and not use_recursive_controller generate
    controller : process (async_reset, clock)
    begin
        if (async_reset = '1') then
            modulus_control <= '0';
            controller_count <= 0;
        elsif (rising_edge(clock)) then
            if (clock_enable = '1') then
                if (prescaler_out = '1') then
                    -- manage counter
                    if (controller_count < a + b - 1) then
                        controller_count <= controller_count + 1;
                    else
                        controller_count <= 0;
                    end if;
                    -- decode counter
                    if (controller_count <= a + b - 1) then
                        case controller_count is
                            when 1|5|10|14|19|23|28|33 => modulus_control <= '0';
                            when 37|42|46|51|55|60|65|69 => modulus_control <= '0';
                            when 74|78|83|88|92|97|101|106 => modulus_control <= '0';
                            when 110|115|120|124|129|133|138|142 => modulus_control <= '0';
                            when 147|152|156|161|165|170|175|179 => modulus_control <= '0';
                            when 184|188|193|197|202|207|211|216 => modulus_control <= '0';
                            when 220|225|230|234|239|243|248|252 => modulus_control <= '0';
                            when 257|262|266|271|275|280|284|289 => modulus_control <= '0';
                            when 294|298|303|307|312|317|321|326 => modulus_control <= '0';
                            when 330|335|339|344|349|353|358|362 => modulus_control <= '0';
                            when 367|372|376|381|385|390|394|399 => modulus_control <= '0';
                            when 404|408|413|417|422|426|431|436 => modulus_control <= '0';
                            when 440|445|449|454|459|463|468|472 => modulus_control <= '0';
                            when 477|481|486|491|495|500|504|509 => modulus_control <= '0';
                            when 514|518|523|527|532|536|541|546 => modulus_control <= '0';
                            when 550|555|559|564|568|573|578|582 => modulus_control <= '0';
                            when 587|591|596|601|605|610|614|619 => modulus_control <= '0';
                            when 623|628|633|637|642|646|651|656 => modulus_control <= '0';
                            when 660|665|669|674|678|683|688|692 => modulus_control <= '0';
                            when 697|701|706|710|715|720|724|729 => modulus_control <= '0';
                            when 733|738|743|747|752|756|761|765 => modulus_control <= '0';
                            when 770|775|779|784|788|793|798|802 => modulus_control <= '0';
                            when 807|811|816|820|825|830|834|839 => modulus_control <= '0';
                            when 843|848|852|857|862|866|871|875 => modulus_control <= '0';
                            when 880|885|889|894|898|903|907|912 => modulus_control <= '0';
                            when 917|921|926|930|935|940|944|949 => modulus_control <= '0';
                            when 953|958|962|967|972|976|981|985 => modulus_control <= '0';
                            when 990|994|999|1004|1008|1013|1017|1022 => modulus_control <= '0';
                            when 1027|1031|1036|1040|1045|1049|1054|1059 => modulus_control <= '0';
                            when 1063|1068|1072|1077 => modulus_control <= '0';
                            when others => modulus_control <= '1';
                        end case;
                    else
                        modulus_control <= '-'; -- allow logic reductions (?)
                    end if;
                end if;
            end if;
        end if;
    end process controller;
end generate low_jitter_controller;

--------------------------------------------------------------------------------
-- recursive controller
-- The modulus control signal for the prescaler can be generated by another
-- fractional-N divider, which in turn can have its modulus control signal
-- generated by yet another fractional-N divider, and so on.
-- We stop when we don't need another fractional-N divider, and can just use
-- a fixed divider.
-- The particular arrangement we use also produces the smallest possible jitter.
-- The stageN_count and stageN_out signals have been initialised to non-zero
-- values to improve the jitter measurements during simulation.  This is not
-- needed for synthesis, and these values should be set to zero if this
-- improves synthesis results.
-- Recursive controller design information (for debugging):
--          n0=6        m0=X        a0=236      b0=845      i0=X
--          n1=4        m1=4        a1=99       b1=137      i1=1
--          n2=2        m2=2        a2=61       b2=38       i2=1
--          n3=2        m3=2        a3=15       b3=23       i3=0
--          n4=2        m4=2        a4=7        b4=8        i4=1
--          n5=2        m5=2        a5=6        b5=1        i5=1
--          n6=6        m6=6        a6=X        b6=X        i6=0
--------------------------------------------------------------------------------
recursive_controller : if not use_phase_accumulator and use_recursive_controller generate
    controller : process (async_reset, clock)
    begin
        if (async_reset = '1') then
            stage1_count <= 4;
            stage2_count <= 2;
            stage3_count <= 2;
            stage4_count <= 2;
            stage5_count <= 2;
            stage6_count <= 6;
            stage1_out <= '1';
            stage2_out <= '1';
            stage3_out <= '0';
            stage4_out <= '1';
            stage5_out <= '1';
            stage6_out <= '0';
            stage1_carry <= '0';
            stage2_carry <= '0';
            stage3_carry <= '0';
            stage4_carry <= '0';
            stage5_carry <= '0';
        elsif (rising_edge(clock)) then
            if (clock_enable = '1') then
                -- Stage 1  stage1_out is low for 236 cycles, and high for 845 cycles.
                -- n1=4 m1=4 a1=99 b1=137 i1=1
                if (prescaler_out = '1') then
                    if (stage1_count < n1) then
                        stage1_count <= stage1_count + 1;
                        stage1_carry <= '0';
                    else
                        if (stage2_out = '0') then
                            stage1_count <= 1;
                        else
                            stage1_count <= 0;
                        end if;
                        stage1_carry <= '1';
                    end if;
                    if (stage1_count < m1) then
                        stage1_out <= '1';
                    else
                        stage1_out <= '0';
                    end if;
                else
                    stage1_carry <= '0';
                end if;
                -- Stage 2  stage2_out is low for 99 cycles, and high for 137 cycles.
                -- n2=2 m2=2 a2=61 b2=38 i2=1
                if (stage1_carry = '1') then
                    if (stage2_count < n2) then
                        stage2_count <= stage2_count + 1;
                        stage2_carry <= '0';
                    else
                        if (stage3_out = '0') then
                            stage2_count <= 1;
                        else
                            stage2_count <= 0;
                        end if;
                        stage2_carry <= '1';
                    end if;
                    if (stage2_count < m2) then
                        stage2_out <= '1';
                    else
                        stage2_out <= '0';
                    end if;
                else
                    stage2_carry <= '0';
                end if;
                -- Stage 3  stage3_out is low for 61 cycles, and high for 38 cycles.
                -- n3=2 m3=2 a3=15 b3=23 i3=0
                if (stage2_carry = '1') then
                    if (stage3_count < n3) then
                        stage3_count <= stage3_count + 1;
                        stage3_carry <= '0';
                    else
                        if (stage4_out = '0') then
                            stage3_count <= 1;
                        else
                            stage3_count <= 0;
                        end if;
                        stage3_carry <= '1';
                    end if;
                    if (stage3_count < m3) then
                        stage3_out <= '0';
                    else
                        stage3_out <= '1';
                    end if;
                else
                    stage3_carry <= '0';
                end if;
                -- Stage 4  stage4_out is low for 15 cycles, and high for 23 cycles.
                -- n4=2 m4=2 a4=7 b4=8 i4=1
                if (stage3_carry = '1') then
                    if (stage4_count < n4) then
                        stage4_count <= stage4_count + 1;
                        stage4_carry <= '0';
                    else
                        if (stage5_out = '0') then
                            stage4_count <= 1;
                        else
                            stage4_count <= 0;
                        end if;
                        stage4_carry <= '1';
                    end if;
                    if (stage4_count < m4) then
                        stage4_out <= '1';
                    else
                        stage4_out <= '0';
                    end if;
                else
                    stage4_carry <= '0';
                end if;
                -- Stage 5  stage5_out is low for 7 cycles, and high for 8 cycles.
                -- n5=2 m5=2 a5=6 b5=1 i5=1
                if (stage4_carry = '1') then
                    if (stage5_count < n5) then
                        stage5_count <= stage5_count + 1;
                        stage5_carry <= '0';
                    else
                        if (stage6_out = '0') then
                            stage5_count <= 1;
                        else
                            stage5_count <= 0;
                        end if;
                        stage5_carry <= '1';
                    end if;
                    if (stage5_count < m5) then
                        stage5_out <= '1';
                    else
                        stage5_out <= '0';
                    end if;
                else
                    stage5_carry <= '0';
                end if;
                -- Stage 6  stage6_out is low for 6 cycles, and high for 1 cycles.
                -- n6=6 m6=6 a6=X b6=X i6=0
                if (stage5_carry = '1') then
                    if (stage6_count < n6) then
                        stage6_count <= stage6_count + 1;
                    else
                        stage6_count <= 0;
                    end if;
                    if (stage6_count < m6) then
                        stage6_out <= '0';
                    else
                        stage6_out <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process controller;

    modulus_control <= stage1_out;

end generate recursive_controller;

end rtl;
--------------------------------------------------------------------------------
-- <EOF> fracn_73728.vhd
--------------------------------------------------------------------------------
