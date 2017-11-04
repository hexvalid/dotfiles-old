#!/bin/bash

#-----------OPTIONS-----------#
INSTALL_DISK="/dev/sdX"


#----------VARIABLES----------#
TOTAL_JOB=26
BASE_URL=http://ftp.linux.org.tr/gentoo/releases/amd64/autobuilds/



if [ -z "$INTERNAL_INIT_SCRIPT" ]; then
  screencfg=$(mktemp)
  echo hardstatus alwayslastline > "$screencfg"
  INTERNAL_INIT_SCRIPT=1 screen -mq -c "$screencfg" bash -c "$0"
  ret=$?
  rm "$screencfg"
  exit $ret
fi

function chroot_cmd {
   chroot /mnt/gentoo /bin/bash -c "source /etc/profile && $1"
}

function set_status {
  screen -X hardstatus string " [$1/$TOTAL_JOB] $2"
}


set_status 1 "Clearing SSD's cells..."
hdparm --user-master u --security-set-pass NULL $INSTALL_DISK
hdparm --user-master u --security-erase-enhanced NULL $INSTALL_DISK

set_status 2 "Partprobing $INSTALL_DISK..."
partprobe $INSTALL_DISK

set_status 3 "Creating Partitions...."
parted -a optimal $INSTALL_DISK --script 'mklabel gpt'
parted -a optimal $INSTALL_DISK --script 'unit mib'
parted -a optimal $INSTALL_DISK --script 'mkpart ESP fat32 1 129'
parted -a optimal $INSTALL_DISK --script 'set 1 boot on'
parted -a optimal $INSTALL_DISK --script 'mkpart primary 129 32897'
parted -a optimal $INSTALL_DISK --script 'name 2 root'
parted -a optimal $INSTALL_DISK --script 'mkpart primary 32897 -1'
parted -a optimal $INSTALL_DISK --script 'name 3 home'
BOOT_PARTITION=${INSTALL_DISK}1
ROOT_PARTITION=${INSTALL_DISK}2
HOME_PARTITION=${INSTALL_DISK}3


set_status 4 "Creating File Systems...."
mkfs.fat -F 32 $BOOT_PARTITION
mkfs.ext4 -F -E discard $ROOT_PARTITION
mkfs.ext4 -F -E discard $HOME_PARTITION

set_status 5 "Mounting partitions...."
mount -o discard $ROOT_PARTITION /mnt/gentoo
mkdir /mnt/gentoo/boot
mount $BOOT_PARTITION /mnt/gentoo/boot
mkdir /mnt/gentoo/boot/EFI
mkdir /mnt/gentoo/boot/EFI/Gentoo
mkdir /mnt/gentoo/home
mount -o discard $HOME_PARTITION /mnt/gentoo/home

set_status 6 "Getting lastest stage's name...."
LASTEST_STAGE_NAME=$(curl -s ${BASE_URL}latest-stage3-amd64.txt | tail -n 1 | cut -d " " -f 1)

set_status 6 "Getting lastest stage's digest...."
LASTEST_STAGE_DIGEST=$(curl -s ${BASE_URL}$LASTEST_STAGE_NAME.DIGESTS | head -2  |tail -1 | cut -d " " -f 1)

if [ -f /tmp/latest-stage3-amd64.tar.bz2 ] && [[ $(sha512sum /tmp/latest-stage3-amd64.tar.bz2 | cut -d " " -f 1) == $LASTEST_STAGE_DIGEST ]]; then
    set_status 7 "Using local stage...."
    sleep 2
else
    set_status 7 "Downloading lastest stage...."
    wget ${BASE_URL}$LASTEST_STAGE_NAME -O /tmp/latest-stage3-amd64.tar.bz2
    STAGE_DIGEST=$(sha512sum /tmp/latest-stage3-amd64.tar.bz2 | cut -d " " -f 1)
    if [ "$STAGE_DIGEST" != "$LASTEST_STAGE_DIGEST" ]; then
        echo "Failed digest verification"
	sleep 3
	exit -1 #exit func
    fi
fi


set_status 8 "Extracting stage...."
tar xvjpf /tmp/latest-stage3-amd64.tar.bz2 --xattrs --numeric-owner -C /mnt/gentoo/

set_status 9 "Getting portage configs...."
rm -rf /mnt/gentoo/etc/portage/package.use
wget https://raw.githubusercontent.com/hexvalid/dotfiles/master/portage/etc/portage/make.conf -O /mnt/gentoo/etc/portage/make.conf
wget https://raw.githubusercontent.com/hexvalid/dotfiles/master/portage/etc/portage/package.accept_keywords -O /mnt/gentoo/etc/portage/package.accept_keywords
wget https://raw.githubusercontent.com/hexvalid/dotfiles/master/portage/etc/portage/package.license -O /mnt/gentoo/etc/portage/package.license
wget https://raw.githubusercontent.com/hexvalid/dotfiles/master/portage/etc/portage/package.use -O /mnt/gentoo/etc/portage/package.use
mkdir /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
cp -L /etc/resolv.conf /mnt/gentoo/etc/

