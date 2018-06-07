#!/bin/bash
# Downsize and prep from standard Raspbian Image

#########Setup Variables###############
#Github public sshkeys
github_user="githubusername"
#New Username for SSH Access
newuser="mtsc"
#Changing the hostname of the pi
hostname="hostnamehere"

#IP Info to set below
ipaddress="0.0.0.0/24"
gateway="0.0.0.0"
#DNS Servers, put a space between if multiple
dns="208.67.222.222 1.1.1.1"


#########Begin Script###############

#Lock the password for pi since it's default, and we won't be using it anymore
##sudo usermod --lock pi
#Create the new ssh only user with no password, and (yes y) hits enter to all the "info"
yes y | sudo adduser ${newuser} --disabled-password

#Update this cow
#sudo rpi-update && sudo apt -y update && sudo apt -y upgrade

#Get rid of extra packages we don't need
#sudo apt-get purge --auto-remove scratch debian-reference-en dillo idle3 python3-tk idle python-pygame python-tk lightdm gnome-themes-standard gnome-icon-theme raspberrypi-artwork gvfs-backends gvfs-fuse desktop-base lxpolkit netsurf-gtk zenity xdg-utils mupdf gtk2-engines alsa-utils  lxde lxtask menu-xdg gksu midori xserver-xorg xinit xserver-xorg-video-fbdev libraspberrypi-dev libraspberrypi-doc dbus-x11 libx11-6 libx11-data libx11-xcb1 x11-common x11-utils lxde-icon-theme gconf-service gconf2-common xserver* ^x11 ^libx ^lx samba* -y

#Add a few, plus raspi-config which we convieniently removed from the above list of packages as a dependency?
#sudo apt -y install vim raspi-config dnsutils

#Clean up apt
#sudo apt-get clean -y && sudo apt-get autoremove -y

#### change the boot to non-gui and console only, expand the filesystem and properly update the hostname
##  See https://raspberrypi.stackexchange.com/a/66939/8375 for a list of all the raspi-config magic you may want to automate.
sudo raspi-config nonint do_boot_behaviour B1
sudo raspi-config nonint do_expand_rootfs
sudo raspi-config nonint do_hostname "${hostname}"

#Blow away the default ssh config and recreate one from scratch
sudo rm /etc/ssh/ssh_host_* && sudo dpkg-reconfigure openssh-server
#Create the .ssh folder and the authorized keys
sudo -S -u ${newuser} mkdir /home/${newuser}/.ssh && sudo -S -u ${newuser} touch /home/${newuser}/.ssh/authorized_keys
sudo  -S -u ${newuser} ssh-keygen -t rsa -C "${hostname}" -f "/home/${newuser}/.ssh/id_rsa" -P ""

#### Get SSH keys for authentication from github and put the public key into authorized_keys for the new user we created

echo -e "GET http://github.com HTTP/1.0\n\n" | nc github.com 80 > /dev/null 2>&1
if [ $? -eq 0 ]; then
   (sudo -S -u ${newuser} touch /home/${newuser}/.ssh/authorized_keys)
   #chown -R $(id -u pi):$(id -g pi) /home/pi/.ssh
   sudo curl -sSL https://github.com/${github_user}.keys >> /home/${newuser}/.ssh/authorized_keys
   echo "Keys installed from gitub.com"
 else
   echo "Won't install ssh keys, github.com couldn't be reached."
 fi

#Will disable password authentication through ssh
sed -i 's|[#]*PasswordAuthentication yes|PasswordAuthentication no|g' /etc/ssh/sshd_config

#One liner for static ip config
sudo sed -i "$ a\interface eth0\nstatic ip_address=${ipaddress}\nstatic routers=${gateway}\nstatic domain_name_servers=${dns}\n" /etc/dhcpcd.conf

cat /home/${newuser}/.ssh/authorized_keys
tail -n 5 /etc/dhcpcd.conf
read -n1 -r -p "All done, Press any key to continue..." key

sudo reboot

