#### Partition Oluşturma:
```
hdparm --user-master u --security-set-pass NULL /dev/sdb
hdparm --user-master u --security-erase-enhanced NULL /dev/sdb
partprobe /dev/sdb
parted -a optimal /dev/sdb
(parted) mklabel gpt
(parted) unit mib
(parted) mkpart ESP fat32 1 129
(parted) set 1 boot on
(parted) mkpart primary 129 32897
(parted) name 2 root
(parted) mkpart primary 32897 -1
(parted) name 3 home
(parted) quit
```

#### Dosya Sistemi oluşturma:
```
mkfs.fat -F 32 /dev/sdb1
mkfs.ext4 -E discard /dev/sdb2
mkfs.ext4 -E discard /dev/sdb3
```

#### Mount:
```
mount -o discard /dev/sdb2 /mnt/gentoo
mkdir /mnt/gentoo/boot
mount /dev/sdb1 /mnt/gentoo/boot
mkdir /mnt/gentoo/boot/EFI
mkdir /mnt/gentoo/boot/EFI/Gentoo
mkdir /mnt/gentoo/home
mount -o discard /dev/sdb3 /mnt/gentoo/home
```
#### Stage Çıkartma:
```
tar xvjpf stage3-amd64-20170907.tar.bz2 --xattrs --numeric-owner -C /mnt/gentoo/
```

#### Portage Ayarı:
```
wget https://raw.githubusercontent.com/hexvalid/dotfiles/master/make.conf -O /mnt/gentoo/etc/portage/make.conf
mkdir /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
```

#### DNS:
```
cp -L /etc/resolv.conf /mnt/gentoo/etc/
```

#### Chroot:
```
mount -t proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) $PS1"
```

#### Init Portage:
```
emerge-webrsync
emerge --sync
eselect profile set 1
```

#### Portage Güncelle: (opsiyonel)
```
emerge --oneshot portage
```

#### emerge world:
```
emerge --ask --update --deep --newuse @world
```

#### Zaman:
```
echo "Europe/Istanbul" > /etc/timezone
emerge --config sys-libs/timezone-data
```

#### Dil:
```
echo "en_US.UTF-8 UTF-8" >>  /etc/locale.gen
echo "tr_TR.UTF-8 UTF-8" >>  /etc/locale.gen
locale-gen
echo "LANG=\"en_US.UTF-8\"" > /etc/env.d/02locale
echo "LC_COLLATE=\"C\"" >> /etc/env.d/02locale
```

#### Chroot'u Yenile:
```
env-update && source /etc/profile && export PS1="(chroot) $PS1"
```
#### Linux Kernel Kaynak Kodunu Al:
```
emerge --ask sys-kernel/gentoo-sources
```

#### Derleme Bağımlılıkları: (opsiyonel)
```
emerge --ask sys-apps/pciutils
emerge --ask sys-apps/usbutils
```
#### Linux Kernel Firmwares:
```
emerge --ask sys-kernel/linux-firmware
```

#### Kernel ayarları (rezerved):
```
cd /usr/src/linux
wget https://raw.githubusercontent.com/hexvalid/dotfiles/master/HELYX-rc1.config -O .config
make menuconfig
```
*(EFI Stub'daki root=PARTUUID'si güncellenecek)*

#### Kernel Derleme:
```
make -j8
```

#### Kernel Kurma:
```
make modules_install
make install
```

#### Bootloader imajı:
```
cp arch/x86/boot/bzImage /boot/EFI/Gentoo/bzImage-(kernel_versiyonu).efi
```

#### fstab (rezerved):
```
blkid
nano /etc/fstab
```

```
/etc/conf.d/hostname
passwd
nano /etc/conf.d/keymaps
nano /etc/rc.conf

emerge --ask net-misc/dhcpcd
```

#### Bootloader:
```
emerge --ask sys-boot/efibootmgr
mount /sys/firmware/efi/efivars -o rw,remount
efibootmgr -c -d /dev/sdb -p 1 -L "Gentoo" -l "\efi\gentoo\bzImage-(kernel_versiyonu).efi"
mount /sys/firmware/efi/efivars -o ro,remount
```

#### Bitiriş:
```
exit
cd
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount /dev/sdb1
umount -R /mnt/gentoo
reboot
```