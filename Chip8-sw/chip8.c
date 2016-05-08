/*
 * Userspace program that communicates with the vga_ball device driver
 * primarily through ioctls
 *
 * David Watkins (djw2146), Ashley Kling (ask2203)
 * Columbia University
 */

#include <stdio.h>
#include "chip8driver.h"
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <stdlib.h>
#include "usbkeyboard.h"

static int CHIP8_FONTSET[] = 
	{
		0xF0, 0x90, 0x90, 0x90, 0xF0, //0
		0x20, 0x60, 0x20, 0x20, 0x70, //1
		0xF0, 0x10, 0xF0, 0x80, 0xF0, //2
		0xF0, 0x10, 0xF0, 0x10, 0xF0, //3
		0x90, 0x90, 0xF0, 0x10, 0x10, //4
		0xF0, 0x80, 0xF0, 0x10, 0xF0, //5
		0xF0, 0x80, 0xF0, 0x90, 0xF0, //6
		0xF0, 0x10, 0x20, 0x40, 0x40, //7
		0xF0, 0x90, 0xF0, 0x90, 0xF0, //8
		0xF0, 0x90, 0xF0, 0x10, 0xF0, //9
		0xF0, 0x90, 0xF0, 0x90, 0x90, //A
		0xE0, 0x90, 0xE0, 0x90, 0xE0, //B
		0xF0, 0x80, 0x80, 0x80, 0xF0, //C
		0xE0, 0x90, 0x90, 0x90, 0xE0, //D
		0xF0, 0x80, 0xF0, 0x80, 0xF0, //E
		0xF0, 0x80, 0xF0, 0x80, 0x80  //F
	};

#define FONTSET_LENGTH 80
#define MEMORY_START 0x200
#define MEMORY_END 0x1000

int chip8_fd;
struct libusb_device_handle *keyboard;
uint8_t endpoint_address;

void quit_program(int signal) {
	printf("Chip8 is terminating\n");
	close(chip8_fd);
	exit(0);
}

void chip8_write(chip8_opcode *op) {
	if(ioctl(chip8_fd, CHIP8_WRITE_ATTR, op)) {
		perror("ioctl(CHIP8_WRITE_ATTR) failed");
		quit_program(0);
	}
}

void chip8_read(chip8_opcode *op) {
	if(ioctl(chip8_fd, CHIP8_READ_ATTR, op)) {
		perror("ioctl(CHIP8_READ_ATTR) failed");
		printf("(%d, %d)\n", op->addr, op->data);
		quit_program(0);
	}
}

void setFramebuffer(int x, int y, int value) {
	chip8_opcode op;
	op.addr = FRAMEBUFFER_ADDR;
	op.data = (1 << 12) | ((value & 0x1) << 11) | ((x & 0x3f) << 5) | (y & 0x1f);
	chip8_write(&op);
}

int readFramebuffer(int x, int y) {
	chip8_opcode op;
	op.addr = FRAMEBUFFER_ADDR;
	op.data = (0 << 12) | (0 << 11) | ((x & 0x3f) << 5) | (y & 0x1f);
	chip8_write(&op);
	chip8_read(&op);
	return op.readdata;
}

void setMemory(int address, int data) {
	chip8_opcode op;
	op.addr = MEMORY_ADDR;
	op.data = (1 << 20) | ((address & 0xfff) << 8) | (data & 0xff);
	chip8_write(&op);	
}

int readMemory(int address) {
	chip8_opcode op;
	op.addr = MEMORY_ADDR;
	op.data = (0 << 20) | ((address & 0xfff) << 8) | (0 & 0xff);
	chip8_write(&op);	
	chip8_read(&op);
	return op.readdata;
}

/*
* Load the font set onto the chip8 sequentially
* Uses the op codes specified in chip8driver.h
*/
void loadfontset() {
	int i;
	for(i = 0; i < FONTSET_LENGTH; ++i) {
		setMemory(i, CHIP8_FONTSET[i]);
		// int mem_val = readMemory(i);
		// printf("(Address: %d) Wrote: %d, Read: %d\n", i, CHIP8_FONTSET[i], mem_val);
	}
}

