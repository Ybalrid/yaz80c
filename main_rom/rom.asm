; rom.asm
;
; From the yaz80c project
;
; This file is the main file tha build the rom


;; Address table configuration
; DART channel A
DART_A_C:	equ	0x0000
DART_A_D:	equ	0x0001

;; RAM configuraiton
TERM_IBUF:	equ	0x8000	; serial input buffer
TERM_IBUF_SZ:	equ	0x80FF	; bytes used in serial input buffer
TERM_IBUF_TMP:	equ	0x80FE
RAM_START:	equ	0x8100	; start of general purpose ram
STACK_START:	equ	0xFFFF	; inital value of stack pointer

;; Serial input buffer
;TODO

org 0x0000
RESET:				; code to be placed at reset vector
	di				; disable all interupts until computer has finished boot
	ld	SP, (STACK_START)	; put stack pointer at the very top of RAM
	call	BOOTUP

;define interupt vectors
defs 0x0C-$
INT_VECT:
RX_CHA_AVAIL:				; 0x000C = character available from terminal
	push	AF
	push 	HL
	push 	DE
	in	A, (DART_A_D)		; READ one character from DART A channel
	ld	(TERM_IBUF_TMP), A	; Store character in temp storage
	
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
	nop				; todo signal that buffer is full
					; this is an error condition we need to recuperate from
RX_CHA_AVAIL_END:
	pop	DE
	pop	HL
	pop	AF
	ei
	reti
	
defs 0x66-$
NMI:
	nop
	ei
	retn	

; DART configuration
INIT_DART:
	ld	A, 0
	ld	(TERM_IBUF_SZ), A
	ld	I, A

	;TODO write configureation bytes in DART_A_C

	im	2		; config interupt mode 2
	ei			; enable maskable interupt
	ret

CLEAR_TERM_BUFFER:
	push 	AF
	xor 	A
	ld	(TERM_IBUF_SZ), A
	pop	AF
	ret

BOOTUP:
	call INIT_DART
	ret

defs 0x1000-$
include "mon.asm"