set_status 9 "Mounting other partitions...."
mount -t proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

set_status 10 "Emerge web rsync..."
chroot_cmd "emerge-webrsync"

set_status 11 "Emerge sync..."
chroot_cmd "emerge --sync"

set_status 12 "Setting profile..."
chroot_cmd "eselect profile set 1"

set_status 13 "Emerging portage..."
chroot_cmd "emerge --oneshot portage"

set_status 14 "Emerging @world..."
chroot_cmd "emerge --oneshot --update --deep --newuse @world -j 4"

set_status 15 "Setting up language, timezone and env..."
echo "Europe/Istanbul" > /mnt/gentoo/etc/timezone
chroot_cmd "emerge --config sys-libs/timezone-data"
echo "en_US.UTF-8 UTF-8" >>  /mnt/gentoo/etc/locale.gen
chroot_cmd "locale-gen"
echo "LANG=\"en_US.UTF-8\"" > /mnt/gentoo/etc/env.d/02locale
echo "LC_COLLATE=\"C\"" >> /mnt/gentoo/etc/env.d/02locale
chroot_cmd "env-update"

set_status 16 "Emerging ck-sources..."
chroot_cmd "emerge --oneshot sys-kernel/ck-sources"

set_status 17 "Emerging linux-firmware..."
chroot_cmd "emerge --oneshot sys-kernel/linux-firmware"

set_status 18 "Emerging pciutils and usbutils..."
chroot_cmd "emerge --oneshot sys-apps/pciutils sys-apps/usbutils -j 2"

set_status 19 "Configuring & patching kernel..."
BOOT_PARTUUID=$(blkid $BOOT_PARTITION | cut -d '"' -f 8)
ROOT_PARTUUID=$(blkid $ROOT_PARTITION | cut -d '"' -f 8)
HOME_PARTUUID=$(blkid $HOME_PARTITION | cut -d '"' -f 8)
wget https://raw.githubusercontent.com/hexvalid/dotfiles/master/linux/usr/src/linux/.config -O /mnt/gentoo/usr/src/linux/.config
sed -i -e "s/root=PARTUUID=_/root=PARTUUID=${ROOT_PARTUUID}/g" /mnt/gentoo/usr/src/linux/.config


set_status 20 "Compiling kernel..."
chroot_cmd "cd /usr/src/linux/ && make -j8"

set_status 21 "Installing kernel, modules and bzImage..."
chroot_cmd "cd /usr/src/linux/ && make modules_install && make install"
cp /mnt/gentoo/usr/src/linux/arch/x86/boot/bzImage /mnt/gentoo/boot/EFI/Gentoo/bzImage.efi

set_status 22 "Generating fstab..."
wget https://raw.githubusercontent.com/hexvalid/dotfiles/master/fstab -O /mnt/gentoo/etc/fstab
sed -i -e "s/ROOT_PARTUUID/${ROOT_PARTUUID}/g" /mnt/gentoo/etc/fstab
sed -i -e "s/BOOT_PARTUUID/${BOOT_PARTUUID}/g" /mnt/gentoo/etc/fstab
sed -i -e "s/HOME_PARTUUID/${HOME_PARTUUID}/g" /mnt/gentoo/etc/fstab

set_status 23 "Setting up hostname,keymap,OpenRC and users..."
sed -i -e "s/localhost/HEXTOO/g" /mnt/gentoo/etc/conf.d/hostname
sed -i -e "s/keymap=\"us\"/keymap=\"trq\"/g" /mnt/gentoo/etc/conf.d/keymaps
chroot_cmd "useradd -m -G audio,cdrom,portage,usb,users,video,wheel,audio -s /bin/bash hexvalid"
chroot_cmd "echo "hexvalid:*" | chpasswd"
chroot_cmd "echo "root:*" | chpasswd"
echo 'rc_hotplug="!net.*"' >> /mnt/gentoo/etc/rc.conf


set_status 24 "Emerging efibootmgr..."
chroot_cmd "emerge --oneshot sys-boot/efibootmgr"

set_status 25 "Creating EFI entity..."
mount /sys/firmware/efi/efivars -o rw,remount
chroot_cmd 'efibootmgr -c -d $INSTALL_DISK -p 1 -L "Gentoo" -l "\efi\gentoo\bzImage.efi"'
mount /sys/firmware/efi/efivars -o ro,remount

set_status 26 "Unmouting partitions..."
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -l {$BOOT_PARTITION,$HOME_PARTITION,$ROOT_PARTITION,}

# Install some component
