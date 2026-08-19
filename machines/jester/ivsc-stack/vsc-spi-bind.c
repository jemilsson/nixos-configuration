// SPDX-License-Identifier: GPL-2.0
/*
 * vsc-spi-bind - register the Intel VSC (IVSC) SPI device on the LJCA SPI bus.
 *
 * On this machine (Raptor Lake, jester) the whole in-kernel IVSC stack is
 * present and loaded: vsc-tp (mei-vsc-hw.ko, an spi_driver matching INTC1009),
 * platform-vsc (mei-vsc.ko), ivsc-ace and ivsc-csi. None of it binds anything,
 * because no spi_device is ever created for the ACPI node
 *
 *     \_SB.PC00.SPI1.SPFD   _HID INTC1009   "Intel SPI OED Device"
 *
 * whose _CRS carries a SpiSerialBus resource pointing at the LJCA-provided
 * virtual SPI controller
 *
 *     \_SB.PC00.XHCI.RHUB.HS08.VSPI   _HID INTC1098
 *
 * spi_register_controller() -> acpi_register_spi_devices() is supposed to walk
 * the namespace and create that device when spi-ljca registers the controller,
 * and on this box it does not (spi_master/spi1 stays childless, and no error
 * is logged). Without the spi_device the VSC firmware is never loaded, the
 * MEI-over-SPI link never comes up, ivsc-csi never gets a chance to hand CSI-2
 * lane ownership from the VSC to the IPU6, and the OV9234 IR sensor answers on
 * I2C but emits no packets.
 *
 * This module does that one missing step explicitly and reports exactly which
 * part of the ACPI path fails, so the root cause is visible in dmesg.
 *
 * Primary path: acpi_spi_device_alloc(NULL, adev, 0). With a NULL controller
 * the SPI core resolves the controller from the SpiSerialBus ResourceSource
 * itself, so we do not have to look the LJCA controller up. This is the same
 * sequence drivers/spi/spi.c uses for ACPI hot-add.
 *
 * Fallback path: if _CRS resolution finds no usable SpiSerialBus (for example
 * when firmware reports the pre-LJCA topology and points the resource at the
 * PCH controller), build the spi_device by hand on the controller that the
 * VSPI ACPI device owns.
 */

#include <linux/acpi.h>
#include <linux/delay.h>
#include <linux/device.h>
#include <linux/module.h>
#include <linux/spi/spi.h>
#include <linux/workqueue.h>

/* Same list vsc-tp.c matches on. */
static const char * const vsc_spi_hids[] = {
	"INTC1009", /* Raptor Lake */
	"INTC1058", /* Tiger Lake */
	"INTC1094", /* Alder Lake */
	"INTC10D0", /* Meteor Lake */
};

/* LJCA virtual SPI controller ACPI IDs (drivers/usb/misc/usb-ljca.c). */
static const char * const ljca_spi_hids[] = {
	"INTC1098",
	"INTC1096", /* some DSDTs name the SPI child differently */
	"INTC10B5",
};

/* Chip parameters used only by the manual fallback. Defaults match the
 * SpiSerialBus descriptor in this machine's DSDT (9 MHz, mode 3, 8 bits).
 */
static unsigned int speed_hz = 9000000;
module_param(speed_hz, uint, 0444);
MODULE_PARM_DESC(speed_hz, "fallback SPI clock in Hz");

static unsigned int spi_mode = SPI_MODE_3;
module_param(spi_mode, uint, 0444);
MODULE_PARM_DESC(spi_mode, "fallback SPI mode");

static struct spi_device *vsc_spi;
static struct acpi_device *vsc_adev;
static struct delayed_work retry_work;
static int retries;

#define VSC_BIND_RETRIES	10
#define VSC_BIND_DELAY_MS	1000

static struct acpi_device *vsc_find_adev(const char * const *hids, size_t n)
{
	struct acpi_device *adev;
	size_t i;

	for (i = 0; i < n; i++) {
		adev = acpi_dev_get_first_match_dev(hids[i], NULL, -1);
		if (adev)
			return adev;
	}

	return NULL;
}

/* Walk the physical nodes attached to the LJCA VSPI ACPI device and return the
 * spi_controller among them. spi_register_controller() binds the controller
 * device to the same ACPI companion as its auxiliary parent, so the controller
 * shows up in this list (as spi1 on this machine).
 */
static struct spi_controller *vsc_find_ljca_controller(void)
{
	struct acpi_device_physical_node *pn;
	struct spi_controller *ctlr = NULL;
	struct acpi_device *adev;

	adev = vsc_find_adev(ljca_spi_hids, ARRAY_SIZE(ljca_spi_hids));
	if (!adev)
		return NULL;

	mutex_lock(&adev->physical_node_lock);
	list_for_each_entry(pn, &adev->physical_node_list, node) {
		if (pn->dev->class && !strcmp(pn->dev->class->name, "spi_master")) {
			ctlr = container_of(pn->dev, struct spi_controller, dev);
			break;
		}
	}
	mutex_unlock(&adev->physical_node_lock);

