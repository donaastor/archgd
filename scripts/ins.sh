#!/bin/bash

efiquit() {
  echo "You are not in UEFI. Quitting"
  exit 33
}

num_of_args=$#
if [ "$num_of_args" -lt "5" ]; then
  printf "At least 5 arguments expected:\n1. BIOS type: BIOS or EFI\n2. Boot partition\n3. Root partition\n4. (optional, only if BIOS selected) name of the whole drive\n5. username\n6. parameters... a string of 0's and 1's (and other digits)\n    first bit: set:\n      0 - if you have an Intel CPU,\n      1 - if you have an AMD pre-Zen CPU, or\n      2 - if you have an AMD Zen CPU\n    second bit: set:\n      0 - for no graphics driver,\n      1 - if you have an AMD GCN-2 or older GPU,\n      2 - if you have a GCN-1 or GCN-2, but want newer drivers,\n      3 - if you have a newer AMD GPU (for newer drivers), or\n      4 - if you have an RDNA 2 or newer GPU\n    third bit: set if WiFi available and ethernet not available\n    fourth bit: set if you want to set up for HiDPI\n    fifth bit: set if you have a battery\n    sixth bit: set if you want more programs installed\n7. (optional, only if WiFi selected) SSID\n"
  exit 1
fi
if [ "$1" = "EFI" ]; then
  efipop=""
  if ! efipop="$(ls /sys/firmware/efi/efivars)"; then
    efiquit
  fi
  if [ "$efipop" = "" ]; then
    efiquit
  fi
  echo "You are in UEFI. Continuing"
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
CPU="${params:0:1}"
if ! [[ $CPU =~ [0-2] ]]; then CPU=0; fi
GPU="${params:1:1}"
if ! [[ $GPU =~ [0-4] ]]; then GPU=0; fi
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

if [ $WIFI = 1 ]; then
  while ! curl https://raw.githubusercontent.com/donaastor/archgd/main/scripts/wifi-guard.sh > /tmp/wifi-guard.sh; do
    reconnect
  done
  2>/dev/null 1>/dev/null bash "/tmp/wifi-guard.sh" "$ssid_dft" &
fi

timedatectl set-ntp true


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

pacman -Syy
pacman -S --noconfirm archlinux-keyring
while ! pacstrap /mnt base linux linux-firmware; do
  reconnect
done
if [ $WIFI = 1 ]; then
  cp -r /var/lib/iwd /mnt/var/lib/iwd
fi
mkdir "/mnt/root/tren"
mount -t tmpfs tmpfs -o defaults,size=128M "/mnt/root/tren"
genfstab -U /mnt >> "/mnt/root/tren/fstab_radni"
cd /
while ! curl https://raw.githubusercontent.com/donaastor/archgd/main/scripts/ins-chroot.sh > /mnt/root/tren/ins-chroot.sh; do
  reconnect
done
if [ $num_of_args = 5 ]; then
  arch-chroot /mnt /bin/bash /root/tren/ins-chroot.sh "$1" "$2" "$3" "$4" "$5"
elif [ $num_of_args = 6 ]; then
  arch-chroot /mnt /bin/bash /root/tren/ins-chroot.sh "$1" "$2" "$3" "$4" "$5" "$6"
elif [ $num_of_args = 7 ]; then
  arch-chroot /mnt /bin/bash /root/tren/ins-chroot.sh "$1" "$2" "$3" "$4" "$5" "$6" "$7"
fi

#			resolv.conf

printf "\nnameserver 84.200.69.80\n" >> /mnt/etc/resolv.conf

#			reboot

while ! umount -R /mnt; do
  sleep 1
done

# echo "Press enter [reboot]"; read line
reboot
