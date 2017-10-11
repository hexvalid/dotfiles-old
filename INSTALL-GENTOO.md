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
rm /mnt/gentoo/etc/portage/package.use/*
wget https://raw.githubusercontent.com/hexvalid/dotfiles/master/make.conf -O /mnt/gentoo/etc/portage/make.conf
wget https://raw.githubusercontent.com/hexvalid/dotfiles/master/HELYX.use -O /mnt/gentoo/etc/portage/package.use/HELYX.use
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
emerge --ask sys-apps/pciutils sys-apps/usbutils -j 3
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
*EFI Stub'daki root=PARTUUID'si güncellenecek*

#### Kernel Yamaları:
```
wget https://raw.githubusercontent.com/hexvalid/dotfiles/master/rtl8723be_4.12.patch
patch drivers/net/wireless/realtek/rtlwifi/btcoexist/halbtc8723b2ant.c rtl8723be_4.12.patch
```

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
```

#### Bootloader:
```
emerge --ask sys-boot/efibootmgr
mount /sys/firmware/efi/efivars -o rw,remount
efibootmgr -c -d /dev/sdb -p 1 -L "Gentoo" -l "\efi\gentoo\bzImage-(kernel_versiyonu).efi"
mount /sys/firmware/efi/efivars -o ro,remount
```

#### Kullanıcı Ekle:
```
useradd -m -G audio,cdrom,portage,usb,users,video,wheel,audio -s /bin/bash hexvalid
passwd hexvalid
```

#### X:
```
emerge --ask --verbose x11-base/xorg-drivers -j 4
emerge --ask --verbose x11-base/xorg-server
emerge --ask --verbose x11-apps/setxkbmap
env-update
source /etc/profile
```

#### Ağ:
```
emerge --ask net-misc/wicd -j 8
rc-update add wicd default
echo "rc_hotplug=\"!net.*\"" >> /etc/rc.conf
```

### Layman:
```
emerge --ask app-portage/layman -j 4
echo PORTDIR_OVERLAY=\"\" > /var/lib/layman/make.conf
layman -S
layman -a 0x4d4c
layman -a frabjous
```
*/etc/portage/make.conf dosyasındaki 'source /var/lib/layman/make.conf' satırının yorumu kalkacak*

### Desktop:
```
emerge -av x11-wm/i3-gaps x11-misc/i3blocks-gaps x11-terms/rxvt-unicode x11-misc/rofi media-gfx/feh -j 6
```

### Env:
```
emerge -av dev-java/oracle-jdk-bin dev-util/idea-ultimate -j 4
emerge -av www-client/inox -j 20

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
