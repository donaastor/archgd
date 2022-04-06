#!/bin/sh

printf '#!'"/bin/bash\n\ngotov() {\n  exec bash --norc -c \"rm /tmp/to100.sh; exit \$1\"\n}\n\nvrti() {\n  xcn=0\n  ycn=0\n  while :; do\n    if pactl set-sink-volume @DEFAULT_SINK@ 100%%; then gotov 0; fi\n    xcn=\$(( \$xcn + 1 ))\n    if [ \$xcn = \$1 ]; then\n      xcn=0\n      ycn=\$(( \$ycn + 1 ))\n      if [ \$ycn = \$2 ]; then break; fi\n      sleep 1\n    fi\n  done\n}\n\nsystemctl --user start pipewire-pulse\nvrti 3 4\nvrti 2 5\nvrti 1 8\n\ngotov 1\n" > /tmp/to100.sh
bash /tmp/to100.sh &
printf '#!'"/bin/bash\n\npsd\ncd /home/username/.config/psd\nxcn=0\nwhile :; do\n  if [ -f psd.conf ]; then\n    sed -i 's/^.*USE_BACKUPS=\\\\\"yes\\\\\".*\$/USE_BACKUPS=\\\\\"no\\\\\"/' psd.conf\n    break\n  else\n    xcn=\$(( \$xcn + 1 ))\n    if [ \$xcn = 400 ]; then break; fi\n    sleep 0.3\n  fi\ndone\nsystemctl --user enable psd\nsystemctl --user start psd\nxcn=0\nwhile :; do\n  if [ -L /home/username/.config/chromium ]; then\n    break\n  else\n    xcn=\$(( \$xcn + 1 ))\n    if [ \$xcn = 200 ]; then break; fi\n    sleep 0.5\n  fi\ndone\ncrxversion=\"\$(pacman -Qi ungoogled-chromium | sed -n '/^Version/p' | awk '{print \$3}' | sed 's/^\\\\(.*\\\\)-.*\$/\\\\1/')\"\ncurl -L 'https://clients2.google.com/service/update2/crx?response=redirect&os=linux&arch=x86-64&os_arch=x86_64&nacl_arch=x86_64&prod=chromiumcrx&prodchannel=unknown&prodversion='\"\$crxversion\"'&acceptformat=crx2,crx3&x=id%%3Dcjpalhdlnbpafiamejdnhcphjbkeiagm%%26uc' > /tmp/uBlock.crx\nubld=\"/home/username/chromium/extensions/uBlock\"\nmkdir \$ubld\nunzip /tmp/uBlock.crx -d \$ubld\ncd \$ubld\nrm -rf \"_metadata\"\nrm -rf /tmp/psdconf.sh\n" > /tmp/psdconf.sh
bash /tmp/psdconf.sh &
exec bash -c "cd /home/username; mv .xinitrc-tobe .xinitrc && source .xinitrc"
