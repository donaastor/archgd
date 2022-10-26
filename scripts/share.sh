#!/bin/bash

while getopts ":" X; do
  case $OPTARG in
    h)
      H=1
      ;;
    l)
      L=1
      ;;
    r)
      R=1
      ;;
    a)
      A=1
      ;;
  esac
  UKO="${UKO}$OPTARG"
done
if [ "$H" = 1 ] || ([ -z "$R" ] && [ -z "$L" ]); then
  printf "Don't run this script as root"'!'"\nusage:\n  -l  (local)   - to set up a local share\n  -r  (remote)  - to set up a remote location\n  -a  (auto)    - to automatically download all the missing software\n"
  exit 0
fi
if ! [ -z "$UKO" ]; then
  NUKO=${#UKO}
  if [ $NUKO = 1 ]; then
    printf "unknown option $UKO\n"
  else
    printf "unknown options:"
    i=0
    while (($i<$NUKO)); do
      if [ $i = 0 ]; then
        printf " "
      else
        printf ","
      fi
      printf "${UKO:i:1}"
      i=$(($i+1))
    done
    printf "\n"
  fi
fi
if [ $USER = root ]; then
  echo "Don't run this script as root!"
  exit 2
fi


tow() {
  if [ $WIFI = 1 ]; then
    iwctl station wlan0 connect "$ssid_dft"
  else
    getent hosts archlinux.org 1>/dev/null
  fi
  return $?
}
reconnect() {
  printf "Connecting..."
  while :; do
    if [ -z "$WWT" ]; then
      local WWT=1
    else sleep 1; fi
    if tow; then
      break
    else printf .; fi
  done
  printf "\nConnected :)\n"
  sleep 1
}
getnet() {
  if [ $STN = 1 ]; then
    return 0
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
    echo "Erro: No internet connection"
    exit 1
  fi
  if [ $WIFI = 1 ]; then
    2>/dev/null 1>/dev/null bash /home/$USER/scripts/wifi-guard.sh "$ssid_dft" &
  fi
  STN=1
}
checksamba() {
  if pacman -Q samba 1>/dev/null 2>/dev/null; then
    printf "samba is already installed\n"
    samba_ai=1
  else
    if [ -z "$TOI" ]; then
      TOI=samba
    else
      TOI="${TOI} samba"
    fi
  fi
}
checkcifs() {
  if pacman -Q cifs-utils 1>/dev/null 2>/dev/null; then
    printf "cifs-utils are already installed\n"
    cifs_ai=1
  else
    if [ -z "$TOI" ]; then
      TOI=cifs-utils
    else
      TOI="${TOI} cifs-utils"
    fi
  fi
}
getpackages() {
  if [ -z "$TOI" ]; then return 0; fi
  printf "Downloading: $TOI\n"
  getnet()
  if [ "$A" = 1 ]; then
    while ! sudo pacman -S --needed --noconfirm $TOI; do reconnect; done
  else
    while ! sudo pacman -S --needed $TOI; do reconnect; done
  fi
}

#			skripta

getsamba
[ -d $HOME/sharing ] || mkdir $HOME/sharing
if [ $? != 0 ]; then echo "Error: $HOME/sharing already exists and isn't a directory"; exit 1; fi
if [ "$L" = 1 ]; then checksamba; fi
if [ "$R" = 1 ]; then checkcifs; fi
getpackages
if [ "$L" = 1 ]; then
  [ -d $HOME/sharing/write ] || mkdir $HOME/sharing/write
  if [ $? != 0 ]; then echo "Error: $HOME/sharing/write already exists and isn't a directory"; exit 1; fi
  hsw=${HOME//\//\\\/}'\/sharing\/write'
  ufs="$(awk "\$2 ~ /^$hsw\$/ { print \$1, \$3 }" /etc/fstab)"
  if [ "$ufs" != "" ] && [ "$ufs" != "tmpfs tmpfs" ]; then
    echo "Error: $HOME/sharing/write already exists in fstab, but isn't tmpfs"; exit 1; fi
  med="$(findmnt $HOME/sharing/write | tail -1 | awk '{ print $2, $3 }')"
  if [ "$med" != "" ] && [ "$med" != "tmpfs tmpfs" ]; then
    echo "Error: $HOME/sharing/write is already mounted, but isn't tmpfs"; exit 1; fi
  if [ "$ufs" = "" ] || [ "$med" = "" ]; then
    printf "Size of local share (in MB): "
    read ssize
    while ! [[ "$ssize" =~ ^[1-9][0-9]*$ ]]; do
      printf "Bad format, try again: "
      read ssize
    done
    if [ "$(find $HOME/sharing/write -maxdepth 0 -empty)" == "" ]; then
      echo "Error: $HOME/sharing/write is not tmpfs and is not empty"; exit 1; fi
  fi
  if [ "$ufs" = "" ]; then
    printf "\ntmpfs $HOME/sharing/write tmpfs defaults,size=${ssize}M 0 0\n" | sudo tee -a /etc/fstab > /dev/null; fi
  if [ "$med" = "" ]; then
    sudo mount -t tmpfs tmpfs $HOME/sharing/write -o defaults,size=${ssize}M; fi
  printf "Name your share: "
  read loc_name
  printf "Give bash nickname to your share: "
  read loc_nick
  if ! [[ "$loc_nick" =~ ^[a-zA-Z0-9_]*$ ]]; then
    printf "Bad format, try again: "
    read loc_nick
  fi
  printf "Password for connecting to \"$loc_name\" as $USER: "
  sudo smbpasswd -a $USER
  if [ -f /etc/samba/smb.conf ]; then
    tmc=$(sudo mktemp /etc/samba/smb_XXXXXX.conf)
    sudo mv /etc/samba/smb.conf $tmc
    if ! [ -z "$samba_ai" ]; then
      printf "Moved old samba config to $tmc\n"; fi
  fi
  printf "[global]\nworkgroup = WORKGROUP\nserver string = Samba Server\nserver role = standalone server\nlog file = /usr/local/samba/var/log.%%m\nmax log size = 50\ndns proxy = no\nserver smb encrypt = desired\nmin protocol = SMB2\nprotocol = SMB3\n\n[$loc_name]\npath = $HOME/sharing/write\navailable = yes\nbrowsable = yes\nread only = yes\nvalid users = $USER\n" | sudo tee /etc/samba/smb.conf 1> /dev/null
fi
if [ "$R" = 1 ]; then
  [ -d $HOME/sharing/read ] || mkdir $HOME/sharing/read
  if [ $? != 0 ]; then echo "Error: $HOME/sharing/read already exists and isn't a directory"; exit 1; fi
  if [ "$(stat -c "%U %G" $HOME/sharing/read)" != "root root" ]; then
    sudo chown root:root $HOME/sharing/read; fi
  printf "Remote IP: "
  read rem_ip
  printf "Remote port: "
  read rem_port
  printf "Remote share name: "
  read rem_name
  printf "Username: "
  read rem_user
  printf "Password for connecting to \"$rem_name\" as $rem_user: "
  read rem_pass
  printf "Bash nickname for remote share: "
  read rem_nick
  if ! [[ "$rem_nick" =~ ^[a-zA-Z0-9_]*$ ]]; then
    printf "Bad format, try again: "
    read rem_nick
  fi
fi

if [ "$L" = 1 ]; then
  STL=("sudo systemctl restart smb nmb" "sudo systemctl stop smb nmb")
else STL=(":" ":"); fi
if [ "$R" = 1 ]; then
  STR=("sudo mount -t cifs \\/\\/$rem_ip\\/$rem_name \\/home\\/$USER\\/sharing\\/read -o port=$rem_port,workgroup=WORKGROUP,iocharset=utf8,username=$rem_user,password=$rem_pass,cache=none" "sudo umount -fl \\/home\\/$USER\\/sharing\\/read")
else STR=(":" ":"); fi
PN="$(grep -e "^SHARE_NICKS=(" $HOME/.bashrc )"
if [ -z "$PN" ]; then
  sed "s/^\\(PS1=.\\[\\\\u@\\\\h \\\\W\\]\\\\. .\\)$/\\1\n\nSHARE_NICKS=(\"$loc_nick\" \"$rem_nick\")\nshon_local(){ ${STL[0]};}\nshoff_local(){ ${STL[1]};}\nshon_remote(){ ${STR[0]};}\nshoff_remote(){ ${STR[1]};}\nshflips=(shon_local shon_remote shoff_local shoff_remote)\nshflip(){\n  if \\[ -z \"\$2\" \\]; then\n    \${shflips[\$1]}; \${shflips[\$1+1]}\n  else\n    for i in {0..1}; do\n      if [ \"\$2\" = \"\${SHARE_NICKS[i]}\" ]; then\n        \${shflips[\$1+i]}; done\n}\nshon(){ shflip 0 \"\$1\";}\nshoff(){ shflip 2 \"\$1\";}\n/" -i $HOME/.bashrc
else
  old_local="$(echo "$PN" | sed "s/.*\\\"\\(.*\\)\\\".*\\\"\\(.*\\)\\\".*/\\1/")"
  old_remote="$(echo "$PN" | sed "s/.*\\\"\\(.*\\)\\\".*\\\"\\(.*\\)\\\".*/\\2/")"
  if [ -z "$loc_nick" ]; then
    loc_nick=old_local; fi
  if [ -z "$rem_nick" ]; then
    rem_nick=old_remote; fi
  old_stl=("$(sed -n "s/^shon_local()[ \\t]*{[ \\t]\+\\(.*\\);[ \\t]*}/\\1/p" $HOME/.bashrc)" "$(sed -n "s/^shoff_local()[ \\t]*{[ \\t]\+\\(.*\\);[ \\t]*}/\\1/p" $HOME/.bashrc)")
  old_m_str=("$(sed -n "s/^\\(^shon_remote()[ \\t]*{.*\\)$/\\1/p" $HOME/.bashrc)" "$(sed -n "s/^shoff_remote()[ \\t]*{[ \\t]\+\\(.*\\);[ \\t]*}/\\1/p" $HOME/.bashrc)")
  if [ -z "$L" ]; then
    STL=("${old_stl[0]}" "${old_stl[1]}"); fi
  if [ -z "$R" ]; then
    STR=("${old_m_str[0]}" "${old_m_str[1]}")
  else
    STR[0]="shon_remote(){ ${STR[0]};}"
  fi
  STR[0]="${STR[0]//\/\\\/}"
  STR[1]="${STR[1]//\/\\\/}"
  sed -n -e "s/^SHARE_NICKS=(.*)/SHARE_NICKS=(\\\"$loc_nick\\\" \\\"$rem_nick\\\")/" -e "s/^shon_local()[ \\t]*{.*$/shon_local(){ ${STL[0]};}/" -e "s/^shoff_local()[ \\t]*{.*$/shoff_local(){ ${STL[1]};}/" -e "s/^shon_remote()[ \\t]*{.*$/${STR[0]}/" -e "s/^shoff_remote()[ \\t]*{.*$/shoff_remote(){ ${STR[1]};}/" -i $HOME/.bashrc
fi

# sudo mkdir /usr/local/samba
# sudo mkdir /usr/local/samba/var
