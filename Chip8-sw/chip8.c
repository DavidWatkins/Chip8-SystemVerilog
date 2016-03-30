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

// /* Read and print the segment values */
// void print_ball_info() {
// 	vga_ball_arg_t vba;
// 	if(ioctl(vga_ball_fd, VGA_BALL_READ_ATTR, &vba)) {
// 		perror("ioctl(VGA_BALL_READ_ATTR) failed");
// 		return;
// 	}
// 	printf("Ball at pos (%d, %d) with radius %d\n", vba.xpos, vba.ypos, vba.radius);
// }

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

/*
* Load the font set onto the chip8 sequentially
* Uses the op codes specified in chip8driver.h
*/
void loadfontset() {
	int i;
	for(i = 0; i < FONTSET_LENGTH; ++i) {
		chip8_opcode op;
		op.opcode = MEMORY_WRITE_ADDR | CHIP8_FONTSET[i];
		op.opcode = (op.opcode << 16) | i;

		chip8_write(&op);
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

		chip8_opcode op;
		op.opcode = MEMORY_WRITE_ADDR | buffer;
		op.opcode = (op.opcode << 16) | (i + MEMORY_START);

		chip8_write(&op);
	}

	fclose(romfile); // Close the file
}

void startChip8() {
	chip8_opcode op;
	op.opcode = (STATE_WRITE_ADDR << 16) | RUNNING_STATE;

	chip8_write(&op);
}

void pauseChip8() {
	chip8_opcode op;
	op.opcode = (STATE_WRITE_ADDR << 16) | PAUSED_STATE;

	chip8_write(&op);
}

void resetChip8() {
	//Need to write to registers and all
	//Reload font set etc.
}

void chip8writekeypress(char val, unsigned int ispressed) {
	chip8_opcode op;
	op.opcode = (KEY_PRESS_ADDR << 16) | (ispressed << 4) | val;
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
	}
}

int chip8isRunning() {
	return 1;
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

	chip8_opcode op;
	static const char filename[] = "/dev/chip8";
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

	printf("Chip8 has started\n");
	startChip8();
	while(chip8isRunning()) {
		checkforkeypress();
		usleep(4000);
	}
	
	printf("Chip8 is terminating\n");
	close(chip8_fd);
	return 0;
}
