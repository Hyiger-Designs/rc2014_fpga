-- RC2014 Emulator
-- Z80 CPU at 7.3728mhz
-- 64K RAM
-- 64K Pageable ROM with 8K page size and page selection
-- Dual ACIA 6850 UARTs at 115200 8N1
-- CF Filesystem

-- see: https://rc2014.co.uk/ for details
-- Inspiration and ideas from: Grant Searle's MULTICOMP project at http://searle.hostei.com/grant/Multicomp/index.html

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RC2014_fpga is
	port(
		-- Z80_BUS
		A               : out   std_logic_vector(15 downto 0); -- 1 - 16
		nM1             : out   std_logic; -- 19
		nRST            : in    std_logic; -- 20
		clk             : in    std_logic; -- 21
		nINT            : in    std_logic; -- 22
		nMREQ           : out   std_logic; -- 23
		nWR             : out   std_logic; -- 24
		nRD             : out   std_logic; -- 25
		nIORQ           : out   std_logic; -- 26
		D               : inout std_logic_vector(7 downto 0); -- 27 - 34
		TX              : out   std_logic; -- 35
		RX              : in    std_logic; -- 36
		-- PRO_BUS
		nRFSH           : out   std_logic; -- 19
		nRST2           : in    std_logic; -- 20
		clk2            : in    std_logic; -- 21
		nBUSAK          : out   std_logic; -- 22
		nHALT           : out   std_logic; -- 23
		nBUSRQ          : in    std_logic; -- 24
		nWAIT           : in    std_logic; -- 25
		nNMI            : in    std_logic; -- 26
		TX2             : out   std_logic; -- 35
		RX2             : in    std_logic; -- 36

		-- FPGA Board specific pins
		rom_page_select : in    std_logic_vector(2 downto 0);
		rom_page_LED    : out   std_logic_vector(7 downto 0);
		RTS             : out   std_logic
	);
end RC2014_fpga;

architecture struct of RC2014_fpga is
	-- Frequency of board clock in Hz
	constant BRD_FREQUENCY : Real := 50000000.0;
	constant CPU_FREQUENCY : Real := 7372800.0;

	signal CPU_clk : std_logic;

	signal CPU_A      : std_logic_vector(15 downto 0);
	signal CPU_nM1    : std_logic;
	signal CPU_nINT   : std_logic;
	signal CPU_nMREQ  : std_logic;
	signal CPU_nIORQ  : std_logic;
	signal CPU_nRD    : std_logic;
	signal CPU_nWR    : std_logic;
	signal CPU_nRFSH  : std_logic;
	signal CPU_nHALT  : std_logic := '1';
	signal CPU_nBUSAK : std_logic;
	signal CPU_D_O    : std_logic_vector(7 downto 0);
	signal CPU_D_I    : std_logic_vector(7 downto 0);

	signal ROM_D   : std_logic_vector(7 downto 0);
	signal ROM_nCS : std_logic := '1';
	signal Page    : std_logic := '0';

	signal RAM_D   : std_logic_vector(7 downto 0);
	signal RAM_nWR : std_logic := '1';
	signal RAM_nRD : std_logic := '1';
	signal RAM_nCS : std_logic := '1';

	signal UART_D   : std_logic_vector(7 downto 0);
	signal UART_nWR : std_logic := '1';
	signal UART_nRD : std_logic := '1';
	signal UART_nCS : std_logic := '1';

