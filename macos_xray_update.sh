#!/opt/homebrew/bin/bash
#============================================
funcin()
{
if test -f latest; then
	rm latest
fi
curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest --output latest
tag=`grep "tag_name" latest | cut -d'"' -f4`
	echo -e "1. Mac-intel"
	echo -e "2. Mac-Apple_silicon"
	echo -e "Choose an appropriate version:[1-2]"
	read a
	if [ $a == 1 ]
	then 
		wget -q `grep browser_download_url latest| grep macos-64 | cut -d'"' -f4 | head -n 1`
	elif [ $a == 2 ]
	then
		wget -q `grep browser_download_url latest| grep macos-arm64 | cut -d'"' -f4 | head -n 1`
	else
 	 	 echo "You entered a wrong number，exit！"
       	 exit 0
	fi
	unzip -p Xray*.zip xray > xray
	chmod +x xray
	mv xray ./core
	echo -e "Update geosite and geoip files as well."
	if ! test -d geobackup; then
	  mkdir geobackup
	fi
	mv geoip.dat geobackup/geoip.dat.backup
	mv geosite.dat geobackup/geosite.dat.backup
	wget `curl -s https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest | grep browser_download_url | grep geosite | cut -d'"' -f4 | head -n 1`
	wget `curl -s https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest | grep browser_download_url | grep geoip | cut -d'"' -f4 | head -n 1`
	rm X*.zip
}
#============================================
funcdo()
{
if test -f latest; then
	rm latest
fi
curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest --output latest
tag=`grep "tag_name" latest | cut -d'"' -f4`
xver=`./core --version | awk  'FNR == 1 {print $2}'`

if [[ "$tag" == *"$xver"* ]]
then
	echo -e "You already have the latest version of Xray [$xver]. Skip updating Xray"
	echo -e "Do you want to update geosite/geoip files [y/n]"
	while true; do
    	read yn
    	case $yn in
       	 [Yy]* ) echo "Updating geosite/geoip files"
		 if ! test -d geobackup; then
		   mkdir geobackup
		 fi
		 mv geoip.dat geobackup/geoip.dat.backup
		 mv geosite.dat geobackup/geosite.dat.backup
		 wget -q `curl -s https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest | grep browser_download_url | grep geosite | cut -d'"' -f4 | head -n 1`
		 wget -q `curl -s https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest | grep browser_download_url | grep geoip | cut -d'"' -f4 | head -n 1`; break;;
      	  [Nn]* ) echo "You don't want to change anything; exit"; exit 0;;
      	  * ) echo "Please answer yes or no.";;
    	esac
	done
else 
	echo -e "1. Mac-intel"
	echo -e "2. Mac-Apple_silicon"
	echo -e "Choose an appropriate version:[1-2]"
	read a
	if [ $a == 1 ]
	then 
		wget -q `grep browser_download_url latest| grep macos-64 | cut -d'"' -f4 | head -n 1`
	elif [ $a == 2 ]
	then
		wget -q `grep browser_download_url latest| grep macos-arm64 | cut -d'"' -f4 | head -n 1`
	else
 	 	 echo "You entered a wrong number，exit！"
       	 exit 0
	fi
	unzip -p Xray*.zip xray > xray
	chmod +x xray
	mv core core-$tag
	mv xray ./core
	echo -e "Update geosite and geoip files as well."
	if ! test -d geobackup; then
	  mkdir geobackup
	fi
	mv geoip.dat geobackup/geoip.dat.backup
	mv geosite.dat geobackup/geosite.dat.backup
	wget `curl -s https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest | grep browser_download_url | grep geosite | cut -d'"' -f4 | head -n 1`
	wget `curl -s https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest | grep browser_download_url | grep geoip | cut -d'"' -f4 | head -n 1`
	rm X*.zip
fi
}
#============================================
if ! test -f core; then
echo -e "Your 'core' file is NOT here! This is your current directory: $PWD"
echo -e "Do you want to download core file to the current directory? [y/n]"
while true; do
    	read ny
    	case $ny in
       	 [Yy]* ) echo "Download Xray core file..."
		funcin; break;;
      	 [Nn]* ) echo "Please enter a correct directory for your core file (use absolute path):"
		read cored
		cd $cored
		echo -e "Your working directory is: $PWD Is it correct [y/n]?"
		while true; do
			read tf
    			case $tf in
			[Yy]* ) echo "Updating Xray ..."
				funcdo; break;;
      	  		[Nn]* ) echo "Please enter your directory again"
				read cored2
				cd $cored2
				echo -e "Your working directory is: $PWD. Is it correct [y/n]?";;
			* ) echo "Please answer yes or no.";;
		esac
		done;;
      	  * ) echo "Please answer yes or no.";;
esac
done
else
	funcdo
fi
