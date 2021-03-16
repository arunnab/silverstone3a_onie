#!/bin/sh

packed_fpga_image=SILVERSTONE_FPGA_primary_V0001_0005.bin
packed_fpga_ver=1.5

#Packed BMC version info
packed_bmc_image=R1141-J0006-01_Silverstone_0.16.ima
packed_bmc_ver=0x10

#Packed BIOS info
packed_bios_image=Silverstone_BIOS_1.1.1.BIN
packed_bios_ver=1.1.1

#Packed CPLD info
packed_cpld_image=Silverstone_V04_20190703_FAN_V02_BASE_V03_COME_V07_SW1_V00_SW2_V00.vme
packed_cpld_ver=04
cpld_ver=

fpga_update_required=0
bios_update_required=0
cpld_update_required=0
backup_bmc_update_required=0
main_bmc_update_required=0

update_log=/mnt/onie-boot/onie/update/update.log

log_and_print()
{
   ts=$(date +"%Y-%m-%d %T")
   echo $1
   echo $ts $1 >> $update_log
}

updater_err_exit()
{
    log_and_print "ONIE FW updater exiting...."
    exit 1
}

update_bios()
{
    ## select bois
    ipmitool raw 0x3a 0x05 0x01 $1
    /bin/CFUFLASH -cd -d 2 /bin/$packed_bios_image
    [ $? -eq 0 ] || {
        log_and_print "update bios failed!!!"
        updater_err_exit
    }
}

update_bmc()
{
    (echo "y"
	 sleep 2
	 echo "y")|/bin/CFUFLASH -cd -d 1 -mse $1 /bin/$packed_bmc_image
    [ $? -eq 0 ] || {
        log_and_print "update bmc failed!!!"
        updater_err_exit
    }     
}

wait_bmc_ready()
{
    local ipmi_log=
    local str_h=
    local str_l=
    local dev_id=

    for waitcnt in 1 2 3 4 5 6
    do
        ipmi_log=$(ipmitool raw 0x06 0x01)
        str_h=$(echo $ipmi_log | awk {'print $1'})
        str_l=$(echo $ipmi_log | awk {'print $2'})
        dev_id="$str_h-$str_l"
        if [ "$dev_id" = "20-01" ]
        then
            log_and_print "Check BMC Ok."
            break
        else
            log_and_print "Wait cnt: $waitcnt"
            sleep 5
        fi
    done

    if [ "$waitcnt" = "6" ]; then
        log_and_print "Wait BMC ready failed!"
        return 1
    fi   

    return 0  
}

enable_virtual_usb()
{
    local ipmi_ret=
    ipmi_ret=$(ipmitool raw 0x32 0xab | awk {'print $1'})
    if [ "$ipmi_ret" = "01" ]
    then
        /bin/ipmitool raw 0x32 0xaa 0
        [ $? -eq 0 ] || {
            log_and_print "ipmitool raw 0x32 0xaa 0 - cmd failed!"
            return 1
        }
        sleep 5
        log_and_print "Virtual usb ready."
    else
        log_and_print "Done, virtual usb already opened."
    fi

    return 0
}

