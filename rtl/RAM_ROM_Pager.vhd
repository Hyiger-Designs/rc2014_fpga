library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM_ROM_Pager is
	port(
		nRST     : in  std_logic;
		A        : in  std_logic_vector(15 downto 0);
		D        : in  std_logic_vector(7 downto 0);
		nIORQ    : in  std_logic;
		nM1      : in  std_logic;
		nMREQ    : in  std_logic;
		nWR      : in  std_logic;
		nROM_CE  : out std_logic;
		nRAM_CE  : out std_logic;
		MA       : out std_logic_vector(18 downto 14);
		page_led : out std_logic
	);

	-- Page Registers addresses are 0x78-0x7B = 0111 10xx
	constant PAGE_ADDR : std_logic_vector(7 downto 2) := "011110";

	-- Page Enable port address is 0x7C = 01111100
	constant PAGE_ENA_ADDR : std_logic_vector(7 downto 0) := x"7C";

end RAM_ROM_Pager;

architecture struct of RAM_ROM_Pager is

	signal nPageRegWR : std_logic;
	signal nPageEnaWR : std_logic;
	signal nPageEna   : std_logic;
	signal page       : std_logic_vector(5 downto 0) := (others => '0');
	signal nIOWR      : std_logic;

begin

	--nIOWR <= nIORQ or nWR or not nM1;
   nIOWR <= '0' when nM1 = '1' and nIORQ = '0' and nWR = '0' else '1';
	--IORD <= '1' when M1 = '1' and IORQ = '0' and RD = '0' else '0';

	-- Page Register ports: x78 - x7B
	nPageRegWR <= '0' when nIOWR = '0' and A(7 downto 2) = PAGE_ADDR else '1';

	-- Page Enable port x7C
	nPageEnaWR <= '0' when nIOWR = '0' and A(7 downto 0) = PAGE_ENA_ADDR else '1';

	-- Toggle Paging: port x7C
	page_rd : process(D(0), nRST, nPageEnaWR)
	begin
		if (nRST = '0') then
			nPageEna <= '1';
		elsif (nPageEnaWR = '0') then
			nPageEna <= not D(0);
		end if;
	end process;

	-- 4 x 6-bit page registers:

	-- ROMWMW initializes as follows: 
	-- Bank 0 : Page 0, 0x00, ROM 0x00000 - 0x03FFF
	-- Bank 1 : Page 1, 0x01, ROM 0x04000 - 0x07FFF

	-- Bank 2 : Page 62,0x3E, RAM 0x78000 - 0x7BFFF
	-- Bank 3 : Page 63,0x3F, RAM 0x7C000 - 0x7FFFF

	page_registers : ENTITY work.DPRAM
		PORT MAP(
			nWR_Ena => nPageRegWR,
			RA      => A(15 downto 14), -- selects register to read
			WA      => A(1 downto 0),   -- selects register to write
			D       => D(5 downto 0),   -- 6-bit input data
			Q       => page(5 downto 0) -- 6-bit output data
		);

	-- If bit 6 is set then select ram otherwise select ROM
	--nRAM_CE <= not page(5) or nMREQ;
	--nROM_CE <= page(5) or nMREQ;
	nROM_CE <= '0' when page(5) = '0' and nMREQ = '0' else '1';
	nRAM_CE <= '0' when page(5) = '1' and nMREQ = '0' else '1';
	
	MA <= page(4 downto 0) when nPageEna = '0' else (others => '0');

	page_led <= nPageEna;
end;
