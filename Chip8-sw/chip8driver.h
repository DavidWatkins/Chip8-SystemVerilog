#ifndef _VGA_LED_H
#define _VGA_LED_H

#include <linux/ioctl.h>

typedef struct {
  unsigned int radius;    /* Radius of ball */
  unsigned int xpos; 	  /* X position */
  unsigned int ypos; 	  /* Y position */
} vga_ball_arg_t;

#define VGA_BALL_MAGIC 'q'

/* ioctls and their arguments */
#define VGA_BALL_WRITE_ATTR _IOW(VGA_BALL_MAGIC, 1, vga_ball_arg_t *)
#define VGA_BALL_READ_ATTR  _IOWR(VGA_BALL_MAGIC, 2, vga_ball_arg_t *)

#define X_WRITE_POS 0
#define Y_WRITE_POS 4
#define R_WRITE_POS 8

#define SCREEN_HEIGHT 480
#define SCREEN_WIDTH 640

#define MIN_RADIUS 1
#define MAX_RADIUS 200

#endif
