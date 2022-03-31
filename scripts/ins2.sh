#!/bin/bash

username="$1"
params="$2"

if [ "${params:0:1}" = "0" ]; then
  AMD_GPU=0
else
  AMD_GPU=1
  if [ "${params:0:1}" = "2" ]; then
    GPU_NEW=1
  else
    AMD_NEW=0
  fi
fi
if [ "${params:1:1}" = "1" ]; then
  AMD_CPU=1
else
  AMD_CPU=0
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





#			internet

sleep 2
reconnect

#			getty

cd "/etc/systemd/system/getty@tty1.sevice.d"
printf "[Service]\nExecStart=\nExecStart=-/sbin/agetty -o \'-p -f -- \\u\' --noclear --autologin $username - $TERM\nType=simple\nEnvironment=XDG_SESSION_TYPE=x11\n" > autologin.conf

#			programi

mkdir /tmp/pikaur_git
cd /tmp/pikaur_git
while ! git clone https://aur.archlinux.org/pikaur.git; do
  reconnect
done
cd pikaur
makepkg -si
sudo -u "$username" pikaur -Sy
sudo -u "$username" cp "/home/$username/.config/pikaur.conf" "/tmp/pikaur_radni.conf"
sed -i 's/keepbuilddeps = no/keepbuilddeps = yes/' "/tmp/pikaur_radni.conf"
sed -i 's/noedit = no/noedit = yes/' "/tmp/pikaur_radni.conf"
sed -i 's/donteditbydefault = no/donteditbydefault = yes/' "/tmp/pikaur_radni.conf"
sudo -u "$username" cp "/tmp/pikaur_radni.conf" "/home/$username/.config/pikaur.conf"
if [ $MORE_PROGS = 1 ]; then
  ad_progs="lyx texlive-formatsextra texlive-langcyrillic texlive-latexextra texlive-science openssh tmux vlc feh zathura zathura-djvu zathura-pdf-poppler flameshot calc geany geany-plugins pcmanfm-gtk3"
else
  ad_progs=""
fi
while ! pacman -S --noconfirm --needed nano xorg-server xorg-xinit xorg-xrdb numlockx xbindkeys i3 rofi nitrogen picom pipewire pipewire-pulse pipewire-jack wireplumber rtkit alacritty xdg-utils ttf-liberation man-db man-pages nnn htop perl-file-mimeinfo zip unzip p7zip ufw $ad_progs; do
  reconnect
done
if [ $BATT = 1 ]; then
  while ! pacman -S --noconfirm --needed acpi; do
    reconnect
  done
fi
while ! pikaur -S --noconfirm xidlehook xkb-switch-i3 xkblayout-state-git; do
  reconnect
done
if [ $AMD_GPU = 1 ]; then
  if [ $GPU_NEW = 1 ]; then
    while ! pacman -S --noconfirm xf86-video-amdgpu libva-mesa-driver vulkan-tools mesa-utils libva-utils; do
      reconnect
    done
  else
    while ! pacman -S --noconfirm xf86-video-ati libva-mesa-driver vulkan-tools mesa-utils libva-utils; do
      reconnect
    done
  fi
  while ! pikaur -S --noconfirm corectrl; do
    reconnect
  done
  sudo -u "$username" cp /usr/share/applications/org.corectrl.corectrl.desktop "/home/$username/.config/autostart/org.corectrl.corectrl.desktop"
  printf "polkit.addRule(function(action, subject){\n	if ((\n		action.id == \"org.corectrl.helper.init\" ||\n		action.id == \"org.corectrl.helperkiller.init\") &&\n		subject.local == true &&\n		subject.active == true &&\n		subject.isInGroup(\"wheel\")\n	){\n		return polkit.Result.YES;\n	}\n});" >> "/etc/polkit-1/rules.d/90-corectrl.rules"
  sudo -u "$username" printf "[General]\nstartOnSysTray=true\n" > "/home/$username/.config/corectrl/corectrl.ini"
