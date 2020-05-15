
-- Z80 CPU at 7.3728mhz
-- 64K RAM
-- 64K Pageable ROM with 8K page size and page selection
-- Dual ACIA 6850 UARTs at 115200 8N1
-- CF Filesystem

-- Inspiration and ideas from: Grant Searle's MULTICOMP project at http://searle.hostei.com/grant/Multicomp/index.html

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.user_types.all;

entity RC2014_fpga is
	port(
	
		-- Board Clock 50 mhz
		clk        : in    std_logic;   -- 
		
		-- RAM/ROM Board
		A          : out   std_logic_vector(18 downto 0); 
		D          : inout std_logic_vector(7 downto 0);
		nRESET_EXT : out   std_logic;   
		RAM_nCE    : out   std_logic;   
		ROM_nCE    : out   std_logic;   
		nRD        : out   std_logic;  
		nWR        : out   std_logic;   

		-- UART/FTDI
		nRTS       : out   std_logic;   -- a2-5
		nCTS       : in    std_logic;   -- a2-6
		TX         : out   std_logic;   -- a2-7
		RX         : in    std_logic;   -- a2-8

		-- FPGA Board
		nRESET     : in    std_logic;	
		step_pb    : in    std_logic;
		mode_sw    : in    std_logic;
		page_led   : out   std_logic;
		LED        : out   std_logic_vector(7 downto 0);
		DISP       : out   sseg
	);
end RC2014_fpga;

architecture struct of RC2014_fpga is

	-- Inputs
	signal CPU_clk   : std_logic;
	signal CPU_nINT  : std_logic;
	signal CPU_nWAIT : std_logic;

	-- Outputs
	signal CPU_nM1   : std_logic;
	signal CPU_nMREQ : std_logic;
	signal CPU_nIORQ : std_logic;
	signal CPU_nRD   : std_logic;
	signal CPU_nWR   : std_logic;

	signal CPU_A   : std_logic_vector(15 downto 0);
	signal CPU_D_O : std_logic_vector(7 downto 0);
	signal CPU_D_I : std_logic_vector(7 downto 0);

	signal MA : std_logic_vector(18 downto 14) := (others => '0');

	signal ROM_nCS : std_logic := '1';

	signal MEM_nWR : std_logic := '1';
	signal MEM_nRD : std_logic := '1';
	signal RAM_nCS : std_logic := '1';

	signal IO_nWR : std_logic := '1';
	signal IO_nRD : std_logic := '1';

	signal UART_clk : std_logic;
	signal UART_D   : std_logic_vector(7 downto 0);
	signal UART_nCS : std_logic := '1';
	
	signal LED_nCS : std_logic;

begin

	stepper : ENTITY work.single_step
		PORT MAP(
			clk     => clk,
			reset   => not nRESET,
			step_pb => step_pb,
			nM1     => CPU_nM1,
			mode_sw => mode_sw,
			nWait   => CPU_nWAIT
		);

	-- Display address and data lines on seven seg display
	display_0 : entity work.display
		port map(
			clk   => clk,
			nReset => nRESET,
			A     => CPU_A,
			D     => CPU_D_O,
			HEX   => DISP
		);

	clock_inst : entity work.fracn_73728
		port map(
			clock     => clk,
			output_50 => CPU_clk
		);

--	clock_inst : entity work.fracn_10
--	port map(
--		clock     => clk,
--			output_50 => CPU_clk
--	);

	UART_clk <= CPU_clk;

	-- T80 CPU
	cpu : entity work.T80s
		generic map(Mode => 1, T2Write => 1, IOWait => 0)
		port map(
			RESET_n => nRESET,
			CLK_n   => CPU_clk,
			WAIT_n  => CPU_nWAIT,
			INT_n   => CPU_nINT,
			NMI_n   => '1',
			BUSRQ_n => '1',
			M1_n    => CPU_nM1,
			MREQ_n  => CPU_nMREQ,
			IORQ_n  => CPU_nIORQ,
			RD_n    => CPU_nRD,
			WR_n    => CPU_nWR,
			RFSH_n  => open,
			HALT_n  => open,
			BUSAK_n => open,
			A       => CPU_A,
			DI      => CPU_D_I,
			DO      => CPU_D_O
		);

	-- Implement 16K page memory model
	pager : entity work.RAM_ROM_Pager
		port map(
			nRST     => nRESET,
			A        => CPU_A,
			D        => CPU_D_O,
			nIORQ    => CPU_nIORQ,
			nM1      => CPU_nM1,
			nMREQ    => CPU_nMREQ,
			nWR      => CPU_nWR,
			nROM_CE  => ROM_nCS,
			nRAM_CE  => RAM_nCS,
			MA       => MA,
			page_led => page_led
		);

	MEM_nWR <= CPU_nWR or CPU_nMREQ;
	MEM_nRD <= CPU_nRD or CPU_nMREQ;

	-- 
	A <= MA & CPU_A(13 downto 0);
	D <= CPU_D_O when MEM_nWR = '0' else (others => 'Z');

	CPU_D_I <= UART_D when UART_nCS = '0'
	           else D when ROM_nCS = '0' or RAM_nCS = '0'
	           else x"FF";

	uart1 : entity work.acia6850
		port map(
			clk      => clk,            -- System Clock
			rst      => not nRESET,     -- Reset input (active high)
			cs       => not UART_nCS,   -- miniUART Chip Select
			addr     => CPU_A(0),       -- Register Select
			rw       => CPU_nWR,        -- Read / Not Write  1 - Read, 0 - Write
			data_in  => CPU_D_O,        -- Data Bus In 
			data_out => UART_D,         -- Data Bus Out
			irq      => CPU_nINT,       -- Interrupt Request out

			RxC      => UART_clk,       -- Receive Baud Clock
			TxC      => UART_clk,       -- Transmit Baud Clock
			RxD      => RX,             -- Receive Data
			TxD      => TX,             -- Transmit Data
			DCD_n    => '0',            -- Data Carrier Detect
			CTS_n    => nCTS,           -- Clear To Send
			RTS_n    => nRTS            -- Request To send
		);

	IO_nRD <= CPU_nRD or CPU_nIORQ;
	IO_nWR <= CPU_nWR or CPU_nIORQ;

	-- Select Serial Channel A - 2 Bytes $80-$81
	UART_nCS <= '0' when CPU_A(7 downto 1) = "1000000" and (IO_nWR = '0' or IO_nRD = '0') else '1';

	
	-- Write to LED's at port 0
	LED_nCS <= '0' when IO_nWR = '0' and CPU_A(7 downto 0) = x"00" else '1';
	
	leds : entity work.gen_register
		port map(
			clk    => clk,
			nRESET => nRESET,
			nENA   => LED_nCS,			
			D		 => CPU_D_O,
			Q      => LED
		);

	-- Memory Control signals
	nWR     <= MEM_nWR;
	nRD     <= MEM_nRD;
	ROM_nCE <= ROM_nCS;
	RAM_nCE <= RAM_nCS;

	nRESET_EXT <= nRESET;

end;
