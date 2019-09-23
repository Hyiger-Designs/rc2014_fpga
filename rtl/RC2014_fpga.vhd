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
		clk          : in    std_logic; -- 21
		nRESET       : in    std_logic; -- 20

		nM1          : out   std_logic; -- 19
		nMREQ        : out   std_logic; -- 23
		nWR          : out   std_logic; -- 24
		nRD          : out   std_logic; -- 25
		nIORQ        : out   std_logic; -- 26

		A            : out   std_logic_vector(15 downto 0); -- 1 - 16
		D            : inout std_logic_vector(7 downto 0); -- 27 - 34

		-- UART/FTDI
		RTS          : out   std_logic;
		TX           : out   std_logic; -- 35
		RX           : in    std_logic; -- 36

		-- FPGA Board specific pins
		rom_page_led : out   std_logic;
		LED          : out   std_logic_vector(7 downto 0);
		step_pb      : in    std_logic;
		mode_sw      : in    std_logic;
		SD_MOSI      : out   std_logic;
		SD_MISO      : in    std_logic;
		SD_CS        : out   std_logic;
		SD_SCLK      : out   std_logic;
		SD_LED       : out   std_logic;
		
		-- 7 Segment Displays
		HEX0         : out   std_logic_vector(7 downto 0);
		HEX1         : out   std_logic_vector(7 downto 0);
		HEX2         : out   std_logic_vector(7 downto 0);
		HEX3         : out   std_logic_vector(7 downto 0);
		HEX4         : out   std_logic_vector(7 downto 0);
		HEX5         : out   std_logic_vector(7 downto 0)
	);
end RC2014_fpga;

architecture struct of RC2014_fpga is

	-- Inputs
	signal CPU_clk    : std_logic;
	signal CPU_nINT   : std_logic := '1';
	signal CPU_nNMI   : std_logic := '1';
	signal CPU_nBUSRQ : std_logic := '1';
	signal CPU_nWAIT  : std_logic := '1';
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

	signal RAM_D   : std_logic_vector(7 downto 0);
	signal RAM_nWR : std_logic := '1';
	signal RAM_nRD : std_logic := '1';
	signal RAM_nCS : std_logic := '1';
	signal RAM_WE  : std_logic;

	signal IO_nWR : std_logic := '1';
	signal IO_nRD : std_logic := '1';

	signal UART_clk : std_logic;
	signal UART_D   : std_logic_vector(7 downto 0);
	signal UART_nCS : std_logic := '1';
	signal UART_RST : std_logic;
	signal UART_CS  : std_logic;

	signal SD_clk : std_logic;
	signal SD_D   : std_logic_vector(7 downto 0);
	signal SD_nCS : std_logic := '1';
	signal SD_nWR : std_logic;
	signal SD_nRD : std_logic;

	signal reset : std_logic := '0';

	component SCM_V100_S3_SCS3_32K
		port(
			clka  : in  std_logic;
			addra : in  std_logic_vector(14 downto 0);
			douta : out std_logic_vector(7 downto 0)
		);
	end component;

begin
	reset <= not nRESET;

	stepper : ENTITY work.single_step
		PORT MAP(
			clk     => clk,
			reset   => reset,
			step_pb => step_pb,
			nM1     => CPU_nM1,
			mode_sw => mode_sw,
			nWait   => CPU_nWAIT
		);

	sseg_unit_0 : entity work.hex_to_sseg
		port map(clk => clk, reset => reset, hex => CPU_D_O(3 downto 0), dp => '0', sseg_o => HEX0);
	sseg_unit_1 : entity work.hex_to_sseg
		port map(clk => clk, reset => reset, hex => CPU_D_O(7 downto 4), dp => '0', sseg_o => HEX1);

	sseg_unit_2 : entity work.hex_to_sseg
		port map(clk => clk, reset => reset, hex => CPU_A(3 downto 0), dp => '0', sseg_o => HEX2);
	sseg_unit_3 : entity work.hex_to_sseg
		port map(clk => clk, reset => reset, hex => CPU_A(7 downto 4), dp => '0', sseg_o => HEX3);
	sseg_unit_4 : entity work.hex_to_sseg
		port map(clk => clk, reset => reset, hex => CPU_A(11 downto 8), dp => '0', sseg_o => HEX4);
	sseg_unit_5 : entity work.hex_to_sseg
		port map(clk => clk, reset => reset, hex => CPU_A(15 downto 12), dp => '0', sseg_o => HEX5);

	-- Otherwise UART is set to 7.3728Mhz
	clocks_inst : entity work.clocks
		PORT MAP(
			areset => reset,
			inclk0 => clk,
			c0     => CPU_clk,
			c2     => SD_clk
		);
	UART_clk <= CPU_clk;

	-- T80 CPU
	cpu : entity work.t80s
		generic map(mode => 1, t2write => 1, iowait => 0)
		port map(
			reset_n => nRESET,
			clk_n   => CPU_clk,
			wait_n  => CPU_nWAIT,
			int_n   => CPU_nINT,
			nmi_n   => CPU_nNMI,
			busrq_n => CPU_nBUSRQ,
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

	rom32k : SCM_V100_S3_SCS3_32K
		port map(
			addra => CPU_A(14 downto 0),
			clka  => clk,
			douta => ROM_D
		);

	-- ROM located from 0000-7FFF
	ROM_nCS <= '0' when CPU_A(15) = '0' and nPage = '0' else '1';

	UART_RST <= not nRESET;
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
			n_reset  => nRESET,
			dataIn   => CPU_D_O,
			dataOut  => SD_D,
			regAddr  => CPU_A(2 downto 0),
			driveLED => SD_LED,
			clk      => SD_clk          -- twice the spi clk
		);

	-- Select SD Card 8 Bytes $88-$8F 10001---
	SD_nCS <= '0' when CPU_A(7 downto 3) = "10001" and (IO_nWR = '0' or IO_nRD = '0') else '1';

	-- Select Serial Channel A - 2 Bytes $80-$81
	UART_nCS <= '0' when CPU_A(7 downto 1) = "1000000" and (IO_nWR = '0' or IO_nRD = '0') else '1';

	-- Write to LED's at port 0
	leds : process(nReset, clk)
	begin
		if (nReset = '0') then
			LED <= (others => '0');
		elsif (rising_edge(clk)) then
			if IO_nWR = '0' and CPU_A(7 downto 0) = x"00" then
				LED <= CPU_D_O;
			end if;
		end if;
	end process;

	-- Handle paging out ROM at port 0x38
	process(nReset, clk)
	begin
		if (nReset = '0') then
			nPage <= '0';
		elsif (rising_edge(clk)) then
			if IO_nWR = '0' and CPU_A(7 downto 0) = x"38" then
				nPage <= '1';
			end if;
		end if;
	end process;

	rom_page_led <= nPage;

	-- Control Bus

	RAM_nCS <= not ROM_nCS;
	RAM_nRD <= CPU_nRD or CPU_nMREQ;
	RAM_nWR <= CPU_nWR or CPU_nMREQ;

	IO_nRD <= CPU_nRD or CPU_nIORQ;
	IO_nWR <= CPU_nWR or CPU_nIORQ;

	A     <= CPU_A;
	nM1   <= CPU_nM1;
	nMREQ <= CPU_nMREQ;
	nWR   <= CPU_nWR;
	nRD   <= CPU_nRD;
	nIORQ <= CPU_nIORQ;

end;
