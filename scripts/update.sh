#!/bin/bash

scripts="ins ins-chroot ins-late share printer wifi-guard update"

username=$USER
if [ "$username" = "root" ]; then
  printf "You are running this script as root!\n\n"
fi

cd /tmp
if ! [ -d current_scripts_from_git ]; then
  mkdir current_scripts_from_git
fi
cd current_scripts_from_git
for scn in $scripts; do
  curl --no-sessionid "https://raw.githubusercontent.com/donaastor/archgd/main/scripts/$scn.sh" > "$scn.sh"
done

hash2=""
MV_UD=0

smeni() {
  hash1="$( md5sum $1.sh | awk '{printf $1}' )"
  if [ -f "/home/$username/scripts/$1.sh" ]; then
    hash2="$( md5sum /home/$username/scripts/$1.sh | awk '{printf $1}' )"
  fi
  if [ "$hash1" != "$hash2" ]; then
    if [ "$1" = "update" ]; then
      MV_UD=1
      echo "\"update.sh\" will be updated"
    else
      mv "$1.sh" "/home/$username/scripts/$1.sh"
      echo "Updated \"$1\""
    fi
  fi
}

for scn in $scripts; do
  smeni "$scn"
done
printf "\nNote that github might serve up to 5 minutes old versions.\n\n"
if [ $MV_UD = 1 ]; then
  exec bash --norc -c "mv /tmp/current_scripts_from_git/update.sh /home/$username/scripts/update.sh; echo \"Updated updater\""
fi
