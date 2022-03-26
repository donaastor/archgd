#!/bin/sh

local num_od_args=$#
if [ "num_of_args" -lt "3" ]; then
  echo "At least 3 arguments expected.\n"
fi
if [ "$1" = "EFI" ]; then
  local EFI=1
elif [ "$1" = "BIOS" ]; then
  local EFI=0
  if [ -z "$4" ]; then
    echo "If BIOS selected, then please provide 4th argument.\n"
  fi
  local drive_name="$4"
else
  echo "Can't recognize the BIOS type,\nset either EFI or BIOS.\n"
  exit 0
fi
local prt1="$2"
local prt2="$3"

# za svaku komandu stavi:
#
# if ! command; then
#   echo "\nError, exiting...\n"
#   exit 2
# fi

mkfs.fat -F 32 "$prt1"
mkfs.ext4 "$prt2"
mount "$prt2" /mnt
if [ EFI = 1 ]; then
  mkdir /mnt/efi
  mount "$prt1" /mnt/efi
else
  mkdir /mnt/boot
  mount "$prt1" /mnt/boot
fi
pacstrap /mnt base base-devel linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt /bin/bash
passwd
pacman -S grub efibootmgr amd-ucode networkmanager nano
systemctl enable NetworkManager
if [ EFI = 1 ]; then
  grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
else
  grub-install $drive_name
fi
cd /etc/default
#	u grub promeni liniju "GRUB_TIMEOUT=5" u "GRUB_TIMEOUT=1"
sed -i 's/#GRUB_TIMEOUT=5/GRUB_TIMEOUT=1' grub
grub-mkconfig -o /boot/grub/grub.cfg
cd /etc
#	u locale.gen odkomentiraj linije "#en_US..."
sed -i 's/#en_US/en_US' locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> locale.conf
echo arch >> hostname
ln -sf /usr/share/zoneinfo/Europe/Belgrade /etc/localtime
exit
umount -R /mnt
reboot
