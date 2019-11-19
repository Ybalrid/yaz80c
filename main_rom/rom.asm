; rom.asm
;
; From the yaz80c project - yet another z80 computer
;
; This file is the main file to build the main 32K system rom


;; Address table configuration
; DART channel A
DART_A_C:	equ	0x0000
DART_A_D:	equ	0x0001
DART_B_C:	equ	0x0010
DART_B_D:	equ	0x0011

;; RAM configuraiton
RAM_START:	equ	0x8100	; start of general purpose ram
STACK_START:	equ	0xFFFF	; inital value of stack pointer

;; Serial input buffer
TERM_IBUF:	equ	0x8000	; serial input buffer
TERM_IBUF_SZ:	equ	0x80FF	; bytes used in serial input buffer
TERM_IBUF_TMP:	equ	0x80FE

org 0x0000
CPU_RESET:					; code to be placed at reset vector
	di				; disable all interupts until computer has finished boot
	ld	SP, (STACK_START)	; put stack pointer at the very top of RAM
	call	BOOTUP			; run hardware boot program
	jp YBAMON			; Jumpt to one program installed in ROM: Ybalrd's monitor


; Define interupt vectors table - this system runs on Interupt Mode 2.
; We keep register I at 0x00
defs 0x0C-$
defw	RX_CHA_AVAIL			; 0x000C = character available from terminal
defs 0x0E-$
defw SPEC_RX_COND


SPEC_RX_COND:
	jp CPU_RESET
	
defs 0x66-$
NMI:
	nop
	ei
	retn	

; DART configuration
INIT_DART:
	ld	A, 0
	ld	I, A
	ld	(TERM_IBUF_SZ), A

	;TODO write configureation bytes in DART_A_C
	
	ld	A, %00110000	;WR0 error reset, select WR0
	out	(DART_A_C), A
	ld	A, 0x18		;WR0 channel reset
	out	(DART_A_C), A
	ld 	A, 0x4		;Select WR4
	out	(DART_A_C), A
	ld 	A, 0x44		;Set clock 16, 1 stop bit no parity
	out	(DART_A_C), A
	ld	A, 0x5		;Select WR5
	out	(DART_A_C), A
	ld	A, 0xE8		;DTR active, TX 8bit, Break Off, TX on RTS not active
	out	(DART_A_C), A
	ld	A, 0x1		;Select WR1 (B)
	out	(DART_B_C), A
	ld	A, %00000100
	out	(DART_B_C), A	;CHB interupt diabled, special RX affect vect

	ld	A, 0x2		;Select WR2 (B)
	out	(DART_B_C), A
	ld	A, 0x0		;Set interupt vector, D3, D2, D1 depend on RX
	out	(DART_B_C), A

	ld	A, 0x1		;Select WR0
	out	(DART_A_C), A
	ld 	A, %00011000	;Interupt all character RX
				;parity interupt OFF
				;buffer overrun interupt ON 
	out	(DART_A_C), A

;TODO push pop registers
DART_A_EI: ;enable RX interupts
	ld	A, 0x3
	out	(DART_A_C), A
	ld	A, 0xC1
	out	(DART_A_C), A
	ret

DART_A_DI: ;disable RX interupts
	ld	A, 0x3
	out	(DART_A_C), A
	ld	A, 0xC0
	out	(DART_A_C), A
	ret

A_RTS_OFF:
	ld	A, 0x5
	out 	(DART_A_C), A
	ld	A, 0xE8
	out	(DART_A_C), A
	ret

A_RTS_ON:
	ld	A, 0x5
	out 	(DART_A_C), A
	ld	A, 0xEA
	out	(DART_A_C), A
	ret


A_TX_EMP:
	sub	A
	inc	A
	out	(DART_A_C), A
	in	A, (DART_A_C)
	bit 	0, A
	jp 	Z,A_TX_EMP
	ret
	
CLEAR_TERM_BUFFER:
	LD	A, (TERM_IBUF_SZ)
	LD	E, A
	LD	HL, TERM_IBUF
CLEAR_TERM_LOOP:
	LD	A, 0
	LD	(HL), A
	INC	HL
	LD	A, L
	CP	E
	JP	C, CLEAR_TERM_LOOP
	LD 	A, 0
	LD	(TERM_IBUF_SZ), A
	ret

