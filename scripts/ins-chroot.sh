#!/bin/bash

if [ $1 = EFI ]; then
  EFI=1
  username=$4
  params="$5"
else
  EFI=0
  drive_name="$4"
  username=$5
  params="$6"
fi
prt1="$2"
prt2="$3"
CPU="${params:0:1}"
if ! [[ "$CPU" =~ [0-2] ]]; then CPU=0; fi
GPU="${params:1:1}"
if ! [[ "$GPU" =~ [0-4] ]]; then GPU=0; fi
if [ "${params:2:1}" = "1" ]; then
  WIFI=1
  if [ $EFI = 1 ]; then
    ssid_dft="$6"
  else
    ssid_dft="$7"
  fi
else
  WIFI=0
fi
if [ "${params:3:1}" = 1 ]; then
  HIDPI=1
else
  HIDPI=0
fi
if [ "${params:4:1}" = 1 ]; then
  BATT=1
else
  BATT=0
fi
if [ "${params:5:1}" = 1 ]; then
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
        printf .
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

printf "\ntmpfs /root/tren tmpfs defaults,size=2048M 0 0\ntmpfs /home/$username/tren tmpfs defaults,size=2048M 0 0\ntmpfs /home/$username/.cache/pikaur tmpfs defaults 0 0\ntmpfs /home/$username/.local/share/pikaur/aur_repos tmpfs defaults,size=2048M 0 0\ntmpfs /home/$username/.local/share/xorg tmpfs defaults,size=1280M 0 0\ntmpfs /var/lib/systemd/coredump tmpfs defaults,size=512M 0 0\ntmpfs /home/$username/.cargo tmpfs defaults,size=640M 0 0\ntmpfs /home/$username/chromium/cache tmpfs noatime,nodev,nosuid,size=1152M 0 0\ntmpfs /var/cache/pacman/pkg tmpfs defaults,size=2560M 0 0\ntmpfs /home/korsic/.cache/fontconfig tmpfs defaults,size=512M 0 0\ntmpfs /home/korsic/.cache/mesa_shader_cache tmpfs defaults,size=1024M 0 0\ntmpfs /home/korsic/.cache/pip tmpfs defaults,size=2560M 0 0\ntmpfs /home/korsic/.cache/thumbnails tmpfs defaults,size=512M 0 0\n" >> /root/tren/fstab_radni
cp /root/tren/fstab_radni /etc/fstab
cd /home/$username
sudo -u $username mkdir tren
sudo -u $username mkdir .cache
sudo -u $username mkdir .cache/pikaur
sudo -u $username mkdir .cache/fontconfig
sudo -u $username mkdir .cache/mesa_shader_cache
sudo -u $username mkdir .cache/pip
sudo -u $username mkdir .cache/thumbnails
sudo -u $username mkdir .local
sudo -u $username mkdir .local/share
sudo -u $username mkdir .local/share/pikaur
sudo -u $username mkdir .local/share/pikaur/aur_repos
mkdir /var/lib/systemd/coredump
sudo -u $username mkdir .cargo
sudo -u $username mkdir chromium
sudo -u $username mkdir chromium/cache

#			modules

if [ $GPU = 1 ]; then
  sed -e 's/^MODULES=(\(..*\))$/MODULES=(radeon \1)/' -e 's/^MODULES=()$/MODULES=(radeon)/' -i /etc/mkinitcpio.conf
  mkinitcpio -P
elif [[ $GPU =~ [2-4] ]]; then
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
if [[ $GPU =~ [0-1] ]]; then
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
sudo -u $username mv scripts /home/$username/scripts
sudo -u $username mv arch_guide sharing_guide /home/$username/scripts/
mv extra/cppc /usr/local/bin/
chmod 755 /usr/local/bin/cppc
sudo -u $username mkdir /home/$username/Pictures
sudo -u $username mv pics/poz_r.jpg /home/$username/Pictures/poz.jpg
sudo -u $username mkdir /home/$username/.config
if [ $MORE_PROGS = 1 ]; then
  sudo -u $username mv geany /home/$username/.config/geany-base
  sudo -u $username ln -s /tmp/geany-conf /home/$username/.config/geany
  sudo -u $username mkdir /home/$username/.config/chromium-base
  sudo -u $username ln -s /tmp/chromium-conf /home/$username/.config/chromium
  sudo -u $username mv pcmanfm /home/$username/.config/pcmanfm
  sudo -u $username mv libfm /home/$username/.config/libfm
fi

#			getty

cd /etc/systemd/system
mkdir getty@tty1.service.d
cd getty@tty1.service.d
printf "[Service]\nExecStart=\nExecStart=-/sbin/agetty -o \'-p -f -- \\\\\\\\u\' --noclear --autologin root - \$TERM\nType=simple\n" > autologin.conf
if [ $WIFI = 1 ]; then
  printf "\n/bin/bash \"/home/$username/scripts/ins-late.sh\" $username \"$params\" \"$ssid_dft\"\n" >> /root/.bash_profile
else
  printf "\n/bin/bash \"/home/$username/scripts/ins-late.sh\" $username \"$params\"\n" >> /root/.bash_profile
fi

#			exit

exit 0
