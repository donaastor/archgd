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
xcn=0
while :; do
  if [ -L /home/username/.config/chromium ]; then
    break
  else
    xcn=$(( $xcn + 1 ))
    if [ $xcn = 200 ]; then break; fi
    sleep 0.5
  fi
done
crxversion="$(pacman -Qi ungoogled-chromium | sed -n '/^Version/p' | awk '{print $3}' | sed 's/^\(.*\)-.*$/\1/')"
curl -L 'https://clients2.google.com/service/update2/crx?response=redirect&os=linux&arch=x86-64&os_arch=x86_64&nacl_arch=x86_64&prod=chromiumcrx&prodchannel=unknown&prodversion='"$crxversion"'&acceptformat=crx2,crx3&x=id%3Dcjpalhdlnbpafiamejdnhcphjbkeiagm%26uc' > /tmp/uBlock.crx
ubld="/home/username/chromium/extensions/uBlock"
mkdir $ubld
unzip /tmp/uBlock.crx -d $ubld
cd $ubld
rm -rf "_metadata"
rm -rf /tmp/psdconf.sh
