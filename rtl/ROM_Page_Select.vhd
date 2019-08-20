library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ROM_Page_Select is
	generic(
		rom       : natural                      := 0; -- 0 = SCM, R0001009 - CPM/Basic
		page_port : std_logic_vector(7 downto 0) := x"38"
	);
	port(
		clk         : in  std_logic;
		nReset      : in  std_logic;
		page_select : in  std_logic_vector(2 downto 0);
		nWR         : in  std_logic;
		A           : in  std_logic_vector(15 downto 0);
		D           : out std_logic_vector(7 downto 0);
		nCS         : out std_logic;
		Page        : out std_logic;
		page_LED    : out std_logic_vector(7 downto 0)
	);

end entity ROM_Page_Select;

architecture RTL of ROM_Page_Select is
	signal ADDR      : std_logic_vector(15 downto 0);
	signal nPage_LED : std_logic_vector(7 downto 0);
	signal nPage     : std_logic := '0';

	component CPM_BASIC
		port(
			address    : in  std_logic_vector(12 downto 0);
			clock  : in  std_logic;
			q : out std_logic_vector(7 downto 0)
		);
	end component;

	component SCM_V100_S3_SCS3_32K
		port(
			clock  : in  std_logic;
			address : in  std_logic_vector(14 downto 0);
			q : out std_logic_vector(7 downto 0)
		);
	end component;

	component R0001009
		port(
			clka  : in  std_logic;
			addra : in  std_logic_vector(15 downto 0);
			douta : out std_logic_vector(7 downto 0)
		);
	end component;

begin

	--	Select Grant Searle's CPM Monitor
	cpm : if rom = 0 generate
		rom8k : CPM_BASIC
			PORT MAP(
				address    => A(12 downto 0),
				clock  => clk,
				q => D
			);

		nCS <= '0' when A(15 downto 13) = "000" and nPage = '0' else '1';

		page_LED <= not nPage_LED when nPage = '0' else (others => '0');
	end generate cpm;

	-- Select Steve cousins SCM S3
	scm : if rom = 1 generate
		rom32k : SCM_V100_S3_SCS3_32K
			port map(
				address => A(14 downto 0),
				clock  => clk,
				q => D
			);
		nCS      <= '0' when A(15) = '0' and nPage = '0' else '1';
		page_LED <= (0 => '1', others => '0');

	end generate scm;

	-- Select RC2014 Paged Rom, currently hardwired to 8K Pages
	rc2014 : if rom = 2 generate

		-- Select Page 1 - 8
		ADDR <= page_select & A(12 downto 0);

		-- Currently this ROM is the only one compatible with the 6850 UART
		rom64k : R0001009
			port map(
				clka  => clk,
				addra => ADDR(15 downto 0),
				douta => D
			);

		-- Start RAM above the 8K page
		nCS <= '0' when A(15 downto 13) = "000" and nPage = '0' else '1';

		-- LED's 1 - 8 denote which page was selected
		led_select : entity work.decoder_3x8
			port map(
				i => page_select,
				y => nPage_LED
			);

		page_LED <= not nPage_LED when nPage = '0' else (others => '0');
	end generate rc2014;

	-- Handle paging out ROM at port 0x38
	process(nReset, nWR)
	begin
		if (nReset = '0') then
			nPage <= '0';
		elsif (rising_edge(nWR)) then
			if A(7 downto 0) = page_port then
				nPage <= '1';
			end if;
		end if;
	end process;

	Page <= nPage;

end architecture RTL;
