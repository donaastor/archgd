if [ $AMD_GPU = 1 ]; then
  if [ $HIDPI = 1 ]; then
    sudo -u "$username" printf "[[ -f ~/.Xresources ]] && xrdb -merge -I\$HOME ~/.Xresources\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset 0 180 0\nnumlockx &\nxset r rate 250 30\nxbindkeys &\n/opt/kbswtb &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 \'systemctl suspend -i\' \'\' &\nfi\npicom --experimental-backends &\nexport QT_SCREEN_SCALE_FACTORS=1.5\ncorectrl &\nnitrogen --restore &\nexec i3\n" > .xinitrc-tobe
  else
    sudo -u "$username" printf "[[ -f ~/.Xresources ]] && xrdb -merge -I\$HOME ~/.Xresources\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset 0 180 0\nnumlockx &\nxset r rate 250 30\nxbindkeys &\n/opt/kbswtb &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 \'systemctl suspend -i\' \'\' &\nfi\npicom --experimental-backends &\ncorectrl &\nnitrogen --restore &\nexec i3\n" > .xinitrc-tobe
  fi
else
  if [ $HIDPI = 1 ]; then
    sudo -u "$username" printf "[[ -f ~/.Xresources ]] && xrdb -merge -I\$HOME ~/.Xresources\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset 0 180 0\nnumlockx &\nxset r rate 250 30\nxbindkeys &\n/opt/kbswtb &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 \'systemctl suspend -i\' \'\' &\nfi\npicom --experimental-backends &\nexport QT_SCREEN_SCALE_FACTORS=1.5\nnitrogen --restore &\nexec i3\n" > .xinitrc-tobe
  else
    sudo -u "$username" printf "[[ -f ~/.Xresources ]] && xrdb -merge -I\$HOME ~/.Xresources\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset 0 180 0\nnumlockx &\nxset r rate 250 30\nxbindkeys &\n/opt/kbswtb &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 \'systemctl suspend -i\' \'\' &\nfi\npicom --experimental-backends &\nnitrogen --restore &\nexec i3\n" > .xinitrc-tobe
  fi
fi








          ~/.xinitrc

#!/bin/sh

# samo zato sto ne znam da li sh moze sve sto mi treba iz basha
exec /bin/bash /home/korsic/xin-scp.sh


          /home/korsic/xin-scp.sh

#!/bin/bash

cd /home/korsic

# tweaks

systemctl --user start pipewire-pulse
pactl set-sink-volume @DEFAULT_SINK@ 100%
nitrogen --set-zoom-fill Pictures/poz.jpg
psd
sed -i 's/^.*\"USE_BACKUPS\"=\"yes\".*$/\"USE_BACKUPS\"=\"no\"/' .config/psd/psd.conf
systemctl --user enable psd
systemctl --user start psd

# reshape

mv .xinitrc-todo .xinitrc
printf '#!/bin/bash\n\nrm /home/korsic/xin-scp.sh\nexec /bin/sh /home/korsic/.xintrc\n' > /tmp/xin-scp-0.sh
exec /bin/bash /tmp/xin-scp-0.sh


# koristi: exec bash -norc -c "rm THIS_SCRIPT"









