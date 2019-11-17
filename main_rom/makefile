all: yaz80c.bin yaz80c.lbl

yaz80c.bin: rom.asm mon.asm 
	z80asm --label-prefix _ --verbose --verbose rom.asm --output yaz80c.bin

yaz80c.lbl: rom.asm mon.asm
	z80asm --label-prefix _ rom.asm --label --output yaz80c.lbl
.PHONY: clean
clean:
	rm *.bin *.lbl > /dev/null 2>&1; true