fi
if [ $AMD_CPU = 1 ]; then
  while ! pacman -S --noconfirm linux-headers dkms; do
    reconnect
  done
  while ! pikaur -S --noconfirm zenpower3-dkms zenmonitor3-git; do
    reconnect
  done
  modprobe zenpower
fi

#			konfiguracije

sensors-detect --auto
sed -i 's/^# set zap/set zap/' /etc/nanorc
printf "\nalias ls=\'ls --color=tty\'\nalias q=\'exit\'\nalias cl=\'clear\'\nalias mountu=\'sudo mount -o gid=users,fmask=113,dmask=002\'\nalias stfu=\'shutdown now\'\nslias sus=\'systemctl suspend\'\n" >> /etc/bash.bashrc
sudo -u "$username" systemctl --user start pipewire-pulse
sudo -u "$username" cp /etc/xdg/picom.conf /tmp/picom_radni.conf
sed -i 's/^fade-in-step/#fade-in-step/' /tmp/picom_radni.conf
sed -i 's/^fade-out-step/#fade-out-step/' /tmp/picom_radni.conf
sed -i 's/^no-fading-openclose/#no-fading-openclose/' /tmp/picom_radni.conf
sed -i 's/^fading = true\;/fading = false\;/' /tmp/picom_radni.conf
sed -i 's/^\(.*popup_menu =.*opacity =\)\( 0\.[0-9]\{1,2\}\)\(.*\)$/\1 0.93\3/' /tmp/picom_radni.conf
sed -i 's/^\(.*dropdown_menu =.*opacity =\)\( 0\.[0-9]\{1,2\}\)\(.*\)$/\1 0.93\3/' /tmp/picom_radni.conf
sudo -u "$username" cp /tmp/picom_radni.conf /etc/xdg/picom.conf
pactl set-sink-volume @DEFAULT_SINK@ 100%
cd "/home/$username"
if [ $HIDPI = 1 ]; then
  sudo -u "$username" printf "Xft.dpi: 192\n" > .Xresources
fi
nitrogen --set-zoom-fill "/home/$username/Pictures/poz.jpg"
if [ $AMD_GPU = 1 ]; then
  if [ $HIDPI = 1 ]; then
    sudo -u "$username" printf "[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset 0 180 0\nnumlockx &\nxset r rate 250 30\nxbindkeys &\n/opt/kbswtb &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 \'systemctl suspend -i\' \'\' &\nfi\npicom --experimental-backends &\nexport QT_SCREEN_SCALE_FACTORS=1.5\ncorectrl &\nnitrogen --restore &\nexec i3" > .xinitrc
  else
    sudo -u "$username" printf "[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset 0 180 0\nnumlockx &\nxset r rate 250 30\nxbindkeys &\n/opt/kbswtb &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 \'systemctl suspend -i\' \'\' &\nfi\npicom --experimental-backends &\ncorectrl &\nnitrogen --restore &\nexec i3" > .xinitrc
  fi
else
  if [ $HIDPI = 1 ]; then
    sudo -u "$username" printf "[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset 0 180 0\nnumlockx &\nxset r rate 250 30\nxbindkeys &\n/opt/kbswtb &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 \'systemctl suspend -i\' \'\' &\nfi\npicom --experimental-backends &\nexport QT_SCREEN_SCALE_FACTORS=1.5\nnitrogen --restore &\nexec i3" > .xinitrc
  else
    sudo -u "$username" printf "[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset 0 180 0\nnumlockx &\nxset r rate 250 30\nxbindkeys &\n/opt/kbswtb &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 \'systemctl suspend -i\' \'\' &\nfi\npicom --experimental-backends &\nnitrogen --restore &\nexec i3" > .xinitrc
  fi
