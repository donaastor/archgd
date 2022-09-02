#!/bin/bash

num_of_args=$#
if [ "$num_of_args" -lt "5" ]; then
  printf "At least 5 arguments expected:\n1. BIOS type: BIOS or EFI\n2. Boot partition\n3. Root partition\n4. (optional, only if BIOS selected) name of the whole drive\n5. username\n6. parameters... a string of 0's and 1's (and other digits)\n    first bit: set:\n      0 - if you have an Intel CPU,\n      1 - if you have an AMD pre-Zen CPU, or\n      2 - if you have an AMD Zen CPU\n    second bit: set:\n      0 - for no graphics driver,\n      1 - if you have an AMD GCN-2 or older GPU,\n      2 - if you have a GCN-1 or GCN-2, but want newer drivers, or\n      3 - if you have a newer AMD GPU (for newer drivers)\n      4 - if you have an RDNA 2 or newer GPU\n    third bit: set if WiFi available and ethernet not available\n    fourth bit: set if you want to set up for HiDPI\n    fifth bit: set if you have a battery\n    sixth bit: set if you want more programs installed\n7. (optional, only if WiFi selected) SSID\n"
  exit 1
fi
if [ "$1" = "EFI" ]; then
  EFI=1
  username="$4"
  params="$5"
elif [ "$1" = "BIOS" ]; then
  EFI=0
  if [ -z "$6" ]; then
    echo "Missing arguments"
    exit 1
  fi
  drive_name="$4"
  username="$5"
  params="$6"
else
  printf "Can't recognize the BIOS type,\nset either EFI or BIOS.\n"
  exit 1
fi
prt1="$2"
prt2="$3"
if [ "${params:0:1}" = "0" ]; then
  CPU=0
elif [ "${params:0:1}" = "1" ]; then
  CPU=1
elif [ "${params:0:1}" = "2" ]; then
  CPU=2
fi
if [ "${params:1:1}" = "0" ]; then
  GPU=0
elif [ "${params:1:1}" = "1" ]; then
  GPU=1
elif [ "${params:1:1}" = "2" ]; then
  GPU=2
elif [ "${params:1:1}" = "3" ]; then
  GPU=3
elif [ "${params:1:1}" = "4" ]; then
  GPU=4
fi
if [ "${params:2:1}" = "1" ]; then
  WIFI=1
  if [ $EFI = 1 ]; then
    if [ -z "$6" ]; then
      echo "Missing arguments"
      exit 1
    fi
    ssid_dft="$6"
  else
    if [ -z "$7" ]; then
      echo "Missing arguments"
      exit 1
    fi
    ssid_dft="$7"
  fi
else
  WIFI=0
fi
if [ "${params:3:1}" = "1" ]; then
  HIDPI=1
else
  HIDPI=0
fi
if [ "${params:4:1}" = "1" ]; then
  BATT=1
else
  BATT=0
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
  sleep 1
}




