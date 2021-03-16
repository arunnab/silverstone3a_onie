# Celestica Silverstone 3a Switch

ONIE_ARCH ?= x86_64
SWITCH_ASIC_VENDOR = bcm

VENDOR_REV ?= 0

#CONSOLE_SPEED = 9600
# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

# The VENDOR_VERSION string is appended to the overal ONIE version
# string.  HW vendors can use this to appended their own versioning
# information to the base ONIE version string.
VENDOR_VERSION = .0.0.1

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Open Compute Project IANA number
VENDOR_ID = 12244
# Add the onie-syseeprom command for this platform

# Enable the i2ctools and the onie-syseeprom command for this platform
I2CTOOLS_ENABLE = yes
I2CTOOLS_SYSEEPROM = no

# Set Linux kernel version
#LINUX_VERSION		= 4.11
#LINUX_MINOR_VERSION	= 3

# Specify uClibc version
#UCLIBC_VERSION = 0.9.32.1
UEFI_ENABLE = yes
IPMITOOL_ENABLE = yes
#EXTRA_CMDLINE_LINUX = earlycon=uart8250,mmio,0xdff9b000
#FIRMWARE_UPDATE_ENABLE = yes

#include $(MACHINEDIR)/firmware.make

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
