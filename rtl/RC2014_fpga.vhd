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
	generic(
		cpu : natural := 0;     -- 0 = t80, 1 = tv80
		rom : natural := 0		-- 0 = CP/M Monitor, 1 = SCM, 2 = R0001009
	);
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
--		nRST2           : in    std_logic; -- 20
--		clk2            : in    std_logic; -- 21
		nBUSAK          : out   std_logic; -- 22
		nHALT           : out   std_logic; -- 23
		nBUSRQ          : in    std_logic; -- 24
		nWAIT           : in    std_logic; -- 25
		nNMI            : in    std_logic; -- 26
--		TX2             : out   std_logic; -- 35
--		RX2             : in    std_logic; -- 36

		-- FPGA Board specific pins

		rom_page_select : in    std_logic_vector(2 downto 0);
		rom_page_LED    : out   std_logic_vector(7 downto 0);
		RTS             : out   std_logic;
		SD_MOSI         : out   std_logic;
		SD_MISO         : in    std_logic;
		SD_CS           : out   std_logic;
		SD_SCLK         : out   std_logic;
		SD_LED          : out   std_logic
	);
end RC2014_fpga;

architecture struct of RC2014_fpga is
	-- Frequency of board clock in Hz
	constant BRD_FREQUENCY  : Real := 50000000.0;
	constant CPU_FREQUENCY  : Real := 7372800.0;
	constant UART_FREQUENCY : Real := 1843200.0;
	constant SD_FREQUENCY   : Real := 1000000.0;

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

	signal RAM_D    : std_logic_vector(7 downto 0);
	signal RAM_nWR  : std_logic := '1';
	signal RAM_nRD  : std_logic := '1';
	signal RAM_nCS  : std_logic := '1';
	signal RAM_WE   : std_logic;
		
	signal IO_nWR   : std_logic := '1';
	signal IO_nRD   : std_logic := '1';
	
	signal UART_clk : std_logic;
	signal UART_D   : std_logic_vector(7 downto 0);
	signal UART_nCS : std_logic := '1';
	signal UART_RST : std_logic;
	signal UART_CS  : std_logic;
	
	signal SD_clk   : std_logic;
	signal SD_D     : std_logic_vector(7 downto 0);
	signal SD_nCS   : std_logic := '1';
	signal SD_nWR	 : std_logic;
	signal SD_nRD	 : std_logic;
	
	--signal OE : std_logic_vector(7 downto 0);
	--signal D               :  std_logic_vector(7 downto 0);
	signal reset : std_logic := '0';

	component tv80s
		generic(
			Mode    : integer := 0;     -- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
			T2Write : integer := 0;     -- 0 => WR_n active in T3, /=0 => WR_n active in T2
			IOWait  : integer := 1      -- 0 => Single cycle I/O, 1 => Std I/O cycle
		);
		port(
			RESET_n : in  std_logic;
			CLK     : in  std_logic;
			WAIT_n  : in  std_logic;
			INT_n   : in  std_logic;
			NMI_n   : in  std_logic;
			BUSRQ_n : in  std_logic;
			M1_n    : out std_logic;
			MREQ_n  : out std_logic;
			IORQ_n  : out std_logic;
			RD_n    : out std_logic;
			WR_n    : out std_logic;
			RFSH_n  : out std_logic;
			HALT_n  : out std_logic;
			BUSAK_n : out std_logic;
			A       : out std_logic_vector(15 downto 0);
			DI      : in  std_logic_vector(7 downto 0);
			dout    : out std_logic_vector(7 downto 0)
		);
	end component;

