#!/bin/bash
# Downsize and prep from standard Raspbian Image

sudo rpi-update && sudo apt -y update && sudo apt -y upgrade

sudo apt-get purge --auto-remove scratch debian-reference-en dillo idle3 python3-tk idle python-pygame python-tk lightdm gnome-themes-standard gnome-icon-theme raspberrypi-artwork gvfs-backends gvfs-fuse desktop-base lxpolkit netsurf-gtk zenity xdg-utils mupdf gtk2-engines alsa-utils  lxde lxtask menu-xdg gksu midori xserver-xorg xinit xserver-xorg-video-fbdev libraspberrypi-dev libraspberrypi-doc dbus-x11 libx11-6 libx11-data libx11-xcb1 x11-common x11-utils lxde-icon-theme gconf-service gconf2-common xserver* ^x11 ^libx ^lx samba* -y

sudo apt -y install vim raspi-config dnsutils sshuttle

sudo apt-get clean -y && sudo apt-get autoremove -y

#### change the boot to non-gui and console only, expand the filesystem and properly update the hostname
##  See https://raspberrypi.stackexchange.com/a/66939/8375 for a list of all the raspi-config magic you may want to automate.
sudo raspi-config nonint do_boot_behaviour B1
sudo raspi-config nonint do_expand_rootfs
sudo raspi-config nonint do_hostname "hostnamehere"

sudo rm /etc/ssh/ssh_host_* && sudo dpkg-reconfigure openssh-server
HOSTNAME=`hostname` ssh-keygen -t rsa -C "$HOSTNAME" -f "$HOME/.ssh/id_rsa" -P ""

#### Get SSH keys for authentication
github_user=mmccollum2
echo -e "GET http://github.com HTTP/1.0\n\n" | nc github.com 80 > /dev/null 2>&1
if [ $? -eq 0 ]; then
   (umask 077; mkdir -p /home/pi/.ssh; touch /home/pi/.ssh/authorized_keys)
   chown -R $(id -u pi):$(id -g pi) /home/pi/.ssh
   curl -sSL https://github.com/${github_user}.keys >> /home/pi/.ssh/authorized_keys
   echo "Keys installed from gitub.com"
 else
   echo "Won't install ssh keys, github.com couldn't be reached."
 fi

#Run this later when you're sure your ssh key access works and you disable password auth
#sed -i 's|[#]*PasswordAuthentication yes|PasswordAuthentication no|g' /etc/ssh/sshd_config

#One liner for static ip config
#sudo sed -i '$ a\interface eth0\nstatic ip_address=0.0.0.0/24\nstatic routers=0.0.0.1\nstatic domain_name_servers=208.67.222.222 1.1.1.1\n' /etc/dhcpcd.conf

sudo reboot

