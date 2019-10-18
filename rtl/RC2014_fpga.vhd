
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
		-- Z80_BUS
		clk          : in    std_logic; -- 
		nRESET_PB	 : in    std_logic;
		nRESET       : out    std_logic; -- 2
		
		RAM_nCE      : out   std_logic; -- 4
		ROM_nCE      : out   std_logic; -- 38
		IDE_nCE      : out   std_logic; -- 40
		nRD          : out   std_logic; -- 19
		nWR          : out   std_logic; -- 20

		A            : out   std_logic_vector(18 downto 0); -- 5-10,13-18,31-37
		D            : inout std_logic_vector(7 downto 0); -- 21-28

		-- UART/FTDI
		nRTS         : out   std_logic; -- a2-5
		nCTS         : in    std_logic; -- a2-6
		TX           : out   std_logic; -- a2-7
		RX           : in    std_logic; -- a2-8

		-- FPGA Board specific pins
		rom_page_led : out   std_logic;
		LED          : out   std_logic_vector(7 downto 0);
		step_pb      : in    std_logic;
		mode_sw      : in    std_logic;
		--		SD_MOSI      : out   std_logic;
		--		SD_MISO      : in    std_logic;
		--		SD_CS        : out   std_logic;
		--		SD_SCLK      : out   std_logic;
		--		SD_LED       : out   std_logic;
		HEX          : out   sseg
	);
end RC2014_fpga;

architecture struct of RC2014_fpga is

	-- Inputs
	signal CPU_clk    : std_logic;
	signal CPU_nINT   : std_logic;
	signal CPU_nNMI   : std_logic;
	signal CPU_nBUSRQ : std_logic;
	signal CPU_nWAIT  : std_logic;
	-- Outputs
	signal CPU_nM1    : std_logic;
	signal CPU_nMREQ  : std_logic;
	signal CPU_nIORQ  : std_logic;
	signal CPU_nRD    : std_logic;
	signal CPU_nWR    : std_logic;
	signal CPU_nRFSH  : std_logic;
	signal CPU_nHALT  : std_logic;
	signal CPU_nBUSAK : std_logic;

	signal CPU_A   : std_logic_vector(15 downto 0);
	-- Tri-state
	signal CPU_D_O : std_logic_vector(7 downto 0);
	signal CPU_D_I : std_logic_vector(7 downto 0);

	signal ROM_D   : std_logic_vector(7 downto 0);
	signal ROM_nCS : std_logic := '1';
	signal nPage   : std_logic := '0';

	signal MEM_nWR : std_logic := '1';
	signal MEM_nRD : std_logic := '1';
	signal RAM_nCS : std_logic := '1';

	signal IO_nWR : std_logic := '1';
	signal IO_nRD : std_logic := '1';

	signal UART_clk : std_logic;
	signal UART_D   : std_logic_vector(7 downto 0);
	signal UART_nCS : std_logic := '1';
	signal UART_CS  : std_logic;

	--	signal SD_clk : std_logic;
	--	signal SD_D   : std_logic_vector(7 downto 0);
	--	signal SD_nCS : std_logic := '1';
	--	signal SD_nWR : std_logic;
	--	signal SD_nRD : std_logic;

	signal reset : std_logic := '0';

