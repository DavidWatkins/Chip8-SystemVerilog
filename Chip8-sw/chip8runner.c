/*
 * Userspace program that communicates with the vga_ball device driver
 * primarily through ioctls
 *
 * David Watkins (djw2146), Ashley Kling (ask2203)
 * Columbia University
 */

#include <stdio.h>
#include "vga_ball.h"
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <stdlib.h>

int vga_ball_fd;

/* Read and print the segment values */
void print_ball_info() {
  vga_ball_arg_t vba;
  if(ioctl(vga_ball_fd, VGA_BALL_READ_ATTR, &vba)) {
    perror("ioctl(VGA_BALL_READ_ATTR) failed");
    return;
  }
  printf("Ball at pos (%d, %d) with radius %d\n", vba.xpos, vba.ypos, vba.radius);
}

/* Write the contents of the array to the display */
void write_ball_attr(const unsigned int xpos, const unsigned int ypos, const unsigned int radius)
{
  vga_ball_arg_t vba;
  vba.radius = radius;
  vba.xpos = xpos;
  vba.ypos = ypos;

  if(ioctl(vga_ball_fd, VGA_BALL_WRITE_ATTR, &vba)) {
    perror("ioctl(VGA_BALL_WRITE_ATTR) failed");
    return;
  }
}

void handle_signal(int signal) {
	printf("VGA Ball Userspace program terminating\n");
	exit(0);
}

int main()
{
  vga_ball_arg_t vba;
  int i, dx, dy;
  unsigned int xpos, ypos, radius;
  static const char filename[] = "/dev/vga_led";
	
	signal(SIGINT, handle_signal);

  printf("VGA Ball Userspace program started\n");

  if ( (vga_ball_fd = open(filename, O_RDWR)) == -1) {
    fprintf(stderr, "could not open %s\n", filename);
    return -1;
  }

  printf("initial state: ");
  print_ball_info();

  radius = 30;
  xpos = SCREEN_WIDTH/2;
  ypos = SCREEN_HEIGHT/2;
  dx = 10;
  dy = -5;
  while(1) {
  	write_ball_attr(xpos, ypos, radius);

  	//Update ball position
  	xpos += dx;
  	ypos += dy;

  	if(xpos + radius >= SCREEN_WIDTH || xpos - radius <= 0)
  		dx = -dx;
  	if(ypos + radius >= SCREEN_HEIGHT || ypos - radius <= 0)
  		dy = -dy;

  	//Print current state
  	printf("current state: ");
    print_ball_info();

  	usleep(40000);
  }
  
  printf("VGA Ball Userspace program terminating\n");
  return 0;
}
