library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- WIP - intended to be a simple implementation of the Zilog SIO/2
entity SIO is
	port(
		clk       : in  std_logic;
		rst       : in  std_logic;
		rx_tx_clk : in  std_logic;
		A         : in  std_logic_vector(15 downto 0);
		n_WR      : in  std_logic;
		D_O       : in  std_logic_vector(7 downto 0);
		rxd       : in  std_logic;
		txd       : out std_logic;
		D         : out std_logic_vector(7 downto 0);
		nCS       : in std_logic;
		n_int     : out std_logic;
		rts       : out std_logic
	);
end entity SIO;

architecture RTL of SIO is

begin
	uart : entity work.acia6850
		port map(
			clk      => clk,            -- System Clock
			rst      => not rst,        -- Reset input (active high)
			cs       => not nCS,        -- miniUART Chip Select
			addr     => A(0),           -- Register Select
			rw       => n_WR,           -- Read / Not Write  1 - Read, 0 - Write
			data_in  => D_O,            -- Data Bus In 
			data_out => D,              -- Data Bus Out
			irq      => n_int,          -- Interrupt Request out

			RxC      => rx_tx_Clk,      -- Receive Baud Clock
			TxC      => rx_tx_Clk,      -- Transmit Baud Clock
			RxD      => rxd,            -- Receive Data
			TxD      => txd,            -- Transmit Data
			DCD_n    => '0',            -- Data Carrier Detect
			CTS_n    => '0',            -- Clear To Send
			RTS_n    => rts             -- Request To send
		);
end architecture RTL;
