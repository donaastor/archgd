#!/bin/bash

num_of_args=$#
if [ "$num_of_args" -lt "5" ]; then
  printf "At least 5 arguments expected:\n1. BIOS type: BIOS or EFI\n2. Boot partition\n3. Root partition\n4. (optional, only if BIOS selected) name of the whole drive\n5. username\n6. parameters... a string of 0's and 1's\n    first bit: set iff you have an AMD processor, specifically set 2 if it's Zen\n    second bit: set iff you have an AMD GPU, specifically set 2 if it's GCN 3 or newer\n    third bit: set iff WiFi available and ethernet not available\n    fourth bit: set iff you want to set up for HiDPI\n    fifth bit: set iff you have a battery\n    sixth bit: set iff you want more programs installed\n7. (optional, only if WiFi selected) SSID\n"
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
  AMD_CPU=0
else
  AMD_CPU=1
  if [ "${params:0:1}" = "2" ]; then
    CPU_NEW=1
  else
    CPU_NEW=0
  fi
fi
if [ "${params:1:1}" = "0" ]; then
  AMD_GPU=0
else
  AMD_GPU=1
  if [ "${params:1:1}" = "2" ]; then
    GPU_NEW=1
  else
    GPU_NEW=0
  fi
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
}






#			user

# echo "Press enter [passwd root]"; read line
echo "For root!"
while ! passwd; do
  echo "Please try again"
done
# echo "Press enter [useradd]"; read line
useradd -mg wheel $username
# echo "Press enter [passwd user]"; read line
echo "For user!"
while ! passwd $username; do
  echo "Please try again"
done

#			pacman

# echo "Press enter [sed pacman]"; read line
sed -i 's/^#Color/Color/' /etc/pacman.conf

#			jezik i vreme

# echo "Press enter [cd /etc]"; read line
cd /etc
# echo "Press enter [sed locale.gen]"; read line
sed -i 's/#en_US/en_US/g' locale.gen
# echo "Press enter [locale-gen]"; read line
locale-gen
# echo "Press enter [locale.conf]"; read line
echo "LANG=en_US.UTF-8" >> locale.conf
# echo "Press enter [hostname]"; read line
echo arch >> hostname
# echo "Press enter [localtime]"; read line
ln -sf /usr/share/zoneinfo/Europe/Belgrade /etc/localtime

#			more tools

# echo "Press enter [pacman more tools]"; read line
while ! pacman -S --noconfirm --needed networkmanager grub git base-devel; do
  reconnect
done

#			sudo

# echo "Press enter [sed sudoers]"; read line
sed -i 's/^# %sudo/%sudo/' /etc/sudoers
# echo "Press enter [groupadd sudo]"; read line
groupadd sudo
# echo "Press enter [gpasswd]"; read line
gpasswd -a $username sudo

#			internet

if [ $WIFI = 0 ]; then
#   echo "Press enter [network manager]"; read line
  systemctl enable NetworkManager
else
#   echo "Press enter [pacman iwd]"; read line
  while ! pacman -S --noconfirm --needed iwd; do
    reconnect
  done
#   echo "Press enter [mkdir /etc/iwd]"; read line
  mkdir /etc/iwd
#   echo "Press enter [wifi dns]"; read line
  printf "\n\n[General]\nEnableNetworkConfiguration=true\n" > /etc/iwd/main.conf
#   echo "Press enter [wifi resolv]"; read line
  printf "\n\nnameserver 8.8.8.8" >> /etc/resolv.conf
#   echo "Press enter [network manager, iwd]"; read line
  systemctl enable NetworkManager iwd
fi

#			fstab

# echo "Press enter [fstab_radni]"; read line
printf "\ntmpfs /root/tren tmpfs defaults,size=2048M 0 0\ntmpfs /home/$username/tren tmpfs defaults,size=2048M 0 0\ntmpfs /home/$username/.cache/pikaur tmpfs defaults 0 0\ntmpfs /home/$username/.local/share/pikaur/aur_repos tmpfs defaults,size=2048M 0 0\ntmpfs /var/lib/systemd/coredumps tmpfs defaults,size=512M 0 0\ntmpfs /home/$username/.cargo tmpfs defaults,size=640M 0 0\ntmpfs /home/$username/chromium/cache tmpfs noatime,nodev,nosuid,size=1152M 0 0\n" >> "/root/tren/fstab_radni"
# echo "Press enter [fstab_radni > fstab]"; read line
cp /root/tren/fstab_radni /etc/fstab
# echo "Press enter [cd home]"; read line
cd "/home/$username"
# echo "Press enter [mkdir .cache]"; read line
sudo -u "$username" mkdir .cache
# echo "Press enter [mkdir .cache/pikaur]"; read line
sudo -u "$username" mkdir .cache/pikaur
# echo "Press enter [mkdir .local]"; read line
sudo -u "$username" mkdir .local
# echo "Press enter [mkdir .local/share]"; read line
sudo -u "$username" mkdir .local/share
# echo "Press enter [mkdir .local/share/pikaur]"; read line
sudo -u "$username" mkdir .local/share/pikaur
# echo "Press enter [mkdir .local/share/pikaur/aur_repos]"; read line
sudo -u "$username" mkdir .local/share/pikaur/aur_repos
# echo "Press enter [mkdir /var/lib/systemd/coredumps]"; read line
mkdir /var/lib/systemd/coredumps
# echo "Press enter [mkdir .cargo]"; read line
sudo -u "$username" mkdir .cargo

