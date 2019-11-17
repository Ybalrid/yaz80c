# yaz80c system rom

This folder contains the assembly listing of the main rom, and the files to build it.

The maximum space the ROM program can take is 32K.

Space is reserverd for a simple bootloader that initialize the stack and devices, then a monitor.

The rest of the rom will be left for fitting other stuff.

ROM is installed in the computer address space at location 0000h

RAM starts at locaiton 8000h


## Assembler

The used assembler to build the ROM is the gnu z80asm from here https://www.nongnu.org/z80asm/

The build system is based on GNU Make.
