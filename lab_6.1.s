	.data

	.global prompt
	.global mydata

start_prompt:	.string "Press sw1 or any key to continue, or press q to quit at any point:", 0
sw1_header:		.string "sw1 : ", 0
UART_header:	.string "UART: ", 0
switch_counter:	.byte	0x00	; This is where you can store data. 
UART_counter:	.byte	0x00			; The .byte assembler directive stores a byte
uartresult:		.byte	0x00
xposition:		.byte	20
yposition:		.byte	0
top:		.string " -------------------- ", 0xa, 0xd, 0
row:		.string "|                    |", 0xa, 0xd, 0
			; (initialized to 0x20) at the label mydata.  
			; Halfwords & Words can be stored using the 
			; directives .half & .word 

	.text
	
	.global uart_interrupt_init
	.global gpio_interrupt_init
	.global gpio_btn_and_LED_init
	.global UART0_Handler
	.global Switch_Handler
	.global Timer_Handler		; This is needed for Lab #6
	.global simple_read_character
	.global output_character	; This is from your Lab #4 Library
	.global read_string		; This is from your Lab #4 Library
	.global output_string		; This is from your Lab #4 Library
	.global uart_init		; This is from your Lab #4 Library
	.global lab6
	
ptr_to_start_prompt:		.word start_prompt
ptr_to_sw1_header:			.word sw1_header
ptr_to_UART_header:			.word UART_header
ptr_to_switch_counter:		.word switch_counter
ptr_to_UART_counter:		.word UART_counter
ptr_to_uartresult: 			.word uartresult

ptr_to_xposition: 			.word xposition
ptr_to_yposition: 			.word yposition
ptr_to_top:		 			.word top
ptr_to_row: 				.word row

lab6:	; This is your main routine which is called from your C wrapper
	PUSH {lr}   		; Store lr to stack

	; Initialize everything
    BL uart_init
	BL gpio_btn_and_LED_init
	BL uart_interrupt_init
	BL gpio_interrupt_init
	BL timer_interrupt_init

;	BL displayboard

	;MOV r0, #0xC
	;BL output_character
	;; Load initial prompt and then print it to screen
	;LDR r0, ptr_to_start_prompt
	;BL output_string

lab6_loop:
	; If q, branch to end, otherwise continue
	;ldr r5, ptr_to_uartresult
	;LDRB r0, [r5]
	;CMP r0, #0x71
	;BEQ end_loop	; If q pressed jump to end
	B lab6_loop		; If q not pressed, continue looping

end_loop:
	POP {lr}		; Restore lr from the stack
	MOV pc, lr


uart_interrupt_init:
    PUSH {lr, r4-r11}          ; store regs
    ; Configure UART for interrupts
    
    MOV  r11, #0xc038
    MOVT r11, #0x4000          ; setting the address
    LDRW r4, [r11]             ; loading the data into r4
    
    ORR r4, r4, #16             ; r4 |= #8
    
    MOV  r11, #0xc038
    MOVT r11, #0x4000          ; setting the address
    STRW r4, [r11]             ; storing the data from r4
    ; Set processor to allow for interrupts from UART0
    
    MOV  r11, #0xe100
    MOVT r11, #0xe000          ; setting the address
    LDRW r4, [r11]             ; loading the data into r4
    
    ORR r4, r4, #32            ; r4 |= #16
    
    MOV  r11, #0xe100
    MOVT r11, #0xe000          ; setting the address
    STRW r4, [r11]             ; storing the data from r4
    
    POP {lr, r4-r11}           ; restore saved regs
    MOV pc, lr                 ; return to source call


gpio_interrupt_init:
    PUSH {lr, r4-r11}          ; store regs
    
    ; Set interrupt to be edge sensitive
    MOV  r11, #0x5404
    MOVT r11, #0x4002          ; setting the address
    LDRW r4, [r11]             ; loading the data into r4
    
    AND r4, r4, #0xfe          ; r4 &= #0xf7
    
    MOV  r11, #0x5404
    MOVT r11, #0x4002          ; setting the address
    STRW r4, [r11]             ; storing the data from r4
    
    ; Set trigger for interrupt to be single edge
    MOV  r11, #0x5408
    MOVT r11, #0x4002          ; setting the address
    LDRW r4, [r11]             ; loading the data into r4
    
    AND r4, r4, #0xfe          ; r4 &= #0xf7
    
    MOV  r11, #0x5408
    MOVT r11, #0x4002          ; setting the address
    STRW r4, [r11]             ; storing the data from r4
    
    ; Set the falling edge to be the trigger (triggers on press, not release)
    MOV  r11, #0x540c
    MOVT r11, #0x4002          ; setting the address
    LDRW r4, [r11]             ; loading the data into r4
    
    AND r4, r4, #0xfe          ; r4 &= #0xf7
    
    MOV  r11, #0x540c
    MOVT r11, #0x4002          ; setting the address
    STRW r4, [r11]             ; storing the data from r4
    
    ; Enable the the interrupt
    MOV  r11, #0x5410
    MOVT r11, #0x4002          ; setting the address
    LDRW r4, [r11]             ; loading the data into r4
    
    ORR r4, r4, #16          ; r4 |= #0x08
    
    MOV  r11, #0x5410
    MOVT r11, #0x4002          ; setting the address
    STRW r4, [r11]             ; storing the data from r4
    
    ; Set processor to allow interrupts from GPIO port F 
    MOV  r11, #0xe100
    MOVT r11, #0xe000          ; setting the address
    LDRW r4, [r11]             ; loading the data into r4
    
    ORR r4, r4, #0x40000000    ; r4 |= #0x20000000
    
    MOV  r11, #0xe100
    MOVT r11, #0xe000          ; setting the address
    STRW r4, [r11]             ; storing the data from r4

    
    POP {lr, r4-r11}           ; restore saved regs
    MOV pc, lr                 ; return to source call             ; return to source call


