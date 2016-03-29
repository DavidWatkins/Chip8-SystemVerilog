ifneq (${KERNELRELEASE},)

# KERNELRELEASE defined: we are being compiled as part of the Kernel
        obj-m := chip8driver.o

else

# We are being compiled as a module: use the Kernel build system

	KERNEL_SOURCE := /usr/src/linux
        PWD := $(shell pwd)

default: module roll_ball bounce_ball

module:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} modules

clean:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} clean
	${RM} roll_ball bounce_ball

socfpga.dtb : socfpga.dtb
	dtc -O dtb -o socfpga.dtb socfpga.dts

endif 
