RC2014_fpga - A VHDL emulation of the RC2014 (Z80) environment
========================================================

This project is a VHDL implementation of the RC2014 Homebrew Z80 Computer targeting the following boards:

* Terasic DE10-Nano
* Terasic DE10-Lite
* Avnet Zedboard (tbd)

Currently the following peripherals are implemented:

* RC2014 PRO Bus with bidirectional data port attached to FPGA pins
* Z80 CPU using the [T80 core](https://opencores.org/projects/t80)
* Separate and configurable CPU and UART clocks 
* ACIA 6850 UART [System09 core](https://opencores.org/projects/system09)
* 64K Internal RAM
* Selection of the following ROMS:
  * Grant's Searle's CPM Monitor
  * Steve Cousin's SCM S3 v1.0
  * 64K Pageable ROM (currently with fixed 8K pages): [Pageable ROM](https://rc2014.co.uk/modules/pageable-rom/)
    * Pages 1 - 8 are selected from 3 switches on FPGA board

ROM can be configured for the following applications:
1. Microsoft BASIC, for 32k RAM, 68B50 ACIA, with origin 0x0000
2. Microsoft BASIC, for 56k RAM, 68B50 ACIA, with origin 0x0000
3. CP/M Monitor, for pageable ROM, 64k RAM, 68B50 ACIA, CF Module at 0x10, with origin at 0x0000
4. [Small Computer Monitor](https://smallcomputercentral.wordpress.com/small-computer-monitor/) for pageable ROM, 64k RAM, SIO/2 or 68B50 ACIA, with Microsoft BASIC and CP/M boot options

In progress:
* CF Flash emulator
* SD Card  enulator
* Zilog SIO/2 Uart (planned to be a simple interface wrapper around the 6850)
* VGA VT100 terminal with PS/2 keyboard
* BusRaider interface

## Installation
### Quartus 18.1 Lite - DE10-Nano and DE10-Lite
### Vivado 2018.3 - Avnet Zedboard
## Usage

### References
* To build your own RC2014 visit: [RC2014 - Homebrew Z80 Computer](https://rc2014.co.uk/) or purchase on [Tindie](https://www.tindie.com/products/Semachthemonkey/rc2014-pro-homebrew-z80-computer-kit/?pt=ac_prod_search)
* [Grant Searle's MULTICOMP](http://searle.hostei.com/grant/Multicomp/index.html). *However, where otherwise noted the work is my own*
* Steve Cousin's [Small Computer Monitor](https://smallcomputercentral.wordpress.com/small-computer-monitor/)
