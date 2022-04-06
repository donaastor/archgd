#!/bin/bash

psd
cd /home/username/.config/psd
xcn=0
while :; do
  if [ -f psd.conf ]; then
    sed -i 's/^.*USE_BACKUPS=\"yes\".*$/USE_BACKUPS=\"no\"/' psd.conf
    break
  else
    xcn=$(( $xcn + 1 ))
    if [ $xcn = 400 ]; then break; fi
    sleep 0.3
  fi
done
systemctl --user enable psd
systemctl --user start psd
rm -rf /tmp/psdconf.sh
