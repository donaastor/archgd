#!/bin/bash

mkdir $HOME/sharing
mkdir $HOME/sharing/write
mkdir $HOME/sharing/read
n_HOME=$HOME
sudo chown root:root $n_HOME/sharing/read
sudo printf "tmpfs $n_HOME/sharing/write tmpfs defaults,size=2048M 0 0" >> /etc/fstab
sudo mount -t tmpfs tmpfs $n_HOME/sharing/write -o defaults,size=2048M
sudo pacman -S samba
n_USER=$USER
sudo printf "[global]\nworkgroup = WORKGROUP\nserver string = Samba Server\nserver role = standalone server\nlog file = /usr/local/samba/var/log.%m\nmax log size = 50\ndns proxy = no\nserver smb encrypt = desired\nmin protocol = SMB2\nprotocol = SMB3\n\n[arch]\npath = $n_HOME/sharing/write\navailable = yes\nbrowsable = yes\nread only = yes\nvalid users = $n_USER\n" > /etc/samba/smb.conf
echo "Password for connecting to share:"
sudo smbpasswd -a $n_USER
sudo ufw allow CIFS
sudo mkdir /usr/local/samba
sudo mkdir /usr/local/samba/var
printf "Remote IP: "
read win_ip
printf "Remote port: "
read win_port
printf "Username: "
read win_user
printf "Password for $win_user: "
read win_pass
sed "s/^\(PS1='\[\\\\u@\\\\h \\\\W\]\\\\. '\)$/alias shares='sudo systemctl restart smb nmb; sudo mount -t cifs \/\/$win_ip\/win $n_HOME\/sharing\/read -o port=$win_port,workgroup=WORKGROUP,iocharset=utf8,username=$win_user,password=$win_pass,cache=none'\nalias shoff='sudo systemctl stop smb nmb; sudo umount $n_HOME\/sharing\/read'\n\n\1/" -i $HOME/.bashrc