get_cpld_version()
{
    local base=$(ipmitool raw 0x3a 3 0 1 0 | awk {'print $1'})
    local come=$(ipmitool raw 0x3a 0x01 1 0x1a 1 0xe0 | awk {'print $1'})
    local fan=$(ipmitool raw 0x3a 0x03 1 1 0 | awk {'print $1'})
    local sw1=00
    local sw2=00
    #local sw1=$(cat /sys/devices/platform/questone2/CPLD1/getreg)    
    #local sw2=$(cat /sys/devices/platform/questone2/CPLD2/getreg)   
    #sw1=${sw1#0x}
    #sw2=${sw2#0x}
    log_and_print "$fan-$base-$come-$sw1-$sw2"
    
    # Silverstone_V04_20190703_FAN_V02_BASE_V03_COME_V07_SW1_V00_SW2_V00
    if [ "$fan" = "02" ] && [ "$base" = "03" ] \
    && [ "$come" = "07" ] && [ "$sw1" = "00" ] \
    && [ "$sw2" = "00" ]; then
        cpld_ver=04
        return 0
    fi
    # Silverstone_V03_20190611_FAN_V01_BASE_V03_COME_V07_SW1_V00_SW2_V00
    if [ "$fan" = "01" ] && [ "$base" = "03" ]; then
        cpld_ver=03
        return 0
    fi
    # Silverstone_V02_20190611_FAN_V01_BASE_V02_COME_V07_SW1_V00_SW2_V00
    if [ "$fan" = "01" ] && [ "$base" = "02" ]; then
        cpld_ver=02
        return 0
    fi
    # Silverstone_V01_20190401_FAN-V01_BASE-V01_COME-V07_SW1-V00_SW2-V00
    if [ "$base" = "01" ]; then
        cpld_ver=01
        return 0
    fi
    # Silverstone_CPLD_V00
    if [ "$base" = "00" ]; then
        cpld_ver=00
        return 0
    fi

    # Error
    cpld_ver=99
    return 1
}

echo ""
echo " =============== ONIE FW UPDATER ==============="
echo "In fw_install.sh"
pwd
ls -ltr

