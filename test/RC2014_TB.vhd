library IEEE;
use IEEE.std_logic_1164.all;
--use work.StimLog.all;

entity RC2014_TB is
end entity RC2014_TB;

architecture behaviour of RC2014_TB is

	signal nRST		: std_logic;
	signal Clk			: std_logic := '0';
	signal nNMI		: std_logic := '1';
	signal nINT		: std_logic := '1';
	signal TX			: std_logic;
	signal RX			: std_logic := '1';
	signal RTS			: std_logic;

component AsyncStim is
	generic(
		FileName		: string;
		Baud			: integer;
		InterCharDelay	: time := 0 ns;
		Bits			: integer := 8;		-- Data bits
		Parity			: boolean := false;	-- Enable Parity
		P_Odd_Even_n	: boolean := false	-- false => Even Parity, true => Odd Parity
	);
	port(
		TXD				: out std_logic
	);
end component;

component AsyncLog is
	generic(
		FileName		: string;
		Baud			: integer;
		Bits			: integer := 8;		-- Data bits
		Parity			: boolean := false;	-- Enable Parity
		P_Odd_Even_n	: boolean := false	-- false => Even Parity, true => Odd Parity
	);
	port(
		RXD				: in std_logic
	);
end component;

begin

	ni : entity work.RC2014_fpga
		port map(
			nRST => nRST,
			clk => Clk,
			nINT =>  '1',
			nNMI => '1',
			nWAIT =>  '1',
			nBUSRQ => '1',
			RX => RX,
			TX => TX,
			RTS => RTS,
			rom_page_select => "000",
			SD_MISO => '1'
);

	as1 : AsyncStim generic map(FileName => "RX_Cmd.txt", InterCharDelay => 0 us, Baud => 115200, Bits => 8)
				port map(RX);

	al1 : AsyncLog generic map(FileName => "RX_Log.txt", Baud => 115200, Bits => 8)
				port map(TX);

	nRST <= '0', '1' after 1 us;

	-- 50 MHz clock
	Clk <= not Clk after 10 ns;

end;
