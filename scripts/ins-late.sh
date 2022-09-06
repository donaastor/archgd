#!/bin/bash

username="$1"
params="$2"
if [ "${params:0:1}" = "0" ]; then
  CPU=0
elif [ "${params:0:1}" = "1" ]; then
  CPU=1
elif [ "${params:0:1}" = "2" ]; then
  CPU=2
fi
if [ "${params:1:1}" = "0" ]; then
  GPU=0
elif [ "${params:1:1}" = "1" ]; then
  GPU=1
elif [ "${params:1:1}" = "2" ]; then
  GPU=2
elif [ "${params:1:1}" = "3" ]; then
  GPU=3
elif [ "${params:1:1}" = "4" ]; then
  GPU=4
fi
if [ "${params:2:1}" = "1" ]; then
  WIFI=1
  ssid_dft="$3"
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
  2>/dev/null 1>/dev/null bash "/home/$username/scripts/wifi-guard.sh" "$ssid_dft" &
fi




aur_get_one() {
  cd /tmp/aur_repos
  if ! pacman -Q $1; then
    while ! sudo -u "$username" git clone --depth 1 https://aur.archlinux.org/$1.git; do
      reconnect
    done
    cd $1
    sed -n '/^.*depends = .*$/p' .SRCINFO > tren1
    sed '/^.*optdepends = .*$/d' tren1 > tren2
    sed 's/^.*depends = \(.*\)$/\1/' tren2 > tren3
    # sed -e 's/^.*makedepends = \(.*\)$/\1/' -e '/^.*depends = .*$/d' tren2 > tren3
    # sed -e '/^.*makedepends = .*$/d' -e 's/^.*depends = \(.*\)$/\1/' tren2 > tren6
    while read hahm; do
      if ! pacman -Q $hahm; then
        printf "$hahm\n" >> tren4
      fi
    done < tren3
    if [ -e tren4 ]; then
      local dpd_list="$(tr '\n' ' ' < tren4)"
      rm tren4
      while ! pacman -S --noconfirm --needed $dpd_list; do
        reconnect
      done
    fi
    rm tren1 tren2 tren3
    sed -n '/^.*validpgpkeys = .*$/p' .SRCINFO > tren1
    sed 's/^.*validpgpkeys = \([[:alnum:]]\+\).*$/\1/' tren1 > tren2
    sed 's/^.*\(................\)$/\1/' tren2 > tren3
    while read ano_pgp; do
      while ! sudo -u "$username" gpg --recv-keys $ano_pgp; do
        reconnect
      done
    done < tren3
    rm tren1 tren2 tren3
    # local pdpdl="$(tr '\n' ' ' < tren6)"
    while ! sudo -u "$username" makepkg -do; do
      reconnect
    done
    sudo -u "$username" makepkg -e
    find . -maxdepth 1 -type f -iregex "^\./$1.*\.pkg\.tar\.zst$" > tren5
    local pkg_name="$(sed -n '1p' tren5)"
    rm tren5
    while ! pacman -U --noconfirm --needed --verbose "${pkg_name}"; do
      reconnect
    done
    rm -rf /tmp/aur_repos/*
  fi
}

aur_get() {
  while (( "$#" )); do
    aur_get_one $1
    shift
  done
}






if ! [ -d /var/cache ]; then mkdir /var/cache; fi
if ! [ -d /var/cache/pacman ]; then mkdir /var/cache/pacman; fi
if ! [ -d /var/cache/pacman/pkg ]; then mkdir /var/cache/pacman/pkg; fi
rm -rf /var/cache/pacman/pkg/*
mount -t tmpfs tmpfs -o defaults,size=2560M /var/cache/pacman/pkg




#			internet

sleep 2
reconnect
timedatectl set-ntp true

#			getty

cd "/etc/systemd/system/getty@tty1.service.d"
printf "[Service]\nExecStart=\nExecStart=-/sbin/agetty -o \'-p -f -- \\\\\\\\u\' --noclear --autologin $username - \$TERM\nType=simple\nEnvironment=XDG_SESSION_TYPE=x11\n" > autologin.conf

#			programi

sudo -u "$username" mkdir /tmp/aur_repos
aur_get pikaur
sudo -u "$username" pikaur
sudo -u "$username" cp "/home/$username/.config/pikaur.conf" "/tmp/pikaur_radni.conf"
sed -i 's/keepbuilddeps = no/keepbuilddeps = yes/' "/tmp/pikaur_radni.conf"
sed -i 's/noedit = no/noedit = yes/' "/tmp/pikaur_radni.conf"
sed -i 's/donteditbydefault = no/donteditbydefault = yes/' "/tmp/pikaur_radni.conf"
sudo -u "$username" cp "/tmp/pikaur_radni.conf" "/home/$username/.config/pikaur.conf"
if [ $GPU -ne 0 ]; then
  if [ $GPU = 2 ] || [ $GPU = 3 ]; then
    while ! pacman -S --noconfirm --needed mesa xf86-video-amdgpu mesa-vdpau libva-mesa-driver vulkan-radeon vulkan-tools mesa-utils libva-utils; do
      reconnect
    done
  elif [ $GPU = 4 ]; then
    while ! pacman -S --noconfirm --needed libva --assume-installed=libgl; do
      reconnect
    done
    while ! pacman -Sdd --noconfirm libglvnd; do
      reconnect
    done
    aur_get mesa-git xf86-video-amdgpu-git
    while ! pacman -S --noconfirm --needed vulkan-tools mesa-utils libva-utils; do
      reconnect
    done
  elif [ $GPU = 1 ]; then
    while ! pacman -S --noconfirm --needed mesa xf86-video-ati mesa-vdpau libva-mesa-driver vulkan-radeon vulkan-tools mesa-utils libva-utils; do
      reconnect
    done
  fi
fi
if [ $MORE_PROGS = 1 ]; then
  ad_progs="texlive-core texlive-formatsextra texlive-langcyrillic texlive-latexextra texlive-science openssh tmux vlc feh zathura zathura-djvu zathura-pdf-poppler flameshot calc geany geany-plugins pcmanfm-gtk3 gvfs simplescreenrecorder gimp transmission-qt torsocks php python python-requests python-pysocks python-pip"
  aur_progs=""
else
  ad_progs=""
  aur_progs=""
fi
while ! pacman -S --noconfirm --needed nano xorg-server xorg-xinit xorg-xrdb xorg-xinput numlockx xbindkeys i3-gaps i3status i3lock ntfs-3g rofi nitrogen picom pipewire pipewire-pulse pipewire-jack wireplumber rtkit alacritty xdg-utils ttf-liberation man-db man-pages nnn htop perl-file-mimeinfo zip unzip p7zip ufw lshw usbutils smartmontools exfatprogs $ad_progs; do
  reconnect
done
rm -rf /var/cache/pacman/pkg/*
while ! modprobe fuse; do
  depmod
  sleep 1
done
while ! modprobe ntfs3; do
  depmod
  sleep 1
done
if [ $BATT = 1 ]; then
  while ! pacman -S --noconfirm --needed acpi; do
    reconnect
  done
  rm -rf /var/cache/pacman/pkg/*
fi
aur_get xidlehook xkb-switch-i3 xkblayout-state-git $aur_progs
if [ $GPU -ne 4 ]; then
  rm -rf /var/cache/pacman/pkg/*
  aur_get corectrl
  if ! [ -d "/home/$username/.config/autostart" ]; then
    sudo -u "$username" mkdir "/home/$username/.config/autostart"
    chown $username:wheel "/home/$username/.config/autostart"
  fi
  sudo -u "$username" cp /usr/share/applications/org.corectrl.corectrl.desktop "/home/$username/.config/autostart/org.corectrl.corectrl.desktop"
  if ! [ -d "/etc/polkit-1" ]; then
    mkdir "/etc/polkit-1"
  fi
  if ! [ -d "/etc/polkit-1/rules.d" ]; then
     mkdir "/etc/polkit-1/rules.d"
  fi
  printf "polkit.addRule(function(action, subject){\n	if ((\n		action.id == \"org.corectrl.helper.init\" ||\n		action.id == \"org.corectrl.helperkiller.init\") &&\n		subject.local == true &&\n		subject.active == true &&\n		subject.isInGroup(\"wheel\")\n	){\n		return polkit.Result.YES;\n	}\n});\n" >> "/etc/polkit-1/rules.d/90-corectrl.rules"
  if ! [ -d "/home/$username/.config/corectrl" ]; then
    sudo -u "$username" mkdir "/home/$username/.config/corectrl"
    chown $username:wheel "/home/$username/.config/corectrl"
  fi
  printf "[General]\nstartOnSysTray=true\n" > "/home/$username/.config/corectrl/corectrl.ini"
  chown $username:wheel "/home/$username/.config/corectrl/corectrl.ini"
fi
if [ $CPU = 2 ]; then
  while ! pacman -S --noconfirm --needed linux-headers dkms; do
    reconnect
  done
  rm -rf /var/cache/pacman/pkg/*
  aur_get zenpower3-dkms zenmonitor3-git
  modprobe zenpower
fi

#			konfiguracije

rm /root/.bash_profile

sensors-detect --auto
sed -i 's/^# set zap/set zap/' /etc/nanorc
printf "\nsleep() {\n  if [ \"\$USER\" = \"$username\" ]; then\n    if [ \"\$1\" = \"on\" ]; then\n      if ! pgrep -f xidlehook; then\n        xidlehook --timer 600 'systemctl suspend -i' '' &\n      fi\n    elif [ \"\$1\" = \"off\" ]; then\n      sudo pkill xidlehook\n    else\n      echo \"wrong parameter\"\n    fi\n  else\n    if [ \"\$1\" = \"on\" ]; then\n      if ! pgrep -f xidlehook; then\n        xidlehook --timer 600 'systemctl suspend -i' '' &\n      fi\n    elif [ \"\$1\" = \"off\" ]; then\n      pkill xidlehook\n    else\n      echo \"wrong parameter\"\n    fi\n  fi\n}\nvol() {\n  if [ -z \"\$1\" ]; then\n    pactl get-sink-volume @DEFAULT_SINK@\n  else\n    pactl set-sink-volume @DEFAULT_SINK@ \$1%%\n  fi\n}\nalias ls=\'ls --color=tty\'\nalias lsa=\'ls -la\'\nalias ip=\'ip -color=auto\'\nalias cal=\'cal -m3\'\nalias q=\'exit\'\nalias cl=\'clear\'\nalias stfu=\'shutdown now\'\nalias sus=\'systemctl suspend\'\n" >> /etc/bash.bashrc

if ! [ -d /etc/modprobe.d ]; then
  mkdir /etc/modprobe.d
fi
printf "blacklist pcspkr\n" > /etc/modprobe.d/nobeep.conf
cp /etc/xdg/picom.conf /tmp/picom_radni.conf
sed -i 's/^fade-in-step/#fade-in-step/' /tmp/picom_radni.conf
sed -i 's/^fade-out-step/#fade-out-step/' /tmp/picom_radni.conf
sed -i 's/^no-fading-openclose/#no-fading-openclose/' /tmp/picom_radni.conf
sed -i 's/^fading = true\;/fading = false\;/' /tmp/picom_radni.conf
sed -i 's/^\(.*popup_menu =.*opacity =\)\( 0\.[0-9]\{1,2\}\)\(.*\)$/\1 0.93\3/' /tmp/picom_radni.conf
sed -i 's/^\(.*dropdown_menu =.*opacity =\)\( 0\.[0-9]\{1,2\}\)\(.*\)$/\1 0.93\3/' /tmp/picom_radni.conf
cp /tmp/picom_radni.conf /etc/xdg/picom.conf
cd "/home/$username"
if [ $HIDPI = 1 ]; then
  # echo "Press enter [HiDPI .Xresources]"; read line
  printf "Xft.dpi: 192\n" > .Xresources
  chown $username:wheel .Xresources
  # echo "done with .Xresources"; read line
fi
if [ $GPU -ne 0 ] && [ $GPU -ne 4 ]; then
  if [ $HIDPI = 1 ]; then
    printf '#!'"/bin/sh\n\n[[ -f ~/.Xresources ]] && xrdb -merge -I\$HOME ~/.Xresources\nif [ -d /etc/X11/xinit/xinitrc.d ] ; then\n for f in /etc/X11/xinit/xinitrc.d/\?*.sh ; do\n  [ -x \"\$f\" ] && . \"\$f\"\n done\n unset f\nfi\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset dpms 0 180 0\nxset r rate 250 30\nnumlockx &\nxbindkeys &\n(sleep 1.5 && /opt/kbswtb) &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 'systemctl suspend -i' '' &\nfi\npicom --experimental-backends &\nexport QT_SCREEN_SCALE_FACTORS=1.5\ncorectrl &\nnitrogen --restore &\nexec i3\n" > .xinitrc-tobe
  else
    printf '#!'"/bin/sh\n\n[[ -f ~/.Xresources ]] && xrdb -merge -I\$HOME ~/.Xresources\nif [ -d /etc/X11/xinit/xinitrc.d ] ; then\n for f in /etc/X11/xinit/xinitrc.d/\?*.sh ; do\n  [ -x \"\$f\" ] && . \"\$f\"\n done\n unset f\nfi\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset dpms 0 180 0\nxset r rate 250 30\nnumlockx &\nxbindkeys &\n(sleep 1.5 && /opt/kbswtb) &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 'systemctl suspend -i' '' &\nfi\npicom --experimental-backends &\ncorectrl &\nnitrogen --restore &\nexec i3\n" > .xinitrc-tobe
  fi
else
  if [ $HIDPI = 1 ]; then
    printf '#!'"/bin/sh\n\n[[ -f ~/.Xresources ]] && xrdb -merge -I\$HOME ~/.Xresources\nif [ -d /etc/X11/xinit/xinitrc.d ] ; then\n for f in /etc/X11/xinit/xinitrc.d/\?*.sh ; do\n  [ -x \"\$f\" ] && . \"\$f\"\n done\n unset f\nfi\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset dpms 0 180 0\nxset r rate 250 30\nnumlockx &\nxbindkeys &\n(sleep 1.5 && /opt/kbswtb) &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 'systemctl suspend -i' '' &\nfi\npicom --experimental-backends &\nexport QT_SCREEN_SCALE_FACTORS=1.5\nnitrogen --restore &\nexec i3\n" > .xinitrc-tobe
  else
    printf '#!'"/bin/sh\n\n[[ -f ~/.Xresources ]] && xrdb -merge -I\$HOME ~/.Xresources\nif [ -d /etc/X11/xinit/xinitrc.d ] ; then\n for f in /etc/X11/xinit/xinitrc.d/\?*.sh ; do\n  [ -x \"\$f\" ] && . \"\$f\"\n done\n unset f\nfi\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset dpms 0 180 0\nxset r rate 250 30\nnumlockx &\nxbindkeys &\n(sleep 1.5 && /opt/kbswtb) &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 'systemctl suspend -i' '' &\nfi\npicom --experimental-backends &\nnitrogen --restore &\nexec i3\n" > .xinitrc-tobe
  fi
fi
if [ $MORE_PROGS = 1 ]; then
  xit_ad="printf '"'#!'"'\"/bin/bash\\\\n\\\\npsd\\\\ncd /home/$username/.config/psd\\\\nxcn=0\\\\nwhile :; do\\\\n  if [ -f psd.conf ]; then\\\\n    sed -i 's/^.*USE_BACKUPS=\\\\\\\\\\\\\\\\\\\\\"yes\\\\\\\\\\\\\\\\\\\\\".*\\\\\$/USE_BACKUPS=\\\\\\\\\\\\\\\\\\\\\"no\\\\\\\\\\\\\\\\\\\\\"/' psd.conf\\\\n    break\\\\n  else\\\\n    xcn=\\\\\$(( \\\\\$xcn + 1 ))\\\\n    if [ \\\\\$xcn = 400 ]; then break; fi\\\\n    sleep 0.3\\\\n  fi\\\\ndone\\\\nsystemctl --user enable psd\\\\nsystemctl --user start psd\\\\nrm -rf /tmp/psdconf.sh\\\\n\" > /tmp/psdconf.sh\n(sleep 1.37 && bash /tmp/psdconf.sh) &\n"
else
  xit_ad=""
fi
printf '#!'"/bin/sh\n\nprintf '"'#!'"'\"/bin/bash\\\\n\\\\ngotov() {\\\\n  exec bash --norc -c \\\\\"rm /tmp/to100.sh; exit \\\\\$1\\\\\"\\\\n}\\\\n\\\\nvrti() {\\\\n  xcn=0\\\\n  ycn=0\\\\n  while :; do\\\\n    if pactl set-sink-volume @DEFAULT_SINK@ 100%%%%; then gotov 0; fi\\\\n    xcn=\\\\\$(( \\\\\$xcn + 1 ))\\\\n    if [ \\\\\$xcn = \\\\\$1 ]; then\\\\n      xcn=0\\\\n      ycn=\\\\\$(( \\\\\$ycn + 1 ))\\\\n      if [ \\\\\$ycn = \\\\\$2 ]; then break; fi\\\\n      sleep 1\\\\n    fi\\\\n  done\\\\n}\\\\n\\\\nsystemctl --user start pipewire-pulse\\\\nvrti 3 4\\\\nvrti 2 5\\\\nvrti 1 8\\\\n\\\\ngotov 1\\\\n\" > /tmp/to100.sh\n(sleep 1.33 && bash /tmp/to100.sh) &\n""$xit_ad""exec bash -c \"cd /home/$username; mv .xinitrc-tobe .xinitrc && source .xinitrc\"\n" > .xinitrc
sudo -u "$username" mkdir .config/nitrogen
printf "[xin_-1]\nfile=/home/$username/Pictures/poz.jpg\nmode=5\nbgcolor=#000000\n" > .config/nitrogen/bg-saved.cfg
chown $username:wheel .xinitrc .xinitrc-tobe .config/nitrogen/bg-saved.cfg
cp "/home/$username/.bashrc" /tmp/bashrc_radni
chmod 777 /tmp/bashrc_radni
sed -i 's/^alias ls.*$//' /tmp/bashrc_radni
printf "\nalias aur=\'pikaur\'\nalias udsc=\'bash /home/$username/scripts/update.sh\'\nalias mountu=\'sudo mount -o uid=$username,gid=wheel,fmask=113,dmask=002,sync\'\n\nif [ -z \"\${DISPLAY}\" ] && [ \"\${XDG_VTNR}\" -eq 1 ]; then\n  startx\nfi\n" >> /tmp/bashrc_radni
sudo -u "$username" cp /tmp/bashrc_radni "/home/$username/.bashrc"
printf '#!/bin/bash\n\nfor tty in /dev/tty{1..6}\ndo\n  /usr/bin/setleds -D +num < \"$tty\";\ndone\n' > /usr/local/bin/numlock
chmod 755 /usr/local/bin/numlock
printf "[Unit]\nDescription=numlock\n\n[Service]\nExecStart=/usr/local/bin/numlock\nStandardInput=tty\nRemainAfterExit=yes\n\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/numlock.service
systemctl enable numlock
cd /usr/share/icons/default
mkdir cursors
cd cursors
ln -s /usr/share/icons/Adwaita/cursors/left_ptr watch
localectl --no-convert set-x11-keymap us,ru,rs,rs pc105 ,,latin,yz
sudo -u "$username" mkdir /tmp/i3git
cd /tmp/i3git
while ! sudo -u "$username" git clone --depth 1 https://github.com/donaastor/i3-config.git; do
  reconnect
done
cd i3-config
rm -rf .git
sudo -u "$username" mv .xbindkeysrc "/home/$username/.xbindkeysrc"
sudo -u "$username" mkdir "/home/$username/.config/i3"
sudo -u "$username" mv config "/home/$username/.config/i3/"
if [ $CPU = 2 ] && [ $GPU = 4 ]; then
  sudo -u "$username" mv status_script_24.sh "/home/$username/.config/i3/status_script.sh"
else
  sudo -u "$username" mv status_script.sh "/home/$username/.config/i3/"
fi
if [ $WIFI = 0 ]; then
  if [ $BATT = 0 ]; then
    if [ $CPU = 2] && [ $GPU = 4 ]; then
      sudo -u "$username" mv i3status_24 "/home/$username/.config/i3/i3status"
    else
      sudo -u "$username" mv i3status "/home/$username/.config/i3/i3status"
    fi
  else
    sudo -u "$username" mv i3status-bat "/home/$username/.config/i3/i3status"
  fi
else
  if [ $BATT = 0 ]; then
    sudo -u "$username" mv i3status-wifi "/home/$username/.config/i3/i3status"
  else
    sudo -u "$username" mv i3status-wifi-bat "/home/$username/.config/i3/i3status"
  fi
fi
echo "[g++ kbswtb.cpp]"
g++ kbswtb.cpp -o kbswtb -pipe -fwrapv -fno-plt -fno-semantic-interposition -std=c++20 -mcmodel=large -march=x86-64 -mtune=generic -Wshadow -Wno-unused-result -Wall -O3 -L /usr/lib -Wl,--as-needed -lm -lz -lcrypt -lutil -ldl -lpthread -lrt -lX11 -lxkbfile
mv kbswtb /opt/kbswtb
cd "/home/$username/.config/i3"
chmod 755 status_script.sh
mandb
printf '<?xml version=\"1.0\"?>\n<!DOCTYPE fontconfig SYSTEM \"urn:fontconfig:fonts.dtd\">\n<fontconfig>\n	<match target=\"pattern\">\n	<test name=\"family\" qual=\"any\">\n		<string>monospace</string>\n	</test>\n	<edit binding=\"strong\" mode=\"prepend\" name=\"family\">\n		<string>LiberationMono</string>\n	</edit>\n	</match>\n</fontconfig>\n' > /etc/fonts/local.conf
systemctl start ufw
systemctl enable ufw
ufw default allow outgoing
ufw default deny incoming
ufw enable
if [ $MORE_PROGS = 1 ]; then
  sudo -u "$username" xdg-mime default feh.desktop image/png image/jpeg
  sudo -u "$username" xdg-mime default org.pwmt.zathura.desktop application/pdf image/vnd.djvu
  sudo -u "$username" xdg-mime default lyx.desktop text/x-tex
  sudo -u "$username" xdg-mime default onlyoffice-desktopeditors.desktop application/msword application/msexcel application/vnd.ms-word application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet application/vnd.openxmlformats-officedocument.wordprocessingml.document
  sudo -u "$username" xdg-mime default geany.desktop text/plain text/html text/x-c text/x-c++ text/x-java-source text/x-script text/x-script.python
  sudo -u "$username" xdg-mime default pcmanfm.desktop inode/mount-point inode/directory
  sudo -u "$username" mkdir "/home/$username/.config/transmission"
  sudo -u "$username" printf "{\n\t\"download-dir\": \"/tmp\"\n}\n" > "/home/$username/.config/transmission/settings.json"
  chown $username:wheel "/home/$username/.config/transmission/settings.json"
  sed -i 's/^;date\.timezone =$/date\.timezone = \"Europe\/Belgrade\"/' /etc/php/php.ini
fi

#			ungoogled-chromium

if [ $MORE_PROGS = 1 ]; then
  while ! curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/x86_64/home_ungoogled_chromium_Arch.key' | pacman-key -a -; do
    reconnect
  done
  printf "[home_ungoogled_chromium_Arch]\nSigLevel = Required TrustAll\nServer = https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/\$arch\n" | tee --append /etc/pacman.conf
  while ! pacman -Sy --noconfirm --needed pipewire-jack profile-sync-daemon ungoogled-chromium; do
    reconnect
  done
  rm -rf /var/cache/pacman/pkg/*
  if [ $GPU != 0 ]; then
    printf -- "--disk-cache-dir=/home/$username/chromium/cache\n--disk-cache-size=1073741824\n--extension-mime-request-handling\n--load-extension=/home/$username/chromium/extensions/uBlock\n--ignore-gpu-blocklist\n--enable-gpu-rasterization\n--enable-zero-copy\n--enable-features=VaapiVideoDecoder\n--use-gl=egl\n" > /etc/chromium-flags.conf
  else
    printf -- "--disk-cache-dir=/home/$username/chromium/cache\n--disk-cache-size=1073741824\n--extension-mime-request-handling\n--load-extension=/home/$username/chromium/extensions/uBlock" > /etc/chromium-flags.conf
  fi
  chown $username:wheel /etc/chromium-flags.conf
  mkdir /home/$username/chromium/extensions
  crxversion="$(pacman -Qi ungoogled-chromium | sed -n '/^Version/p' | awk '{print $3}' | sed 's/^\(.*\)-.*$/\1/')"
  while ! curl -L 'https://clients2.google.com/service/update2/crx?response=redirect&os=linux&arch=x86-64&os_arch=x86_64&nacl_arch=x86_64&prod=chromiumcrx&prodchannel=unknown&prodversion='"$crxversion"'&acceptformat=crx2,crx3&x=id%3Dcjpalhdlnbpafiamejdnhcphjbkeiagm%26uc' > /tmp/uBlock.crx; do
    reconnect
  done
  ubld="/home/$username/chromium/extensions/uBlock"
  mkdir $ubld
  unzip /tmp/uBlock.crx -d $ubld
  cd $ubld
  rm -rf "_metadata"
  xdg-settings set default-web-browser chromium.desktop
  sed -e 's/^\(.*=\)\(chromium.desktop;\)\(..*\)$/\1\3/' -e 's/^\(.*\)\(chromium\)\(.desktop;\)$/\1geany\3/' -i /usr/share/applications/mimeinfo.cache
fi

#			cleaning

# pacman --noconfirm -Rsn rust
rm -rf /var/cache/pacman/pkg/*

#			reboot

echo 'DONE, rebooting'
reboot
