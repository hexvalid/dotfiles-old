#!/bin/bash

#-----------OPTIONS-----------#
INSTALL_DISK="/dev/sdb"


#----------VARIABLES----------#
TOTAL_JOB=20
BASE_URL=http://ftp.linux.org.tr/gentoo/releases/amd64/autobuilds/



if [ -z "$INTERNAL_INIT_SCRIPT" ]; then
  screencfg=$(mktemp)
  echo hardstatus alwayslastline > "$screencfg"
  INTERNAL_INIT_SCRIPT=1 screen -mq -c "$screencfg" bash -c "$0"
  ret=$?
  rm "$screencfg"
  exit $ret
fi


function set_status {
  screen -X hardstatus string " [$1/$TOTAL_JOB] $2"
}



set_status 1 "Clearing SSD's cells..."
#hdparm --user-master u --security-set-pass NULL $INSTALL_DISK
#hdparm --user-master u --security-erase-enhanced NULL $INSTALL_DISK
sleep 0.2

set_status 2 "Partprobing $INSTALL_DISK..."
partprobe $INSTALL_DISK
sleep 0.2

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
sleep 0.2

set_status 4 "Creating File Systems...."
mkfs.fat -F 32 $BOOT_PARTITION
mkfs.ext4 -E discard $ROOT_PARTITION
mkfs.ext4 -E discard $HOME_PARTITION
sleep 0.2

set_status 5 "Mounting partitions...."
mount -o discard $ROOT_PARTITION /mnt/gentoo
mkdir /mnt/gentoo/boot
mount $BOOT_PARTITION /mnt/gentoo/boot
mkdir /mnt/gentoo/boot/EFI
mkdir /mnt/gentoo/boot/EFI/Gentoo
mkdir /mnt/gentoo/home
mount -o discard $HOME_PARTITION /mnt/gentoo/home
sleep 0.2

set_status 6 "Getting lastest stage's name...."
LASTEST_STAGE_NAME=$(curl -s ${BASE_URL}latest-stage3-amd64.txt | tail -n 1 | cut -d " " -f 1)

set_status 7 "Downloading lastest stage...."
wget ${BASE_URL}$LASTEST_STAGE_NAME -O /tmp/latest-stage3-amd64.tar.bz2

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

set_status 10 "Mounting partitions for chroot...."
cp -L /etc/resolv.conf /mnt/gentoo/etc/
mount -t proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev



# Install some component
