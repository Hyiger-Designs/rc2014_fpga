library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity RC2014_fpga is
	port(
		clk     : in  std_logic;
		n_reset : in  std_logic;
		rxd     : in  std_logic;
		txd     : out std_logic;
		rts     : out std_logic
	);
end RC2014_fpga;

architecture struct of RC2014_fpga is
	-- Frequency of board clock in Hz
	constant CLK_FREQUENCY : Real := 50000000.0;

	signal CPU_clk : std_logic;
	signal n_WR    : std_logic;
	signal n_RD    : std_logic;
	signal n_MREQ  : std_logic := '1';
	signal n_IORQ  : std_logic := '1';
	signal n_int   : std_logic := '1';
	signal A       : std_logic_vector(15 downto 0);
	signal D_O     : std_logic_vector(7 downto 0);
	signal D_I     : std_logic_vector(7 downto 0);

	signal ROM_D     : std_logic_vector(7 downto 0);
	signal ROM_nCS   : std_logic := '1';
	signal ROM_nPage : std_logic := '0';

	signal RAM_D   : std_logic_vector(7 downto 0);
	signal RAM_nWR : std_logic := '1';
	signal RAM_nRD : std_logic := '1';
	signal RAM_nCS : std_logic := '1';

	signal UART_D   : std_logic_vector(7 downto 0);
	signal UART_nWR : std_logic := '1';
	signal UART_nRD : std_logic := '1';
	signal UART_nCS : std_logic := '1';

begin

	cpu : entity work.t80s
		generic map(mode => 1, t2write => 1, iowait => 0)
		port map(
			reset_n => n_reset,
			clk_n   => CPU_clk,
			wait_n  => '1',
			int_n   => '1',
			nmi_n   => '1',
			busrq_n => '1',
			mreq_n  => n_MREQ,
			iorq_n  => n_IORQ,
			rd_n    => n_RD,
			wr_n    => n_WR,
			a       => A,
			di      => D_I,
			do      => D_O
		);

	-- Z80 CPU clock - 7.3728 Mhz
	clk1 : entity work.fracn20
		generic map(
			input_frequency    => CLK_FREQUENCY,
			output_frequency   => 7372800.0,
			improve_duty_cycle => TRUE
		)
		port map(
			clock     => clk,
			output_50 => CPU_clk
		);

	-- TODO: figure out how to infer a ROM/RAM from a file
	rom32k : entity work.SCM_V100_S3_SCS3_32K
		port map(
			clock   => clk,
			address => A(14 downto 0),
			q       => ROM_D
		);

	ram64k : entity work.single_port_ram
		port map(
			clock   => clk,
			we      => not (RAM_nWR or RAM_nCS),
			address => A(15 downto 0),
			data    => D_O,
			q       => RAM_D
		);

	uart : entity work.acia6850
		port map(
			clk      => clk,            -- System Clock
			rst      => not n_reset,    -- Reset input (active high)
			cs       => not UART_nCS,   -- miniUART Chip Select
			addr     => A(0),           -- Register Select
			rw       => n_WR,           -- Read / Not Write  1 - Read, 0 - Write
			data_in  => D_O,            -- Data Bus In 
			data_out => UART_D,         -- Data Bus Out
			irq      => n_int,          -- Interrupt Request out

			RxC      => CPU_clk,        -- Receive Baud Clock
			TxC      => CPU_clk,        -- Transmit Baud Clock
			RxD      => rxd,            -- Receive Data
			TxD      => txd,            -- Transmit Data
			DCD_n    => '0',            -- Data Carrier Detect
			CTS_n    => '0',            -- Clear To Send
			RTS_n    => rts             -- Request To send
		);

	-- 32K ROM from 0x0000 to 0x7FFF
	ROM_nCS <= '0' when A(15) = '0' and ROM_nPage = '0' else '1';

	RAM_nRD <= n_RD or n_MREQ;
	RAM_nWR <= n_WR or n_MREQ;
	RAM_nCS <= not ROM_nCS;

	UART_nRD <= n_RD or n_IORQ;
	UART_nWR <= n_WR or n_IORQ;
	-- Serial Channel A - 2 Bytes $80-$81
	UART_nCS <= '0' when A(7 downto 1) = "1000000" and (UART_nWR = '0' or UART_nRD = '0') else '1';

	D_I <= UART_D when UART_nCS = '0'
		else ROM_D when ROM_nCS = '0'
		else RAM_D when RAM_nCS = '0'
		else x"FF";

	-- Disable ROM if out 38. Re-enable when (asynchronous) reset pressed
	process(UART_nWR, n_reset)
	begin
		if (n_reset = '0') then
			ROM_nPage <= '0';
		elsif (rising_edge(UART_nWR)) then
			if A(7 downto 0) = to_stdlogicvector(x"38") then
				ROM_nPage <= '1';
			end if;
		end if;
	end process;

end;
