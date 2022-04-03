#!/bin/bash

username="$1"
params="$2"
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
}





aur_get_one() {
  echo "Press enter to start building from AUR: $1"; read line
  cd /tmp/aur_repos
  while ! sudo -u "$username" git clone https://aur.archlinux.org/$1.git; do
    reconnect
  done
  cd $1
  
  sed -n '/^.*depends = .*$/p' .SRCINFO > tren1
  sed '/^.*optdepends = .*$/d' tren1 > tren2
  sed 's/^.*depends = \(.*\)$/\1/' tren2 > tren3
  sed '/^i3-wm$/d' tren3 > tren4
  local dpd_list="$(tr '\n' ' ' < tren4)"
  rm tren1 tren2 tren3 tren4
  while ! pacman -S --noconfirm --needed $dpd_list; do
    reconnect
  done
  sudo -u "$username" makepkg
  find . -maxdepth 1 -type f -iregex "^\./$1.*\.pkg\.tar\.zst$" > tren5
  local pkg_name="$(sed -n '1p' tren5)"
  rm tren5
  while ! pacman -U --noconfirm --needed "${pkg_name}"; do
    reconnect
  done
  echo "Press enter to continue..."; read line
}

aur_get() {
  while (( "$#" )); do
    aur_get_one $1
    shift
  done
}





#			internet

sleep 2
echo "Press enter [reconnect]"; read line
reconnect

#			getty

echo "Press enter [cd getty]"; read line
cd "/etc/systemd/system/getty@tty1.service.d"
echo "Press enter [fix getty]"; read line
printf "[Service]\nExecStart=\nExecStart=-/sbin/agetty -o \'-p -f -- \\\\\\\\u\' --noclear --autologin $username - \$TERM\nType=simple\nEnvironment=XDG_SESSION_TYPE=x11\n" > autologin.conf

#			programi

echo "Press enter [mkdir /tmp/aur_repos]"; read line
sudo -u "$username" mkdir /tmp/aur_repos

echo "Press enter [aur_get pikaur]"; read line
aur_get pikaur

echo "Press enter [pikaur (create conf)]"; read line
sudo -u "$username" pikaur
echo "Press enter [cp pikaur.conf]"; read line
sudo -u "$username" cp "/home/$username/.config/pikaur.conf" "/tmp/pikaur_radni.conf"
echo "Press enter [sed pikaur.conf keepbuilddeps]"; read line
sed -i 's/keepbuilddeps = no/keepbuilddeps = yes/' "/tmp/pikaur_radni.conf"
echo "Press enter [sed pikaur.conf noedit]"; read line
sed -i 's/noedit = no/noedit = yes/' "/tmp/pikaur_radni.conf"
echo "Press enter [sed pikaur.conf donteditbydefault]"; read line
sed -i 's/donteditbydefault = no/donteditbydefault = yes/' "/tmp/pikaur_radni.conf"
echo "Press enter [cp pikaur.conf]"; read line
sudo -u "$username" cp "/tmp/pikaur_radni.conf" "/home/$username/.config/pikaur.conf"
echo "Press enter [build ad_progs]"; read line
if [ $MORE_PROGS = 1 ]; then
  ad_progs="texlive-formatsextra texlive-langcyrillic texlive-latexextra texlive-science openssh tmux vlc feh zathura zathura-djvu zathura-pdf-poppler flameshot calc geany geany-plugins pcmanfm-gtk3 simplescreenrecorder"
  aur_progs="lyx"
else
  ad_progs=""
  aur_progs=""
fi
echo "Press enter [pacman ...!!!.....!!!!!!]"; read line
while ! pacman -S --noconfirm --needed nano xorg-server xorg-xinit xorg-xrdb numlockx xbindkeys i3-gaps i3status i3lock rofi nitrogen picom pipewire pipewire-pulse pipewire-jack wireplumber rtkit alacritty xdg-utils ttf-liberation man-db man-pages nnn htop perl-file-mimeinfo zip unzip p7zip ufw $ad_progs; do
  reconnect
done
if [ $BATT = 1 ]; then
  echo "Press enter [pacman acpi]"; read line
  while ! pacman -S --noconfirm --needed acpi; do
    reconnect
  done