void readWriteFramebuffer() {
	int x, y;
	for(x = 0; x < 64; ++x) {
		for(y = 0; y < 32; ++y) {

			int mem_val = readFramebuffer(x, y);
			setFramebuffer(x, y, !mem_val);

			// printf("(x: %d, y: %d) Wrote: %d, Read: %d\n", x, y, !mem_val, mem_val);
		}
	}
}

/*
* Load a ROM file byte by byte onto the chip8
* Uses the op codes specified in chip8driver.h
*/
void loadROM(const char* romfilename) {
	FILE *romfile;
	char buffer;
	long filelen;
	int i;

	romfile = fopen(romfilename, "rb");         
	fseek(romfile, 0, SEEK_END);          
	filelen = ftell(romfile);            
	rewind(romfile);                      

	for(i = 0; i < filelen && i < MEMORY_END - MEMORY_START; i++) {
		fread((&buffer), 1, 1, romfile); 

		setMemory(MEMORY_START + i, buffer);
	}

	fclose(romfile); // Close the file
}

void startChip8() {
	chip8_opcode op;
	op.addr = STATE_ADDR;
	op.data = RUNNING_STATE;

	chip8_write(&op);
}

void pauseChip8() {
	chip8_opcode op;
	op.addr = STATE_ADDR;
	op.data = PAUSED_STATE;

	chip8_write(&op);
}

void resetChip8() {
	//Need to write to registers and all
	//Reload font set etc.
}

void chip8writekeypress(char val, unsigned int ispressed) {
	chip8_opcode op;
	op.addr = KEY_PRESS_ADDR;
	op.data = (ispressed << 4) | val;
	chip8_write(&op);
}

/*
* Checks to see if a key is pressed, or depressed
* Then writes the associated action to the chip8 device
*/
void checkforkeypress() {
	struct usb_keyboard_packet packet;
	int transferred;
	char keystate[12];

	libusb_interrupt_transfer(keyboard, endpoint_address, (unsigned char *) &packet, sizeof(packet), &transferred, 0);
	if (transferred == sizeof(packet)) {
		sprintf(keystate, "%02x %02x %02x", packet.modifiers, packet.keycode[0], packet.keycode[1]);
		char val[1];
		if (kbiskeypad(&packet, val)) {
			printf("Key pressed %d\n", val[0]);
			chip8writekeypress(val[0], 1);
		} else if(kbisstart(&packet)) {
			startChip8();
		} else if(kbispause(&packet)) {
			pauseChip8();
		} else if(kbisreset(&packet)) {
			resetChip8();
		} else {
			chip8writekeypress(0, 0);
		}
	} else {
		printf("Size mismatch %d %d\n", sizeof(packet), transferred);
	}
}

int chip8isRunning() {
	chip8_opcode op;
	op.addr = STATE_ADDR;
	chip8_read(&op);
	return op.readdata == RUNNING_STATE;
}

int readPC() {
	chip8_opcode op;
	op.addr = PROGRAM_COUNTER_ADDR;
	chip8_read(&op);
	return op.readdata;
}

int main(int argc, char** argv)
{
	if(argc != 2) {
		printf("Usage: chip8 <romfilename>\n");
		exit(1);
	}

	/* Open the keyboard */
	if ( (keyboard = openkeyboard(&endpoint_address)) == NULL ) {
		fprintf(stderr, "Did not find a keyboard\n");
		exit(1);
	}

	static const char filename[] = "/dev/vga_led";
	if ( (chip8_fd = open(filename, O_RDWR)) == -1) {
		fprintf(stderr, "could not open %s\n", filename);
		return -1;
	}
	
	signal(SIGINT, quit_program);

	printf("Chip8 has started\n");
	pauseChip8();

	printf("Loading font set...\n");
	loadfontset();

	printf("Loading ROM %s\n", argv[1]);
	loadROM(argv[1]);

	printf("Flipping framebuffer\n");
	readWriteFramebuffer();

	printf("Chip8 has started\n");
	startChip8();
	while(chip8isRunning()) {
		int pc = readPC();
		printf("Program counter is: %d\n", pc);
		checkforkeypress();
		usleep(4000);
	}
	
	printf("Chip8 is terminating\n");
	close(chip8_fd);
	return 0;
}
