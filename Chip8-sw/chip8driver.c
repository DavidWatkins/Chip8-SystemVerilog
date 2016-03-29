/*
 * Device driver for the VGA Ball Emulator
 *
 * A Platform device implemented using the misc subsystem
 *
 * David Watkins (djw2146), Ashley Kling (ask2203)
 * Columbia University
 *
 * References:
 * Linux source: Documentation/driver-model/platform.txt
 *               drivers/misc/arm-charlcd.c
 * http://www.linuxforu.com/tag/linux-device-drivers/
 * http://free-electrons.com/docs/
 *
 * "make" to build
 * insmod vga_ball.ko
 *
 * Check code style with
 * checkpatch.pl --file --no-tree vga_ball.c
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
#include "vga_ball.h"

#define DRIVER_NAME "vga_led"

/*
 * Information about our device
 */
struct vga_ball_dev {
	struct resource res;         /* Resource: our registers */
	void __iomem *virtbase;      /* Where registers can be accessed in memory */
	unsigned int radius;
	unsigned int xpos;
	unsigned int ypos;
} dev;

/*
 * Write attributes of ball (radius, y, x)
 * Assumes ball attributes are in range
 */

static void write_ball(unsigned int xpos, unsigned int ypos, unsigned int radius) {
	iowrite32(xpos, dev.virtbase + X_WRITE_POS);
	iowrite32(ypos, dev.virtbase + Y_WRITE_POS);
	iowrite32(radius, dev.virtbase + R_WRITE_POS);

	dev.radius = radius;
	dev.xpos = xpos;
	dev.ypos = ypos;
}

/*
 * Handle ioctl() calls from userspace:
 * Read or write the segments on single digits.
 * Note extensive error checking of arguments
 */
static long vga_ball_ioctl(struct file *f, unsigned int cmd, unsigned long arg)
{
	vga_ball_arg_t vba;

	switch (cmd) {
	case VGA_BALL_WRITE_ATTR:
		if (copy_from_user(&vba, (vga_ball_arg_t *) arg, sizeof(vga_ball_arg_t)))
			return -EACCES;
		if (vba.radius > MAX_RADIUS || vba.radius < MIN_RADIUS)
			return -EINVAL;
		if (vba.xpos > SCREEN_WIDTH || vba.xpos < 0)
			return -EINVAL;
		if (vba.ypos > SCREEN_HEIGHT || vba.ypos < 0)
			return -EINVAL;
		write_ball(vba.xpos, vba.ypos, vba.radius);
		break;

	case VGA_BALL_READ_ATTR:
		if (copy_from_user(&vba, (vga_ball_arg_t *) arg, sizeof(vga_ball_arg_t)))
			return -EACCES;
		vba.radius = dev.radius;
		vba.xpos = dev.xpos;
		vba.ypos = dev.ypos;
		if (copy_to_user((vga_ball_arg_t *) arg, &vba, sizeof(vga_ball_arg_t)))
			return -EACCES;
		break;

	default:
		return -EINVAL;
	}

	return 0;
}

/* The operations our device knows how to do */
static const struct file_operations vga_ball_fops = {
	.owner		= THIS_MODULE,
	.unlocked_ioctl = vga_ball_ioctl,
};

/* Information about our device for the "misc" framework -- like a char dev */
static struct miscdevice vga_ball_misc_device = {
	.minor		= MISC_DYNAMIC_MINOR,
	.name		= DRIVER_NAME,
	.fops		= &vga_ball_fops,
};

/*
 * Initialization code: get resources (registers) and display
 * a welcome message
 */
static int __init vga_ball_probe(struct platform_device *pdev)
{
	//Place ball at (320,240) with radius 3
	static unsigned int init_pos[3] = {SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 20};
	int ret;

	/* Register ourselves as a misc device: creates /dev/vga_ball */
	ret = misc_register(&vga_ball_misc_device);

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

	/* Display a welcome message */
	write_ball(init_pos[0], init_pos[1], init_pos[2]);

	return 0;

out_release_mem_region:
	release_mem_region(dev.res.start, resource_size(&dev.res));
out_deregister:
	misc_deregister(&vga_ball_misc_device);
	return ret;
}

/* Clean-up code: release resources */
static int vga_ball_remove(struct platform_device *pdev)
{
	iounmap(dev.virtbase);
	release_mem_region(dev.res.start, resource_size(&dev.res));
	misc_deregister(&vga_ball_misc_device);
	return 0;
}

/* Which "compatible" string(s) to search for in the Device Tree */
#ifdef CONFIG_OF
static const struct of_device_id vga_ball_of_match[] = {
	{ .compatible = "altr,vga_led" },
	{},
};
MODULE_DEVICE_TABLE(of, vga_ball_of_match);
#endif

/* Information for registering ourselves as a "platform" driver */
static struct platform_driver vga_ball_driver = {
	.driver	= {
		.name	= DRIVER_NAME,
		.owner	= THIS_MODULE,
		.of_match_table = of_match_ptr(vga_ball_of_match),
	},
	.remove	= __exit_p(vga_ball_remove),
};

/* Called when the module is loaded: set things up */
static int __init vga_ball_init(void)
{
	pr_info(DRIVER_NAME ": init\n");
	return platform_driver_probe(&vga_ball_driver, vga_ball_probe);
}

/* Called when the module is unloaded: release resources */
static void __exit vga_ball_exit(void)
{
	platform_driver_unregister(&vga_ball_driver);
	pr_info(DRIVER_NAME ": exit\n");
}

module_init(vga_ball_init);
module_exit(vga_ball_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("David Watkins (djw2146), Ashley Kling (ask2203)");
MODULE_DESCRIPTION("VGA Ball Emulator");
