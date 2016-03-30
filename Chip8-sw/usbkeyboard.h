#ifndef _USBKEYBOARD_H
#define _USBKEYBOARD_H

#include <libusb-1.0/libusb.h>

#define USB_HID_KEYBOARD_PROTOCOL 1

/* Modifier bits */
#define USB_LCTRL  (1 << 0)
#define USB_LSHIFT (1 << 1)
#define USB_LALT   (1 << 2)
#define USB_LGUI   (1 << 3)
#define USB_RCTRL  (1 << 4)
#define USB_RSHIFT (1 << 5)
#define USB_RALT   (1 << 6) 
#define USB_RGUI   (1 << 7)


/*
* Keyboard layout for the Chip8:
*     +---------+
*     | 1 2 3 C |
*     | 4 5 6 D |
*     | 7 8 9 E |
*     | A 0 B F |
*     +---------+
* In this program mapped to a qwerty keyboard:
*     +---------+
*     | 1 2 3 4 |
*     | Q W E R |
*     | A S D F |
*     | Z X C V |
*     +---------+
* Relying on the ascii mapping defined by the usb standard
*/
#define KEY1 0x1E
#define KEY2 0x1F
#define KEY3 0x20
#define KEYC 0x06
#define KEY4 0x21
#define KEY5 0x22
#define KEY6 0x23
#define KEYD 0x07
#define KEY7 0x24
#define KEY8 0x25
#define KEY9 0x26
#define KEYE 0x08
#define KEYA 0x04
#define KEY0 0x27
#define KEYB 0x05
#define KEYF 0x09

/*
* Three additional keys will be defined
* START - Enter key
* PAUSE - P key
* RESET - O key
*/

#define KEY_START 0x28
#define KEY_PAUSE 0x13
#define KEY_RESET 0x12

struct usb_keyboard_packet {
  uint8_t modifiers;
  uint8_t reserved;
  uint8_t keycode[6];
};

/* Find and open a USB keyboard device.  Argument should point to
   space to store an endpoint address.  Returns NULL if no keyboard
   device was found. */
extern struct libusb_device_handle *openkeyboard(uint8_t *);
int kbiskeypad(struct usb_keyboard_packet* packet, char val[1]);
int kbisstart(struct usb_keyboard_packet* packet);
int kbispause(struct usb_keyboard_packet* packet);
int kbisreset(struct usb_keyboard_packet* packet);

#endif
