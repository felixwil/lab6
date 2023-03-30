	.data

	.global prompt
	.global mydata

start_prompt:	.string "Press sw1 or any key to continue, or press q to quit at any point:", 0
sw1_header:		.string "sw1 : ", 0
UART_header:	.string "UART: ", 0

switch_speed:	.byte	0x00	; This is where you can store data. 
current_direction:	.byte	0x00			; The .byte assembler directive stores a byte
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
ptr_to_switch_speed:		.word switch_speed
ptr_to_current_direction:	.word current_direction

lab6:	; This is your main routine which is called from your C wrapper    
	PUSH {lr}   		; Store lr to stack

	; Initialize everything
    BL uart_init
	BL gpio_btn_and_LED_init
	BL uart_interrupt_init
	BL gpio_interrupt_init

	; Load initial prompt and then print it to screen
	LDR r0, ptr_to_start_prompt
	BL output_string

lab6_loop:
	; If q, branch to end, otherwise continue
	CMP r0, #0x71	
	BEQ end_loop	; If q pressed jump to end
	B lab6_loop		; If q not pressed, continue looping

end_loop:
	POP {lr}		; Restore lr from the stack
	MOV pc, lr


uart_interrupt_init:
    PUSH {lr, r4-r11}          ; store regs
    ; Configure UART for interrupts
    
    MOV  r11, #0xc038
    MOVT r11, #0x4000          ; setting the address
    LDRB r4, [r11]             ; loading the data into r4
    
    ORR r4, r4, #8             ; r4 |= #8
    
    MOV  r11, #0xc038
    MOVT r11, #0x4000          ; setting the address
    STRB r4, [r11]             ; storing the data from r4
    ; Set processor to allow for interrupts from UART0
    
    MOV  r11, #0xe100
    MOVT r11, #0xe000          ; setting the address
    LDRB r4, [r11]             ; loading the data into r4
    
    ORR r4, r4, #16            ; r4 |= #16
    
    MOV  r11, #0xe100
    MOVT r11, #0xe000          ; setting the address
    STRB r4, [r11]             ; storing the data from r4
    
    POP {lr, r4-r11}           ; restore saved regs
    MOV pc, lr                 ; return to source call


gpio_interrupt_init:
    PUSH {lr, r4-r11}          ; store regs
    
    ; Set interrupt to be edge sensitive
    MOV  r11, #0x5404
    MOVT r11, #0x4002          ; setting the address
    LDRB r4, [r11]             ; loading the data into r4
    
    AND r4, r4, #0xf7          ; r4 &= #0xf7
    
    MOV  r11, #0x5404
    MOVT r11, #0x4002          ; setting the address
    STRB r4, [r11]             ; storing the data from r4
    
    ; Set trigger for interrupt to be single edge
    MOV  r11, #0x5408
    MOVT r11, #0x4002          ; setting the address
    LDRB r4, [r11]             ; loading the data into r4
    
    AND r4, r4, #0xf7          ; r4 &= #0xf7
    
    MOV  r11, #0x5408
    MOVT r11, #0x4002          ; setting the address
    STRB r4, [r11]             ; storing the data from r4
    
    ; Set the falling edge to be the trigger (triggers on press, not release)
    MOV  r11, #0x540c
    MOVT r11, #0x4002          ; setting the address
    LDRB r4, [r11]             ; loading the data into r4
    
    AND r4, r4, #0xf7          ; r4 &= #0xf7
    
    MOV  r11, #0x540c
    MOVT r11, #0x4002          ; setting the address
    STRB r4, [r11]             ; storing the data from r4
    
    ; Enable the the interrupt
    MOV  r11, #0x5410
    MOVT r11, #0x4002          ; setting the address
    LDRB r4, [r11]             ; loading the data into r4
    
    ORR r4, r4, #0x08          ; r4 |= #0x08
    
    MOV  r11, #0x5410
    MOVT r11, #0x4002          ; setting the address
    STRB r4, [r11]             ; storing the data from r4
    
    ; Set processor to allow interrupts from GPIO port F 
    MOV  r11, #0x5410
    MOVT r11, #0x4002          ; setting the address
    LDRB r4, [r11]             ; loading the data into r4
    
    ORR r4, r4, #0x20000000    ; r4 |= #0x20000000
    
    MOV  r11, #0x5410
    MOVT r11, #0x4002          ; setting the address
    STRB r4, [r11]             ; storing the data from r4
    
    
    POP {lr, r4-r11}           ; restore saved regs
    MOV pc, lr                 ; return to source call             ; return to source call


UART0_Handler: 
	; NEEDS TO MAINTAIN REGISTERS R4-R11, R0-R3;R12;LR;PC DONT NEED PRESERVATION
	; Save registers
	PUSH {r4-r11}

	; Clear the interrupt, load -> or -> store
	MOV r11, #0xC044
	MOVT r11, #0x4000	; address load
	LDRB r4, [r11]		; data load
	ORR r4, r4, #8		; Or to set bit 4 to 1
	STRB r4, [r11]		; Store

	; Simple_read_character, store in r5 to return to lab5 later
	BL simple_read_character 
	MOV r5, r0

	; Load UART counter, increment it, and store it
	LDR r11, ptr_to_UART_counter
	LDRB r4, [r11]
	ADD r4, r4, #1
	STRB r4, [r11]

	; Display the graph
	BL display_graph

	; Restore registers
	MOV r0, r5
	POP {r4-r11}

	BX lr       	; Return
	
Switch_Handler:
	; Save registers
    PUSH {r4-r11}

    ; Clear the interrupt, using load -> or -> store to not overwrite other data
    MOV  r11, #0x541c			
    MOVT r11, #0x4002			; Address for interrupt
    LDRB r4, [r11]          	; Load interrup value
    ORR r4, r4, #8          	; Set bit 4 to 1
	STRB r4, [r11]				; Store back to clear interrupt

	; Increment the switch counter: load it, increment, store
    LDR r11, ptr_to_switch_counter	; Load the address
    LDRB r4, [r11]					; Read the value into r4
	ADD r4, r4, #1					; Increment the value
	STRB r4, [r11]					; Store the value
    
	; Display the graph
	BL display_graph

	; Restore registers
    POP {r4-r11}

	; Return to interrupted instruction
    BX lr

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

    ; Call display board to referesh the screen
    BL displayBoard

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

# output_character: 
	
# 	MOV PC,LR      	; Return


# read_string: 
	
# 	MOV PC,LR      	; Return


# output_string: 
	
# 	MOV PC,LR      	; Return


display_graph:
	; Store registers
	PUSH {r4-r11}

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
	POP {r4-r11}

	MOV PC,LR		; Return


	.end