UART0_Handler: 
	; NEEDS TO MAINTAIN REGISTERS R4-R11, R0-R3;R12;LR;PC DONT NEED PRESERVATION
	; Save registers
	PUSH {lr, r4-r11}

	; Clear the interrupt, load -> or -> store
	MOV r11, #0xC044
	MOVT r11, #0x4000	; address load
	LDRB r4, [r11]		; data load
	ORR r4, r4, #8		; Or to set bit 4 to 1
	STRB r4, [r11]		; Store

	; Simple_read_character, store in r5 to return to lab5 later
	BL simple_read_character 

	ldr r5, ptr_to_uartresult
	STRB r0, [r5]

	; Load UART counter, increment it, and store it
	LDR r11, ptr_to_UART_counter
	LDRB r4, [r11]
	ADD r4, r4, #1
	STRB r4, [r11]

	; Display the graph
	BL display_graph

	; Restore registers
	POP {lr, r4-r11}

	BX lr       	; Return
	
Switch_Handler:
	; Save registers
    PUSH {lr, r4-r11}

    ; Clear the interrupt, using load -> or -> store to not overwrite other data
    MOV  r11, #0x541c			
    MOVT r11, #0x4002			; Address for interrupt
    LDRB r4, [r11]          	; Load interrup value
    ORR r4, r4, #16          	; Set bit 4 to 1
	STRB r4, [r11]				; Store back to clear interrupt

	; Increment the switch counter: load it, increment, store
    LDR r11, ptr_to_switch_counter	; Load the address
    LDRB r4, [r11]					; Read the value into r4
	ADD r4, r4, #1					; Increment the value
	STRB r4, [r11]					; Store the value
    
	; Display the graph
	BL display_graph

	; Restore registers
    POP {lr, r4-r11}

	; Return to interrupted instruction
    BX lr

timer_interrupt_init:
    ; Connect clock to timer
    MOV r11, #0xE604
    MOVT r11, #0x400F   ; load address
    LDRW r4, [r11]      ; load value
    ORR r4, r4, #1      ; write 1 to bit 0
    STRW r4, [r11]      ; store back

    ; Disable timer
    MOV r11, #0x000C
    MOVT r11, #0x4003   ; load address
    LDRW r4, [r11]      ; load value
    AND r4, r4, #0xFE      ; write 1 to bit 0
    STRW r4, [r11]      ; store back

    ; Put timer into 32-bit mode
    MOV r11, #0x0000
    MOVT r11, #0x4003   ; load address
    LDRW r4, [r11]      ; load value
    AND r4, r4, #0xF8   ; write 0 to first 3 bits
    STRW r4, [r11]      ; write back

    ; Put timer into periodic mode
    MOV r11, #0x0004
    MOVT r11, #0x4003   ; load address
    LDRW r4, [r11]      ; load value
    AND r4, r4, #0xFE      ; write 2 to first two bits
    ORR r4, r4, #2      ; write 2 to first two bits
    STRW r4, [r11]      ; write back

    ; Set up interval period
    MOV r11, #0x0028
    MOVT r11, #0x4003   ; load address
    MOV r4, #0x2400
    MOVT r4, #0x00F4    ; load frequency
    STRW r4, [r11]      ; store frequency

    ; Enable timer to interrupt processor
    MOV r11, #0x0018
    MOVT r11, #0x4003   ; load address
    LDRW r4, [r11]      ; load value
    ORR r4, r4, #1      ; write 1 to bit 0
    STRW r4, [r11]      ; write back

    ; Configure processor to allow timer interrupts
    MOV r11, #0xE100
    MOVT r11, #0xE000   ; load address
    LDR r4, [r11]       ; load value
    ORR r4, r4, #1 << 19 ; 0x80000; write 1 to bit 19
    STRW r4, [r11]       ; write back

    ; Enable timer
    MOV r11, #0x000C
    MOVT r11, #0x4003  ; load address
    LDRW r4, [r11]      ; load value
    ORR r4, r4, #1      ; write 1 to bit 0
    STRW r4, [r11]

