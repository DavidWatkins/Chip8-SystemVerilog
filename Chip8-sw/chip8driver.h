#ifndef __CHIP8_DRIVER_H__
#define __CHIP8_DRIVER_H__

#include <linux/ioctl.h>
#include <stdbool.h>

typedef struct {
	unsigned int data;
	unsigned int addr;
	unsigned int readdata;
} chip8_opcode;

#define CHIP8_MAGIC 'q'

/* ioctls and their arguments */
#define CHIP8_WRITE_ATTR _IOW(CHIP8_MAGIC, 1, chip8_opcode *)
#define CHIP8_READ_ATTR  _IOWR(CHIP8_MAGIC, 2, chip8_opcode *)

/*
* To write data to a particular register, use iowrite with
* NNNNNNXX
* Where NNNNNN is ignored
* XX is the 8 bits to be written
*
* To read from a register use ioread with one of the following addresses
*/
#define V0_ADDR 0x00
#define V1_ADDR 0x04
#define V2_ADDR 0x08
#define V3_ADDR 0x0C
#define V4_ADDR 0x10
#define V5_ADDR 0x14
#define V6_ADDR 0x18
#define V7_ADDR 0x1C
#define V8_ADDR 0x20
#define V9_ADDR 0x24
#define VA_ADDR 0x28
#define VB_ADDR 0x2C
#define VC_ADDR 0x30
#define VD_ADDR 0x34
#define VE_ADDR 0x38
#define VF_ADDR 0x3C

/*
* To write to the I index register
* NNNNDDDD
* DDDD is the 16 bits to write
* 
* Use ioread to read from the I register
*/
#define I_ADDR 0x40

/*
* To write to the sound timer
* NNNNNNDD
* Where DD is the number to write to the sound timer
* 
* Use ioread to read from the sound timer
*/
#define SOUND_TIMER_ADDR 0x44

/*
* To write to the delay timer
* NNNNNNDD
* Where DD is the number to write to the delay timer
* 
* Use ioread to read from the delay timer
*/
#define DELAY_TIMER_ADDR 0x48

/*
* To write to the stack pointer
* NNNNNNDD
* Where DD is the number to write to the stack pointer
* Only the last six bits are considered
* 
* Use ioread to read from the stack pointer
*/
#define STACK_POINTER_ADDR 0x60

/*
* To reset the stack, iowrite
*/
#define STACK_ADDR 0x4C

/*
* To write to the program counter
* 0014DDDD
* Where DDDD is the number to write to the program counter
* 
* Use ioread to read from the program counter
*/
#define PROGRAM_COUNTER_ADDR 0x50

/*
* To write a keypress to the Chip8 control unit
* NNNNNNPD
* Where D is the number corresponding to a keypress 0-F
* Where P is whether a key is currently pressed or not (0x1, 0x0)
*/
#define KEY_PRESS_ADDR 0x54

/*
* To change the state of the Chip8
* 001600DD
* Where DD is an 8-bit number corresponding to varying states
* * 0x01 - Running
* * 0x02 - Loading ROM
* * 0x03 - Loading font set
* * 0x04 - Paused
* The state is initially set to loading font set
*
* Use ioread to read the state of the Chip8
*/
#define STATE_ADDR 0x58
#define RUNNING_STATE 0x0
#define RUN_INSTRUCTION_STATE 0x1
#define PAUSED_STATE 0x2

/*
* To write to a location in memory
* 0000_0000_0001_AAAA_AAAA_AAAA_DDDD_DDDD
* Where DD is the 8-bit data that is to be written
* Where AAA is the 12-bit address to write the data
* Where W is a 1-bit value corresponding to a read or a write
*
* To read data from memory, use iowrite with
* 0000_0000_0000_AAAA_AAAA_AAAA_NNNN_NNNN
* Where AAA is the 12-bit address to read the data from
*/
#define MEMORY_ADDR 0x64

/*
* In order to write data to the framebuffer
* 0000_0000_0000_0000_0001_DXXX_XXXY_YYYY
* Where XX is the x position (6 bits)
* Where YY is the y position (5 bits)
* Where DD is the 8-bits of data to write to the screen
*
* In order to read data from the framebuffer
* 0000_0000_0000_0000_0000_NXXX_XXXY_YYYY
* Where XX is the x position (6 bits)
* Where YY is the y position (5 bits)
* Where NN is ignored
*/
#define FRAMEBUFFER_ADDR 0x5C

#define SCREEN_HEIGHT 480
#define SCREEN_WIDTH 640

#define MAX_FBX 32 //32/8
#define MAX_FBY 64

/*
* In order to write data to the instruction
* 0000_0000_0000_0000_IIII_IIII_IIII_IIII
* Where I corresponds to the 16 bits in the instruction
* The state must currently be in Chip8_RUN_INSTRUCTION
*
* In order to read data from the framebuffer
* 0000_0000_0000_0000_0000_NXXX_XXXY_YYYY
* Where XX is the x position (6 bits)
* Where YY is the y position (5 bits)
* Where NN is ignored
*/
#define INSTRUCTION_ADDR 0x68

#endif //__CHIP8_DRIVER_H__
