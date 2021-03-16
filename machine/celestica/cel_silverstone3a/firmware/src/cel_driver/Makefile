#obj-m:=switchboard_fpga.o
obj-m:=seastone2_switchboard.o
#KERNELDIR:=/lib/modules/3.16.0-5-amd64/build
KVERS = $(shell uname -r)
KERNELDIR:=/lib/modules/$(KVERS)/build

PWD:=$(shell pwd)
default:
	$(MAKE) -C $(LINUXDIR)  M=$(PWD) modules
clean:
	$(MAKE) -C $(KERNELDIR)  M=$(PWD) clean