Timer_Handler:
	; NEEDS TO MAINTAIN REGISTERS R4-R11, R0-R3;R12;LR;PC DONT NEED PRESERVATION 
	; Your code for your Timer handler goes here.  It is not needed
	; for Lab #5, but will be used in Lab #6.  It is referenced here
	; because the interrupt enabled startup code has declared Timer_Handler.
	; This will allow you to not have to redownload startup code for 
	; Lab #6.  Instead, you can use the same startup code as for Lab #5.
	; Remember to preserver registers r4-r11 by pushing then popping 
	; them to & from the stack at the beginning & end of the handler.

    ; Save the registers
    PUSH {lr, r4-r11}

	; Clear the interrupt, using load -> or -> store to not overwrite other data
    MOV  r11, #0x0024
    MOVT r11, #0x4003			; Address for interrupt
    LDRB r4, [r11]          	; Load interrup value
    ORR r4, r4, #1          	; Set bit 0 to 1
	STRB r4, [r11]				; Store back to clear interrupt

    ; Update position based on direction stored in current_direction and switch_speed

    ; Call display board to referesh the screen
    BL displayboard

    ; Restore the registers
    POP {lr, r4-r11}

	BX lr       	; Return

simple_read_character:
    PUSH {lr, r4-r11}          ; store regs
    
    MOV  r11, #0xc000
    MOVT r11, #0x4000          ; setting the address
    LDRB r0, [r11]             ; loading the data into r0
    
    POP {lr, r4-r11}           ; restore saved regs
    MOV pc, lr                 ; return to source call

; output_character:
	
; 	MOV PC,LR      	; Return


; read_string:
	
; 	MOV PC,LR      	; Return


; output_string:
	
; 	MOV PC,LR      	; Return

displayboard:
	PUSH {lr, r4-r11}          ; store regs

	MOV r0, #0xC ; clear screen
	BL output_character

	LDR r0, ptr_to_top ; print top
	BL output_string

	MOV r4, #0 ; y = 0
	; r5 = x;
	LDR r2, ptr_to_yposition
	LDRB r2, [r2]
	LDR r3, ptr_to_xposition
	LDRB r3, [r3]

printrow:
		; if y == yposition:
		CMP r4, r2
		BEQ beginprintrowloop

		; print row until y = yposition

		; if y == 20
		CMP r4, #19
		BGE exitprintboardloop

		ADD r4, r4, #1 ; y++;

		LDR r0, ptr_to_row ; print row
		BL output_string

		B printrow

beginprintrowloop:
			MOV r5, #0 ; x = 0
            LDR r6, ptr_to_row
printplayerrow:

			ADD r7, r6, r5
			LDRB r0, [r7]
			BL output_character

			ADD r5, r5, #1 ; x++

			; if x == xposition
			CMP r5, r3
			BNE printplayerrow

			MOV r0, #0x2A ; print '*'
			BL output_character

			ADD r5, r5, #1 ; x++
			ADD r0, r6, r5 ; print(row+r6+r5)
			BL output_string
		; print every character from row until x = xposition
	ADD r4, r4, #1 ; y++;
	B printrow

exitprintboardloop:
	LDR r0, ptr_to_top ; print top
	BL output_string

	POP {lr, r4-r11}
	MOV pc, lr

display_graph:
	; Store registers
	PUSH {lr, r4-r11}

	; Load the sw1 and UART counts, r4 and r5 respectively
	LDR r11, ptr_to_switch_counter
	LDRB r4, [r11]					; Load switch count to r4
	LDR r11, ptr_to_UART_counter
	LDRB r5, [r11]					; Load UART count to r5

	; Clear the screen (r0=0xC then output_character)
	MOV r0, #0xC
	BL output_character

	; Load ptr_to_sw1_header to r0 then output_string
	LDR r0, ptr_to_sw1_header
	BL output_string

	; Initialize a tracker (r6=0) and the # character (r0=0x23)
	MOV r6, #0
	MOV r0, #0x23

sw1_graph:
	; If counter = sw1_count(r6=r4), skip to sw1_graph_done
	CMP r6, r4
	BEQ sw1_graph_done

	; Output_character
	BL output_character

	; Increment counter
	ADD r6, r6, #1

	; Loop back until all printed
	B sw1_graph

sw1_graph_done:
	; Move cursor to beginning of the line (r0=0xD then output_character)
	MOV r0, #0xD
	BL output_character

	; Move cursor to next line (r0=0xA then output_character)
	MOV r0, #0xA
	BL output_character

	; Load ptr_to_UART_header to r0 then output_string
	LDR r0, ptr_to_UART_header
	BL output_string

	; Initialize a tracker (r6=0) and the # character (r0=0x23)
	MOV r6, #0
	MOV r0, #0x23

UART_graph:
	; If counter = UART_count(r6=r5), skip to UART_graph_done
	CMP r6, r5
	BEQ UART_graph_done

	; output_character
	BL output_character

	; increment counter
	ADD r6, r6, #1

	; Loop back until all printed
	B UART_graph

UART_graph_done:
	; Restore registers
	POP {lr, r4-r11}

	MOV PC,LR		; Return


	.end