begin
	reset <= not nRST;

	cpm_basic_rom: if rom = 0 generate
		clocks_inst : entity work.clocks PORT MAP (
			areset	 => reset,
			inclk0	 => clk,
			c0	 => CPU_clk,
			c1	 => UART_clk,
			c2	 => SD_clk
		);
	end generate cpm_basic_rom;

	-- Otherwise UART is set to 7.3728Mhz
	c_clk : if rom /= 0 generate
		clocks_inst : entity work.clocks PORT MAP (
			areset	 => reset,
			inclk0	 => clk,
			c0	 => CPU_clk,
			c2	 => SD_clk
		);
		UART_clk <= CPU_clk;
	end generate c_clk;


	-- T80 CPU
	t80s : if cpu = 0 generate
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
	end generate t80s;

	-- Tv80 CPU
	tv80 : if cpu = 1 generate
		cpu : tv80s
			generic map(mode => 1, t2write => 1, iowait => 0)
			port map(
				reset_n => nRST,
				clk     => CPU_clk,
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
				dout    => CPU_D_O
			);
	end generate tv80;


	D <= UART_D when UART_nCS = '0'
		else SD_D when SD_nCS = '0'
		else ROM_D when ROM_nCS = '0'
		else RAM_D when RAM_nCS = '0'
		else CPU_D_O when CPU_nWR = '0'
		else (others => 'Z');

	CPU_D_I <= D;

	RAM_WE <= not (RAM_nWR or RAM_nCS);
	-- 64K Generic (Non vendor specific Single Port RAM)
	ram64k : entity work.single_port_ram
		port map(
			clock   => clk,
			we      => RAM_WE,
			address => CPU_A(15 downto 0),
			data    => CPU_D_O,
			q       => RAM_D
		);

	-- Selection of roms available, defaults to CPM Monitor
	-- 0 - Grant Searle's 8K CP/M Monitor
	-- 1 - Steve Cousin's 32K SCM v 1.0 S3
	-- 2 - RC2014 64K Paged ROM (fixed at 8K pages) ver R0001009
	--     use the rom_page_select[0-3] switches to select page
	rom_select : entity work.ROM_Page_Select
		generic map(rom => rom)         -- Select SCM ROM
		port map(
			clk         => clk,
			nReset      => nRST,
			page_select => rom_page_select,
			nWR         => IO_nWR,
			A           => CPU_A,
			D           => ROM_D,
			nCS         => ROM_nCS,
			Page        => Page,
			page_LED    => rom_page_LED
		);

	UART_RST <= not nRST;
	UART_CS  <= not UART_nCS;

	uart1 : entity work.acia6850
		port map(
			clk      => clk,            -- System Clock
			rst      => UART_RST,       -- Reset input (active high)
			cs       => UART_CS,        -- miniUART Chip Select
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
			CTS_n    => '0',            -- Clear To Send
			RTS_n    => rts             -- Request To send
		);

	SD_nWR <= SD_nCS or IO_nRD;
	SD_nRD <= SD_nCS or IO_nWR;
		
	sd1 : entity work.sd_controller
		port map(
			sdCS     => SD_CS,
			sdMOSI   => SD_MOSI,
			sdMISO   => SD_MISO,
			sdSCLK   => SD_SCLK,
			n_wr     => SD_nWR,
			n_rd     => SD_nRD,
			n_reset  => nRST,
			dataIn   => CPU_D_O,
			dataOut  => SD_D,
			regAddr  => CPU_A(2 downto 0),
			driveLED => SD_LED,
			clk      => SD_clk          -- twice the spi clk
		);

	-- 8 Bytes $88-$8F 10001---
	SD_nCS <= '0' when CPU_A(7 downto 3) = "10001" and (IO_nWR = '0' or IO_nRD = '0') else '1';
		
	-- Serial Channel A - 2 Bytes $80-$81
	UART_nCS <= '0' when CPU_A(7 downto 1) = "1000000" and (IO_nWR = '0' or IO_nRD = '0') else '1';

	-- Control Bus

	RAM_nCS <= not ROM_nCS;
	RAM_nRD <= CPU_nRD or CPU_nMREQ;
	RAM_nWR <= CPU_nWR or CPU_nMREQ;

	IO_nRD <= CPU_nRD or CPU_nIORQ;
	IO_nWR <= CPU_nWR or CPU_nIORQ;

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
