/*
 * Device driver for the CHIP8 SystemVerilog Emulator
 *
 * A Platform device implemented using the misc subsystem
 *
 * Columbia University
 *
 * References:
 * Linux source: Documentation/driver-model/platform.txt
 *               drivers/misc/arm-charlcd.c
 * http://www.linuxforu.com/tag/linux-device-drivers/
 * http://free-electrons.com/docs/
 *
 * "make" to build
 * insmod chip8driver.ko
 *
 * Check code style with
 * checkpatch.pl --file --no-tree chip8driver.c
 */

#include <linux/module.h>
#include <linux/init.h>
#include <linux/errno.h>
#include <linux/version.h>
#include <linux/kernel.h>
#include <linux/platform_device.h>
#include <linux/miscdevice.h>
#include <linux/slab.h>
#include <linux/io.h>
#include <linux/of.h>
#include <linux/of_address.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include "chip8driver.h"

#define DRIVER_NAME "vga_led"

/*
 * Information about our device
 */
struct chip8_dev {
	struct resource res;         /* Resource: our registers */
	void __iomem *virtbase;      /* Where registers can be accessed in memory */
} dev;

/*
 * Writes an opcode (defined in chip8driver.h) to the device
 */
static void write_op(unsigned int addr, unsigned int instruction) {
	iowrite32(instruction, dev.virtbase + addr);
}

/*
 * Reads a value after sending a proper write opcode to the device
 */
static int read_value(unsigned int addr) {
	return ioread32(dev.virtbase + addr);
}

/*
* Checks to see if the address is validly formatted
*/
static int isValidInstruction(unsigned int addr, unsigned int instruction, int isWrite) {
	switch(addr) {
		//Register instructions are always okay
		case V0_ADDR: return 1;
		case V1_ADDR: return 1;
		case V2_ADDR: return 1;
		case V3_ADDR: return 1;
		case V4_ADDR: return 1;
		case V5_ADDR: return 1;
		case V6_ADDR: return 1;
		case V7_ADDR: return 1;
		case V8_ADDR: return 1;
		case V9_ADDR: return 1;
		case VA_ADDR: return 1;
		case VB_ADDR: return 1;
		case VC_ADDR: return 1;
		case VD_ADDR: return 1;
		case VE_ADDR: return 1;
		case VF_ADDR: return 1;
		case I_ADDR:  return 1;

		//Timer instructions are always okay
		case SOUND_TIMER_ADDR: return 1;
		case DELAY_TIMER_ADDR: return 1;

		//Stack instructions are only valid if they conform to stack size
		//Always looks at last three nibbles
		case STACK_POINTER_ADDR: return !isWrite || (instruction >= 0 && instruction < 64);
		case STACK_ADDR: 		 return 1;

		//Handle state transition
		case STATE_ADDR: switch(instruction) {
			case RUNNING_STATE: return 1;
			case RUN_INSTRUCTION_STATE: return 1;
			case PAUSED_STATE: return 1;
			default: return !isWrite;
		} 

		//Memory address
		case MEMORY_ADDR: 
		//0000_0000_0001_AAAA_AAAA_AAAA_DDDD_DDDD
		if(isWrite) return 1;
		else return 2;

		//Program Counter will always look at the last 3 nibbles
		case PROGRAM_COUNTER_ADDR: return 1;

		//Always considers last nibble
		case KEY_PRESS_ADDR: return 1;

		//Make sure X, Y, and data values conform
		//Data value will always be 1 byte
		case FRAMEBUFFER_ADDR: 
		//0000_0000_0000_0000_0001_DXXX_XXXY_YYYY
		if(isWrite) return 1;
		else 		return 2;

		case INSTRUCTION_ADDR: return 1;

		default: break;
	}

	return 0;
}


/*
 * Handle ioctl() calls from userspace:
 * Read or write the segments on single digits.
 * Note extensive error checking of arguments
 */
