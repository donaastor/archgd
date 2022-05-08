#!/bin/bash

username=$USER
if [ "$username" = "root" ]; then
  printf "You are running this script as root!\n\n"
fi

cd /tmp
mkdir current_scripts_from_git
cd current_scripts_from_git
curl https://raw.githubusercontent.com/donaastor/archgd/main/scripts/ins.sh > ins.sh
curl https://raw.githubusercontent.com/donaastor/archgd/main/scripts/ins-chroot.sh > ins-chroot.sh
curl https://raw.githubusercontent.com/donaastor/archgd/main/scripts/ins-late.sh > ins-late.sh
curl https://raw.githubusercontent.com/donaastor/archgd/main/scripts/share.sh > share.sh
curl https://raw.githubusercontent.com/donaastor/archgd/main/scripts/printer.sh > printer.sh
curl https://raw.githubusercontent.com/donaastor/archgd/main/scripts/wifi-guard.sh > wifi-guard.sh

hash2=""

smeni() {
  hash1="$( md5sum $1.sh | awk '{printf $1}' )"
  if [ -f "/home/$username/scripts/$1.sh" ]; then
    hash2="$( md5sum /home/$username/scripts/$1.sh | awk '{printf $1}' )"
  fi
  if [ "$hash1" != "$hash2" ]; then
    mv "$1.sh" "/home/$username/scripts/$1.sh"
    echo "Updated \"$1\""
  fi
}

smeni ins
smeni ins-chroot
smeni ins-late
smeni share
smeni printer
smeni wifi-guard
