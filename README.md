RC2014_fpga - A VHDL emulation of the RC2014 (Z80) environment
==============================================================

This project is a VHDL implementation of the RC2014 Homebrew Z80 Computer targeting the following boards:

* Terasic DE10-Nano
* Terasic DE10-Lite
* Avnet Zedboard 

Currently the following peripherals are implemented:

* Z80 CPU using the [T80 core](https://opencores.org/projects/t80)
* Separate and configurable CPU and UART clocks 
* ACIA 6850 UART [System09 core](https://opencores.org/projects/system09)
* 64K Internal RAM
* 64K Pageable ROM (currently with fixed 8K pages): [Pageable ROM](https://rc2014.co.uk/modules/pageable-rom/)

In progress:
* CF Flash emulator
* SD Card  enulator
* Zilog SIO/2 Uart (planned to be an interface wrapper around the 6850)

For details on building your own RC2014 visit: [RC2014 - Homebrew Z80 Computer](https://rc2014.co.uk/)  

Inspiration for this project is due to: [Grant's MULTICOMP](http://searle.hostei.com/grant/Multicomp/index.html). *However, where otherwise noted the work is my own*

## Installation
