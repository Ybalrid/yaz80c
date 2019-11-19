org 0x1000

YBAMON:
	call BELL
	ld	HL, ybamon_welcome
	call PUTS 

;main loop of program
ybamon_loop:
	call ybamon_shell
	jp ybamon_loop

ybamon_shell:
ybamon_shell_loop:
	ld	HL, ybamon_prompt		;load prompt text
	call 	PUTS				;disp text
	call 	CLEAR_TERM_BUFFER		;clear input buffer
ybamon_shell_buff_reset:
	ld	HL, TERM_IBUF			;load pointer to buffer
	ld	B, 0				;reset B to zero
ybamon_shell_buff_watch:
	ld	A, (HL)				;load pointed char
	cp	0x0D				;compare with carriage return
	jp 	Z, ybamon_shell_buff_CR		;if carraige return, jump to ouptut
	cp	0
	jp	Z, ybamon_shell_buff_reset
	inc	HL				; HL++
	inc 	B				; B++
	push	AF				;push A
	ld	A, (TERM_IBUF_SZ)		;load buff size
	cp	B				;check with B
	pop	AF				;pop A
	jp	C, ybamon_shell_buff_reset	;if B >= TERM_IBUF_SZ, jumpto reset
	jp 	ybamon_shell_buff_watch		;jump to buff_watch

ybamon_shell_buff_CR:				;CR has been found
						;TODO parse input
	call	CLEAR_TERM_BUFFER			;clear buffer
	LD 	HL, ybamon_crlf
	call	PUTS
	ret

;DATA

ybamon_welcome:
db "Starting YbaMon, Ybalrid's z80 monitor\r\n",0

ybamon_prompt:
db "? ",0

ybamon_crlf:
db 0x0D, 0x0A, 0

ybamon_ok:
db "OK\r\n",0

ybamon_synerr:
db "SYN ERR\r\n", 0

