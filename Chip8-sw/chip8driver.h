#ifndef __CHIP8_DRIVER_H__
#define __CHIP8_DRIVER_H__

#include <linux/ioctl.h>
#include <stdbool.h>

typedef struct {
	unsigned int opcode;
} chip8_opcode;

#define CHIP8_MAGIC 'q'

/* ioctls and their arguments */
#define CHIP8_WRITE_ATTR _IOW(CHIP8_MAGIC, 1, chip8_opcode *)
#define CHIP8_READ_ATTR  _IOWR(CHIP8_MAGIC, 2, chip8_opcode *)

/*
* To write data to a particular register
* 000X00DD
* Where X is the current register to write to
* and DD is the 8 bits of data to write to it
*
* To read from a register
* 002X0000
* Where X is the register you want to read from
*/
#define V0_WRITE_ADDR 0x0000
#define V1_WRITE_ADDR 0x0001
#define V2_WRITE_ADDR 0x0002
#define V3_WRITE_ADDR 0x0003
#define V4_WRITE_ADDR 0x0004
#define V5_WRITE_ADDR 0x0005
#define V6_WRITE_ADDR 0x0006
#define V7_WRITE_ADDR 0x0007
#define V8_WRITE_ADDR 0x0008
#define V9_WRITE_ADDR 0x0009
#define VA_WRITE_ADDR 0x000A
#define VB_WRITE_ADDR 0x000B
#define VC_WRITE_ADDR 0x000C
#define VD_WRITE_ADDR 0x000D
#define VE_WRITE_ADDR 0x000E
#define VF_WRITE_ADDR 0x000F

#define V0_READ_ADDR 0x0020
#define V1_READ_ADDR 0x0021
#define V2_READ_ADDR 0x0022
#define V3_READ_ADDR 0x0023
#define V4_READ_ADDR 0x0024
#define V5_READ_ADDR 0x0025
#define V6_READ_ADDR 0x0026
#define V7_READ_ADDR 0x0027
#define V8_READ_ADDR 0x0028
#define V9_READ_ADDR 0x0029
#define VA_READ_ADDR 0x002A
#define VB_READ_ADDR 0x002B
#define VC_READ_ADDR 0x002C
#define VD_READ_ADDR 0x002D
#define VE_READ_ADDR 0x002E
#define VF_READ_ADDR 0x002F

/*
* To write to the I index register
* 0010DDDD
* Where 0010 is the op code, and DDDD is the 16 bits to write
* 
* To read from the I index register
* 00300000
*/
#define I_WRITE_ADDR 0x0010
#define I_READ_ADDR 0x0030

/*
* To write to the sound timer
* 001100DD
* Where DD is the number to write to the sound timer
* 
* To read from the sound timer
* 00310000
*/
#define SOUND_TIMER_WRITE_ADDR 0x0011
#define SOUND_TIMER_READ_ADDR 0x0031

/*
* To write to the delay timer
* 001200DD
* Where DD is the number to write to the delay timer
* 
* To read from the delay timer
* 00320000
*/
#define DELAY_TIMER_WRITE_ADDR 0x0012
#define DELAY_TIMER_READ_ADDR 0x0032

/*
* To write to the stack pointer
* 001300DD
* Where DD is the number to write to the stack pointer
* 
* To read from the stack pointer
* 00330000
*/
#define STACK_POINTER_WRITE_ADDR 0x0013
#define STACK_POINTER_READ_ADDR 0x0033

/*
* To write to the program counter
* 0014DDDD
* Where DDDD is the number to write to the program counter
* 
* To read from the program counter
* 00340000
*/
#define PROGRAM_COUNTER_WRITE_ADDR 0x0014
#define PROGRAM_COUNTER_READ_ADDR 0x0034

/*
* To write a keypress to the Chip8 control unit
* 001500PD
* Where D is the number corresponding to a keypress 0-F
* Where P is whether a key is currently pressed or not (0x1, 0x0)
*/
#define KEY_PRESS_ADDR 0x0015

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
* To read the state of the Chip8
* 00360000
*/
#define STATE_WRITE_ADDR 0x0016
#define RUNNING_STATE 0x01
#define LOADING_ROM_STATE 0x02
#define LOADING_FONT_SET_STATE 0x03
#define PAUSED_STATE 0x04
#define STATE_READ_ADDR 0x0036

/*
* To write to a location in memory
* 01DDAAAA
* Where DD is the 8-bit data that is to be written
* Where AAAA is the 16-bit address to write the data
*
* To read data from memory
* 0300AAAA
* Where AAAA is the 16-bit address to read the data
*/
#define MEMORY_WRITE_ADDR 0x0100
#define MEMORY_READ_ADDR 0x300

/*
* In order to write data to the framebuffer
* 10XXYYDD
* Where XX is the x position
* Where YY is the y position
* Where DD is the 8-bits of data to write to the screen
*/
#define FRAMEBUFFER_ADDR 0x1000

#define SCREEN_HEIGHT 480
#define SCREEN_WIDTH 640

#endif //__CHIP8_DRIVER_H__
