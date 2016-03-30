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

#define DRIVER_NAME "chip8"

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
static void write_op(unsigned int opcode) {
	iowrite32(opcode, dev.virtbase);
}

/*
 * Reads a value after sending a proper write opcode to the device
 */
static void read_value(unsigned int *value) {
	ioread32(value);
}

/*
* Checks to see if the opcode is validly formatted
* Need to create a more robust test, including check values
*/
static int isValidWriteOpcode(unsigned int opcode) {
	return (opcode & (V0_WRITE_ADDR << 16)
		|| (opcode & (V1_WRITE_ADDR << 16)
		|| (opcode & (V2_WRITE_ADDR << 16)
		|| (opcode & (V3_WRITE_ADDR << 16)
		|| (opcode & (V4_WRITE_ADDR << 16)
		|| (opcode & (V5_WRITE_ADDR << 16)
		|| (opcode & (V6_WRITE_ADDR << 16)
		|| (opcode & (V7_WRITE_ADDR << 16)
		|| (opcode & (V8_WRITE_ADDR << 16)
		|| (opcode & (V9_WRITE_ADDR << 16)
		|| (opcode & (VA_WRITE_ADDR << 16)
		|| (opcode & (VB_WRITE_ADDR << 16)
		|| (opcode & (VC_WRITE_ADDR << 16)
		|| (opcode & (VD_WRITE_ADDR << 16)
		|| (opcode & (VE_WRITE_ADDR << 16)
		|| (opcode & (VF_WRITE_ADDR << 16)
		|| (opcode & (I_WRITE_ADDR << 16)
		|| (opcode & (SOUND_TIMER_WRITE_ADDR << 16)
		|| (opcode & (DELAY_TIMER_WRITE_ADDR << 16)
		|| (opcode & (STACK_POINTER_WRITE_ADDR << 16)
		|| (opcode & (PROGRAM_COUNTER_WRITE_ADDR << 16)
		|| (opcode & (KEY_PRESS_ADDR << 16)
		|| (opcode & (STATE_WRITE_ADDR << 16)
		|| (opcode & (MEMORY_WRITE_ADDR << 16)
		|| (opcode & (FRAMEBUFFER_ADDR << 16);
}

static int isValidReadOpcode(unsigned int opcode) {
	return (opcode & (V0_READ_ADDR << 16))
		|| (opcode & (V1_READ_ADDR << 16))
		|| (opcode & (V2_READ_ADDR << 16))
		|| (opcode & (V3_READ_ADDR << 16))
		|| (opcode & (V4_READ_ADDR << 16))
		|| (opcode & (V5_READ_ADDR << 16))
		|| (opcode & (V6_READ_ADDR << 16))
		|| (opcode & (V7_READ_ADDR << 16))
		|| (opcode & (V8_READ_ADDR << 16))
		|| (opcode & (V9_READ_ADDR << 16))
		|| (opcode & (VA_READ_ADDR << 16))
		|| (opcode & (VB_READ_ADDR << 16))
		|| (opcode & (VC_READ_ADDR << 16))
		|| (opcode & (VD_READ_ADDR << 16))
		|| (opcode & (VE_READ_ADDR << 16))
		|| (opcode & (VF_READ_ADDR << 16))
		|| (opcode & (I_READ_ADDR << 16))
		|| (opcode & (SOUND_TIMER_READ_ADDR << 16))
		|| (opcode & (DELAY_TIMER_READ_ADDR << 16))
		|| (opcode & (STACK_POINTER_READ_ADDR << 16))
		|| (opcode & (PROGRAM_COUNTER_READ_ADDR << 16))
		|| (opcode & (STATE_READ_ADDR << 16))
		|| (opcode & (MEMORY_READ_ADDR << 16));
}

/*
 * Handle ioctl() calls from userspace:
 * Read or write the segments on single digits.
 * Note extensive error checking of arguments
 */
static long chip8_ioctl(struct file *f, unsigned int cmd, unsigned long arg)
{
	chip8_opcode op;

	switch (cmd) {
	case CHIP8_WRITE_ATTR:
		if (copy_from_user(&op, (chip8_opcode *) arg, sizeof(chip8_opcode)))
			return -EACCES;
		if (!isValidWriteOpcode(op.opcode))
			return -EINVAL;
		write_op(op.opcode);
		break;

	case CHIP8_READ_ATTR:
		if (copy_from_user(&op, (chip8_opcode *) arg, sizeof(chip8_opcode)))
			return -EACCES;
		if (!isValidReadOpcode(op.opcode))
			return -EINVAL;

		iowrite32(op.opcode);
		ioread32(&(op.opcode));
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
	//Place ball at (320,240) with radius 3
	static unsigned int init_pos[3] = {SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 20};
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
	write_op((STATE_WRITE_ADDR << 16) | PAUSED_STATE);

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
	{ .compatible = "altr,chip8" },
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
