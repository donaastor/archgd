#!/bin/bash

sudo pacman -S cups hplip
pikaur -S hplip-plugin
sudo sed 's/^#\(net.ipv4.ip_forward\).*$/\1=1/' -i /etc/ufw/sysctl.conf
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
sudo systemctl start cups
hp-setup -i -a -x $fake_ip
p_name=$( lpstat -d )
lpoptions -p "$p_name" -o PageSize=A4
