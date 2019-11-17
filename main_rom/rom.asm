; rom.asm
;
; From the yaz80c project
;
; This file is the main file tha build the rom

org 0x0000
reset:				; code to be placed at reset vector
	di			; disable all interupts until computer has finished boot
	ld	sp, 0xFFFF	; put stack pointer at the very top of RAM
	jp 	fzero


; buffer space to be at address F0
	defs	0xF0-$
fzero:
	ld	a, 0x42		;just a test
	
	