fi
echo "Press enter [aur_get ...!!!]"; read line
aur_get xidlehook xkb-switch-i3 xkblayout-state-git $aur_progs
if [ $AMD_GPU = 1 ]; then
  echo "Press enter [pacman vulkan...]"; read line
  if [ $GPU_NEW = 1 ]; then
    while ! pacman -S --noconfirm xf86-video-amdgpu libva-mesa-driver vulkan-tools mesa-utils libva-utils; do
      reconnect
    done
  else
    while ! pacman -S --noconfirm xf86-video-ati libva-mesa-driver vulkan-tools mesa-utils libva-utils; do
      reconnect
    done
  fi
  echo "Press enter [aur_get corectrl]"; read line
  aur_get corectrl
  echo "Press enter [cp corectrl.desktop]"; read line
  sudo -u "$username" cp /usr/share/applications/org.corectrl.corectrl.desktop "/home/$username/.config/autostart/org.corectrl.corectrl.desktop"
  echo "Press enter [printf polkit rule]"; read line
  printf "polkit.addRule(function(action, subject){\n	if ((\n		action.id == \"org.corectrl.helper.init\" ||\n		action.id == \"org.corectrl.helperkiller.init\") &&\n		subject.local == true &&\n		subject.active == true &&\n		subject.isInGroup(\"wheel\")\n	){\n		return polkit.Result.YES;\n	}\n});\n" >> "/etc/polkit-1/rules.d/90-corectrl.rules"
  echo "Press enter [printf corectrl.ini]"; read line
  sudo -u "$username" printf "[General]\nstartOnSysTray=true\n" > "/home/$username/.config/corectrl/corectrl.ini"
fi
if [ $CPU_NEW = 1 ]; then
  echo "Press enter [pacman linux-headers dkms]"; read line
  while ! pacman -S --noconfirm linux-headers dkms; do
    reconnect
  done
  echo "Press enter [aur_get zen3]"; read line
  aur_get zenpower3-dkms zenmonitor3-git
  echo "Press enter [modprobe zenpower]"; read line
  modprobe zenpower
fi

#			konfiguracije

echo "Press enter [rm /root/.bash_profile]"; read line
rm /root/.bash_profile

echo "Press enter [sensors-detect --auto]"; read line
sensors-detect --auto
echo "Press enter [sed nanorc]"; read line
sed -i 's/^# set zap/set zap/' /etc/nanorc
echo "Press enter [printf bash.bashrc (aliases)]"; read line
printf "\nalias ls=\'ls --color=tty\'\nalias q=\'exit\'\nalias cl=\'clear\'\nalias mountu=\'sudo mount -o gid=users,fmask=113,dmask=002\'\nalias stfu=\'shutdown now\'\nalias sus=\'systemctl suspend\'\n" >> /etc/bash.bashrc

echo "Press enter [start pipewire-pulse]"; read line
# sudo -u "$username" systemctl --user start pipewire-pulse
echo "Press enter [cp picom.conf]"; read line
cp /etc/xdg/picom.conf /tmp/picom_radni.conf
echo "Press enter [sed fade-in-step]"; read line
sed -i 's/^fade-in-step/#fade-in-step/' /tmp/picom_radni.conf
echo "Press enter [sed fade-out-step]"; read line
sed -i 's/^fade-out-step/#fade-out-step/' /tmp/picom_radni.conf
echo "Press enter [sed no-fading-openclose]"; read line
sed -i 's/^no-fading-openclose/#no-fading-openclose/' /tmp/picom_radni.conf
echo "Press enter [sed fading = true -> false]"; read line
sed -i 's/^fading = true\;/fading = false\;/' /tmp/picom_radni.conf
echo "Press enter [sed popup_menu opacity]"; read line
sed -i 's/^\(.*popup_menu =.*opacity =\)\( 0\.[0-9]\{1,2\}\)\(.*\)$/\1 0.93\3/' /tmp/picom_radni.conf
echo "Press enter [sed dropdown_menu opacity]"; read line
sed -i 's/^\(.*dropdown_menu =.*opacity =\)\( 0\.[0-9]\{1,2\}\)\(.*\)$/\1 0.93\3/' /tmp/picom_radni.conf
echo "Press enter [cp picom.conf]"; read line
cp /tmp/picom_radni.conf /etc/xdg/picom.conf
echo "Press enter [set volume to 100%]"; read line
# pactl set-sink-volume @DEFAULT_SINK@ 100%
echo "Press enter [cd home]"; read line
cd "/home/$username"
if [ $HIDPI = 1 ]; then
  echo "Press enter [HiDPI .Xresources]"; read line
  sudo -u "$username" printf "Xft.dpi: 192\n" > .Xresources