static long chip8_ioctl(struct file *f, unsigned int cmd, unsigned long arg)
{
	chip8_opcode op;
	int isWrite = 0;

	switch (cmd) {
	case CHIP8_WRITE_ATTR:
		if (copy_from_user(&op, (chip8_opcode *) arg, sizeof(chip8_opcode)))
			return -EACCES;
		if (!isValidInstruction(op.addr, op.data, 1))
			return -EINVAL;
		write_op(op.addr, op.data);
		break;

	case CHIP8_READ_ATTR:
		if (copy_from_user(&op, (chip8_opcode *) arg, sizeof(chip8_opcode)))
			return -EACCES;
		isWrite = isValidInstruction(op.addr, op.data, 0);
		if(isWrite == 0)
			return -EINVAL;


		if(isWrite == 2)
			write_op(op.addr, op.data);
		
		op.readdata = read_value(op.addr);
		if (copy_to_user((chip8_opcode *) arg, &op, sizeof(chip8_opcode)))
			return -EACCES;
		break;

	default:
		return -EINVAL;
	}

	return 0;
}

/* The operations our device knows how to do */
static const struct file_operations chip8_fops = {
	.owner		= THIS_MODULE,
	.unlocked_ioctl = chip8_ioctl,
};

/* Information about our device for the "misc" framework -- like a char dev */
static struct miscdevice chip8_misc_device = {
	.minor		= MISC_DYNAMIC_MINOR,
	.name		= DRIVER_NAME,
	.fops		= &chip8_fops,
};

/*
 * Initialization code: get resources (registers) and display
 * a welcome message
 */
static int __init chip8_probe(struct platform_device *pdev)
{
	int ret;

	/* Register ourselves as a misc device: creates /dev/chip8 */
	ret = misc_register(&chip8_misc_device);

	/* Get the address of our registers from the device tree */
	ret = of_address_to_resource(pdev->dev.of_node, 0, &dev.res);
	if (ret) {
		ret = -ENOENT;
		goto out_deregister;
	}

	/* Make sure we can use these registers */
	if (request_mem_region(dev.res.start, resource_size(&dev.res), DRIVER_NAME) == NULL) {
		ret = -EBUSY;
		goto out_deregister;
	}

	/* Arrange access to our registers */
	dev.virtbase = of_iomap(pdev->dev.of_node, 0);
	if (dev.virtbase == NULL) {
		ret = -ENOMEM;
		goto out_release_mem_region;
	}

	/* Write paused state to the chip8 device */
	write_op(STATE_ADDR, PAUSED_STATE);

	return 0;

out_release_mem_region:
	release_mem_region(dev.res.start, resource_size(&dev.res));
out_deregister:
	misc_deregister(&chip8_misc_device);
	return ret;
}

/* Clean-up code: release resources */
static int chip8_remove(struct platform_device *pdev)
{
	iounmap(dev.virtbase);
	release_mem_region(dev.res.start, resource_size(&dev.res));
	misc_deregister(&chip8_misc_device);
	return 0;
}

/* Which "compatible" string(s) to search for in the Device Tree */
#ifdef CONFIG_OF
static const struct of_device_id chip8_of_match[] = {
	{ .compatible = "altr,vga_led" },
	{},
};
MODULE_DEVICE_TABLE(of, chip8_of_match);
#endif

/* Information for registering ourselves as a "platform" driver */
static struct platform_driver chip8_driver = {
	.driver	= {
		.name	= DRIVER_NAME,
		.owner	= THIS_MODULE,
		.of_match_table = of_match_ptr(chip8_of_match),
	},
	.remove	= __exit_p(chip8_remove),
};

/* Called when the module is loaded: set things up */
static int __init chip8_init(void)
{
	pr_info(DRIVER_NAME ": init\n");
	return platform_driver_probe(&chip8_driver, chip8_probe);
}

/* Called when the module is unloaded: release resources */
static void __exit chip8_exit(void)
{
	platform_driver_unregister(&chip8_driver);
	pr_info(DRIVER_NAME ": exit\n");
}

module_init(chip8_init);
module_exit(chip8_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("The Chip8 Team");
MODULE_DESCRIPTION("Chip8 Emulator");
