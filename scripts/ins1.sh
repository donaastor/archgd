#!/bin/bash

local num_od_args=$#
if [ "num_of_args" -lt "6" ]; then
  printf "At least 6 arguments expected:\n1. Next script\n2. BIOS type: BIOS or EFI\n3. Boot partition\n4. Root partition\n5. (optional, only if BIOS selected) name of the whole drive\n6. username\n7. parameters... a string of 0's and 1's\n    first bit: set iff you have an AMD GPU\n    second bit: set if wifi available and ethernet not available, additional argument: SSID\n    third bit: set iff you want to set up for HiDPI\n"
fi
if [ "$2" = "EFI" ]; then
  local EFI=1
  local username="$5"
  local params="$6"
elif [ "$2" = "BIOS" ]; then
  local EFI=0
  if [ -z "$7" ]; then
    echo "Missing arguments"
    exit 1
  fi
  local drive_name="$5"
  local username="$6"
  local params="$7"
else
  printf "Can't recognize the BIOS type,\nset either EFI or BIOS.\n"
  exit 1
fi
local next_script="$1"
local prt1="$3"
local prt2="$4"
if [ "${params:1:1}" = "1" ]; then
  local WIFI=1
  if [ EFI = 1 ]; then
    if [ -z "$7" ]; then
      echo "Missing arguments"
      exit 1
    fi
    local ssid_dft="$7"
  elif
    if [ -z "$8" ]; then
      echo "Missing arguments"
      exit 1
    fi
    local ssid_dft="$8"
  fi
else
  local WIFI=0
fi
if [ "${params:2:1}" = "1" ]; then
  local HIDPI=1
else
  local HIDPI=0
fi






# za svaku komandu stavi:
#
# if ! command; then
#   echo "\nError, exiting...\n"
#   exit 2
# fi


#			formatiranje

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

#			linux

pacstrap /mnt base base-devel linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt /bin/bash
passwd

#			programi

pacman -S grub amd-ucode networkmanager nano git

#			internet

if [ WIFI = 0 ]; then
  systemctl enable NetworkManager
else
  pacman -S iwd
  printf "\n\n[General]\nEnableNetworkConfiguration=true" >> /etc/iwd/main.conf
  printf "\n\nnameserver 8.8.8.8" >> /etc/resolv.conf
  systemctl enable NetworkManager iwd
fi

#			grub

if [ EFI = 1 ]; then
  pacman -S efibootmgr
  grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
else
  grub-install $drive_name
fi
mkdir /tmp/grub_radni
cd /tmp/grub_radni
cp /etc/default/grub grub
sed -i 's/#GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/' grub
if [ "${params:0:1}" = "1" ]; then
  sed -i 's/\(^GRUB_CMDLINE_LINUX_DEFAULT.*\)\"/\1 amdgpu.ppfeaturemask=0xffffffff mitigations=off\"/' grub
else
  sed -i 's/\(^GRUB_CMDLINE_LINUX_DEFAULT.*\)\"/\1 mitigations=off\"/' grub
fi
cp grub /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

#			jezik i vreme

cd /etc
sed -i 's/#en_US/en_US/g' locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> locale.conf
echo arch >> hostname
ln -sf /usr/share/zoneinfo/Europe/Belgrade /etc/localtime

#			user

useradd -mg wheel $username
passwd $username
sed -i 's/^# %sudo/%sudo/' /etc/sudoers
groupadd sudo
gpasswd -a $username sudo

#			skripte

cd /tmp
mkdir git_scripts
cd git_scripts
git clone https://github.com/donaastor/archgd.git
cd archgd
rm -rf .git
mv scripts "/home/$username/scripts"
mkdir "/home/"$username"/Pictures"
mv poz.jpg poz_r.jpg "/home/$username/Pictures/"

#			priprema sledece skripte

cd /etc/systemd/system
mkdir getty@tty1.service.d
cd getty@tty1.service.d
printf "[Service]\nExecStart=\nExecStart=-/sbin/agetty -o \'-p -f -- \\u\' --noclear --autologin $username - $TERM\nType=simple\n" >> autologin.conf
#		Environment=XDG_SESSION_TYPE=x11		(ovu liniju dodaj posle u ovaj autologin!!!)
printf "/bin/bash \"/home/$username/scripts/$next_script\" $username \"$ssid_dft\"" >> "/home/$username/.bashrc"

#			fali:

...
od nano /etc/nanorc
do pacman -S xorg...
posle login se kao korsic
...

#			reboot

exit
umount -R /mnt
reboot
