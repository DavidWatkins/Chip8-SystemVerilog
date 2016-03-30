ifneq (${KERNELRELEASE},)

# KERNELRELEASE defined: we are being compiled as part of the Kernel
        obj-m := chip8driver.o

else

# We are being compiled as a module: use the Kernel build system

	KERNEL_SOURCE := /usr/src/linux*
        PWD := $(shell pwd)

default: module chip8 

module:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} modules

chip8: usbkeyboard

clean:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} clean
	${RM} chip8

socfpga.dtb : socfpga.dtb
	dtc -O dtb -o socfpga.dtb socfpga.dts

endif 
