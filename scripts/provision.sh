#!/usr/bin/env bash

## Standard boostrap

apt-get update

# Hide Ubuntu splash screen during OS Boot, so you can see if the boot hangs
apt-get remove -y plymouth-theme-ubuntu-text
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT=""/' /etc/default/grub
update-grub

# Add no-password sudo config for vagrant user
echo "%vagrant ALL=NOPASSWD:ALL" > /etc/sudoers.d/vagrant
chmod 0440 /etc/sudoers.d/vagrant

# Add vagrant to sudo group
usermod -a -G sudo vagrant

# Install vagrant key
mkdir /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
wget --no-check-certificate 'https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub' -O /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh

# Install NFS for Vagrant
apt-get install -y nfs-common
# Without libdbus virtualbox would not start automatically after compile
apt-get -y install --no-install-recommends libdbus-1-3

# Install Linux headers and compiler toolchain
apt-get -y install build-essential linux-headers-$(uname -r)


# The netboot installs the VirtualBox support (old) so we have to remove it
service virtualbox-ose-guest-utils stop
rmmod vboxguest
apt-get purge -y virtualbox-ose-guest-x11 virtualbox-ose-guest-dkms virtualbox-ose-guest-utils
apt-get install -y dkms

# Install the VirtualBox guest additions
VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
VBOX_ISO=/home/vagrant/VBoxGuestAdditions_$VBOX_VERSION.iso
mount -o loop $VBOX_ISO /mnt
yes|sh /mnt/VBoxLinuxAdditions.run
umount /mnt

#Cleanup VirtualBox
rm $VBOX_ISO

# unattended apt-get upgrade
DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade

## Box specific provision
# Install python3 flask and dummy website
apt-get -y install python3-pip policykit-1
python3 -m pip install --user --upgrade pip==9.0.3
pip3 install virtualenv flask jinja2 Flask-And-Redis
echo 'export LC_ALL="en_US.UTF-8"' >> /etc/bash.bashrc
echo 'export LC_CTYPE="en_US.UTF-8"' >> /etc/bash.bashrc
mkdir -p /home/vagrant/flask-website
cat <<EOF > /etc/systemd/system/flask-website.service
[Unit]
Description=Microwebsite application
After=network.target

[Service]
User=vagrant
WorkingDirectory=/home/vagrant/flask-website
Environment=FLASK_ENV=development
Environment=FLASK_APP=project.py
Environment=FLASK_RUN_PORT=8080
Environment=REDIS_HOST=127.0.0.1
ExecStart=/usr/local/bin/flask run
Restart=always

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF > /home/vagrant/flask-website/project.py
#!/usr/bin/python
from flask import Flask, escape, request

app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello World!'
EOF
systemctl enable flask-website

# Install some tools
apt-get -y install jq curl unzip vim tmux

# Install reverse proxy rerouting to high ports >1024
apt-get -y install nginx
cat <<EOF > /etc/nginx/sites-available/flask-website
server {
    listen 80;
    location / {
        proxy_pass http://127.0.0.1:8080/;
    }
}
EOF
rm -rf /etc/nginx/sites-enabled/*
ln -s /etc/nginx/sites-available/flask-website /etc/nginx/sites-enabled/
systemctl enable nginx

apt-get autoremove -y
apt-get clean

# Removing leftover leases and persistent rules
echo "cleaning up dhcp leases"
rm /var/lib/dhcp/*

# Zero out the free space to save space in the final image:
echo "Zeroing device to make space..."
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
