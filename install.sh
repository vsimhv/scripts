#!/bin/bash

user=$1

if [ -z $user ]; then
  echo "Usage $0 user_name"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  return 1
fi

apt-get update && apt-get dist-upgrade -y

# install tools
apt-get install -y sudo \
  git \
  screen \
  i3 \
  rofi \
  sakura \
  zsh \
  nautilus \
  xserver-xorg \
  xinit \
  maim \
  slop \
  zenity \
  man \
  zip \
  feh \
  net-tools \
  wget \
  slim \
  ruby \
  ruby-dev \
  zlib1g-dev \
  aptitude \
  vim \
  ipcalc \
  socat \
  golang \
  nmap \
  zsh-theme-powerlevel9k \
  virt-what

#install tools for hypervisor
  if [[ $(virt-what |grep virtualbox) -eq 0 ]] ; then
    echo "vbox detected"
    apt install -y virtualbox-guest-x11 virtualbox-guest-dkms
  elif [[ $(virt-what |grep vmware) -eq 0 ]] ; then
    echo "vmware detected"
    apt install -y open-vm-tools  open-vm-tools-desktop 
  else
    echo "barebone, skipping tools instalation"
  fi
 
# docker
apt-get install -y \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg2 \
     software-properties-common

curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
apt-key fingerprint 0EBFCD88

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"

apt-get update && apt-get install -y docker-ce
update-rc.d docker defaults

# add opera repo and install
add-apt-repository \
   "deb [arch=amd64] http://deb.opera.com/opera-stable/ \
    stable \
    non-free"

wget -O - https://deb.opera.com/archive.key | apt-key add -

apt update 
apt install -y opera-stable


# clean garbage
apt autoremove -y 
apt clean all

# enable user namespaces

echo 'kernel.unprivileged_userns_clone=1' > /etc/sysctl.d/00-local-userns.conf
service procps restart

# add $user to groups
usermod -G docker,sudo $user

# create directories
directories=(files containers work projects/linux)
for dir in ${directories[*]}; do
  mkdir -p /home/$user/$dir
done

#install environment
su - $user -c "$(pwd)/pre.sh"
chown -R $user:$user /home/$user

