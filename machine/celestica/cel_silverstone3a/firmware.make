#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile that defines the build of Celestica tools
#

firmware_BUILD_DIR		= $(MBUILDDIR)/firmware
firmware_SOURCE_DIR		= $(MACHINEDIR)/firmware

firmware_CONFIGURE_STAMP	= $(STAMPDIR)/firmware-configure
firmware_BUILD_STAMP		= $(STAMPDIR)/firmware-build
firmware_INSTALL_STAMP	= $(STAMPDIR)/firmware-install
firmware_STAMP		= $(firmware_BUILD_STAMP) \
				  $(firmware_INSTALL_STAMP)

PHONY += firmware firmware-install firmware-clean

all: firmware

firmware: $(firmware_STAMP)

ifndef MAKE_CLEAN
firmware_NEW_FILES = $(shell test -d $(firmware_BUILD_DIR) && test -f $(firmware_BUILD_STAMP) && \
	              find -L $(firmware_BUILD_DIR) -newer $(firmware_BUILD_STAMP) -type f \
			\! -name symlinks \! -name symlinks.o -print -quit)
endif

$(firmware_BUILD_DIR): $(firmware_SOURCE_DIR)
	rm -rf $@
	mkdir -p $(@D)
	#cp $(firmware_SOURCE_DIR)/config.svn $(firmware_BUILD_DIR)/config.svn
	cp -R $(firmware_SOURCE_DIR) $(MBUILDDIR)
	cd $(firmware_BUILD_DIR)
	#$(Q) $(firmware_BUILD_DIR)/fetch-code

firmware-build: $(firmware_BUILD_STAMP)
$(firmware_BUILD_STAMP): $(firmware_NEW_FILES) $(firmware_BUILD_DIR) $(DEV_SYSROOT_INIT_STAMP)
	$(Q) echo "====  Building firmware-$(firmware_VERSION) ===="
	$(Q) cd $(firmware_BUILD_DIR)/src/cel_driver &&	\
	    PATH='$(CROSSBIN):$(PATH)'		\
	    $(MAKE)				\
		V=$(V) 				\
		-f Makefile.wrapper		\
		CROSS_COMPILE=$(CROSSPREFIX)	\
		CEL_BSP_KSRCS=$(LINUXDIR)	\
		all
	$(Q) touch $@


firmware-install: $(firmware_INSTALL_STAMP)
$(firmware_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(firmware_BUILD_STAMP)
	$(Q) echo "==== Installing firmware ===="
	$(Q) cd $(firmware_BUILD_DIR)/src/cel_driver &&	\
	    PATH='$(CROSSBIN):$(PATH)'		\
	    $(MAKE)				\
		V=$(V) 				\
		-f Makefile.wrapper		\
		INSTALL_DIR=$(MACHINEDIR)/firmware/tools  \
		CROSS_COMPILE=$(CROSSPREFIX)	\
		CEL_BSP_KSRCS=$(LINUXDIR)	\
		install
	$(Q) touch $@

USERSPACE_CLEAN += firmware-clean
firmware-clean:
	$(Q) rm -rf $(firmware_BUILD_DIR)
	$(Q) rm -f $(firmware_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
