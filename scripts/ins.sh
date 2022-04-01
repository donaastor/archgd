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
  argx+="\"${args_array[${i}]}\" "
done
read line
echo $argx
read line
arch-chroot /mnt /bin/bash /tmp/ins-chroot.sh $argx

#			reboot

umount -R /mnt
reboot
