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
		cpu       : natural := 0 --0 = t80, 1 = tv80, 2 = a-z80
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
    signal RAM_WE   : std_logic;
	signal UART_D   : std_logic_vector(7 downto 0);
	signal UART_nWR : std_logic := '1';
	signal UART_nRD : std_logic := '1';
	signal UART_nCS : std_logic := '1';
    signal UART_RST  : std_logic;
   signal  UART_CS  : std_logic;
	
	signal OE : std_logic_vector(7 downto 0);
	--signal D               :  std_logic_vector(7 downto 0);
	
	
	component tv80s
		generic(
			Mode : integer := 0;	-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
			T2Write : integer := 0;	-- 0 => WR_n active in T3, /=0 => WR_n active in T2
			IOWait : integer := 1	-- 0 => Single cycle I/O, 1 => Std I/O cycle
		);
		port(
			RESET_n		: in std_logic;
			CLK		: in std_logic;
			WAIT_n		: in std_logic;
			INT_n		: in std_logic;
			NMI_n		: in std_logic;
			BUSRQ_n		: in std_logic;
			M1_n		: out std_logic;
			MREQ_n		: out std_logic;
			IORQ_n		: out std_logic;
			RD_n		: out std_logic;
			WR_n		: out std_logic;
			RFSH_n		: out std_logic;
			HALT_n		: out std_logic;
			BUSAK_n		: out std_logic;
			A			: out std_logic_vector(15 downto 0);
			DI			: in std_logic_vector(7 downto 0);
			dout			: out std_logic_vector(7 downto 0)
		);
	end component;
		
	component NextZ80
		port(
			DI : in std_logic_vector(7 downto 0);
			CLK: in std_logic;
			RESET: in std_logic;
			INT: in std_logic;
			NMI: in std_logic;
			WT: in std_logic;

			DO : out std_logic_vector(7 downto 0);
			ADDR: out std_logic_vector(15 downto 0);
			WR: out   std_logic;
			MREQ: out   std_logic;
			IORQ: out   std_logic;
			HALT: out   std_logic;
			M1: out   std_logic
		);
	end component;

	component z80_top_direct_n 
		port (
			nM1: out   std_logic;
			nMREQ: out   std_logic;
			nIORQ: out   std_logic;
			nRD: out   std_logic;
			nWR: out   std_logic;
			nRFSH: out   std_logic;
			nHALT: out   std_logic;
			nBUSACK: out   std_logic;

			nWAIT: in std_logic;
			nINT: in std_logic;
			nNMI: in std_logic;
			nRESET: in std_logic;
			nBUSRQ: in std_logic;

			CLK: in std_logic;
			A: out std_logic_vector(15 downto 0);
			D: inout std_logic_vector(7 downto 0)
		);
	end component;
	
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

	tv80 : if cpu = 1 generate
		cpu : tv80s
			generic map(mode => 1, t2write => 1, iowait => 0)
			port map(
				reset_n => nRST,
				clk   => CPU_clk,
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
				dout      => CPU_D_O
			);
	end generate tv80;
	
	
	t80ctrl : if cpu = 0 or cpu = 1 generate
		D <= UART_D when UART_nCS = '0'
			else ROM_D when ROM_nCS = '0'
			else RAM_D when RAM_nCS = '0'
			else CPU_D_O when CPU_nWR = '0'
			else (others => 'Z');

		CPU_D_I <= D;
	end generate t80ctrl;
	
	a_z80 : if cpu = 2 generate
		cpu : z80_top_direct_n 
			port map (
				nM1=> CPU_nM1,
				nMREQ=> CPU_nMREQ,
				nIORQ=> CPU_nIORQ,
				nRD=> CPU_nRD,
				nWR=> CPU_nWR,
				nRFSH=> CPU_nRFSH,
				nHALT=> CPU_nHALT,
				nBUSACK=> CPU_nBUSAK,

				nWAIT=> nWAIT,
				nINT=> CPU_nINT,
				nNMI=> nNMI,
				nRESET=> nRST,
				nBUSRQ=> nBUSRQ,

				CLK => CPU_clk,
				A => CPU_A,
				D => D
			);
				
		--OE <= (others => '1') when CPU_nWR = '1' else (others => '0');
		
		D <= UART_D  when UART_nCS = '0'
			else ROM_D   when ROM_nCS = '0'
			else RAM_D when RAM_nCS = '0'
			else CPU_D_O  when CPU_nWR = '0'
			else (others => 'Z');

		CPU_D_I <= D;
--		cpu_data_inst : entity work.cpu_data PORT MAP (
--			datain	 => CPU_D_I,
--			oe	 => OE,
--			dataio	 => D,
--			dataout	 => CPU_D_O
--		);
--
--		CPU_D_I <= UART_D when UART_nCS = '0'
--			else ROM_D when ROM_nCS = '0'
--			else RAM_D when RAM_nCS = '0'
--			else CPU_D_O when CPU_nWR = '0'
--			else (others => '1');
	end generate a_z80;
	
--	cpu :	NextZ80
--		port map (
--			DI => CPU_D_I,
--			CLK => CPU_clk,
--			RESET =>  nRST,
--			INT=> CPU_nINT,
--			NMI   =>  nNMI,
--			WT  => nWAIT,
--
--			DO => CPU_D_O,
--			ADDR => CPU_A,
--			WR => CPU_nWR,
--			MREQ => CPU_nMREQ,
--			IORQ=> CPU_nIORQ,
--			HALT=> CPU_nHALT,
--			M1=> CPU_nM1
--		);

	
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

    UART_RST <= not nRST;
    UART_CS <= not UART_nCS;
    
	uart : entity work.acia6850
		port map(
			clk      => clk,            -- System Clock
			rst      => UART_RST,       -- Reset input (active high)
			cs       => UART_CS,   -- miniUART Chip Select
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


	-- Control Bus
			
	RAM_nCS <= not ROM_nCS;
	RAM_nRD <= CPU_nRD or CPU_nMREQ;
	RAM_nWR <= CPU_nWR or CPU_nMREQ;

	-- Serial Channel A - 2 Bytes $80-$81
	UART_nCS <= '0' when CPU_A(7 downto 1) = "1000000" and (UART_nWR = '0' or UART_nRD = '0') else '1';
	UART_nRD <= CPU_nRD or CPU_nIORQ;
	UART_nWR <= CPU_nWR or CPU_nIORQ;

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
