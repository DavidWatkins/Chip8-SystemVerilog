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
#define V1_ADDR 0x01
#define V2_ADDR 0x02
#define V3_ADDR 0x03
#define V4_ADDR 0x04
#define V5_ADDR 0x05
#define V6_ADDR 0x06
#define V7_ADDR 0x07
#define V8_ADDR 0x08
#define V9_ADDR 0x09
#define VA_ADDR 0x0A
#define VB_ADDR 0x0B
#define VC_ADDR 0x0C
#define VD_ADDR 0x0D
#define VE_ADDR 0x0E
#define VF_ADDR 0x0F

/*
* To write to the I index register
* NNNNDDDD
* DDDD is the 16 bits to write
* 
* Use ioread to read from the I register
*/
#define I_ADDR 0x10

/*
* To write to the sound timer
* NNNNNNDD
* Where DD is the number to write to the sound timer
* 
* Use ioread to read from the sound timer
*/
#define SOUND_TIMER_ADDR 0x11

/*
* To write to the delay timer
* NNNNNNDD
* Where DD is the number to write to the delay timer
* 
* Use ioread to read from the delay timer
*/
#define DELAY_TIMER_ADDR 0x12

/*
* To write to the stack pointer
* NNNNNNDD
* Where DD is the number to write to the stack pointer
* Only the last six bits are considered
* 
* Use ioread to read from the stack pointer
*/
#define STACK_POINTER_ADDR 0x13

/*
* To write to the stack at the current sp
* NNNNNDDD
* Where DDD is the number to write to the stack
* Increments the stack pointer as a result of the write
* 
* Use ioread to read from the stack at the sp
*/
#define STACK_ADDR 0x18

/*
* To write to the program counter
* 0014DDDD
* Where DDDD is the number to write to the program counter
* 
* Use ioread to read from the program counter
*/
#define PROGRAM_COUNTER_ADDR 0x14

/*
* To write a keypress to the Chip8 control unit
* NNNNNNPD
* Where D is the number corresponding to a keypress 0-F
* Where P is whether a key is currently pressed or not (0x1, 0x0)
*/
#define KEY_PRESS_ADDR 0x15

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
#define STATE_ADDR 0x16
#define RUNNING_STATE 0x0
#define LOADING_ROM_STATE 0x1
#define LOADING_FONT_SET_STATE 0x2
#define PAUSED_STATE 0x3

/*
* To write to a location in memory
* 1AAAA, DD
* Where DD is the 8-bit data that is to be written
* Where AAA is the 16-bit address to write the data
*
* To read data from memory, use ioread with
* 1NAAA
* Where AAA is the 16-bit address to read the data from
*/
#define MEMORY_ADDR 0x10000

/*
* In order to write data to the framebuffer
* XXYYDD
* Where XX is the x position
* Where YY is the y position
* Where DD is the 8-bits of data to write to the screen
*/
#define FRAMEBUFFER_ADDR 0x17

#define SCREEN_HEIGHT 480
#define SCREEN_WIDTH 640

#define MAX_FBX 4 //32/8
#define MAX_FBY 64

#endif //__CHIP8_DRIVER_H__
