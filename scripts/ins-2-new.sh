if [ $AMD_GPU = 1 ]; then
  if [ $HIDPI = 1 ]; then
    sudo -u "$username" printf '#!'"/bin/sh\n\n[[ -f ~/.Xresources ]] && xrdb -merge -I\$HOME ~/.Xresources\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset dpms 0 180 0\nnumlockx &\nxset r rate 250 30\nxbindkeys &\n/opt/kbswtb &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 \'systemctl suspend -i\' \'\' &\nfi\npicom --experimental-backends &\nexport QT_SCREEN_SCALE_FACTORS=1.5\ncorectrl &\nnitrogen --restore &\nexec i3\n" > .xinitrc-tobe
  else
    sudo -u "$username" printf '#!'"/bin/sh\n\n[[ -f ~/.Xresources ]] && xrdb -merge -I\$HOME ~/.Xresources\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset dpms 0 180 0\nnumlockx &\nxset r rate 250 30\nxbindkeys &\n/opt/kbswtb &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 \'systemctl suspend -i\' \'\' &\nfi\npicom --experimental-backends &\ncorectrl &\nnitrogen --restore &\nexec i3\n" > .xinitrc-tobe
  fi
else
  if [ $HIDPI = 1 ]; then
    sudo -u "$username" printf '#!'"/bin/sh\n\n[[ -f ~/.Xresources ]] && xrdb -merge -I\$HOME ~/.Xresources\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset dpms 0 180 0\nnumlockx &\nxset r rate 250 30\nxbindkeys &\n/opt/kbswtb &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 \'systemctl suspend -i\' \'\' &\nfi\npicom --experimental-backends &\nexport QT_SCREEN_SCALE_FACTORS=1.5\nnitrogen --restore &\nexec i3\n" > .xinitrc-tobe
  else
    sudo -u "$username" printf '#!'"/bin/sh\n\n[[ -f ~/.Xresources ]] && xrdb -merge -I\$HOME ~/.Xresources\nxset s noblank\nxset s noexpose\nxset s 0 0\nxset +dpms\nxset dpms 0 180 0\nnumlockx &\nxset r rate 250 30\nxbindkeys &\n/opt/kbswtb &\nif ! pgrep -f xidlehook; then\n  xidlehook --timer 600 \'systemctl suspend -i\' \'\' &\nfi\npicom --experimental-backends &\nnitrogen --restore &\nexec i3\n" > .xinitrc-tobe
  fi
fi
if [ $MORE_PROGS = 1 ]; then
  printf '#!'"/bin/sh\n\ncd /home/$username\nsystemctl --user start pipewire-pulse\npactl set-sink-volume @DEFAULT_SINK@ 100%%\nnitrogen --set-zoom-fill Pictures/poz.jpg\npsd\nsed -i \'s/^.*\\\\\"USE_BACKUPS\\\\\"=\\\\\"yes\\\\\".*\$/\\\\\"USE_BACKUPS\\\\\"=\\\\\"no\\\\\"/\' .config/psd/psd.conf\nsystemctl --user enable psd\nsystemctl --user start psd\nexec bash --norc -c \"cd /home/$username; mv .xinitrc-tobe .xinitrc && source .xinitrc\"\n" > .xinitrc
else
  printf '#!'"/bin/sh\n\ncd /home/$username\nsystemctl --user start pipewire-pulse\npactl set-sink-volume @DEFAULT_SINK@ 100%%\nnitrogen --set-zoom-fill Pictures/poz.jpg\nexec bash --norc -c \"cd /home/$username; mv .xinitrc-tobe .xinitrc && source .xinitrc\"\n" > .xinitrc
fi
