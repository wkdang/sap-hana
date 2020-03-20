#!/bin/bash
# This script enables kdump on LI systems
# supported OS version are SLES12-SP3 and above

ExitIfFailed()
{
    if [ "$1" != 0 ]; then
        echo "$2 ! Exiting !!!!"
        exit 1
    fi
}

# check if the kexec-tool is enabled
rpm -q kexec-tools
ExitIfFailed $? "kxec-tools required to enable kdump, please install"

# get low and high value reported by kdumptool calibrate
# kdumptool calibrate reports key value pair
# so these can be imported in shell environment
eval $(kdumptool calibrate | sed -e s"@: @=@")
ExitIfFailed $? "Failed to run kdumptool calibrate command"

# get system memory in tb
mem=$(free --tera | awk 'FNR == 2 {print $2}')
ExitIfFailed $? "Failed to get memory using free command"

# high memory to use for kdump is calculated according to system
# if the total memory of a system is greater than 1TB
# then the high value to use is (High From kdumptool * RAM in TB)
high_to_use=$High
if [ $mem -gt 1 ]; then
    high_to_use=$(($High*$mem))
fi

# replace high and low value in /boot/grub2/grub.cfg
sed -i "s/crashkernel=[0-9]*M,high/crashkernel=$high_to_use\M,high/gI" /boot/grub2/grub.cfg
ExitIfFailed $? "Enable to change kernal crash high value in /boot/grub2/grub.cfg"

sed -i "s/crashkernel=[0-9]*M,low/crashkernel=$Low\M,low/gI" /boot/grub2/grub.cfg
ExitIfFailed $? "Enable to change kernal crash low value in /boot/grub2/grub.cfg"

# set KDUMP_SAVEDIR in /etc/sysconfig/kdump
sed -i "s/^KDUMP_SAVEDIR=\".*\"/KDUMP_SAVEDIR=\"\/var\/crash\"/gI" /etc/sysconfig/kdump

# set KDUMP_DUMPLEVEL to 31(recommended)
sed -i "s/^KDUMP_DUMPLEVEL=[0-9]*/KDUMP_DUMPLEVEL=31/gI" /etc/sysconfig/kdump

# enable kdump service
systemctl enable kdump
ExitIfFailed $? "Failed to enable kdump service"

# set kernel.sysrq to 184(recommended)
sysctl kernel.sysrq=184
ExitIfFailed $? "Failed to set kernel.sysrq value to 184"

# load the new kernel.sysrq
sysctl -p
ExitIfFailed $? "Failed to load new kernel.sysrq value"

echo "KDUMP is successfully enabled, please reboot system to apply change"
exit 0