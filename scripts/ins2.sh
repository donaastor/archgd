#!/bin/bash

local username="$1"
local params="$2"

if [ "${params:0:1}" = "0" ]; then
  local AMD_GPU=0
else
  local AMD_GPU=1
  if [ "${params:0:1}" = "2" ]; then
    local GPU_NEW=1
  else
    local AMD_NEW=0
  fi
fi
if [ "${params:1:1}" = "1" ]; then
  local AMD_CPU=1
else
  local AMD_CPU=0
fi
if [ "${params:2:1}" = "1" ]; then
  local WIFI=1
  local ssid_dft="$3"
else
  local WIFI=0
fi
if [ "${params:3:1}" = "1" ]; then
  local HIDPI=1
else
  local HIDPI=0
fi








# za svaku komandu stavi:
#
# if ! command; then
#   echo "\nError, exiting...\n"
#   exit 2
# fi








#			internet

iwctl station wlan0 connect "$ssid_dft"

#			getty

cd "/etc/systemd/system/getty@tty1.sevice.d"
printf "[Service]\nExecStart=\nExecStart=-/sbin/agetty -o \'-p -f -- \\u\' --noclear --autologin $username - $TERM\nType=simple\nEnvironment=XDG_SESSION_TYPE=x11\n" > autologin.conf

#			programi

mkdir /tmp/pikaur_git
cd /tmp/pikaur_git
git clone https://aur.archlinux.org/pikaur.git
cd pikaur
makepkg -si
sudo -u "$username" pikaur -Sy
sudo -u "$username" cp "/home/$username/.config/pikaur.conf" "/tmp/pikaur_radni.conf"
sed -i 's/keepbuilddeps = no/keepbuilddeps = yes/' "/tmp/pikaur_radni.conf"
sed -i 's/noedit = no/noedit = yes/' "/tmp/pikaur_radni.conf"
sed -i 's/donteditbydefault = no/donteditbydefault = yes/' "/tmp/pikaur_radni.conf"
sudo -u "$username" cp "/tmp/pikaur_radni.conf" "/home/$username/.config/pikaur.conf"
pacman -S --noconfirm nano xorg-server xorg-xinit xorg-xrdb numlockx xbindkeys i3 rofi nitrogen picom pipewire pipewire-pulse pipewire-jack wireplumber rtkit alacritty pcmanfm-gtk3 feh zathura zathura-djvu zathura-pdf-poppler xdg-utils ttf-liberation man-db man-pages nnn htop calc
pikaur -S --noconfirm xidlehook xkb-switch xkblayout-state-git
if [ AMD_GPU = 1 ]; then
  if [ GPU_NEW = 1 ]; then
    pacman -S --noconfirm xf86-video-amdgpu libva-mesa-driver vulkan-tools mesa-utils libva-utils
  else
    pacman -S --noconfirm xf86-video-ati libva-mesa-driver vulkan-tools mesa-utils libva-utils
  fi
  pikaur -S --noconfirm corectrl
  sudo -u "$username" cp /usr/share/applications/org.corectrl.corectrl.desktop "/home/$username/.config/autostart/org.corectrl.corectrl.desktop"
  printf "polkit.addRule(function(action, subject){\n	if ((\n		action.id == \"org.corectrl.helper.init\" ||\n		action.id == \"org.corectrl.helperkiller.init\") &&\n		subject.local == true &&\n		subject.active == true &&\n		subject.isInGroup(\"wheel\")\n	){\n		return polkit.Result.YES;\n	}\n});" >> "/etc/polkit-1/rules.d/90-corectrl.rules"
  sudo -u "$username" printf "[General]\nstartOnSysTray=true\n" > "/home/$username/.config/corectrl/corectrl.ini"
fi
if [ AMD_CPU = 1 ]; then
  pacman -S --noconfirm linux-headers dkms
  pikaur -S --noconfirm zenpower3-dkms zenmonitor3-git
  modprobe zenpower
fi

#			konfiguracije

sensors-detect --auto
sed -i 's/^# set zap/set zap/' /etc/nanorc
printf "\nalias ls=\'ls --color=tty\'\nalias q=\'exit\'\nalias cl=\'clear\'\nalias stfu=\'shutdown now\'\nslias sus=\'systemctl suspend\'\n" >> /etc/bash.bashrc
sudo -u "$username" systemctl --user start pipewire-pulse
sudo -u "$username" cp /etc/xdg/picom.conf /tmp/picom_radni.conf
sed -i 's/^fade-in-step/#fade-in-step/' /tmp/picom_radni.conf
sed -i 's/^fade-out-step/#fade-out-step/' /tmp/picom_radni.conf
sed -i 's/^no-fading-openclose/#no-fading-openclose/' /tmp/picom_radni.conf
sed -i 's/^fading = true\;/fading = false\;/' /tmp/picom_radni.conf
sudo -u "$username" cp /tmp/picom_radni.conf /etc/xdg/picom.conf
pactl set-sink-volume @DEFAULT_SINK@ 100%
cd "/home/$username"
sudo -u "$username" printf "Xft.dpi: 192\n" > .Xresources
nitrogen --set-zoom-fill "/home/$username/Pictures/poz_r.jpg"
if [ AMD_GPU = 1 ]; then
  sudo -u "$username" printf "[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset 0 180 0\nnumlockx &\nxset r rate 250 30\nxbindkeys &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 \'systemctl suspend -i\' \'\' &\nfi\npicom --experimental-backends &\ncorectrl &\nnitrogen --restore &\nexec i3" > .xinitrc
else
  sudo -u "$username" printf "[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset 0 180 0\nnumlockx &\nxset r rate 250 30\nxbindkeys &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 \'systemctl suspend -i\' \'\' &\nfi\npicom --experimental-backends &\nnitrogen --restore &\nexec i3" > .xinitrc
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
sudo -u "$username" git clone --depth=1 https://github.com/donaastor/i3-config.git
cd i3-config
rm -r .git
sudo -u "$username" mv .xbindkeysrc "/home/$username/.xbindkeysrc"
cd ..
sudo -u "$username" mv i3-config "/home/$username/.config/i3"
cd "/home/$username/.config/i3"
chmod 755 status_script.sh
mandb
printf "<?xml version=\"1.0\"?>\n<!DOCTYPE fontconfig SYSTEM \"urn:fontconfig:fonts.dtd\">\n<fontconfig>\n	<match target=\"pattern\">\n	<test name=\"family\" qual=\"any\">\n		<string>monospace</string>\n	</test>\n	<edit binding=\"strong\" mode=\"prepend\" name=\"family\">\n		<string>LiberationMono</string>\n	</edit>\n	</match>\n</fontconfig>" > /etc/fonts/local.conf
xdg-mime default feh.desktop image/png image/jpeg
xdg-mime default org.pwmt.zathura.desktop application/pdf application/djvu

#			reboot

reboot