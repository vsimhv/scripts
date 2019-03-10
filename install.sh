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
  open-vm-tools \
  open-vm-tools-desktop \
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
  nmap

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

# enable user namespaces

echo 'kernel.unprivileged_userns_clone=1' > /etc/sysctl.d/00-local-userns.conf
service procps restart

# add $user to groups
usermod -G docker,sudo $user

# create directories
directories=(files containers work)
for dir in ${directories[*]}; do
  mkdir -p /home/$user/$dir
done

chown -R $user:$user /home/$user