if ! [ -d /var/cache ]; then mkdir /var/cache; fi
if ! [ -d /var/cache/pacman ]; then mkdir /var/cache/pacman; fi
if ! [ -d /var/cache/pacman/pkg ]; then mkdir /var/cache/pacman/pkg; fi
rm -rf /var/cache/pacman/pkg/*
mount -t tmpfs tmpfs -o defaults,size=2560M /var/cache/pacman/pkg



#			user

echo "For root!"
while ! passwd; do
  echo "Please try again"
done
useradd -mg wheel $username
echo "For user!"
while ! passwd $username; do
  echo "Please try again"
done

#			pacman

sed -i 's/^#Color/Color/' /etc/pacman.conf

#			jezik i vreme

cd /etc
sed -i 's/#en_US/en_US/g' locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> locale.conf
echo arch >> hostname
ln -sf /usr/share/zoneinfo/Europe/Belgrade /etc/localtime

#			more tools

while ! pacman -S --noconfirm --needed networkmanager grub git base-devel; do
  reconnect
done
rm -rf /var/cache/pacman/pkg/*

#			sudo

sed -i 's/^# %sudo/%sudo/' /etc/sudoers
groupadd sudo
gpasswd -a $username sudo

#			internet

if ! [ -d /etc/NetworkManager ]; then
  mkdir /etc/NetworkManager
fi
if ! [ -d /etc/NetworkManager/conf.d ]; then
  mkdir /etc/NetworkManager/conf.d
fi
printf "[main]\ndns=none\n" > /etc/NetworkManager/conf.d/dns.conf
if [ $WIFI = 0 ]; then
  systemctl enable NetworkManager
else
  while ! pacman -S --noconfirm --needed iwd; do
    reconnect
  done
  rm -rf /var/cache/pacman/pkg/*
  mkdir /etc/iwd
  printf "\n\n[General]\nEnableNetworkConfiguration=true\n" > /etc/iwd/main.conf
  systemctl enable NetworkManager iwd
fi

#			fstab

printf "\ntmpfs /root/tren tmpfs defaults,size=2048M 0 0\ntmpfs /home/$username/tren tmpfs defaults,size=2048M 0 0\ntmpfs /home/$username/.cache/pikaur tmpfs defaults 0 0\ntmpfs /home/$username/.local/share/pikaur/aur_repos tmpfs defaults,size=2048M 0 0\ntmpfs /var/lib/systemd/coredump tmpfs defaults,size=512M 0 0\ntmpfs /home/$username/.cargo tmpfs defaults,size=640M 0 0\ntmpfs /home/$username/chromium/cache tmpfs noatime,nodev,nosuid,size=1152M 0 0\n" >> "/root/tren/fstab_radni"
cp /root/tren/fstab_radni /etc/fstab
cd "/home/$username"
sudo -u "$username" mkdir tren
sudo -u "$username" mkdir .cache
sudo -u "$username" mkdir .cache/pikaur
sudo -u "$username" mkdir .local
sudo -u "$username" mkdir .local/share
sudo -u "$username" mkdir .local/share/pikaur
sudo -u "$username" mkdir .local/share/pikaur/aur_repos
mkdir /var/lib/systemd/coredumps
sudo -u "$username" mkdir .cargo
sudo -u "$username" mkdir chromium
sudo -u "$username" mkdir chromium/cache

#			modules

if [ $GPU = 1 ]; then
  sed -e 's/^MODULES=(\(..*\))$/MODULES=(radeon \1)/' -e 's/^MODULES=()$/MODULES=(radeon)/' -i /etc/mkinitcpio.conf
  mkinitcpio -P
elif [ $GPU = 2 ] || [ $GPU = 3 ] || [ $GPU = 4 ]; then
  sed -e 's/^MODULES=(\(..*\))$/MODULES=(amdgpu \1)/' -e 's/^MODULES=()$/MODULES=(amdgpu)/' -i /etc/mkinitcpio.conf
  mkinitcpio -P
fi
sed -n '/^MODULES/p' /etc/mkinitcpio.conf

#			grub

if [ $EFI = 1 ]; then
  while ! pacman -S --noconfirm --needed efibootmgr; do
    reconnect
  done
  rm -rf /var/cache/pacman/pkg/*
  grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
else
  grub-install $drive_name
fi
mkdir /tmp/grub_radni
cd /tmp/grub_radni
cp /etc/default/grub grub
sed -i 's/^GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=1/' grub
if [ $GPU = 0 ] || [ $GPU = 1 ]; then
  sed -i 's/\(^GRUB_CMDLINE_LINUX_DEFAULT.*\)\"/\1 mitigations=off\"/' grub
elif [ $GPU = 2 ]; then
  sed -i 's/\(^GRUB_CMDLINE_LINUX_DEFAULT.*\)\"/\1 mitigations=off radeon.si_support=0 radeon.cik_support=0 amdgpu.si_support=1 amdgpu.cik_support=1 amdgpu.ppfeaturemask=0xffffffff\"/' grub
elif [ $GPU = 3 ]; then
  sed -i 's/\(^GRUB_CMDLINE_LINUX_DEFAULT.*\)\"/\1 mitigations=off amdgpu.ppfeaturemask=0xffffffff\"/' grub
elif [ $GPU = 4 ]; then
  sed -i 's/\(^GRUB_CMDLINE_LINUX_DEFAULT.*\)\"/\1 mitigations=off amdgpu.ppfeaturemask=0xffffffff amdgpu.dcdebugmask=0x10\"/' grub
fi
if [ $CPU = 0 ]; then
  while ! pacman -S --noconfirm --needed intel-ucode; do
    reconnect
  done
else
  while ! pacman -S --noconfirm --needed amd-ucode; do
    reconnect
  done
fi
rm -rf /var/cache/pacman/pkg/*
cp grub /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

#			skripte

cd /tmp
sudo -u "$username" mkdir git_scripts
cd git_scripts
while ! sudo -u "$username" git clone --depth 1 https://github.com/donaastor/archgd.git; do
  reconnect
done
cd archgd
rm -rf .git
sudo -u "$username" mv scripts "/home/$username/scripts"
sudo -u "$username" mv arch_guide sharing_guide "/home/$username/scripts/"
sudo -u "$username" mkdir "/home/$username/Pictures"
sudo -u "$username" mv poz_r.jpg "/home/$username/Pictures/poz.jpg"
sudo -u "$username" mkdir "/home/$username/.config"
if [ $MORE_PROGS = 1 ]; then
  sudo -u "$username" mv "geany" "/home/$username/.config/geany"
  sudo -u "$username" mv "pcmanfm" "/home/$username/.config/pcmanfm"
  sudo -u "$username" mv "libfm" "/home/$username/.config/libfm"
fi

#			getty

cd /etc/systemd/system
mkdir "getty@tty1.service.d"
cd "getty@tty1.service.d"
printf "[Service]\nExecStart=\nExecStart=-/sbin/agetty -o \'-p -f -- \\\\\\\\u\' --noclear --autologin root - \$TERM\nType=simple\n" > autologin.conf
if [ $WIFI = 1 ]; then
  printf "\n/bin/bash \"/home/$username/scripts/ins-late.sh\" $username \"$params\" \"$ssid_dft\"\n" >> "/root/.bash_profile"
else
  printf "\n/bin/bash \"/home/$username/scripts/ins-late.sh\" $username \"$params\"\n" >> "/root/.bash_profile"
fi

#			exit

exit 0
