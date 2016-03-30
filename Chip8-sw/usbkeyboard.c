#include "usbkeyboard.h"

#include <stdio.h>
#include <stdlib.h> 

/* References on libusb 1.0 and the USB HID/keyboard protocol
 *
 * http://libusb.org
 * http://www.dreamincode.net/forums/topic/148707-introduction-to-using-libusb-10/
 * http://www.usb.org/developers/devclass_docs/HID1_11.pdf
 * http://www.usb.org/developers/devclass_docs/Hut1_11.pdf
 */

/*
 * Find and return a USB keyboard device or NULL if not found
 * The argument con
 * 
 */
 struct libusb_device_handle *openkeyboard(uint8_t *endpoint_address) {
 	libusb_device **devs;
 	struct libusb_device_handle *keyboard = NULL;
 	struct libusb_device_descriptor desc;
 	ssize_t num_devs, d;
 	uint8_t i, k;

	/* Start the library */
 	if ( libusb_init(NULL) < 0 ) {
 		fprintf(stderr, "Error: libusb_init failed\n");
 		exit(1);
 	}

	/* Enumerate all the attached USB devices */
 	if ( (num_devs = libusb_get_device_list(NULL, &devs)) < 0 ) {
 		fprintf(stderr, "Error: libusb_get_device_list failed\n");
 		exit(1);
 	}

	/* Look at each device, remembering the first HID device that speaks
		 the keyboard protocol */

 	for (d = 0 ; d < num_devs ; d++) {
 		libusb_device *dev = devs[d];
 		if ( libusb_get_device_descriptor(dev, &desc) < 0 ) {
 			fprintf(stderr, "Error: libusb_get_device_descriptor failed\n");
 			exit(1);
 		}

 		if (desc.bDeviceClass == LIBUSB_CLASS_PER_INTERFACE) {
 			struct libusb_config_descriptor *config;
 			libusb_get_config_descriptor(dev, 0, &config);
 			for (i = 0 ; i < config->bNumInterfaces ; i++)	       
 				for ( k = 0 ; k < config->interface[i].num_altsetting ; k++ ) {
 					const struct libusb_interface_descriptor *inter =
 					config->interface[i].altsetting + k ;
 					if ( inter->bInterfaceClass == LIBUSB_CLASS_HID &&
 						inter->bInterfaceProtocol == USB_HID_KEYBOARD_PROTOCOL) {
 						int r;
 					if ((r = libusb_open(dev, &keyboard)) != 0) {
 						fprintf(stderr, "Error: libusb_open failed: %d\n", r);
 						exit(1);
 					}
 					if (libusb_kernel_driver_active(keyboard,i))
 						libusb_detach_kernel_driver(keyboard, i);
 					libusb_set_auto_detach_kernel_driver(keyboard, i);
 					if ((r = libusb_claim_interface(keyboard, i)) != 0) {
 						fprintf(stderr, "Error: libusb_claim_interface failed: %d\n", r);
 						exit(1);
 					}
 					*endpoint_address = inter->endpoint[0].bEndpointAddress;
 					goto found;
 				}
 			}
 		}
 	}

 	found:
 	libusb_free_device_list(devs, 1);

 	return keyboard;
 }

/*
* Check to see if any value in the keypad is currently pressed
*/
int kbiskeypad(struct usb_keyboard_packet* packet, char val[1]) {
	uint8_t keycode = packet->keycode[0];

	switch(keycode) {
		case KEY1: val[0] = 0x0; return 1; break;
		case KEY2: val[0] = 0x1; return 1; break;
		case KEY3: val[0] = 0x2; return 1; break;
		case KEYC: val[0] = 0x3; return 1; break;
		case KEY4: val[0] = 0x4; return 1; break;
		case KEY5: val[0] = 0x5; return 1; break;
		case KEY6: val[0] = 0x6; return 1; break;
		case KEYD: val[0] = 0x7; return 1; break;
		case KEY7: val[0] = 0x8; return 1; break;
		case KEY8: val[0] = 0x9; return 1; break;
		case KEY9: val[0] = 0xA; return 1; break;
		case KEYE: val[0] = 0xB; return 1; break;
		case KEYA: val[0] = 0xC; return 1; break;
		case KEY0: val[0] = 0xD; return 1; break;
		case KEYB: val[0] = 0xE; return 1; break;
		case KEYF: val[0] = 0xF; return 1; break;
		default: break;
	}

	return 0;
}

int kbisstart(struct usb_keyboard_packet* packet) {
	uint8_t keycode = packet->keycode[0];
	return keycode == KEY_START;
}

int kbispause(struct usb_keyboard_packet* packet) {
	uint8_t keycode = packet->keycode[0];
	return keycode == KEY_PAUSE;
}

int kbisreset(struct usb_keyboard_packet* packet) {
	uint8_t keycode = packet->keycode[0];
	return keycode == KEY_RESET;
}