fi
echo "Press enter [nitrogen setup]"; read line
# nitrogen --set-zoom-fill "/home/$username/Pictures/poz.jpg"
echo "Press enter [printf .xinitrc]"; read line
if [ $AMD_GPU = 1 ]; then
  if [ $HIDPI = 1 ]; then
    sudo -u "$username" printf "[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset 0 180 0\nnumlockx &\nxset r rate 250 30\nxbindkeys &\n/opt/kbswtb &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 \'systemctl suspend -i\' \'\' &\nfi\npicom --experimental-backends &\nexport QT_SCREEN_SCALE_FACTORS=1.5\ncorectrl &\nnitrogen --restore &\nexec i3\n" > .xinitrc
  else
    sudo -u "$username" printf "[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset 0 180 0\nnumlockx &\nxset r rate 250 30\nxbindkeys &\n/opt/kbswtb &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 \'systemctl suspend -i\' \'\' &\nfi\npicom --experimental-backends &\ncorectrl &\nnitrogen --restore &\nexec i3\n" > .xinitrc
  fi
else
  if [ $HIDPI = 1 ]; then
    sudo -u "$username" printf "[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset 0 180 0\nnumlockx &\nxset r rate 250 30\nxbindkeys &\n/opt/kbswtb &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 \'systemctl suspend -i\' \'\' &\nfi\npicom --experimental-backends &\nexport QT_SCREEN_SCALE_FACTORS=1.5\nnitrogen --restore &\nexec i3\n" > .xinitrc
  else
    sudo -u "$username" printf "[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset 0 180 0\nnumlockx &\nxset r rate 250 30\nxbindkeys &\n/opt/kbswtb &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 \'systemctl suspend -i\' \'\' &\nfi\npicom --experimental-backends &\nnitrogen --restore &\nexec i3\n" > .xinitrc
  fi
fi
echo "Press enter [cp .bashrc]"; read line
cp "/home/$username/.bashrc" /tmp/bashrc_radni
echo "Press enter [chmod bashrc_radni]"; read line
chmod 777 /tmp/bashrc_radni
echo "Press enter [sed remove 'alias ls']"; read line
sed -i 's/^alias ls.*$//' /tmp/bashrc_radni
echo "Press enter [printf startx > bashrc_radni]"; read line
printf "if [ -z \"\${DISPLAY}\" ] && [ \"\${XDG_VTNR}\" -eq 1 ]; then\n  startx\nfi\n" >> /tmp/bashrc_radni
echo "Press enter [cp .bashrc]"; read line
sudo -u "$username" cp /tmp/bashrc_radni "/home/$username/.bashrc"
echo "Press enter [printf numlock]"; read line
printf '#!/bin/bash\n\nfor tty in /dev/tty{1..6}\ndo\n  /usr/bin/setleds -D +num < \"$tty\";\ndone\n' > /usr/local/bin/numlock
echo "Press enter [chmod numlock]"; read line
chmod 755 /usr/local/bin/numlock
echo "Press enter [printf numlock.service]"; read line
printf "[Unit]\nDescription=numlock\n\n[Service]\nExecStart=/usr/local/bin/numlock\nStandardInput=tty\nRemainAfterExit=yes\n\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/numlock.service
echo "Press enter [systemctl enable numlock]"; read line
systemctl enable numlock
echo "Press enter [cd icons/default]"; read line
cd /usr/share/icons/default
echo "Press enter [mkdir cursors]"; read line
mkdir cursors
echo "Press enter [cd cursors]"; read line
cd cursors
echo "Press enter [link watch]"; read line
ln -s /usr/share/icons/Adwaita/cursors/left_ptr watch
echo "Press enter [localectl set...]"; read line
localectl --no-convert set-x11-keymap us,ru,rs,rs pc105 ,,latin,yz
echo "Press enter [mkdir /tmp/i3git]"; read line
sudo -u "$username" mkdir /tmp/i3git
echo "Press enter [cd /tmp/i3git]"; read line
cd /tmp/i3git
echo "Press enter [git clone i3-config]"; read line
while ! sudo -u "$username" git clone --depth=1 https://github.com/donaastor/i3-config.git; do
  reconnect
