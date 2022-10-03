#!/bin/bash
if ! command -v xray &> /dev/null; then
  echo -e "Xray is not installed. Do you want to install now? [y/n]"
  while true; do
    	read ny
    	case $ny in
       	 [Yy]* ) echo "Installing Xray ..."
			   bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install; break;;
      	  [Nn]* ) echo "You don't want to change anything; exit"; exit 0;;
      	  * ) echo "Please answer yes or no.";;
    	esac
	done
fi

mkdir -p ~/renewX
	cd ~/renewX
	if [ -d "$PWD" ]
	then
	  if [ "$(ls -A $PWD)" ]; then
    	    echo "Emptying $PWD"
    	    rm -rf *
	  else
   	    echo "$PWD is empty, continue"
	  fi
      else
	  echo "ERROR: Directory not found."
        exit 0
      fi

wget -q https://api.github.com/repos/XTLS/Xray-core/releases/latest
tag=`grep "tag_name" latest | cut -d'"' -f4`
xver=`xray --version | awk  'FNR == 1 {print $2}'`

if [[ "$tag" == *"$xver"* ]]
then
	echo -e "You already have the latest version of Xray [$xver]. Skip updating Xray"
	echo -e "Do you want to update geosite/geoip files [y/n]"
	while true; do
    	read yn
    	case $yn in
       	 [Yy]* ) echo "Updating geosite/geoip files"
			   wget -q `curl -s https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest | grep browser_download_url | grep geosite | cut -d'"' -f4 | head -n 1`
			   wget -q `curl -s https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest | grep browser_download_url | grep geoip | cut -d'"' -f4 | head -n 1`
			   cp geoip.dat /usr/local/share/xray/geoip.dat
			   cp geosite.dat /usr/local/share/xray/geosite.dat; break;;
      	  [Nn]* ) echo "You don't want to change anything; exit"; exit 0;;
      	  * ) echo "Please answer yes or no.";;
    	esac
	done
else 
	echo -e "1. linux-64"
	echo -e "2. linux-arm64"
	echo -e "Choose an appropriate version:[1-2]"
	read a
	if [ $a == 1 ]
	then 
		wget -q `grep browser_download_url latest| grep linux-64 | cut -d'"' -f4 | head -n 1`
	elif [ $a == 2 ]
	then
		wget -q `grep browser_download_url latest| grep linux-arm64 | cut -d'"' -f4 | head -n 1`
	else
 	 	 echo "You entered a wrong number，exit！"
       	 exit 0
	fi
	unzip Xray*.zip
	mv xray /usr/local/bin/xray
	echo -e "Update geosite and geoip files as well."
	wget `curl -s https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest | grep browser_download_url | grep geosite | cut -d'"' -f4 | head -n 1`
	wget `curl -s https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest | grep browser_download_url | grep geoip | cut -d'"' -f4 | head -n 1`
	cp geoip.dat.1 /usr/local/share/xray/geoip.dat
	cp geosite.dat.1 /usr/local/share/xray/geosite.dat
fi


systemctl restart xray
sleep 1
systemctl status xray