#			grub

if [ $EFI = 1 ]; then
#   echo "Press enter [pacman efibootmgr]"; read line
  while ! pacman -S --noconfirm --needed efibootmgr; do
    reconnect
  done
#   echo "Press enter [grub-install]"; read line
  grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
else
#   echo "Press enter [grub-install]"; read line
  grub-install $drive_name
fi
# echo "Press enter [mkdir /tmp/grub_radni]"; read line
mkdir /tmp/grub_radni
# echo "Press enter [cd /tmp/grub_radni]"; read line
cd /tmp/grub_radni
# echo "Press enter [cp /etc/default/grub grub]"; read line
cp /etc/default/grub grub
# echo "Press enter [sed GRUB_TIMEOUT]"; read line
sed -i 's/^GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=1/' grub
if [ $AMD_GPU = 1 ]; then
#   echo "Press enter [sed KERNEL, GPU]"; read line
  sed -i 's/\(^GRUB_CMDLINE_LINUX_DEFAULT.*\)\"/\1 amdgpu.ppfeaturemask=0xffffffff mitigations=off\"/' grub
else
#   echo "Press enter [sed KERNEL]"; read line
  sed -i 's/\(^GRUB_CMDLINE_LINUX_DEFAULT.*\)\"/\1 mitigations=off\"/' grub
fi
if [ $AMD_CPU = 0 ]; then
#   echo "Press enter [pacman intel-ucode]"; read line
  while ! pacman -S --noconfirm --needed intel-ucode; do
    reconnect
  done
else
#   echo "Press enter [pacman amd-ucode]"; read line
  while ! pacman -S --noconfirm --needed amd-ucode; do
    reconnect
  done
fi
# echo "Press enter [cp grub /etc/default/grub]"; read line
cp grub /etc/default/grub
# echo "Press enter [grub-mkconfig]"; read line
grub-mkconfig -o /boot/grub/grub.cfg

#			skripte

# echo "Press enter [cd /tmp]"; read line
cd /tmp
# echo "Press enter [mkdir git_scripts]"; read line
sudo -u "$username" mkdir git_scripts
# echo "Press enter [cd git_scripts]"; read line
cd git_scripts
# echo "Press enter [git archgd]"; read line
while ! sudo -u "$username" git clone https://github.com/donaastor/archgd.git; do
  reconnect
done
# echo "Press enter [cd archgd]"; read line
cd archgd
# echo "Press enter [rm .git]"; read line
rm -rf .git
# echo "Press enter [mv scripts /home/$username/scripts]"; read line
sudo -u "$username" mv scripts "/home/$username/scripts"
# echo "Press enter [mkdir /home/$username/Pictures]"; read line
sudo -u "$username" mkdir "/home/$username/Pictures"
# echo "Press enter [mv poz.jpg]"; read line
sudo -u "$username" mv poz_r.jpg "/home/$username/Pictures/poz.jpg"
# echo "Press enter [mkdir .config]"; read line
sudo -u "$username" mkdir "/home/$username/.config"
if [ $MORE_PROGS = 1 ]; then
#   echo "Press enter [mv geany config]"; read line
  sudo -u "$username" mv "geany" "/home/$username/.config/geany"
fi

#			getty

# echo "Press enter [cd /etc/systemd/system]"; read line
cd /etc/systemd/system
# echo "Press enter [mkdir getty_tty_service_d]"; read line
mkdir "getty@tty1.service.d"
# echo "Press enter [cd getty_tty_service_d]"; read line
cd "getty@tty1.service.d"
# echo "Press enter [autologin.conf]"; read line
printf "[Service]\nExecStart=\nExecStart=-/sbin/agetty -o \'-p -f -- \\\\\\\\u\' --noclear --autologin root - \$TERM\nType=simple\n" > autologin.conf
if [ $WIFI = 1 ]; then
#   echo "Press enter [prep ins-2, wifi]"; read line
  printf "\n/bin/bash \"/home/$username/scripts/ins-2.sh\" $username \"$params\" \"$ssid_dft\"\n" >> "/root/.bashrc"
else
#   echo "Press enter [prep ins-2, no wifi]"; read line
  printf "\n/bin/bash \"/home/$username/scripts/ins-2.sh\" $username \"$params\"\n" >> "/root/.bashrc"
fi

#			exit

# echo "Press enter [exit chroot]"; read line
exit 0