	acpi_dev_put(adev);

	return ctlr;
}

static struct spi_device *vsc_alloc_manual(struct acpi_device *adev)
{
	struct spi_controller *ctlr;
	struct spi_device *spi;

	ctlr = vsc_find_ljca_controller();
	if (!ctlr) {
		pr_err("vsc-spi-bind: no LJCA SPI controller found\n");
		return ERR_PTR(-EPROBE_DEFER);
	}

	spi = spi_alloc_device(ctlr);
	if (!spi)
		return ERR_PTR(-ENOMEM);

	spi_set_chipselect(spi, 0, 0);
	spi->cs_index_mask = BIT(0);
	spi->max_speed_hz = speed_hz;
	spi->mode |= spi_mode;
	spi->bits_per_word = 8;
	spi->irq = -1;
	ACPI_COMPANION_SET(&spi->dev, adev);

	pr_info("vsc-spi-bind: built %s by hand on %s (%u Hz, mode %u)\n",
		acpi_device_hid(adev), dev_name(&ctlr->dev), speed_hz, spi_mode);

	return spi;
}

static int vsc_spi_bind(void)
{
	struct acpi_device *adev;
	struct spi_device *spi;
	int ret;

	adev = vsc_find_adev(vsc_spi_hids, ARRAY_SIZE(vsc_spi_hids));
	if (!adev) {
		pr_info("vsc-spi-bind: no IVSC SPI ACPI device on this system\n");
		return -ENODEV;
	}

	if (acpi_device_enumerated(adev)) {
		pr_info("vsc-spi-bind: %s already enumerated, nothing to do\n",
			dev_name(&adev->dev));
		acpi_dev_put(adev);
		return 0;
	}

	spi = acpi_spi_device_alloc(NULL, adev, 0);
	if (IS_ERR(spi)) {
		ret = PTR_ERR(spi);
		pr_warn("vsc-spi-bind: _CRS SPI lookup for %s failed (%d)\n",
			dev_name(&adev->dev), ret);
		if (ret == -EPROBE_DEFER) {
			acpi_dev_put(adev);
			return ret;
		}
		spi = vsc_alloc_manual(adev);
		if (IS_ERR(spi)) {
			ret = PTR_ERR(spi);
			acpi_dev_put(adev);
			return ret;
		}
	}

	acpi_set_modalias(adev, acpi_device_hid(adev), spi->modalias,
			  sizeof(spi->modalias));

	/* GpioInt in _CRS: vsc-tp uses spi->irq as the wakeup-host interrupt. */
	if (spi->irq < 0)
		spi->irq = acpi_dev_gpio_irq_get(adev, 0);
	if (spi->irq < 0) {
		pr_err("vsc-spi-bind: no GpioInt for %s (%d)\n",
		       dev_name(&adev->dev), spi->irq);
		spi_dev_put(spi);
		acpi_dev_put(adev);
		return spi->irq;
	}

	acpi_device_set_enumerated(adev);
	adev->power.flags.ignore_parent = true;

	ret = spi_add_device(spi);
	if (ret) {
		adev->power.flags.ignore_parent = false;
		acpi_device_clear_enumerated(adev);
		pr_err("vsc-spi-bind: spi_add_device failed (%d)\n", ret);
		spi_dev_put(spi);
		acpi_dev_put(adev);
		return ret;
	}

	vsc_spi = spi;
	vsc_adev = adev;	/* reference held until module unload */

	pr_info("vsc-spi-bind: registered %s as %s (irq %d)\n",
		acpi_device_hid(adev), dev_name(&spi->dev), spi->irq);

	return 0;
}

static void vsc_spi_retry(struct work_struct *work)
{
	int ret = vsc_spi_bind();

	if (ret == -EPROBE_DEFER && retries++ < VSC_BIND_RETRIES)
		schedule_delayed_work(&retry_work,
				      msecs_to_jiffies(VSC_BIND_DELAY_MS));
	else if (ret && ret != -ENODEV)
		pr_err("vsc-spi-bind: giving up (%d)\n", ret);
}

static int __init vsc_spi_bind_init(void)
{
	INIT_DELAYED_WORK(&retry_work, vsc_spi_retry);
	schedule_delayed_work(&retry_work, 0);

	return 0;
}

static void __exit vsc_spi_bind_exit(void)
{
	cancel_delayed_work_sync(&retry_work);

	if (vsc_spi) {
		spi_unregister_device(vsc_spi);
		vsc_spi = NULL;
	}
	if (vsc_adev) {
		vsc_adev->power.flags.ignore_parent = false;
		acpi_device_clear_enumerated(vsc_adev);
		acpi_dev_put(vsc_adev);
		vsc_adev = NULL;
	}
}

module_init(vsc_spi_bind_init);
module_exit(vsc_spi_bind_exit);

MODULE_DESCRIPTION("Register the Intel VSC SPI device on the LJCA SPI bus");
MODULE_LICENSE("GPL");