done
echo "Press enter [cd i3-config]"; read line
cd i3-config
echo "Press enter [rm .git]"; read line
rm -rf .git
echo "Press enter [mv .xbindkeysrc]"; read line
sudo -u "$username" mv .xbindkeysrc "/home/$username/.xbindkeysrc"
echo "Press enter [mkdir .config/i3]"; read line
sudo -u "$username" mkdir "/home/$username/.config/i3"
echo "Press enter [mv config, status_script.sh]"; read line
sudo -u "$username" mv config status_script.sh "/home/$username/.config/i3/"
echo "Press enter [mv i3status-?]"; read line
if [ $WIFI = 0 ]; then
  if [ $BATT = 0 ]; then
    sudo -u "$username" mv i3status "/home/$username/.config/i3/i3status"
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
echo "Press enter [g++ kbswtb.cpp]"; read line
g++ kbswtb.cpp -o kbswtb -pipe -fwrapv -fno-plt -fno-semantic-interposition -std=c++20 -mcmodel=large -march=x86-64 -mtune=generic -Wshadow -Wno-unused-result -Wall -L /usr/lib -lm -lz -lcrypt -lutil -ldl -lpthread -lrt -O3 -lX11 -lxkbfile
echo "Press enter [mv kbswtb]"; read line
mv kbswtb /opt/kbswtb
echo "Press enter [cd /home/$username/.config/i3]"; read line
cd "/home/$username/.config/i3"
echo "Press enter [chmod status_script.sh]"; read line
chmod 755 status_script.sh
echo "Press enter [mandb]"; read line
mandb
echo "Press enter [printf /etc/fonts/local.conf]"; read line
printf '<?xml version=\"1.0\"?>\n<!DOCTYPE fontconfig SYSTEM \"urn:fontconfig:fonts.dtd\">\n<fontconfig>\n	<match target=\"pattern\">\n	<test name=\"family\" qual=\"any\">\n		<string>monospace</string>\n	</test>\n	<edit binding=\"strong\" mode=\"prepend\" name=\"family\">\n		<string>LiberationMono</string>\n	</edit>\n	</match>\n</fontconfig>\n' > /etc/fonts/local.conf
echo "Press enter [systemctl start ufw]"; read line
systemctl start ufw
echo "Press enter [systemctl enable ufw]"; read line
systemctl enable ufw
echo "Press enter [ufw default allow outgoing]"; read line
ufw default allow outgoing
echo "Press enter [ufw default deny incoming]"; read line
ufw default deny incoming
echo "Press enter [ufw enable]"; read line
ufw enable
if [ $MORE_PROGS = 1 ]; then
  echo "Press enter [xdg-mime feh]"; read line
  sudo -u "$username" xdg-mime default feh.desktop image/png image/jpeg
  echo "Press enter [xdg-mime zathura]"; read line
  sudo -u "$username" xdg-mime default org.pwmt.zathura.desktop application/pdf image/vnd.djvu
  echo "Press enter [xdg-mime lyx]"; read line
  sudo -u "$username" xdg-mime default lyx.desktop text/x-tex
  echo "Press enter [xdg-mime geany]"; read line
  sudo -u "$username" xdg-mime default geany.desktop text/plain text/html text/x-c text/x-c++ text/x-java-source text/x-script text/x-script.python
  echo "Press enter [xdg-mime pcmanfm]"; read line
  sudo -u "$username" xdg-mime default pcmanfm.desktop inode/mount-point inode/directory
fi

#			ungoogled-chromium

echo "Press enter [add ug-ch to pacman-key]"; read line
while ! curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/x86_64/home_ungoogled_chromium_Arch.key' | pacman-key -a -; do
  reconnect
done
echo "Press enter [add ug-ch to /etc/pacman.conf]"; read line
printf "[home_ungoogled_chromium_Arch]\nSigLevel = Required TrustAll\nServer = https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/\$arch\n" | tee --append /etc/pacman.conf
echo "Press enter [pacman ungoogled-chromium]"; read line
while ! pacman -Sy --noconfirm --needed pipewire-jack profile-sync-daemon ungoogled-chromium; do
  reconnect
done
echo "Press enter [printf /etc/chromium-flags.conf]"; read line
if [ $AMD_GPU = 1 ]; then
  sudo -u "$username" printf -- "--disk-cache-dir=/home/$username/chromium/cache\n--disk-cache-size=1073741824\n--ignore-gpu-blocklist\n--enable-gpu-rasterization\n--enable-zero-copy\n--enable-features=VaapiVideoDecoder\n--use-gl=egl\n" > /etc/chromium-flags.conf
else
  sudo -u "$username" printf -- "--disk-cache-dir=/home/$username/chromium/cache\n--disk-cache-size=1073741824\n" > /etc/chromium-flags.conf
fi
echo "Press enter [sed psd.conf]"; read line
# sudo -u "$username" sed -i 's/^.*\"USE_BACKUPS\"=\"yes\".*$/\"USE_BACKUPS\"=\"no\"/' "/home/$username/.config/psd/psd.conf"
echo "Press enter [enable psd]"; read line
# sudo -u "$username" systemctl --user enable psd
echo "Press enter [start psd]"; read line
# sudo -u "$username" systemctl --user start psd

#			cleaning

echo "Press enter [cleaning rust]"; read line
pacman -Rsn rust
echo "Press enter [cleaning pacman]"; read line
rm -rf /var/cache/pacman/pkg

#			reboot

echo "Press enter [reboot]"; read line
reboot
