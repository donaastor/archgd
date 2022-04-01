#!/bin/bash

num_of_args=$#
if [ "$num_of_args" -lt "5" ]; then
  printf "At least 5 arguments expected:\n1. BIOS type: BIOS or EFI\n2. Boot partition\n3. Root partition\n4. (optional, only if BIOS selected) name of the whole drive\n5. username\n6. parameters... a string of 0's and 1's\n    first bit: set iff you have an AMD processor\n    second bit: set iff you have an AMD GPU, specifically set 2 if it's GCN 3 or newer\n    third bit: set iff wifi available and ethernet not available, additional argument: SSID\n    fourth bit: set iff you want to set up for HiDPI\n    fifth bit: set iff you have a battery\n    sixth bit: set iff you want more programs installed\n"
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

read line
mkfs.fat -F 32 "$prt1"
read line
mkfs.ext4 "$prt2"
read line
mount "$prt2" /mnt
if [ $EFI = 1 ]; then
  read line
  mkdir /mnt/efi
  read line
  mount "$prt1" /mnt/efi
else
  read line
  mkdir /mnt/boot
  read line
  mount "$prt1" /mnt/boot
fi

#			linux

read line
mkdir /mnt/tmp
read line
while ! pacstrap /mnt base base-devel linux linux-firmware grub networkmanager git; do
  reconnect
done
if [ $WIFI = 1 ]; then
  read line
  cp -r /var/lib/iwd /mnt/var/lib/iwd
fi
read line
mkdir "/mnt/root/tren"
read line
mount -t tmpfs tmpfs -o defaults,size=128M "/mnt/root/tren"
read line
genfstab -U /mnt >> "/mnt/root/tren/fstab_radni"
read line
cd /tmp
read line
curl https://raw.githubusercontent.com/donaastor/archgd/main/scripts/ins-chroot.sh > ins-chroot.sh
read line
args_array=("$@")
ELEMENTS=${#args_array[@]}
argx=""
for (( i=0;i<$ELEMENTS;i++)); do
  argx+="\"${args[${i}]}\" "
done
read line
echo $argx
read line
arch-chroot /mnt /bin/bash /tmp/ins1-chroot.sh $argx
read line
passwd

#			user

read line
useradd -mg wheel $username
read line
passwd $username
read line
sed -i 's/^# %sudo/%sudo/' /etc/sudoers
read line
groupadd sudo
read line
gpasswd -a $username sudo
read line

#			pacman

read line
sed -i 's/^#Color/Color/' /etc/pacman.conf

#			internet

if [ $WIFI = 0 ]; then
  read line
  systemctl enable NetworkManager
else
  read line
  while ! pacman -S --noconfirm --needed iwd; do
    reconnect
  done
  read line
  printf "\n\n[General]\nEnableNetworkConfiguration=true" >> /etc/iwd/main.conf
  read line
  printf "\n\nnameserver 8.8.8.8" >> /etc/resolv.conf
  read line
  systemctl enable NetworkManager iwd
fi

#			fstab

read line
printf "\ntmpfs /root/tren tmpfs defaults,size=2048M 0 0\ntmpfs /home/$username/tren tmpfs defaults,size=2048M 0 0\ntmpfs /home/$username/.cache/pikaur tmpfs default 0 0\ntmpfs /home/$username/.local/share/pikaur/aur_repos tmpfs defaults,size=2048M 0 0\ntmpfs /var/lib/systemd/coredumps tmpfs defaults,size=512M 0 0\ntmpfs /home/$username/.cargo tmpfs defaults,size=640M 0 0\ntmpfs /home/$username/chromium/cache tmpfs noatime,nodev,nosuid,size=1152M 0 0" >> "/root/tren/fstab_radni"
read line
cp "/root/tren/fstab_radni" > /etc/fstab
read line
cd "/home/$username"
read line
sudo -u "$username" mkdir .cache
read line
sudo -u "$username" mkdir .cache/pikaur
read line
sudo -u "$username" mkdir .local
read line
sudo -u "$username" mkdir .local/share
read line
sudo -u "$username" mkdir .local/share/pikaur
read line
sudo -u "$username" mkdir .local/share/pikaur/aur_repos
read line
sudo -u "$username" mkdir /var/lib/systemd/coredumps
read line
sudo -u "$username" mkdir .cargo

#			grub

read line
if [ $EFI = 1 ]; then
  read line
  while ! pacman -S --noconfirm --needed efibootmgr; do
    reconnect
  done
  read line
  grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
else
  read line
  grub-install $drive_name
fi
read line
mkdir /tmp/grub_radni
read line
cd /tmp/grub_radni
read line
cp /etc/default/grub grub
read line
sed -i 's/#GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/' grub
if [ $AMD_GPU = 1 ]; then
  read line
  sed -i 's/\(^GRUB_CMDLINE_LINUX_DEFAULT.*\)\"/\1 amdgpu.ppfeaturemask=0xffffffff mitigations=off\"/' grub
else
  read line
  sed -i 's/\(^GRUB_CMDLINE_LINUX_DEFAULT.*\)\"/\1 mitigations=off\"/' grub
fi
if [ $AMD_CPU = 1 ]; then
  read line
  while ! pacman -S --noconfirm --needed amd-ucode; do
    reconnect
  done
else
  read line
  while ! pacman -S --noconfirm --needed intel-ucode; do
    reconnect
  done
fi
read line
cp grub /etc/default/grub
read line
grub-mkconfig -o /boot/grub/grub.cfg

#			jezik i vreme

read line
cd /etc
read line
sed -i 's/#en_US/en_US/g' locale.gen
read line
locale-gen
read line
echo "LANG=en_US.UTF-8" >> locale.conf
read line
echo arch >> hostname
read line
ln -sf /usr/share/zoneinfo/Europe/Belgrade /etc/localtime

#			skripte

read line
cd /tmp
read line
sudo -u "$username" mkdir git_scripts
read line
cd git_scripts
read line
while ! sudo -u "$username" git clone https://github.com/donaastor/archgd.git; do
  reconnect
done
read line
cd archgd
read line
rm -rf .git
read line
sudo -u "$username" mv scripts "/home/$username/scripts"
read line
sudo -u "$username" mkdir "/home/$username/Pictures"
read line
sudo -u "$username" mv poz_r.jpg "/home/$username/Pictures/poz.jpg"
read line
sudo -u "$username" mkdir "/home/$username/.config"
if [ $MORE_PROGS = 1 ]; then
  read line
  sudo -u "$username" mv "geany" "/home/$username/.config/geany"
fi

#			getty

read line
cd /etc/systemd/system
read line
mkdir "getty@tty1.service.d"
read line
cd "getty@tty1.service.d"
read line
printf "[Service]\nExecStart=\nExecStart=-/sbin/agetty -o \'-p -f -- \\u\' --noclear --autologin root - $TERM\nType=simple\n" > autologin.conf
if [ $WIFI = 1 ]; then
  read line
  printf "/bin/bash \"/home/$username/scripts/$next_script\" $username \"$params\" \"$ssid_dft\"" >> "/home/$username/.bashrc"
else
  read line
  printf "/bin/bash \"/home/$username/scripts/$next_script\" $username \"$params\"" >> "/home/$username/.bashrc"
fi

#			reboot

exit
umount -R /mnt
reboot
