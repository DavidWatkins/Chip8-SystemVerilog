/******************************************************************************
 * enums.svh
 *
 * Defines the enums used by Chip8_Top, Chip8_ALU, Chip8_CPU
 *
 * AUTHORS: David Watkins
 * Updated: Gabrielle Taylor 5/3/2016
 * Dependencies:
 *****************************************************************************/

`ifndef CHIP8_ENUMS
`define CHIP8_ENUMS

/**
 * ALU_f is an input into the ALU to specify which operation to execute
 * 
 * 	- ALU_f_OR 		: bitwise OR
 * 	- ALU_f_AND 	: bitwise AND
 * 	- ALU_f_XOR		: bitwise XOR
 * 	- ALU_f_ADD		: Addition
 * 	- ALU_f_MINUS		: Subtract
 * 	- ALU_f_LSHIFT	: Shift left
 * 	- ALU_f_RSHIFT	: Shift right
 * 	- ALU_f_EQUALS 	: Equals compare
 * 	- ALU_f_GREATER	: Greater than compare
 * 	- ALU_f_INC 	: Increment
 */
typedef enum { 
	ALU_f_OR, 
	ALU_f_AND, 
	ALU_f_XOR, 
	ALU_f_ADD, 
	ALU_f_MINUS, 
	ALU_f_LSHIFT, 
	ALU_f_RSHIFT, 
	ALU_f_EQUALS, 
	ALU_f_GREATER, 
	ALU_f_INC, 
	ALU_f_NOP
} ALU_f ;

/**
 * PC_SRC defines the behavior of the program counter from output from the CPU
 * 
 * PC_SRC_STACK : Read from the current stack pointer
 * PC_SRC_ALU   : Read the output from the processor
 * PC_SRC_DEVICE: Read from linux input
 * PC_SRC_SKIP  : Assign PC = PC + 4
 * PC_SRC_HOLD  : Assign PC = PC
 * PC_SRC_NEXT  : Assign PC = PC + 2
 */
typedef enum {
	PC_SRC_STACK, 
	PC_SRC_ALU, 
	PC_SRC_DEVICE, 
	PC_SRC_SKIP, 
	PC_SRC_HOLD, 
	PC_SRC_NEXT
} PC_SRC;

/**
 * Chip8_STATE defines the current state of the emulator
 *
 * Chip8_RUNNING 		: The emulator is loading and executing instructions
 * Chip8_LOADING_ROM 	: The emulator is paused loading ROM from linux
 * Chip8_LOADING_FONT 	: The emulator is paused loading font from linux
 * Chip8_PAUSED 		: The emulator is paused and will only respond to linux
 */
 typedef enum {
 	Chip8_RUNNING,
	Chip8_LOADING_ROM,
	Chip8_LOADING_FONT,
	Chip8_PAUSED,
	Chip8_RUN_INSTRUCTION
 } Chip8_STATE;

/**
 * STACK_OP defines the behavior of the stack
 *
 * STACK_POP 	: Pop the stack and write out value
 * STACK_PUSH 	: Push the input onto the stack
 * STACK_HOLD 	: Do nothing
 */
 typedef enum {
 	STACK_POP,
 	STACK_PUSH,
 	STACK_HOLD
 } STACK_OP;

 parameter NEXT_PC_WRITE_STAGE = 32'd12;
 
`endif