begin

	-- CPU clock at 7.3728 Mhz (for 115200 Baud UART support /64)
	-- Uses a fractional divider instead of vendor specific PLL
	ctc_clk : entity work.fracn20
		generic map(
			input_frequency    => BRD_FREQUENCY,
			output_frequency   => CPU_FREQUENCY,
			improve_duty_cycle => TRUE
		)
		port map(
			clock     => clk,
			output_50 => CPU_clk
		);

	-- Z80 CPU
	cpu : entity work.t80s
		generic map(mode => 1, t2write => 1, iowait => 0)
		port map(
			reset_n => nRST,
			clk_n   => CPU_clk,
			wait_n  => nWAIT,
			int_n   => CPU_nINT,
			nmi_n   => nNMI,
			busrq_n => nBUSRQ,
			M1_n    => CPU_nM1,
			mreq_n  => CPU_nMREQ,
			iorq_n  => CPU_nIORQ,
			rd_n    => CPU_nRD,
			wr_n    => CPU_nWR,
			RFSH_n  => CPU_nRFSH,
			HALT_n  => CPU_nHALT,
			BUSAK_n => CPU_nBUSAK,
			a       => CPU_A,
			di      => CPU_D_I,
			do      => CPU_D_O
		);

	-- 64K Generic (Non vendor specific Single Port RAM)
	ram64k : entity work.single_port_ram
		port map(
			clock   => clk,
			we      => not (RAM_nWR or RAM_nCS),
			address => CPU_A(15 downto 0),
			data    => CPU_D_O,
			q       => RAM_D
		);

	-- Selection of roms available, defaults to CPM Monitor
	-- 0 - Grant Searle's 8K CP/M Monitor
	-- 1 - Steve Cousin's 32K SCM v 1.0 S3
	-- 2 - RC2014 64K Paged ROM (fixed at 8K pages) ver R0001009
	--     use the rom_page_select[0-3] switches to select page
	rom : entity work.ROM_Page_Select
		generic map(rom => 1)           -- Select SCM ROM
		port map(
			clk         => clk,
			nReset      => nRST,
			page_select => rom_page_select,
			nWR         => UART_nWR,
			A           => CPU_A,
			D           => ROM_D,
			nCS         => ROM_nCS,
			Page        => Page,
			page_LED    => rom_page_LED
		);

	uart : entity work.acia6850
		port map(
			clk      => clk,            -- System Clock
			rst      => not nRST,       -- Reset input (active high)
			cs       => not UART_nCS,   -- miniUART Chip Select
			addr     => CPU_A(0),       -- Register Select
			rw       => CPU_nWR,        -- Read / Not Write  1 - Read, 0 - Write
			data_in  => CPU_D_O,        -- Data Bus In 
			data_out => UART_D,         -- Data Bus Out
			irq      => CPU_nINT,       -- Interrupt Request out

			RxC      => CPU_clk,        -- Receive Baud Clock
			TxC      => CPU_clk,        -- Transmit Baud Clock
			RxD      => RX,             -- Receive Data
			TxD      => TX,             -- Transmit Data
			DCD_n    => '0',            -- Data Carrier Detect
			CTS_n    => '0',            -- Clear To Send
			RTS_n    => rts             -- Request To send
		);

	-- Internal Bus Managment
	RAM_nCS <= not ROM_nCS;
	RAM_nRD <= CPU_nRD or CPU_nMREQ;
	RAM_nWR <= CPU_nWR or CPU_nMREQ;

	-- Serial Channel A - 2 Bytes $80-$81
	UART_nCS <= '0' when CPU_A(7 downto 1) = "1000000" and (UART_nWR = '0' or UART_nRD = '0') else '1';
	UART_nRD <= CPU_nRD or CPU_nIORQ;
	UART_nWR <= CPU_nWR or CPU_nIORQ;

	-- External Bus management

	D <= UART_D when UART_nCS = '0'
		else ROM_D when ROM_nCS = '0'
		else RAM_D when RAM_nCS = '0'
		else CPU_D_O when CPU_nWR = '0'
		else (others => 'Z');

	CPU_D_I <= D;

	A      <= CPU_A;
	nM1    <= CPU_nM1;
	nMREQ  <= CPU_nMREQ;
	nWR    <= CPU_nWR;
	nRD    <= CPU_nRD;
	nIORQ  <= CPU_nIORQ;
	nBUSAK <= CPU_nBUSAK;
	nHALT  <= CPU_nHALT;
	nRFSH  <= CPU_nRFSH;
end;
