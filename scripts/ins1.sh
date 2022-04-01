#!/bin/bash

num_of_args=$#
if [ "$num_of_args" -lt "6" ]; then
  printf "At least 6 arguments expected:\n1. Next script\n2. BIOS type: BIOS or EFI\n3. Boot partition\n4. Root partition\n5. (optional, only if BIOS selected) name of the whole drive\n6. username\n7. parameters... a string of 0's and 1's\n    first bit: set iff you have an AMD processor\n    second bit: set iff you have an AMD GPU, specifically set 2 if it's GCN 3 or newer\n    third bit: set iff wifi available and ethernet not available, additional argument: SSID\n    fourth bit: set iff you want to set up for HiDPI\n    fifth bit: set iff you have a battery\n    sixth bit: set iff you want more programs installed\n"
  exit 1
fi
if [ "$2" = "EFI" ]; then
  EFI=1
  username="$5"
  params="$6"
elif [ "$2" = "BIOS" ]; then
  EFI=0
  if [ -z "$7" ]; then
    echo "Missing arguments"
    exit 1
  fi
  drive_name="$5"
  username="$6"
  params="$7"
else
  printf "Can't recognize the BIOS type,\nset either EFI or BIOS.\n"
  exit 1
fi
next_script="$1"
prt1="$3"
prt2="$4"
if [ "${params:0:1}" = "1" ]; then
  AMD_GPU=1
else
  AMD_GPU=0
fi
if [ "${params:1:1}" = "1" ]; then
  AMD_CPU=1
else
  AMD_CPU=0
fi
if [ "${params:2:1}" = "1" ]; then
  WIFI=1
  if [ $EFI = 1 ]; then
    if [ -z "$7" ]; then
      echo "Missing arguments"
      exit 1
    fi
    ssid_dft="$7"
  else
    if [ -z "$8" ]; then
      echo "Missing arguments"
      exit 1
    fi
    ssid_dft="$8"
  fi
else
  WIFI=0
fi
if [ "${params:5:1}" = "1" ]; then
  MORE_PROGS=1
else
  MORE_PROGS=0
fi







reconnect() {
  local JOS=1
  local WWAIT=0
  printf "Connecting...\n"
  while [ $JOS = 1 ]; do
    if [ $WWAIT = 1 ]; then
      sleep 1
    fi
    if [ $WIFI = 1 ]; then
      if iwctl station wlan0 connect "$ssid_dft"; then
        JOS=0
      else
        printf "\n"
      fi
    else
      if getent hosts archlinux.org; then
        JOS=0
      else
        printf "."
      fi
    fi
    WWAIT=1
  done
  printf "\n:)\n"
}



#			formatiranje

mkfs.fat -F 32 "$prt1"
mkfs.ext4 "$prt2"
mount "$prt2" /mnt
if [ $EFI = 1 ]; then
  mkdir /mnt/efi
  mount "$prt1" /mnt/efi
else
  mkdir /mnt/boot
  mount "$prt1" /mnt/boot
fi

#			linux

mkdir /mnt/tmp
while ! pacstrap /mnt base base-devel linux linux-firmware grub networkmanager git; do
  reconnect
done
if [ $WIFI = 1 ]; then
  cp -r /var/lib/iwd /mnt/var/lib/iwd
fi
mkdir "/mnt/root"
mkdir "/mnt/root/tren"
mount -t tmpfs tmpfs -o defaults,size=128M "/mnt/root/tren"
genfstab -U /mnt >> "/mnt/root/tren/fstab_radni"
arch-chroot /mnt /bin/bash
passwd

#			user

useradd -mg wheel $username
passwd $username
sed -i 's/^# %sudo/%sudo/' /etc/sudoers
groupadd sudo
gpasswd -a $username sudo

#			pacman

sed -i 's/^#Color/Color/' /etc/pacman.conf

#			internet

if [ $WIFI = 0 ]; then
  systemctl enable NetworkManager
