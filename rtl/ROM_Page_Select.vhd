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
		Page        : out std_logic
	);

end entity ROM_Page_Select;

architecture RTL of ROM_Page_Select is
	signal ADDR      : std_logic_vector(15 downto 0);
	signal nPage_LED : std_logic_vector(7 downto 0);
	signal nPage     : std_logic := '0';

	component CPM_BASIC
		port(
			a    : in  std_logic_vector(12 downto 0);
			clk  : in  std_logic;
			qspo : out std_logic_vector(7 downto 0)
		);
	end component;

	component SCM_V100_S3_SCS3_32K
		port(
			clka  : in  std_logic;
			addra : in  std_logic_vector(14 downto 0);
			douta : out std_logic_vector(7 downto 0)
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
				a    => A(12 downto 0),
				clk  => clk,
				qspo => D
			);

		nCS <= '0' when A(15 downto 13) = "000" and nPage = '0' else '1';

	end generate cpm;

	-- Select Steve cousins SCM S3
	scm : if rom = 1 generate
		rom32k : SCM_V100_S3_SCS3_32K
			port map(
				addra => A(14 downto 0),
				clka  => clk,
				douta => D
			);
		nCS      <= '0' when A(15) = '0' and nPage = '0' else '1';
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
