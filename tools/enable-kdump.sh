# This script enables kdump on LI systems

ExitIfFailed()
{
    if [ $1 != 0 ]; then
        echo "$2 ! Exiting !!!!"
        exit 1
    fi
}

# check if the kexec-tool is enabled
rpm_kexec_tools_pkg=$(rpm -q kexec-tools)
ExitIfFailed $? "kxec-tools required to enable kdump, please install"

# get low value reported by kdumptool calibrate
low=$(kdumptool calibrate | grep "^Low:" | tr -dc '0-9')
ExitIfFailed $? "Failed to get Low value using kdumptool calibrate"

# get high value reported by kdumptool calibrate
high=$(kdumptool calibrate | grep "^High:" | tr -dc '0-9')
ExitIfFailed $? "Failed to get High value using kdumptool calibrate"

# get system memory in tb
mem=$(free --tera | awk 'FNR == 2 {print $2}')
ExitIfFailed $? "Failed to get memory using free command"

#high memory to use for kdump
high_to_use=$(( $high*$mem))

# replace high and low value in /boot/grub2/grub.cfg
sed -i "s/crashkernel=[0-9]*M,high/crashkernel=$high_to_use\M,high/gI" /boot/grub2/grub.cfg
ExitIfFailed $? "Enable to change kernal crash high value in /boot/grub2/grub.cfg"

sed -i "s/crashkernel=[0-9]*M,low/crashkernel=$low\M,low/gI" /boot/grub2/grub.cfg
ExitIfFailed $? "Enable to change kernal crash low value in /boot/grub2/grub.cfg"

# set KDUMP_SAVEDIR in /etc/sysconfig/kdump
sed -i "s/^KDUMP_SAVEDIR=\".*\"/KDUMP_SAVEDIR=\"\/var\/crash\"/gI" /etc/sysconfig/kdump

# set KDUMP_DUMPLEVEL to 31(recommender)
sed -i "s/^KDUMP_DUMPLEVEL=[0-9]*/KDUMP_DUMPLEVEL=31/gI" /etc/sysconfig/kdump

# start and enable kdump service
systemctl start kdump
ExitIfFailed $? "Enable to start kdump service"

systemctl enable kdump
ExitIfFailed $? "Failed to enable kdump service"

# set kernel.sysrq to 184(remomended value)
sysctl kernel.sysrq=184
ExitIfFailed $? "Failed to set kernel.sysrq value to 184"

# load the new kernel.sysrq
sysctl -p
ExitIfFailed $? "Failed to load new kernel.sysrq value"

echo "KDUMP is successfully enabled, please reboot system to apply change"
exit 0