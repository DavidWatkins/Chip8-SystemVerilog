ifneq (${KERNELRELEASE},)
# KERNELRELEASE defined: we are being compiled as part of the Kernel
    obj-m := chip8driver.o
else

# We are being compiled as a module: use the Kernel build system

KERNEL_SOURCE := /usr/src/linux*
PWD := $(shell pwd)

CFLAGS = -Wall
OBJECTS = chip8.o usbkeyboard.o

default: module chip8 

module:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} modules

chip8 : $(OBJECTS)
	cc $(CFLAGS) -o chip8 $(OBJECTS) -lusb-1.0 -pthread

lab2.o : lab2.c fbputchar.h usbkeyboard.h
usbkeyboard.o : usbkeyboard.c usbkeyboard.h

.PHONY : clean
clean:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} clean
	${RM} chip8

socfpga.dtb : socfpga.dtb
	dtc -O dtb -o socfpga.dtb socfpga.dts

endif 
