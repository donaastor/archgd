#!/bin/sh

local num_od_args=$#
if [ "num_of_args" -lt "4" ]; then
  echo "At least 4 arguments expected.\n"
fi
if [ "$2" = "EFI" ]; then
  local EFI=1
elif [ "$2" = "BIOS" ]; then
  local EFI=0
  if [ -z "$5" ]; then
    echo "If BIOS selected, then please provide 5th argument.\n"
  fi
  local drive_name="$5"
else
  echo "Can't recognize the BIOS type,\nset either EFI or BIOS.\n"
  exit 0
fi
local next_script="$1"
local prt1="$3"
local prt2="$4"

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
pacman -S grub amd-ucode networkmanager nano git
systemctl enable NetworkManager
if [ EFI = 1 ]; then
  pacman -S efibootmgr
  grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
else
  grub-install $drive_name
fi
cd /etc/default
sed -i 's/#GRUB_TIMEOUT=5/GRUB_TIMEOUT=1' grub
grub-mkconfig -o /boot/grub/grub.cfg
cd /etc
sed -i 's/#en_US/en_US' locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> locale.conf
echo arch >> hostname
ln -sf /usr/share/zoneinfo/Europe/Belgrade /etc/localtime
cd /tmp
mkdir git_scripts
cd git_scripts
git clone https://github.com/donaastor/archgd.git
cd archgd
rm -rf .git
mv scripts /home/scripts
mkdir /home/Wallpapers
mv poz.jpg poz_r.jpg /home/Wallpapers/

# namesti da se posle reboota pokrene skripta "$next_script"
# ... ".bashrc"
cd /etc/systemd/system
mkdir getty@tty1.service.d
cd getty@tty1.service.d
nano autologin.conf:
	[Service]
	ExecStart=
	ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin korsic - $TERM
	Type=simple
	Environment=XDG_SESSION_TYPE=x11

exit
umount -R /mnt
reboot
