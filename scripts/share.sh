#!/bin/bash

username=$USER
if [ $username = root ]; then
  echo "Don't run this script as root!"
  exit 2
fi

if pacman -Q iwd; then
  ima_iwd=1
else
  ima_iwd=0
fi

if [ $ima_iwd = 1 ]; then
  ssid_dft="$( iwctl station wlan0 show | grep -- 'Connected network' | awk '{print $3}' )"
  if [ "$ssid_dft" = "" ]; then
    WIFI=0
  else
    WIFI=1
  fi
else
  WIFI=0
fi

if [ $WIFI = 0 ]; then
  inrt="$( ip route )"
  if [ "$inrt" = "" ]; then
    incn=0
  else
    incn=1
  fi
else
  incn=1
fi

if [ $incn = 0 ]; then
  echo "No internet connection, aborting."
  exit 1
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

if [ $WIFI = 1 ]; then
  2>/dev/null 1>/dev/null bash /home/$username/scripts/wifi-guard.sh "$ssid_dft" &
fi

#			skripta

AUTO=0
while getopts ":a" OPTION; do
  case $OPTION in
    a)
      AUTO=1
      echo "Automated setup"
      ;;
  esac
done

if [ $AUTO = 1 ]; then
  while ! sudo pacman -S --needed --noconfirm samba; do
    reconnect
  done
else
  while ! sudo pacman -S --needed samba; do
    reconnect
  done
fi
mkdir $HOME/sharing
mkdir $HOME/sharing/write
mkdir $HOME/sharing/read
n_HOME=$HOME
sudo chown root:root $n_HOME/sharing/read
printf "\ntmpfs $n_HOME/sharing/write tmpfs defaults,size=2048M 0 0\n" | sudo tee -a /etc/fstab > /dev/null
sudo mount -t tmpfs tmpfs $n_HOME/sharing/write -o defaults,size=2048M
n_USER=$USER
printf "Name your share: "
read loc_name
printf "Give bash nickname to your share: "
read loc_nick
if [ -f /etc/samba/smb.conf ]; then
  sudo mv /etc/samba/smb.conf /etc/samba/smb-before-share-script.conf
fi
printf "[global]\nworkgroup = WORKGROUP\nserver string = Samba Server\nserver role = standalone server\nlog file = /usr/local/samba/var/log.%%m\nmax log size = 50\ndns proxy = no\nserver smb encrypt = desired\nmin protocol = SMB2\nprotocol = SMB3\n\n[$loc_name]\npath = $n_HOME/sharing/write\navailable = yes\nbrowsable = yes\nread only = yes\nvalid users = $n_USER\n" | sudo tee /etc/samba/smb.conf > /dev/null
echo "Password for connecting to \"$loc_name\" as $n_USER:"
sudo smbpasswd -a $n_USER
sudo ufw allow CIFS
sudo mkdir /usr/local/samba
sudo mkdir /usr/local/samba/var
printf "Remote IP: "
read win_ip
printf "Remote port: "
read win_port
printf "Remote share name: "
read rem_name
printf "Username: "
read win_user
printf "Password for connecting to \"$rem_name\" as $win_user: "
read win_pass
printf "Bash nickname for remote share: "
read win_nick
sed "s/^\\(PS1=.\\[\\\\u@\\\\h \\\\W\\]\\\\. .\\)$/\\1\nalias shon_$loc_nick='sudo systemctl restart smb nmb'\nalias shon_$win_nick='sudo mount -t cifs \\/\\/$win_ip\\/$rem_name \\/home\\/$USER\\/sharing\\/read -o port=$win_port,workgroup=WORKGROUP,iocharset=utf8,username=$win_user,password=$win_pass,cache=none'\nshon() {\n  if \\[ -z \"\$1\" \\]; then\n    shon_$loc_nick\n    shon_$win_nick\n  else\n    if \\[ \"\$1\" = \"$loc_nick\" \\]; then\n      shon_$loc_nick\n    elif \\[ \"\$1\" = \"$win_nick\" \\]; then\n      shon_$win_nick\n    fi\n  fi\n}\nalias shoff_$loc_nick='sudo systemctl stop smb nmb'\nalias shoff_$win_nick='sudo umount -fl \\/home\\/$USER\\/sharing\\/read'\nshoff() {\n  if \\[ -z \"\$1\" \\]; then\n    shoff_$loc_nick\n    shoff_$win_nick\n  else\n    if \\[ \"\$1\" = \"$loc_nick\" \\]; then\n      shoff_$loc_nick\n    elif \\[ \"\$1\" = \"$win_nick\" \\]; then\n      shoff_$win_nick\n    fi\n  fi\n}\n/" -i $HOME/.bashrc