##
##
##  Common infra setup
##
chmod 777 -R libs/
cp -r tools/* /bin/

#
#
#  LIBS UPDATE INFRA
#
libs/lib_setup.sh || {
    log_and_print "ERROR: Problem setting up libs infra"
    updater_err_exit
}

# Enable virtual usb
enable_virtual_usb
[ $? -eq 0 ] || {
    log_and_print "Enable virtual usb failed!!!"
    updater_err_exit
}  

##
##
##  FPGA update infra
##
echo ""
echo " =============== FPGA ==============="
echo ""
echo "Installing switchboard driver..."
echo 1 4 1 5 > /proc/sys/kernel/printk
insmod /bin/seastone2_switchboard.ko > /dev/null 2>&1
echo 5 4 1 5 > /proc/sys/kernel/printk
echo "Done."

regval=$(cat /sys/devices/platform/questone2/FPGA/getreg)
echo "Get FPGA reg: $regval"
regval=$(printf %d $regval)
log_and_print $regval
ver_h=$(((regval&0xffff0000)>>16))
ver_l=$((regval&0x0000ffff))

fpga_ver="$ver_h.$ver_l"
if [ "$fpga_ver" != "$packed_fpga_ver" ]; then
    log_and_print "FPGA version mis-match between packed and running."
    fpga_update_required=1
fi
echo " FPGA VERSION        : $fpga_ver "
echo " PACKED FPGA VERSION        : $packed_fpga_ver "

if [ $fpga_update_required = 1 ] ; then
    log_and_print "update FPGA image ..."	
    cp fpga/$packed_fpga_image /bin
    cp tools/reboot-cmd /tmp
	/bin/fpga_prog /bin/$packed_fpga_image
    [ $? -eq 0 ] || {
        log_and_print "update fpga failed!!!"
        updater_err_exit
    }     
    
	log_and_print "FPGA update complete.  No errors detected."
else
    log_and_print "FPGA packed and running image revs are same. FPGA update is not required."
fi

##
##
##  BMC update infra
##
echo ""
echo " =============== BMC ==============="
echo ""
version=$(ipmitool raw 0x32 0x8f 8 2)
backup_bmc_ver=0x${version:4}
echo " BACKUP BMC VERSION        : $backup_bmc_ver "

version=$(ipmitool raw 0x32 0x8f 8 1)
main_bmc_ver=0x${version:4}

if [ "$main_bmc_ver" != "$packed_bmc_ver" ]; then
    log_and_print "Main BMC version mis-match between packed and running."
    main_bmc_update_required=1
fi
echo " MAIN BMC VERSION        : $main_bmc_ver "
echo " PACKED BMC VERSION        : $packed_bmc_ver "

if [ $main_bmc_update_required = 1 ]; then
    cp bmc/$packed_bmc_image /bin
    cp tools/reboot-cmd /tmp	
		
    echo ""
    log_and_print "Upgrading main BMC using $packed_bmc_image "
    log_and_print "DO NOT INTERRUPT THE BOARD, WHILE BMC update IS IN PROGRESS !!!"
	
    update_bmc 1
    log_and_print "Main BMC update complete.  No errors detected."
 
    log_and_print "Waiting for BMC ready..."
    sleep 55
    sleep 10
    wait_bmc_ready
    [ $? -eq 0 ] || {
        log_and_print "Wait BMC ready failed!"
        updater_err_exit
    }

    # After BMC reset, check if need to enable the virtual usb again.
    enable_virtual_usb
    [ $? -eq 0 ] || {
        log_and_print "Enable virtual usb failed!!!"
        updater_err_exit
    }  

    log_and_print "BMC ready."
else
    log_and_print "Main BMC update is not required."
fi

##
##  BIOS update infra
##
echo ""
echo " =============== BIOS ==============="
echo ""
bios_ver=$(dmidecode -t 0 |grep Version | awk {'print $2'})
if [ "$bios_ver" != "$packed_bios_ver" ]; then
    log_and_print "BIOS version mis-match between packed and running."
    bios_update_required=1
fi
echo " BIOS VERSION        : $bios_ver "
echo " PACKED BIOS VERSION        : $packed_bios_ver "

if [ $bios_update_required = 1 ]; then
    cp bios/$packed_bios_image /bin
    cp tools/reboot-cmd /tmp
    echo ""
    log_and_print "update main bios image ..."
    update_bios 0
    
    echo ""
    #log_and_print "update backup bios image ..."
    #update_bios 1

    # Set BIOS Firmware Boot Selector back to default value.
    ipmitool raw 0x3a 0x05 0x01 0x02
    log_and_print "BIOS update complete.  No errors detected."
else
    log_and_print "BIOS update not required."
fi

##
##
##  CPLD update infra
##
echo ""
echo " =============== CPLD ==============="
echo ""
get_cpld_version
[ $? -eq 0 ] || {
    log_and_print "Get CPLD version:$cpld_ver failed!!!"
    updater_err_exit
} 

if [ "$cpld_ver" != "$packed_cpld_ver" ]; then
    log_and_print "CPLD version mis-match between packed and running."
    
    cpld_run=$(printf %d $cpld_ver)
    cpld_pack=$(printf %d $packed_cpld_ver)

    if [ $cpld_run -lt 3 ] && [ $cpld_pack -gt 2 ]; then
        log_and_print "Not supported! CPLD V00/01/02 can't be upgraded to V03 or later version."
        log_and_print "Please use offline upgrade tool instead!"
        cpld_update_required=0
    else
        cpld_update_required=1
    fi
fi
echo " CPLD VERSION        : $cpld_ver "
echo " PACKED CPLD VERSION        : $packed_cpld_ver "

if [ $cpld_update_required = 1 ]; then
    log_and_print "CPLD update begin..."
    cp cpld/$packed_cpld_image /bin
    cp tools/reboot-cmd /tmp
	
    /bin/CFUFLASH -cd -d 4 /bin/$packed_cpld_image
    [ $? -eq 0 ] || {
        log_and_print "update cpld failed!!!"
        updater_err_exit
    }     

    log_and_print "CPLD update complete.  No errors detected."
else
    log_and_print "CPLD update is not required."
fi

log_and_print "Waiting for done..."
sleep 2

# disable virtual usb
ipmitool raw 0x32 0xaa 1
sleep 3

onie-boot-mode -q -o install

echo " done."

exit 0
