org 0x1000

YBAMON_RAM_START:	equ	0x8100
YBAMON_PRINT_START:	equ	YBAMON_RAM_START
YBAMON_PRINT_STOP:	equ	YBAMON_RAM_START + 2

YBAMON:
	;consider that everything is junk in input buffer and deep clean it
	ld A, 253
	ld (TERM_IBUF_SZ), A
	call CLEAR_TERM_BUFFER
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
	LD	HL, TERM_IBUF
	LD	BC, ybamon_command_help_str
	call	STRCMP
	cp	1
	jp	NZ, ybamon_not_help
	ld	HL, ybamon_ok
	call 	PUTS
	call	ybamon_command_help
	jp	command_end

ybamon_not_help:
	LD	HL, TERM_IBUF
	LD	BC, ybamon_command_echo_str
	call STRCMP
	cp 	1
	jp	NZ, ybamon_not_echo
	ld	HL, ybamon_ok
	call 	PUTS
	call	ybamon_command_echo
	jp	command_end

ybamon_not_echo:
	LD	HL, TERM_IBUF
	LD	BC, ybamon_command_print_str
	call STRCMP
	cp 	1
	jp	NZ, ybamon_not_print
	ld	HL, ybamon_ok
	call 	PUTS
	call ybamon_command_print	
	jp	command_end

ybamon_not_print:
	LD	HL, TERM_IBUF
	LD	BC, ybamon_command_jump_str
	call STRCMP
	cp 	1
	jp	NZ, ybamon_not_jump
	ld	HL, ybamon_ok
	call 	PUTS
	call ybamon_command_jump	
	jp	command_end

ybamon_not_jump:
	ld	HL, TERM_IBUF
	ld	BC, ybamon_command_put_str
	call STRCMP
	cp	1
	jp NZ, ybamon_not_put
	ld	HL, ybamon_ok
	call	PUTS
	call ybamon_command_put
	jp	command_end
ybamon_not_put:

	ld	HL, TERM_IBUF
	ld	BC, ybamon_command_clear_str
	call STRCMP
	cp	1
	jp NZ, ybamon_not_clear
	ld	HL, ybamon_clear
	call PUTS
	jp	command_end
ybamon_not_clear:

	;this is the point where the input string did not result in any usable command
	LD	HL, ybamon_crlf
	call	PUTS
	LD	HL, ybamon_synerr
	call	PUTS

command_end:
	call	CLEAR_TERM_BUFFER			;clear buffer
	LD 	HL, ybamon_crlf
	call	PUTS
	ret


ybamon_command_help:
	ld 	HL, ybamon_help_txt
	call PUTS
	ret

ybamon_command_echo:
	ld	HL, TERM_IBUF	; input buffer should have "print ADDR" 
	ld	B, 0
	ld 	C, 5
	add	HL, BC		; pointer to characters string after "echo "
	call PUTS
	ret

ybamon_command_print:
	ld	HL, TERM_IBUF	; input buffer should have "print ADDR" 
	ld	B, 0
	ld 	C, 6
	add	HL, BC		; pointer to characters string after "print "
	call	READ_HEX
	ld	A, (BC)
	call	PUT_HEX
	ret

ybamon_jump_message:
db "we are going to jump to the following memory location: ",0

ybamon_command_jump:
	ld	HL, ybamon_jump_message
	call PUTS
	ld	HL, TERM_IBUF	; input buffer should have "print ADDR" 
	ld	B, 0
	ld 	C, 5
	add	HL, BC		; pointer to characters string after "jump "
	call	READ_HEX
	ld 	A, B
	call 	PUT_HEX
	ld	A, C
	call 	PUT_HEX
	ld	HL, ybamon_crlf
	call    PUTS	
	ld	HL, 0
	add	HL, BC
	jp	(HL)		; At this point, all bets are of about what's gonna happen
				; to the computer... :D
	ret			;useless ret just for good measure

ybamon_command_put:
	ld	HL, TERM_IBUF	; input buffer should have "print ADDR" 
	ld	B, 0
	ld 	C, 4
	add	HL, BC		; pointer to characters string after "put "
	call	READ_HEX
	push	BC
	call CLEAR_TERM_BUFFER
ybamon_put_loop:
ybamon_put_buff_reset:
	ld	HL, TERM_IBUF			;load pointer to buffer
	ld	B, 0				;reset B to zero
ybamon_put_buff_watch:
	ld	A, (HL)				;load pointed char
	cp	0x0D				;compare with carriage return
	jp 	Z, ybamon_put_buff_CR		;if carraige return, jump to ouptut
	cp	0
	jp	Z, ybamon_put_buff_reset
	inc	HL				; HL++
	inc 	B				; B++
	push	AF				;push A
	ld	A, (TERM_IBUF_SZ)		;load buff size
	cp	B				;check with B
	pop	AF				;pop A
	jp	C, ybamon_put_buff_reset	;if B >= TERM_IBUF_SZ, jumpto reset
	jp 	ybamon_put_buff_watch		;jump to buff_watch
ybamon_put_buff_CR:
	pop 	BC
	ld	E, 0
	ld	D, 0
	ld	HL, TERM_IBUF
ybamon_put_read_loop:
	add	HL, DE
	ld	A, (HL)
	cp	0x0D
	jp 	Z,ybamon_put_end
	cp	0x00
	jp 	Z,ybamon_put_end
	call	ASCII_HEX_TO_N
	push	HL
	ld	HL, 0
	add	HL, BC
	ld	(HL), A
	inc	C
	pop	HL
	inc	E
	inc 	E
	jp	ybamon_put_read_loop
ybamon_put_end:
	ret

;DATA

ybamon_welcome:
db "Starting YbaMon, Ybalrid's z80 monitor\r\n"
db "Type \"help\" to know what you can do\r\n",0

ybamon_prompt:
db "? ",0

ybamon_crlf:
db 0x0D, 0x0A, 0

ybamon_ok:
db "\r\nOK\r\n",0

ybamon_synerr:
db "SYN ERR\r\n", 0

ybamon_clear:
db 0x0C, 0x00

ybamon_command_string_array:
ybamon_command_help_str:
db "help",0
ybamon_command_print_str:
db "print",0
ybamon_command_echo_str:
db "echo",0
ybamon_command_put_str:
db "put",0
ybamon_command_jump_str:
db "jump",0
ybamon_command_clear_str:
db "clear",0

ybamon_command_string_offset_ptr:
db ybamon_command_string_array - ybamon_command_help_str
db ybamon_command_string_array - ybamon_command_print_str
db ybamon_command_string_array - ybamon_command_echo_str
db ybamon_command_string_array - ybamon_command_put_str
db ybamon_command_string_array - ybamon_command_jump_str
db ybamon_command_string_array - ybamon_command_clear_str

ybamon_command_list_size:
db 6
ybamon_help_txt:
db "\nShort manual of monitor:\r\n"
db " help\r\n"
db "  print this help\r\n"
db " echo <SOME TEXT>\r\n"
db "  echo back some input (test feature)\r\n"
db " print XXXX\r\n"
db "  print value in memory at adress XXXX (HEX, upper case only)\r\n"
db " jump XXXX\r\n"
db "  jump to XXXX and start executing arbitrary code from there! :-D\r\n"
db " put XXXX\r\n"
db "  Open PUT mode at address XXXX, serve to write memory. each char inputed after return is a nibble, exit with RETURN\r\n"
db " clear\r\n"
db "  Clear the screen / send \"Form Feed\" ASCII char to terminal"
db 0