BOOTUP:
	call INIT_DART
	ld	HL, BOOT_MSG_STR 
	call	PUTS
	call CLEAR_TERM_BUFFER		; clear terminal input buffer (for e.g: soft reset)
	im 2
	ei
	call	A_RTS_ON	
	ret

;print the character in A
PUTCHAR:
	out (DART_A_D), A
	call A_TX_EMP
	ret

BELL:
	LD	A,0x07
	call PUTCHAR
	ret

;print the string pointed by HL
PUTS:
	push	HL
PUTS_LOOP:
	ld 	A, (HL)
	cp 	0
	jp	z, PUTS_END
	call PUTCHAR
	inc HL
	jp PUTS_LOOP
PUTS_END:
	POP	HL
	ret

;print 8bit hex number in A
PUT_HEX:
;TODO display hex number on terminal
	ret	

;print 16bit number in HL
PUT_HEX16:
;TODO display hex number on terminal
	LD A, H
	call PUT_HEX
	LD A, L
	call PUT_HEX
	ret


RX_CHA_AVAIL:				
	push	AF
	push 	HL
	push 	DE
	in	A, (DART_A_D)		; READ one character from DART A channel
	ld	(TERM_IBUF_TMP), A	; Store character in temp storage
	
	cp	0x0D
	jp	Z, RX_CHA_EXPLICT_ACCEPT
	cp 	0x08			;check if backspace
	jp	Z, RX_CHA_BACKSPACE
	cp	0x20			;ignore non printabel char here
	jp	C, RX_CHA_NO_PRINT
	cp	0x7E
	jp	NC, RX_CHA_NO_PRINT
RX_CHA_EXPLICT_ACCEPT:
	out	(DART_A_D), A		; Assume no echo local on terminal
	call	A_TX_EMP		; wait
	
	; At this point, the character is stored from the device to RAM
	; We need to check the size of the input buffer
	
	ld  	A, (TERM_IBUF_SZ)	; Check current size of buffer
	cp	254			
	jp	NC, RX_CHA_BUFF_FULL	; exit if buffer is full
	ld	HL, TERM_IBUF
	ld	D, 0
	ld	E, A
	add 	HL, DE			; calculate address of where to write 	
	
	; Append char to buffer
	ld	A, (TERM_IBUF_TMP)
	ld 	(HL), A
	
	; Store new buffer size	
	ld  	A, (TERM_IBUF_SZ)	; Check current size of buffer
	inc 	A			; Increment Buffer size
	ld	(TERM_IBUF_SZ), A	; Store new Buffer size
	jp	RX_CHA_AVAIL_END

RX_CHA_BUFF_FULL:
			; todo signal that buffer is full
					; this is an error condition we need to recuperate from
RX_CHA_BACKSPACE:
	ld	A, (TERM_IBUF_SZ)
	cp	0
	JP	NZ, RX_CHA_BACKSPACE_NO_EMPTY
	JP 	RX_CHA_NO_PRINT
RX_CHA_BACKSPACE_NO_EMPTY:
	dec	A
	cp	255
	JP	NZ, RX_CHA_BACKPACE_NO_OVERFLOW
	xor	A
RX_CHA_BACKPACE_NO_OVERFLOW:
	ld	(TERM_IBUF_SZ), A
	ld	HL, TERM_IBUF
	ld	D, 0
	ld	E, A
	add	HL, DE
	ld	A, 0
	ld	(HL), A

	;Now, erase last character on the terminal by printing erase sequece
	ld	HL, ERASE_SEC
	call	PUTS
	jp 	RX_CHA_AVAIL_END		
RX_CHA_NO_PRINT:
	call BELL
RX_CHA_AVAIL_END:
	pop	DE
	pop	HL
	pop	AF
	ei
	reti


BOOT_MSG_STR:
db "yaz80c 8bit z80 computer\r\n(C) 2019 Arthur Brainville (Ybalrid)\r\nThis is open-source hardware and software\r\n",0

ERASE_SEC:
db 0x08, 0x20, 0x08, 0

defs 0x1000-$
include "mon.asm"

defs 0x8000-$
