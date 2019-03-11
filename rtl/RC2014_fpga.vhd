-- RC2014 Emulator
-- Z80 CPU at 7.3728mhz
-- 64K RAM
-- 64K Pageable ROM with 8K page size and page selection
-- Dual ACIA 6850 UARTs at 115200 8N1
-- SD Filesystem

-- see: https://rc2014.co.uk/ for details

-- License:
--  This source code (and accompanying test bench and scripts) are released
--  under the terms of the BSD license.
--  http://www.opensource.org/licenses/bsd-license.html
--
--    Copyright (c) 2003, Allan Herriman
--    All rights reserved.
--
--    Redistribution and use in source and binary forms, with or without
--    modification, are permitted provided that the following conditions
--    are met:
--
--        Redistributions of source code must retain the above copyright
--        notice, this list of conditions and the following disclaimer.
--        Redistributions in binary form must reproduce the above copyright
--        notice, this list of conditions and the following disclaimer in
--        the documentation and/or other materials provided with the
--        distribution.
--        The name of Richard Lewis may not be used to endorse or promote
--        products derived from this software without specific prior
--        written permission.
--
--    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
--    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
--    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
--    A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
--    OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
--    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
--    LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
--    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
--    THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
--    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RC2014_fpga is
	port(
		clk         : in  std_logic;
		n_reset     : in  std_logic;
		rxd         : in  std_logic;
		txd         : out std_logic;
		rts         : out std_logic;
		page_select : in  std_logic_vector(2 downto 0);
		page_LED    : out std_logic_vector(7 downto 0)
	);
end RC2014_fpga;

architecture struct of RC2014_fpga is
	-- Frequency of board clock in Hz
	constant BRD_FREQUENCY : Real := 50000000.0;
	constant CPU_FREQUENCY : Real := 7372800.0;

	signal CPU_clk : std_logic;
	signal n_WR    : std_logic;
	signal n_RD    : std_logic;
	signal n_MREQ  : std_logic := '1';
	signal n_IORQ  : std_logic := '1';
	signal n_int   : std_logic := '1';
	signal A       : std_logic_vector(15 downto 0);
	signal D_O     : std_logic_vector(7 downto 0);
	signal D_I     : std_logic_vector(7 downto 0);

	signal ROM_D   : std_logic_vector(7 downto 0);
	signal ROM_nCS : std_logic := '1';
	signal Page    : std_logic := '0';

	signal RAM_D   : std_logic_vector(7 downto 0);
	signal RAM_nWR : std_logic := '1';
	signal RAM_nRD : std_logic := '1';
	signal RAM_nCS : std_logic := '1';

	signal UART_D   : std_logic_vector(7 downto 0);
	signal UART_nWR : std_logic := '1';
	signal UART_nRD : std_logic := '1';
	signal UART_nCS : std_logic := '1';

begin

	cpu : entity work.t80s
		generic map(mode => 1, t2write => 1, iowait => 0)
		port map(
			reset_n => n_reset,
			clk_n   => CPU_clk,
			wait_n  => '1',
			int_n   => '1',
			nmi_n   => '1',
			busrq_n => '1',
			mreq_n  => n_MREQ,
			iorq_n  => n_IORQ,
			rd_n    => n_RD,
			wr_n    => n_WR,
			a       => A,
			di      => D_I,
			do      => D_O
		);

	-- Z80 CPU clock - 7.3728 Mhz
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

	-- Selection of roms available, defaults to CPM Monitor
	rom : entity work.ROM_Page_Select
		generic map(rom => 1)           -- Select SCM ROM
		port map(
			clk         => clk,
			nReset      => n_reset,
			page_select => page_select,
			nWR         => UART_nWR,
			A           => A,
			D           => ROM_D,
			nCS         => ROM_nCS,
			Page        => Page,
			page_LED    => page_LED
		);

	ram64k : entity work.single_port_ram
		port map(
			clock   => clk,
			we      => not (RAM_nWR or RAM_nCS),
			address => A(15 downto 0),
			data    => D_O,
			q       => RAM_D
		);

	uart : entity work.acia6850
		port map(
			clk      => clk,            -- System Clock
			rst      => not n_reset,        -- Reset input (active high)
			cs       => not UART_nCS,        -- miniUART Chip Select
			addr     => A(0),           -- Register Select
			rw       => n_WR,           -- Read / Not Write  1 - Read, 0 - Write
			data_in  => D_O,            -- Data Bus In 
			data_out => UART_D,              -- Data Bus Out
			irq      => n_int,          -- Interrupt Request out

			RxC      => CPU_clk,      -- Receive Baud Clock
			TxC      => CPU_clk,      -- Transmit Baud Clock
			RxD      => rxd,            -- Receive Data
			TxD      => txd,            -- Transmit Data
			DCD_n    => '0',            -- Data Carrier Detect
			CTS_n    => '0',            -- Clear To Send
			RTS_n    => rts             -- Request To send
		);

	RAM_nRD <= n_RD or n_MREQ;
	RAM_nWR <= n_WR or n_MREQ;
	RAM_nCS <= not ROM_nCS;

	-- Serial Channel A - 2 Bytes $80-$81
	UART_nCS <= '0' when A(7 downto 1) = "1000000" and (UART_nWR = '0' or UART_nRD = '0') else '1';
	UART_nRD <= n_RD or n_IORQ;
	UART_nWR <= n_WR or n_IORQ;

	D_I <= UART_D when UART_nCS = '0'
		else ROM_D when ROM_nCS = '0'
		else RAM_D when RAM_nCS = '0'
		else x"FF";

end;
