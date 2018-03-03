#!/bin/bash

# Define Variables
DESKTOP=0
I3GAPS=0
VERBOSE=0
REBOOT=0


# Stop on errors
set -e;


#read options provided
while getopts vdih: opt; do
	case $opt in 
		h)
			show_help; exit 0;
			;;
		v)
			VERBOSE=1;
			;;
		d)
			DESKTOP=1;
			;;
		i)
			I3GAPS=1;
			;;
		*)
			show_help >&2; exit 1;
			;;
	esac
done


# Show friendly help message
show_help() {
cat << EOF
Usage: ${0##*/} [-hvdi]
Set up a new installation of Ubuntu.

	-h 	display help
	-v	verbose mode
	-d	install desktop programs like Chrome and Sublime
	-i	install i3-gaps
EOF
}

echo test

say() {
	echo -e "\n\e[1m\e[38;5;69m$1\e[m" >&2
}


# Set verbosity
if [ $VERBOSE = 0 ]
then
	exec > /dev/null
fi


say "Starting setup script";


if [ $DESKTOP = 1 ]
then
	say "  Adding Google Chrome Repo";
	wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -;
	echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | sudo tee /etc/apt/sources.list.d/google-chrome.list;

	say "  Adding Sublime Text Repo"
	wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -;
	echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list;
fi


#install curl
say "  Installing Curl";
apt install curl -y


#add nodejs and yarn
say "  Adding NodeJS 7.x Repo";
curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash - 
say "  Adding Yarn Repo";
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list


# Update and install basic programs
say "  Installing Basic Programs"
apt update;
apt upgrade -y;
apt install -y apt-transport-https yarn git nodejs htop
{
	sudo ln -s $(which nodejs) /usr/bin/node
} || {
	say "  Symlink for node --> nodejs already exists"
}

#install docker and docker-compose
if [ -z $(which docker) ] 
then
	say "  Installing Docker"
	wget -q -O ~/Downloads/docker-install.sh https://get.docker.io
	chmod +x ~/Downloads/docker-install.sh
	~/Downloads/docker-install.sh
	say "  Installing Docker-Compose"
	sudo curl -L https://github.com/docker/compose/releases/download/1.19.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
else
	say "  Docker already installed"
fi


if [ $DESKTOP = 1 ]
then
	say "  Installing Desktop Programs"
	apt install -y google-chrome-stable sublime-text gitk
fi


if [ $I3GAPS = 1 ]
then
	say "  Installing i3-gaps dependencies"
	apt install -y libxcb1-dev libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev libxcb-icccm4-dev libyajl-dev libstartup-notification0-dev libxcb-randr0-dev libev-dev libxcb-cursor-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev autoconf libxcb-xrm0 libxcb-xrm-dev automake feh suckless-tools i3status

	say "  Downloading i3-gaps"
	{
		git clone https://www.github.com/Airblader/i3 ~/Downloads/i3-gaps
	} || {
		say "  repo already downloaded"
	}
	say "  Installing i3-gaps"
	(cd ~/Downloads/i3-gaps && autoreconf --force --install && rm -rf build/ && mkdir -p build)
	(cd ~/Downloads/i3-gaps/build && ../configure --prefix=/usr --sysconfdir=/etc --disable-sanitizers && make && sudo make install)
fi


say "Installations complete. Reboot now? [Y/n]" >&2
read REBOOT

if [ -z $REBOOT ] || [ $REBOOT = "y" ]
then
	sudo reboot now
fi
