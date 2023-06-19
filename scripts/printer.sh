#!/bin/bash

# listaj printere: lpstat -v
# printaj fajl: lpadmin -o page-ranges=a-b,c-d filename      https://www.cups.org/doc/options.html
# citaj error: systemctl status cups
# error log: /var/log/cups/error_log
# dodaj hp prineter rucno: hp-setup -i -x IP_ADRESA

# ako ne radi:
# PAZI da su IP adrese u redu i da je forwardovanje u redu ! proveri ufw (enabled, /etc/ufw/sysctl.conf, /etc/ufw/before.rules) i IP printera na ruteru
# PAZI da su programi hplip i hplip-plugin iste verzije

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

aur_get_one() {
  cd /tmp/aur_repos
  if ! pacman -Q $1; then
    while ! git clone --depth 1 https://aur.archlinux.org/$1.git; do
      reconnect
    done
    cd $1
    
    sed -n '/^.*depends = .*$/p' .SRCINFO > tren1
    sed '/^.*optdepends = .*$/d' tren1 > tren2
    sed 's/^.*depends = \(.*\)$/\1/' tren2 > tren3
    while read hahm; do
      if ! pacman -Q $hahm; then
        printf "$hahm\n" >> tren4
      fi
    done < tren3
    if [ -e tren4 ]; then
      local dpd_list="$(tr '\n' ' ' < tren4)"
      rm tren4
      while ! sudo pacman -S --noconfirm --needed $dpd_list; do
        reconnect
      done
    fi
    rm tren1 tren2 tren3
    sed -n '/^.*validpgpkeys = .*$/p' .SRCINFO > tren1
    sed 's/^.*validpgpkeys = \([[:alnum:]]\+\).*$/\1/' tren1 > tren2
    sed 's/^.*\(................\)$/\1/' tren2 > tren3
    while read ano_pgp; do
      while ! gpg --recv-keys $ano_pgp; do
        reconnect
      done
    done < tren3
    rm tren1 tren2 tren3
    while ! makepkg -do; do
      reconnect
    done
    makepkg -e
    find . -maxdepth 1 -type f -iregex "^\./$1.*\.pkg\.tar\.zst$" > tren5
    local pkg_name="$(sed -n '1p' tren5)"
    rm tren5
    while ! sudo pacman -U --noconfirm --needed "$pkg_name"; do
      reconnect
    done
    rm -rf /tmp/aur_repos/*
  fi
}

aur_get() {
  while (( $# )); do
    aur_get_one $1
    shift
  done
}

if [ $WIFI = 1 ]; then
  2>/dev/null 1>/dev/null bash /home/$username/scripts/wifi-guard.sh "$ssid_dft" &
fi

if ! [ -d /tmp/aur_repos ]; then
  mkdir /tmp/aur_repos
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
  pacad=--noconfirm
fi

while ! sudo pacman -S --needed $pacad cups hplip; do
  reconnect
done
if [ $AUTO = 1 ]; then
  aur_get hplip-plugin
else
  while ! pikaur -S hplip-plugin; do
    reconnect
  done
fi
Q1_F=1
while [ $Q1_F == 1 ]; do
  printf "Are you accessing your printer directly (yes/no)? "
  read dir_odg
  if [ "$dir_odg" == yes ]; then
    FWD=0
    Q1_F=0
  elif [ "$dir_odg" == no ]; then
    FWD=1
    Q1_F=0
  fi
done
if [ $FWD == 1 ]; then
  sudo sed 's/^#\(net.ipv4.ip_forward\).*$/\1=1/' -i /etc/ufw/sysctl.conf # ovo se ponistilo jednom posle updata, pazi
  sudo sed 's/^\(DEFAULT_OUTPUT_POLICY\).*$/\1="ACCEPT"/' -i /etc/default/ufw
  printf "Real printer IP: "
  read real_ip
  printf "Fake new printer IP: "
  read fake_ip
  printf "Ports that are forwarded to 80,9100,161,162 (separate by spaces):\n"
  read fw_ports
  fwpa=( $fw_ports )
  pt80=${fwpa[0]}
  pt9100=${fwpa[1]}
  pt161=${fwpa[2]}
  pt162=${fwpa[3]}
  sudo sed "s/^\(\*filter\)$/\*nat\n:OUTPUT ACCEPT \[0:0\]\n-A OUTPUT -p tcp -d $fake_ip --dport 80   -j DNAT --to-destination $real_ip:$pt80\n-A OUTPUT -p tcp -d $fake_ip --dport 9100 -j DNAT --to-destination $real_ip:$pt9100\n-A OUTPUT -p udp -d $fake_ip --dport 9100 -j DNAT --to-destination $real_ip:$pt9100\n-A OUTPUT -p tcp -d $fake_ip --dport 161  -j DNAT --to-destination $real_ip:$pt161\n-A OUTPUT -p udp -d $fake_ip --dport 161  -j DNAT --to-destination $real_ip:$pt161\n-A OUTPUT -p tcp -d $fake_ip --dport 162  -j DNAT --to-destination $real_ip:$pt162\n-A OUTPUT -p udp -d $fake_ip --dport 162  -j DNAT --to-destination $real_ip:$pt162\nCOMMIT\n\1/" -i /etc/ufw/before.rules
  sudo ufw disable
  sudo ufw enable
else
  printf "Printer IP: "
  read fake_ip
fi
sudo systemctl enable cups.socket cups.service
sudo systemctl start cups
echo "Starting CUPS..."
sleep 0.3
while ! hp-setup -i -a -x $fake_ip; do
  echo "Waiting for CUPS to initialize..."
  sleep 1
done
p_name="$( sudo cat /etc/cups/printers.conf | sed -n '/^<Printer .*>$/p' | sed 's/^<Printer \(.*\)>$/\1/' )"
while [ "$p_name" = "" ]; do
  echo "Waiting for CUPS to load printer..."
  sleep 1
  p_name="$( sudo cat /etc/cups/printers.conf | sed -n '/^<Printer .*>$/p' | sed 's/^<Printer \(.*\)>$/\1/' )"
done
while ! lpadmin -d "$p_name"; do
  echo "Waiting for CUPS to load printer..."
  sleep 1
done
while ! lpoptions -p "$p_name" -o PageSize=A4; do
  echo "Waiting for CUPS to load printer..."
  sleep 1
done
while ! lpadmin -p "$p_name" -u allow:$username; do
  echo "Waiting for CUPS to load printer..."
  sleep 1
done
if [ -f /home/$username/.config/gtk-3.0/settings.ini ]; then
  mv /home/$username/.config/gtk-3.0/settings.ini /home/$username/.config/gtk-3.0/settings-before-print-setup.ini
fi
printf "[Settings]\ngtk-print-backends=file,cups,pdf\n" > /home/$username/.config/gtk-3.0/settings.ini
echo "Exiting setup..."
