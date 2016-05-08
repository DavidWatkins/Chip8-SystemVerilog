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
	chip8_read(&op);
	return (op.readdata & 0xff);
}

void setIRegister(int data) {
	chip8_opcode op;
	op.addr = I_ADDR;
	op.data = (data & 0xffff);
	chip8_write(&op);
}

int readIRegister() {
	chip8_opcode op;
	op.addr = I_ADDR;
	chip8_read(&op);
	return op.readdata;
}

int readRegister(int reg) {
	chip8_opcode op;
	op.addr = V0_ADDR + 4 * (reg & 0xf);
	chip8_read(&op);
	return op.readdata;
}

void writeRegister(int value, int reg) {
	chip8_opcode op;
	op.addr = V0_ADDR + 4 * (reg & 0xf);
	op.data = value & 0xff;
	chip8_write(&op);
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
		int got = readMemory(i);
		if (CHIP8_FONTSET[i] != got) {
			printf("Memory mismatch (expected: %d, got: %d)\n", CHIP8_FONTSET[i], got);
		} 
	}
}

void refreshFrameBuffer() {
	int x, y;
	for(x = 0; x < 64; ++x) {
		for(y = 0; y < 32; ++y) {

			// int mem_val = readFramebuffer(x, y);
			setFramebuffer(x, y, 0);

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
		int got = readMemory(MEMORY_START + i);
		if (buffer != got) {
			printf("Memory mismatch (expected: %d, got: %d)\n", buffer, got);
		} else {
			printf("%d ", got);
		}
	}

	for(i = i; i < MEMORY_END - MEMORY_START; ++i) {
		setMemory(MEMORY_START + i, 0);
	}

	fclose(romfile); // Close the file
	printf("\n");
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

int chip8isRunning() {
	chip8_opcode op;
	op.addr = STATE_ADDR;
	chip8_read(&op);
	return op.readdata == RUNNING_STATE;
}

int chip8isPaused() {
	chip8_opcode op;
	op.addr = STATE_ADDR;
	chip8_read(&op);
	return op.readdata == PAUSED_STATE;
}

int readPC() {
	chip8_opcode op;
	op.addr = PROGRAM_COUNTER_ADDR;
	chip8_read(&op);
	printf("Instruction: %d, PC: %d\n", (op.readdata & 0xfffff000) >> 12, (op.readdata & 0xfff));
	return (op.readdata & 0xfff);
}

void writePC(int pc) {
	chip8_opcode op;
	op.addr = PROGRAM_COUNTER_ADDR;
	op.data = pc;
	chip8_write(&op);
}

void printMemory() {
	int i = 0;
	for(i = 0; i < MEMORY_END; ++i) {
		printf("%d ", readMemory(i));
	}
	printf("\n");
}

void resetChip8(const char* filename) {
	//Need to write to registers and all
	//Reload font set etc.
	pauseChip8();
	loadfontset();
	loadROM(filename);
	refreshFrameBuffer();

	printMemory();
}

int readSoundTimer() {
	chip8_opcode op;
	op.addr = SOUND_TIMER_ADDR;
	chip8_read(&op);
	return op.readdata;
}

void writeSoundTimer() {
	chip8_opcode op;
	op.addr = SOUND_TIMER_ADDR;
	op.data = 0;
	chip8_write(&op);
}

void chip8writekeypress(char val, unsigned int ispressed) {
	chip8_opcode op;
	op.addr = KEY_PRESS_ADDR;
	op.data = ((ispressed & 0x1) << 4) | (val & 0xf);
	chip8_write(&op);
}

void printKeyState() {
	chip8_opcode op;
	op.addr = KEY_PRESS_ADDR;
	chip8_read(&op);

	printf("Is pressed: %d, Key val: %d, raw value: %d\n", (op.readdata & 0x10) >> 4, (op.readdata & 0xf), op.readdata);
}

/*
* Checks to see if a key is pressed, or depressed
* Then writes the associated action to the chip8 device
*/
void checkforkeypress(const char *file) {
	struct usb_keyboard_packet packet;
	int transferred;
	char keystate[12];

	libusb_interrupt_transfer(keyboard, endpoint_address, (unsigned char *) &packet, sizeof(packet), &transferred, 0);
	if (transferred == sizeof(packet)) {
		sprintf(keystate, "%02x %02x %02x", packet.modifiers, packet.keycode[0], packet.keycode[1]);
		char val[1];
		if (kbiskeypad(&packet, val)) {
			chip8writekeypress(val[0], 1);
		} else if(kbisstart(&packet)) {
			startChip8();
		} else if(kbispause(&packet)) {
			pauseChip8();
		} else if(kbisreset(&packet)) {
			resetChip8(file);
		} else {
			chip8writekeypress(0, 0);
		}
	} else {
		printf("Size mismatch %d %d\n", sizeof(packet), transferred);
	}
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
	refreshFrameBuffer();

	printf("Chip8 has started\n");
	// startChip8();
	writePC(0x200);

	printMemory();
	while(chip8isRunning() || chip8isPaused()) {
		if(chip8isPaused()) {
			printf("Paused\n");
		} else {
			printf("Running\n");
		}
		int pc = readPC();
		int mem = readMemory(pc);
		printf("Program counter is: %d, instruction is: %d\n", pc, mem);
		printf("I register: %d\n", readIRegister());
		printf("v1: %d\n", readRegister(1));
		printf("v2: %d\n", readRegister(2));
		// printf("Sound timer: %d\n", readSoundTimer());
		// int i;
		// for(i = 0; i < 100000; ++i) 
		// 	writeSoundTimer();
		// printf("Sound timer: %d\n", readSoundTimer());
		checkforkeypress(argv[1]);
		usleep(4000);
		printKeyState();
	}
	
	printf("Chip8 is terminating\n");
	close(chip8_fd);
	return 0;
}