begin
	reset <= not nRESET_PB;

	stepper : ENTITY work.single_step
		PORT MAP(
			clk     => clk,
			reset   => reset,
			step_pb => step_pb,
			nM1     => CPU_nM1,
			mode_sw => mode_sw,
			nWait   => CPU_nWAIT
		);

	display_0 : entity work.display
		port map(clk => clk, reset => reset, A => CPU_A, D => CPU_D_O, HEX => HEX);

	clock_inst : entity work.fracn_73728
		port map(
			clock     => clk,
			output_50 => CPU_clk
		);

	UART_clk <= CPU_clk;

	CPU_nNMI   <= '1';
	CPU_nBUSRQ <= '1';

	IDE_nCE <= '0';
	
	-- T80 CPU
	cpu : entity work.T80s
		generic map(Mode => 1, T2Write => 1, IOWait => 0)
		port map(
			RESET_n => nRESET_PB,
			CLK_n   => CPU_clk,
			WAIT_n  => CPU_nWAIT,
			INT_n   => CPU_nINT,
			NMI_n   => CPU_nNMI,
			BUSRQ_n => CPU_nBUSRQ,
			M1_n    => CPU_nM1,
			MREQ_n  => CPU_nMREQ,
			IORQ_n  => CPU_nIORQ,
			RD_n    => CPU_nRD,
			WR_n    => CPU_nWR,
			RFSH_n  => CPU_nRFSH,
			HALT_n  => CPU_nHALT,
			BUSAK_n => CPU_nBUSAK,
			A       => CPU_A,
			DI      => CPU_D_I,
			DO      => CPU_D_O
		);

	A <= "000" & CPU_A;
	D <= CPU_D_O when MEM_nWR = '0' else (others => 'Z');

	CPU_D_I <= UART_D when UART_nCS = '0'
				  else ROM_D when ROM_nCS = '0'
	           else D when RAM_nCS = '0' -- or ROM_nCS = '0'
	           else x"FF";

	nWR     <= MEM_nWR;
	nRD     <= MEM_nRD;
	RAM_nCE <= RAM_nCS;
	ROM_nCE <= ROM_nCS;

	rom32k : entity work.SCM_V100_S3_SCS3_32K
		port map(
			address => CPU_A(14 downto 0),
			rden => RAM_nCS,
			clock  => clk,
			q => ROM_D
		);

	UART_CS  <= not UART_nCS;

	uart1 : entity work.acia6850
		port map(
			clk      => clk,            -- System Clock
			rst      => reset,       -- Reset input (active high)
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
			CTS_n    => nCTS,           -- Clear To Send
			RTS_n    => nRTS            -- Request To send
		);

	--	SD_nWR <= SD_nCS or IO_nRD;
	--	SD_nRD <= SD_nCS or IO_nWR;
	--
	--	sd1 : entity work.sd_controller
	--		port map(
	--			sdCS     => SD_CS,
	--			sdMOSI   => SD_MOSI,
	--			sdMISO   => SD_MISO,
	--			sdSCLK   => SD_SCLK,
	--			n_wr     => SD_nWR,
	--			n_rd     => SD_nRD,
	--			n_reset  => nRESET,
	--			dataIn   => CPU_D_O,
	--			dataOut  => SD_D,
	--			regAddr  => CPU_A(2 downto 0),
	--			driveLED => SD_LED,
	--			clk      => SD_clk          -- twice the spi clk
	--		);

	-- Select SD Card 8 Bytes $88-$8F 10001---
	--	SD_nCS <= '0' when CPU_A(7 downto 3) = "10001" and (IO_nWR = '0' or IO_nRD = '0') else '1';

	-- Select Serial Channel A - 2 Bytes $80-$81
	UART_nCS <= '0' when CPU_A(7 downto 1) = "1000000" and (IO_nWR = '0' or IO_nRD = '0') else '1';

	-- Write to LED's at port 0
	leds : process(nRESET_PB, clk)
	begin
		if (nRESET_PB = '0') then
			LED <= (others => '0');
		elsif (rising_edge(clk)) then
			if IO_nWR = '0' and CPU_A(7 downto 0) = x"00" then
				LED <= CPU_D_O;
			end if;
		end if;
	end process;

	-- Handle paging out ROM at port 0x38
	process(nRESET_PB, clk)
	begin
		if (nRESET_PB = '0') then
			nPage <= '0';
		elsif (rising_edge(clk)) then
			if IO_nWR = '0' and CPU_A(7 downto 0) = x"38" then
				nPage <= '1';
			end if;
		end if;
	end process;

	rom_page_led <= nPage;

	MEM_nRD <= CPU_nRD or CPU_nMREQ;
	MEM_nWR <= CPU_nWR or CPU_nMREQ;

	IO_nRD <= CPU_nRD or CPU_nIORQ;
	IO_nWR <= CPU_nWR or CPU_nIORQ;

	-- Control Bus
	-- ROM located from 0000-7FFF
	ROM_nCS <= '0' when CPU_A(15) = '0' and nPage = '0' else '1';
	RAM_nCS <= not ROM_nCS;

	nRESET <= nRESET_PB;

end;