else
  while ! pacman -S --noconfirm --needed iwd; do
    reconnect
  done
  printf "\n\n[General]\nEnableNetworkConfiguration=true" >> /etc/iwd/main.conf
  printf "\n\nnameserver 8.8.8.8" >> /etc/resolv.conf
  systemctl enable NetworkManager iwd
fi

#			fstab

printf "\ntmpfs /root/tren tmpfs defaults,size=2048M 0 0\ntmpfs /home/$username/tren tmpfs defaults,size=2048M 0 0\ntmpfs /home/$username/.cache/pikaur tmpfs default 0 0\ntmpfs /home/$username/.local/share/pikaur/aur_repos tmpfs defaults,size=2048M 0 0\ntmpfs /var/lib/systemd/coredumps tmpfs defaults,size=512M 0 0\ntmpfs /home/$username/.cargo tmpfs defaults,size=640M 0 0\ntmpfs /home/$username/chromium/cache tmpfs noatime,nodev,nosuid,size=1152M 0 0" >> "/root/tren/fstab_radni"
cp "/root/tren/fstab_radni" > /etc/fstab
cd "/home/$username"
sudo -u "$username" mkdir .cache
sudo -u "$username" mkdir .cache/pikaur
sudo -u "$username" mkdir .local
sudo -u "$username" mkdir .local/share
sudo -u "$username" mkdir .local/share/pikaur
sudo -u "$username" mkdir .local/share/pikaur/aur_repos
sudo -u "$username" mkdir /var/lib/systemd/coredumps
sudo -u "$username" mkdir .cargo

#			grub

if [ $EFI = 1 ]; then
  while ! pacman -S --noconfirm --needed efibootmgr; do
    reconnect
  done
  grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
else
  grub-install $drive_name
fi
mkdir /tmp/grub_radni
cd /tmp/grub_radni
cp /etc/default/grub grub
sed -i 's/#GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/' grub
if [ $AMD_GPU = 1 ]; then
  sed -i 's/\(^GRUB_CMDLINE_LINUX_DEFAULT.*\)\"/\1 amdgpu.ppfeaturemask=0xffffffff mitigations=off\"/' grub
else
  sed -i 's/\(^GRUB_CMDLINE_LINUX_DEFAULT.*\)\"/\1 mitigations=off\"/' grub
fi
if [ $AMD_CPU = 1 ]; then
  while ! pacman -S --noconfirm --needed amd-ucode; do
    reconnect
  done
else
  while ! pacman -S --noconfirm --needed intel-ucode; do
    reconnect
  done
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

#			skripte

cd /tmp
sudo -u "$username" mkdir git_scripts
cd git_scripts
while ! sudo -u "$username" git clone https://github.com/donaastor/archgd.git; do
  reconnect
done
cd archgd
rm -rf .git
sudo -u "$username" mv scripts "/home/$username/scripts"
sudo -u "$username" mkdir "/home/$username/Pictures"
sudo -u "$username" mv poz_r.jpg "/home/$username/Pictures/poz.jpg"
sudo -u "$username" mkdir "/home/$username/.config"
if [ $MORE_PROGS = 1 ]; then
  sudo -u "$username" mv "geany" "/home/$username/.config/geany"
fi

#			getty

cd /etc/systemd/system
mkdir "getty@tty1.service.d"
cd "getty@tty1.service.d"
printf "[Service]\nExecStart=\nExecStart=-/sbin/agetty -o \'-p -f -- \\u\' --noclear --autologin root - $TERM\nType=simple\n" > autologin.conf
if [ $WIFI = 1 ]; then
  printf "/bin/bash \"/home/$username/scripts/$next_script\" $username \"$params\" \"$ssid_dft\"" >> "/home/$username/.bashrc"
else
  printf "/bin/bash \"/home/$username/scripts/$next_script\" $username \"$params\"" >> "/home/$username/.bashrc"
fi

#			reboot

exit
umount -R /mnt
reboot