fi
sudo -u "$username" cp "/home/$username/.bashrc" /tmp/bashrc_radni
sed -i 's/^alias ls.*$//' /tmp/bashrc_radni
printf "if [ -z \"\${DISPLAY}\" ] && [ \"\${XDG_VTNR}\" -eq 1 ]; then\n  startx\nfi\n" >> /tmp/bashrc_radni
sudo -u "$username" cp /tmp/bashrc_radni "/home/$username/.bashrc"
printf "#!/bin/bash\n\nfor tty in /dev/tty\{1..6\}\ndo\n  /usr/bin/setleds -D +num < \"\$tty\";\ndone\n" > /usr/local/bin/numlock
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
while ! sudo -u "$username" git clone --depth=1 https://github.com/donaastor/i3-config.git; do
  reconnect
done
cd i3-config
rm -rf .git
sudo -u "$username" mv .xbindkeysrc "/home/$username/.xbindkeysrc"
sudo -u "$username" mkdir "/home/$username/.config/i3"
sudo -u "$username" mv config status_script.sh "/home/$username/.config/i3/"
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
g++ kbswtb.cpp -o kbswtb -pipe -fwrapv -fno-plt -fno-semantic-interposition -std=c++20 -mcmodel=large -march=x86-64 -mtune=generic -Wshadow -Wno-unused-result -Wall -L /usr/lib -lm -lz -lcrypt -lutil -ldl -lpthread -lrt -O3 -lX11 -lxkbfile
mv kbswtb /opt/kbswtb
cd "/home/$username/.config/i3"
chmod 755 status_script.sh
mandb
printf "<?xml version=\"1.0\"?>\n<!DOCTYPE fontconfig SYSTEM \"urn:fontconfig:fonts.dtd\">\n<fontconfig>\n	<match target=\"pattern\">\n	<test name=\"family\" qual=\"any\">\n		<string>monospace</string>\n	</test>\n	<edit binding=\"strong\" mode=\"prepend\" name=\"family\">\n		<string>LiberationMono</string>\n	</edit>\n	</match>\n</fontconfig>" > /etc/fonts/local.conf
systemctl start ufw
systemctl enable ufw
ufw default allow outgoing
ufw default deny incoming
ufw enable
if [ $MORE_PROGS = 1 ]; then
  sudo -u "$username" xdg-mime default feh.desktop image/png image/jpeg
  sudo -u "$username" xdg-mime default org.pwmt.zathura.desktop application/pdf image/vnd.djvu
  sudo -u "$username" xdg-mime default lyx.desktop text/x-tex
  sudo -u "$username" xdg-mime default geany.desktop text/plain text/html text/x-c text/x-c++ text/x-java-source text/x-script text/x-script.python
fi

#			ungoogled-chromium

while ! curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/x86_64/home_ungoogled_chromium_Arch.key' | pacman-key -a -; do
  reconnect
done
printf "[home_ungoogled_chromium_Arch]\nSigLevel = Required TrustAll\nServer = https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/\$arch\n" | tee --append /etc/pacman.conf
while ! pacman -Sy --noconfirm pipewire-jack profile-sync-daemon ungoogled-chromium; do
  reconnect
done
if [ $AMD_GPU = 1 ]; then
  sudo -u "$username" printf "--disk-cache-dir=/home/$username/chromium/cache\n--disk-cache-size=1073741824\n--ignore-gpu-blocklist\n--enable-gpu-rasterization\n--enable-zero-copy\n--enable-features=VaapiVideoDecoder\n--use-gl=egl\n" > /etc/chromium-flags.conf
else
  sudo -u "$username" printf "--disk-cache-dir=/home/$username/chromium/cache\n--disk-cache-size=1073741824\n" > /etc/chromium-flags.conf
fi
sudo -u "$username" sed -i 's/^.*\"USE_BACKUPS\"=\"yes\".*$/\"USE_BACKUPS\"=\"no\"/' "/home/$username/.config/psd/psd.conf"
sudo -u "$username" systemctl --user enable psd
sudo -u "$username" systemctl --user start psd

#			cleaning

rm -rf /var/cache/pacman/pkg

#			reboot

reboot
